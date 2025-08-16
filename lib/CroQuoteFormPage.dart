import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 웹 DOM/JS interop
import 'package:web/web.dart' as web;
import 'package:js/js.dart' as js;           // allowInterop
import 'package:js/js_util.dart' as jsu;     // getProperty 등

class CroQuoteFormPage extends StatefulWidget {
  const CroQuoteFormPage({super.key});
  @override
  State<CroQuoteFormPage> createState() => _CroQuoteFormPageState();
}

class _CroQuoteFormPageState extends State<CroQuoteFormPage> {
  int _step = 0;

  // 컨트롤러
  final _projectCtrl = TextEditingController();
  final _indicationCtrl = TextEditingController();
  final _treatCtrl = TextEditingController();
  final _fuCtrl = TextEditingController();
  final _monitorCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  // 선택 값
  String? _category;         // 의약품/의료기기/기타
  String? _detailSubject;    // 카테고리별 상세
  String? _institutionType;  // SIT/IIT (기타면 숨김)
  String? _siteCount;        // 1개~6개이상
  String? _region;           // 서울/경기/강원/충청/전라/경상/제주
  DateTime? _startDate;
  DateTime? _endDate;
  String? _crfType;          // 전자/종이/해당없음
  final Set<String> _scope = {}; // 업무범위(복수)

  // 파일 (선택)
  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSize;

  bool _submitting = false;

  // 스크롤 및 섹션 키
  final _scroll = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(16, (_) => GlobalKey());

  // 유효성
  bool get _validProject =>
      _projectCtrl.text.trim().isNotEmpty &&
          _projectCtrl.text.trim().length <= 50;
  bool get _validCategory => _category != null;

  List<String> get _detailOptions {
    switch (_category) {
      case '의료기기':
        return ['탐색', '확증', '기타'];
      case '의약품':
        return ['비임상', '1상', '2상', '3상', '4상', 'PMS', '기타'];
      case '기타':
        return ['건기식', '화장품', '기타'];
      default:
        return [];
    }
  }

  bool get _validDetail => _detailOptions.isEmpty || _detailSubject != null;
  bool get _validIndication =>
      _indicationCtrl.text.trim().isNotEmpty &&
          _indicationCtrl.text.trim().length <= 50;

  int _nextIndexAfterIndication() => _needInstitution ? 4 : 5;
  bool get _needInstitution => _category != '기타';
  bool get _validInstitution => _needInstitution ? _institutionType != null : true;

  bool get _validSiteCount => _siteCount != null;
  bool get _validRegion => _region != null;

  // 헬퍼: 오늘(자정) 날짜
  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

// 기존 _validPeriod 교체
  bool get _validPeriod =>
      _startDate != null &&
          _endDate != null &&
          !_endDate!.isBefore(_startDate!) &&       // 종료일 >= 시작일
          !_startDate!.isBefore(_todayDate());      // 시작일 >= 오늘

  bool get _validTreat => RegExp(r'^\d{1,2}$').hasMatch(_treatCtrl.text.trim());
  bool get _validFU => RegExp(r'^\d{1,2}$').hasMatch(_fuCtrl.text.trim());
  bool get _validMonitoring => RegExp(r'^\d{1,2}$').hasMatch(_monitorCtrl.text.trim());
  bool get _validCRF => _crfType != null;
  bool get _validScope => _scope.isNotEmpty;

  // UI 상수
  static const double _kFieldHeight = 48.0;
  static const double _kMaxWidth = 860.0;

  void _nextIf(bool ok, int to) {
    if (ok && _step < to) {
      setState(() => _step = to);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(to));
    }
  }

  void _truncateStep(int keepUpTo) {
    if (_step > keepUpTo) {
      setState(() => _step = keepUpTo);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSection(keepUpTo));
    }
  }

  Future<void> _scrollToSection(int index) async {
    if (!mounted || index < 0 || index >= _sectionKeys.length) return;
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    final offset = _scroll.offset + position.dy - 100;
    await _scroll.animateTo(
      offset.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = _todayDate();
    final last  = DateTime(today.year + 5, 12, 31);

    // 시작일 선택: 최소 오늘
    if (isStart) {
      final initial = (_startDate != null && !_startDate!.isBefore(today)) ? _startDate! : today;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: today,     // 과거 비허용
        lastDate: last,
      );
      if (picked != null) {
        setState(() => _startDate = picked);
        _nextIf(_validPeriod, 8);
      }
      return;
    }

    // 종료일 선택: 최소 max(오늘, 시작일)
    final minEnd = (_startDate != null && !_startDate!.isBefore(today)) ? _startDate! : today;
    final initialEnd = (_endDate != null && !_endDate!.isBefore(minEnd)) ? _endDate! : minEnd;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialEnd,
      firstDate: minEnd,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _nextIf(_validPeriod, 8);
    }
  }

  void _onCategorySelect(String v) {
    setState(() {
      _category = v;
      _detailSubject = null;
      _institutionType = null;
    });
    _truncateStep(2);
    _nextIf(_validCategory, 2);
  }

  // ---- 파일 선택(웹 전용): package:web + js/js_util ----
  Future<void> _pickFileWeb() async {
    final input = web.HTMLInputElement();
    input.type = 'file';
    input.accept = '.pdf,.png,.jpg,.jpeg,.txt,.doc,.docx';
    input.style.display = 'none';
    web.document.body?.append(input);

    final completer = Completer<void>();
    web.EventListener? changeListener;
    web.EventListener? loadListener;

    void cleanUp() {
      if (changeListener != null) input.removeEventListener('change', changeListener!);
      input.remove();
    }

    changeListener = js.allowInterop((web.Event e) {
          () async {
        try {
          final files = input.files;
          if (files != null && files.length > 0) {
            final file = files.item(0)!; // web.File
            final reader = web.FileReader();

            loadListener = js.allowInterop((web.Event _) {
              final res = jsu.getProperty<String?>(reader, 'result'); // dataURL
              if (res != null) {
                final idx = res.indexOf(',');
                if (idx >= 0) {
                  final b64 = res.substring(idx + 1);
                  try {
                    final bytes = base64Decode(b64);
                    setState(() {
                      _fileBytes = bytes;
                      _fileName = file.name;
                      _fileSize = file.size.toInt();
                    });
                  } catch (_) {}
                }
              }
              reader.removeEventListener('load', loadListener!);
              cleanUp();
              completer.complete();
            }) as web.EventListener;

            reader.addEventListener('load', loadListener!);
            reader.readAsDataURL(file);
          } else {
            cleanUp(); // 취소
            completer.complete();
          }
        } catch (_) {
          cleanUp();
          completer.complete();
        }
      }();
    }) as web.EventListener;

    input.addEventListener('change', changeListener);
    input.click();

    await completer.future;
  }

  Future<void> _submit() async {
    // 클라이언트 유효성
    if (!(_validProject && _validCategory && _validDetail && _validIndication &&
        _validInstitution && _validSiteCount && _validRegion && _validPeriod &&
        _validTreat && _validFU && _validMonitoring && _validCRF && _validScope)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력 항목을 다시 확인해주세요.')),
      );
      return;
    }

    if (_fileBytes != null && _fileBytes!.length > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일은 2MB 이하만 업로드 가능합니다.')),
      );
      return;
    }

    // ----- scope_list 전송용: All → 실제 전체 항목으로 변환 -----
    const allLabel = 'All';
    const allReal = [
      'All','MW(Protocol)','DM','STAT','Monitoring',
      'MW(CSR)','IND/IMDA','Audit','Inspection',
    ];
    final scopeToSend = _scope.contains(allLabel)
        ? allReal
        : _scope.toList();

    setState(() => _submitting = true);

    try {
      final uri = Uri.parse('https://sonjobdamd.com/func/hcsave_cro_quote.php');
      final req = http.MultipartRequest('POST', uri);
      final p = await SharedPreferences.getInstance();
      final userJson = p.getString('userInfo');
      String userId = '';
      if (userJson != null) {
        final Map<String, dynamic> userInfo = jsonDecode(userJson);
        userId = userInfo['userid'];
      }

      req.fields.addAll({
        'project_name'     : _projectCtrl.text.trim(),
        "userId"           : userId,
        'category'         : _category ?? '',
        'sub_category'     : _detailSubject ?? '',
        'indication'       : _indicationCtrl.text.trim(),
        'institution_type' : _needInstitution ? (_institutionType ?? '') : '',
        'site_count'       : _siteCount ?? '',
        'region'           : _region ?? '',
        'start_date'       : _fmt(_startDate!),
        'end_date'         : _fmt(_endDate!),
        'treatment_months' : _treatCtrl.text.trim(),
        'fu_months'        : _fuCtrl.text.trim(),
        'monitoring_count' : _monitorCtrl.text.trim(),
        'crf_type'         : _crfType ?? '',
        'scope_list'       : jsonEncode(scopeToSend),
        'memo'             : _memoCtrl.text.trim(),
      });

      if (_fileBytes != null && _fileName != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'attachment',
          _fileBytes!,
          filename: _fileName!,
        ));
      }

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body);

      if (!mounted) return;
      if (data['success'] == true) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('전송 완료'),
            content: const Text(
              '정보 기입이 완료되었습니다.\n파트너사의 확인을 거처 견적을 확인하실 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final msg = data['message'] ?? (data['errors']?.join('\n') ?? '저장 실패');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _projectCtrl.dispose();
    _indicationCtrl.dispose();
    _treatCtrl.dispose();
    _fuCtrl.dispose();
    _monitorCtrl.dispose();
    _memoCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ==== UI helpers ====

  Widget _stepCard({
    required int index,
    required String title,
    required Widget child,
  }) {
    if (_step < index) return const SizedBox.shrink();
    return Card(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE7E5EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }

  InputDecoration _decor({String? hint}) => InputDecoration(
    hintText: hint,
    border: const OutlineInputBorder(),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _uniformTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction? action,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    String? errorText,
  }) {
    return SizedBox(
      height: _kFieldHeight,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: action,
        onChanged: (v) {
          if (onChanged != null) onChanged(v);
          setState(() {});
        },
        onSubmitted: onSubmitted,
        decoration: _decor(hint: hint).copyWith(errorText: errorText),
      ),
    );
  }

  // 일반 칩 행(단일/복수) — scope 전용이 아닌 곳에서 사용
  Widget _chipRow<T>({
    required List<T> items,
    required T? value,
    required void Function(T) onSelect,
    bool multi = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kFieldHeight),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            final selected = multi ? _scope.contains(e.toString()) : (value != null && value == e);
            return ChoiceChip(
              label: Text(e.toString()),
              selected: selected,
              onSelected: (_) {
                if (multi) {
                  setState(() {
                    if (_scope.contains(e.toString())) {
                      _scope.remove(e.toString());
                    } else {
                      _scope.add(e.toString());
                    }
                  });
                } else {
                  onSelect(e);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===== 업무범위 전용 칩(ALL 로직 포함) =====
  Widget _scopeChips() {
    const allLabel = 'All';
    const others = [
      'MW(Protocol)','DM','STAT','Monitoring',
      'MW(CSR)','IND/IMDA','Audit','Inspection',
    ];
    final allSelected = _scope.contains(allLabel);

    List<String> items = [allLabel, ...others];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kFieldHeight),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((label) {
            final bool isAll = label == allLabel;
            final bool selected = _scope.contains(label);

            // All이 선택되어 있으면 다른 칩들은 비활성화
            final bool disabled = !isAll && allSelected;

            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: disabled ? null : (_) {
                setState(() {
                  if (isAll) {
                    // All 토글
                    if (selected) {
                      // All 해제 -> 아무것도 선택 안 된 상태로
                      _scope.clear();
                    } else {
                      // All 선택 -> All만 남기고 나머지 제거
                      _scope
                        ..clear()
                        ..add(allLabel);
                    }
                  } else {
                    // 개별 항목 토글
                    if (selected) {
                      _scope.remove(label);
                    } else {
                      _scope.add(label);
                    }
                    // 모든 개별 항목이 선택되면 All로 치환
                    final allOthersSelected = others.every(_scope.contains);
                    if (allOthersSelected) {
                      _scope
                        ..clear()
                        ..add(allLabel);
                    } else {
                      // All이 선택된 상태에서 개별을 건드리면 All 해제(하지만 disabled라 원래 못 누름)
                      _scope.remove(allLabel);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _dateTextStr(DateTime? d) => d == null ? '선택' : _fmt(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRO 의뢰서 작성'), centerTitle: true),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxWidth),
            child: Column(
              children: [
                _stepCard(
                  index: 0,
                  title: '프로젝트명 (50자 미만)',
                  child: _uniformTextField(
                    controller: _projectCtrl,
                    hint: '예) 24년 2상 임상시험',
                    action: TextInputAction.next,
                    onSubmitted: (_) => _nextIf(_validProject, 1),
                    errorText: _projectCtrl.text.isEmpty || _validProject ? null : '50자 이내로 입력',
                  ),
                ),
                _stepCard(
                  index: 1,
                  title: '구분',
                  child: _chipRow<String>(
                    items: const ['의약품', '의료기기', '기타'],
                    value: _category,
                    onSelect: (v) => _onCategorySelect(v),
                  ),
                ),
                _stepCard(
                  index: 2,
                  title: '임상시험 주체',
                  child: _detailOptions.isEmpty
                      ? const Text('선택할 항목이 없습니다.')
                      : _chipRow<String>(
                    items: _detailOptions,
                    value: _detailSubject,
                    onSelect: (v) {
                      setState(() => _detailSubject = v);
                      _nextIf(_validDetail, 3);
                    },
                  ),
                ),
                _stepCard(
                  index: 3,
                  title: '적응증 (50자 미만)',
                  child: _uniformTextField(
                    controller: _indicationCtrl,
                    hint: '예) 당뇨, 고혈압 등',
                    action: TextInputAction.next,
                    onSubmitted: (_) => _nextIf(_validIndication, _nextIndexAfterIndication()),
                    onChanged: (_) {
                      setState(() {});
                      if (_validIndication) {
                        _nextIf(true, _nextIndexAfterIndication());
                      }
                    },
                    errorText: _indicationCtrl.text.isEmpty || _validIndication ? null : '50자 이내로 입력',
                  ),
                ),
                if (_needInstitution)
                  _stepCard(
                    index: 4,
                    title: '임상시험 기관',
                    child: _chipRow<String>(
                      items: const ['SIT', 'IIT'],
                      value: _institutionType,
                      onSelect: (v) {
                        setState(() => _institutionType = v);
                        _nextIf(_validInstitution, 5);
                      },
                    ),
                  ),
                _stepCard(
                  index: 5,
                  title: '기관수',
                  child: _chipRow<String>(
                    items: const ['1개', '2개', '3개', '4개', '5개', '6개이상'],
                    value: _siteCount,
                    onSelect: (v) {
                      setState(() => _siteCount = v);
                      _nextIf(_validSiteCount, 6);
                    },
                  ),
                ),
                _stepCard(
                  index: 6,
                  title: '기관 위치',
                  child: _chipRow<String>(
                    items: const ['서울', '경기', '강원', '충청', '전라', '경상', '제주'],
                    value: _region,
                    onSelect: (v) {
                      setState(() => _region = v);
                      _nextIf(_validRegion, 7);
                    },
                  ),
                ),
                _stepCard(
                  index: 7,
                  title: '총기간',
                  child: SizedBox(
                    height: _kFieldHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(isStart: true),
                            child: Text('시작일: ${_dateTextStr(_startDate)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(isStart: false),
                            child: Text('종료일: ${_dateTextStr(_endDate)}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 총기간 섹션 아래에 추가 (선택사항)
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    !_startDate!.isBefore(_todayDate())
                        ? (!_endDate!.isBefore(_startDate!) ? '' : '종료일이 시작일보다 빠를 수 없습니다.')
                        : '시작일은 오늘 이후만 가능합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _validPeriod ? Colors.green : Colors.red,
                    ),
                  ),
                ],
                _stepCard(
                  index: 8,
                  title: '치료기간 (개월, 두자리 숫자)',
                  child: _uniformTextField(
                    controller: _treatCtrl,
                    keyboardType: TextInputType.number,
                    hint: '예) 06',
                    action: TextInputAction.next,
                    onSubmitted: (_) => _nextIf(_validTreat, 9),
                    errorText: _treatCtrl.text.isEmpty || _validTreat ? null : '두자리 숫자',
                  ),
                ),
                _stepCard(
                  index: 9,
                  title: '1인당 FU기간 (개월, 두자리 숫자)',
                  child: _uniformTextField(
                    controller: _fuCtrl,
                    keyboardType: TextInputType.number,
                    hint: '예) 03',
                    action: TextInputAction.next,
                    onSubmitted: (_) => _nextIf(_validFU, 10),
                    errorText: _fuCtrl.text.isEmpty || _validFU ? null : '두자리 숫자',
                  ),
                ),
                _stepCard(
                  index: 10,
                  title: '모니터링 횟수 (두자리 숫자)',
                  child: _uniformTextField(
                    controller: _monitorCtrl,
                    keyboardType: TextInputType.number,
                    hint: '예) 06',
                    action: TextInputAction.next,
                    onSubmitted: (_) => _nextIf(_validMonitoring, 11),
                    errorText: _monitorCtrl.text.isEmpty || _validMonitoring ? null : '두자리 숫자',
                  ),
                ),
                _stepCard(
                  index: 11,
                  title: '증례기록서(CRF) 형태',
                  child: _chipRow<String>(
                    items: const ['전자', '종이', '해당없음'],
                    value: _crfType,
                    onSelect: (v) {
                      setState(() => _crfType = v);
                      _nextIf(_validCRF, 12);
                    },
                  ),
                ),
                _stepCard(
                  index: 12,
                  title: '업무범위 (복수 선택)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _scopeChips(), // ← All 로직 포함한 전용 UI
                      const SizedBox(height: 8),
                      Text(
                        _scope.isEmpty ? '선택 필요' : '선택: ${_scope.join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _scope.isEmpty ? Colors.red : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_validScope) _nextIf(true, 13);
                            setState(() {});
                          },
                          child: const Text('다음'),
                        ),
                      ),
                    ],
                  ),
                ),
                _stepCard(
                  index: 13,
                  title: '안내 가능한 첨부파일 (선택, 2MB 이하)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickFileWeb,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('파일 선택'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fileName == null
                                  ? '선택된 파일 없음 (건너뛰기 가능)'
                                  : '$_fileName (${(_fileSize ?? 0) ~/ 1024} KB)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '허용: pdf, png, jpg, jpeg, txt, doc, docx / 최대 2MB',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => _nextIf(true, 14),
                          child: const Text('다음'),
                        ),
                      ),
                    ],
                  ),
                ),
                _stepCard(
                  index: 14,
                  title: '추가 요청/비고 (선택) & 최종 확인',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120,
                        child: TextField(
                          controller: _memoCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _decor(hint: '기타 요청사항이 있으면 작성해주세요.'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _reviewTile(),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('견적 의뢰 제출'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewTile() {
    String period = (_startDate == null || _endDate == null)
        ? '-'
        : '${_dateTextStr(_startDate)} ~ ${_dateTextStr(_endDate)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E5EF)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('프로젝트명', _projectCtrl.text),
            _kv('구분', _category),
            _kv('임상시험 주체', _detailSubject),
            _kv('적응증', _indicationCtrl.text),
            _kv('임상시험 기관', _needInstitution ? _institutionType : '(구분: 기타 — 입력 불필요)'),
            _kv('기관수', _siteCount),
            _kv('기관 위치', _region),
            _kv('총기간', period),
            _kv('치료기간(개월)', _treatCtrl.text),
            _kv('FU기간(개월)', _fuCtrl.text),
            _kv('모니터링 횟수', _monitorCtrl.text),
            _kv('CRF 형태', _crfType),
            _kv('업무범위', _scope.join(', ')),
            _kv('첨부파일', _fileName ?? '없음'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(v == null || v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }
}

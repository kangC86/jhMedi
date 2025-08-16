import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Kakao 주소 팝업(web)
import 'helpers/kakaoAddressHelper.dart';

class CompanyJoinPage extends StatefulWidget {
  final String userType; // "client" | "partner"
  const CompanyJoinPage({super.key, required this.userType});

  @override
  State<CompanyJoinPage> createState() => _CompanyJoinPageState();
}

class _CompanyJoinPageState extends State<CompanyJoinPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _userIdController = TextEditingController();
  final _pwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _mainAddressController = TextEditingController();   // 검색 주소
  final _detailAddressController = TextEditingController(); // 상세 주소
  final _bizNumberController = TextEditingController();     // client 전용
  final _corpNumberController = TextEditingController();    // client 전용

  // FocusNodes (특수 상황에서만 사용)
  final _fDetailAddr = FocusNode();

  // 상태
  Timer? _debounce;
  String? _idMessage;
  Color? _idMessageColor;
  bool _idChecked = false;
  bool _isSubmitting = false;
  bool _pwSame = true;
  bool _mailValid = false;

  // 정규식
  final _reUserId = RegExp(r'^[a-z0-9]{1,20}$');
  final _rePwd = RegExp(r'^[A-Za-z0-9!@#\$%^&*]{1,20}$'); // 공백 불가, 대문자 선택
  final _reName = RegExp(r'^[\uAC00-\uD7A3a-zA-Z0-9]{1,15}$');
  final _reEmail = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

  // 보기 포맷(하이픈 포함)
  final _rePhoneView = RegExp(r'^\d{3}-\d{4}-\d{4}$');
  final _reBizView = RegExp(r'^\d{3}-\d{2}-\d{5}$');
  final _reCorpView = RegExp(r'^\d{6}-\d{7}$');

  bool get _isClient => widget.userType == 'client';
  bool get _isPartner => widget.userType == 'partner';

  @override
  void initState() {
    super.initState();

    // ID 중복체크 디바운스
    _userIdController.addListener(_onIdChanged);

    // 비번 동일성
    _pwdController.addListener(_onPwChanged);
    _confirmPwdController.addListener(_onPwChanged);

    // 이메일 포맷
    _emailController.addListener(() {
      setState(() => _mailValid = _reEmail.hasMatch(_emailController.text.trim()));
    });

    // 전화번호 포맷팅
    _phoneController.addListener(() {
      final digits = _digitsOnly(_phoneController.text);
      String out = digits;
      if (digits.length >= 4 && digits.length <= 7) {
        out = '${digits.substring(0, 3)}-${digits.substring(3)}';
      } else if (digits.length >= 8) {
        out =
        '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
      }
      _setTextSafely(_phoneController, out);
    });

    // client 전용 포맷팅
    _bizNumberController.addListener(() {
      if (!_isClient) return;
      final d = _digitsOnly(_bizNumberController.text);
      String out = d;
      if (d.length >= 6) {
        out = '${d.substring(0, 3)}-${d.substring(3, 5)}-${d.substring(5, d.length > 10 ? 10 : d.length)}';
      } else if (d.length >= 4) {
        out = '${d.substring(0, 3)}-${d.substring(3)}';
      }
      _setTextSafely(_bizNumberController, out);
    });

    _corpNumberController.addListener(() {
      if (!_isClient) return;
      final d = _digitsOnly(_corpNumberController.text);
      String out = d;
      if (d.length >= 7) {
        out = '${d.substring(0, 6)}-${d.substring(6, d.length > 13 ? 13 : d.length)}';
      }
      _setTextSafely(_corpNumberController, out);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _userIdController.dispose();
    _pwdController.dispose();
    _confirmPwdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _mainAddressController.dispose();
    _detailAddressController.dispose();
    _bizNumberController.dispose();
    _corpNumberController.dispose();

    _fDetailAddr.dispose();

    super.dispose();
  }

  // ===== Listeners =====

  void _onIdChanged() {
    final id = _userIdController.text.trim();
    _idChecked = false;
    _idMessage = null;
    _debounce?.cancel();

    if (id.isEmpty) {
      setState(() {});
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final resp = await http.post(
          Uri.parse('https://sonjobdamd.com/func/hccheckid.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userid': id}),
        );
        final data = jsonDecode(resp.body);
        setState(() {
          final exists = data['exists'] == true;
          _idChecked = !exists;
          _idMessage = exists ? '이미 사용중인 아이디입니다' : '사용가능한 아이디입니다';
          _idMessageColor = exists ? Colors.red : Colors.green;
        });
      } catch (_) {
        setState(() {
          _idChecked = false;
          _idMessage = '확인 실패. 다시 시도해주세요';
          _idMessageColor = Colors.red;
        });
      }
    });
  }

  void _onPwChanged() {
    setState(() => _pwSame = _pwdController.text == _confirmPwdController.text);
  }

  // ===== Utils =====
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
  void _setTextSafely(TextEditingController c, String next) {
    if (c.text == next) return;
    c.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
  }

  void _openAddressPopup() {
    KakaoAddressHelper.openAddressPopup((selectedAddress) {
      setState(() {
        _mainAddressController.text = selectedAddress;
      });
      // ✅ 특수상황: 팝업 닫힌 직후에만 상세주소로 직접 포커스 이동
      _fDetailAddr.requestFocus();
    });
  }

  bool _validateAll() {
    final ok = _formKey.currentState!.validate();
    return ok && _idChecked && _pwSame && _mailValid;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력값을 확인해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final fullAddress =
      '${_mainAddressController.text.trim()} ${_detailAddressController.text.trim()}'.trim();

      final body = {
        'userType': widget.userType, // "client" or "partner"
        'userId': _userIdController.text.trim(),
        'pwd': _pwdController.text,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'company_name': _companyNameController.text.trim(),
        'address': _isClient ? fullAddress : null,                 // partner는 주소 미전송
        'biz_number': _isClient ? _bizNumberController.text.trim() : null,
        'corp_number': _isClient ? _corpNumberController.text.trim() : null,
      };

      final resp = await http.post(
        Uri.parse('https://sonjobdamd.com/func/hcregister.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('회원가입 신청 완료'),
            content: Text('가입 승인 결과는 메일(${_emailController.text})로 전달해 드리겠습니다.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '등록에 실패했습니다.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입 (${_isClient ? '의뢰사' : '파트너사'})')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(), // ✅ 탭 순서 정책
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 아이디
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: TextFormField(
                    controller: _userIdController,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(), // ✅ 엔터=다음
                    decoration: const InputDecoration(labelText: '아이디'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return '아이디 입력';
                      if (!_reUserId.hasMatch(s)) return '영소문자/숫자 1~20자';
                      if (!_idChecked) return '아이디 중복 확인 중 또는 사용 불가';
                      return null;
                    },
                  ),
                ),
                if (_idMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(_idMessage!, style: TextStyle(color: _idMessageColor)),
                  )
                else
                  const SizedBox(height: 8),

                // 2. 비밀번호
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: TextFormField(
                    controller: _pwdController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    validator: (v) {
                      final s = v ?? '';
                      if (s.isEmpty) return '비밀번호 입력';
                      if (!_rePwd.hasMatch(s)) return '영문/숫자/기호(!@#\$%^&*) 1~20자';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 3. 비밀번호 확인
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: TextFormField(
                    controller: _confirmPwdController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '비밀번호 확인'),
                    validator: (v) {
                      if (_pwdController.text.isEmpty) return '비밀번호 먼저 입력';
                      if (_pwdController.text != (v ?? '')) return '비밀번호가 다릅니다';
                      return null;
                    },
                  ),
                ),
                if (!_pwSame)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('비밀번호가 다릅니다', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),

                // 4. 이름
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '이름'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return '이름 입력';
                      if (!_reName.hasMatch(s)) return '한글/영문/숫자 1~15자';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 5. 연락처
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '연락처 (예: 010-1234-5678)'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return '연락처 입력';
                      if (!_rePhoneView.hasMatch(s)) return '전화번호 형식 오류';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 6. 이메일
                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return '이메일 입력';
                      if (!_reEmail.hasMatch(s)) return '이메일 형식 오류';
                      return null;
                    },
                  ),
                ),
                if (_emailController.text.isNotEmpty && !_mailValid)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('이메일 형식이 아닙니다', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),

                // 7. 기업명
                FocusTraversalOrder(
                  order: const NumericFocusOrder(7),
                  child: TextFormField(
                    controller: _companyNameController,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    decoration: const InputDecoration(labelText: '기업명'),
                    validator: (v) => ((v ?? '').trim().isEmpty) ? '기업명 입력' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // 8~10. 주소(검색/상세) — client만
                if (_isClient) ...[
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mainAddressController,
                            readOnly: true,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () => FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                              labelText: '주소 (검색으로 입력)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return '주소를 검색해 입력하세요';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FocusTraversalGroup(
                          descendantsAreFocusable: false, // 탭 포커스 건너뜀
                          child: ElevatedButton(
                            onPressed: _openAddressPopup,
                            child: const Text('주소검색'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(9),
                    child: TextFormField(
                      focusNode: _fDetailAddr,
                      controller: _detailAddressController,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: '상세주소',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return '상세주소 입력';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 11. 사업자등록번호 — client만
                if (_isClient)
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(10),
                    child: TextFormField(
                      controller: _bizNumberController,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: '사업자등록번호/고유번호 (예: 000-00-00000)',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return '사업자/고유번호 입력';
                        if (!_reBizView.hasMatch(s)) return '형식: 000-00-00000';
                        return null;
                      },
                    ),
                  ),
                if (_isClient) const SizedBox(height: 16),

                // 12. 법인번호 — client만
                if (_isClient)
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(11),
                    child: TextFormField(
                      controller: _corpNumberController,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: '법인번호 (예: 000000-0000000)',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return '법인번호 입력';
                        if (!_reCorpView.hasMatch(s)) return '형식: 000000-0000000';
                        return null;
                      },
                    ),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('회원가입 신청'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

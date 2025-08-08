import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'helpers/kakaoAddressHelper.dart';

class CompanyJoinPage extends StatefulWidget {
  final String userType; // "client" | "actor" | "master"
  const CompanyJoinPage({super.key, required this.userType});

  @override
  State<CompanyJoinPage> createState() => _CompanyJoinPageState();
}

class _CompanyJoinPageState extends State<CompanyJoinPage> {
  // controllers
  final _userIdController = TextEditingController();
  final _pwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _mainAddressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _bizNumberController = TextEditingController();
  final _corpNumberController = TextEditingController();

  // debouncer
  Timer? _debounce;

  // validity states
  bool _idChecked = false;
  String? _idMessage;
  Color? _idMessageColor;

  bool _pwFormatOK = false;
  bool _pwSame = false;

  bool _nameOK = false;
  bool _phoneOK = false;
  bool _emailOK = false;
  bool _companyOK = false;
  bool _addrMainOK = false;
  bool _addrDetailOK = false;

  bool _bizOK = true;
  bool _corpOK = true;

  bool _submitting = false;

  bool get _isClient => widget.userType == "client";

  // regex
  final _reUserId = RegExp(r'^[a-z0-9]{1,20}$');
  final _rePwd = RegExp(r'^[A-Za-z0-9!@#\$%^&*]{1,20}$'); // 대문자 선택, 공백 불가
  final _reName = RegExp(r'^[\uAC00-\uD7A3a-zA-Z0-9]{1,15}$');
  final _rePhone = RegExp(r'^\d{3}-\d{4}-\d{4}$');     // 보기 포맷
  final _reEmail = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
  final _reBiz = RegExp(r'^\d{3}-\d{2}-\d{5}$');       // 보기 포맷
  final _reCorp = RegExp(r'^\d{6}-\d{7}$');            // 보기 포맷

  @override
  void initState() {
    super.initState();
    // listeners
    _userIdController.addListener(_onIdChanged);
    _pwdController.addListener(_onPwChanged);
    _confirmPwdController.addListener(_onPwChanged);
    _nameController.addListener(_onNameChanged);
    _emailController.addListener(_onEmailChanged);
    _companyNameController.addListener(_onCompanyChanged);
    _mainAddressController.addListener(_onAddrMainChanged);
    _detailAddressController.addListener(_onAddrDetailChanged);

    // 숫자만 입력 + 자동포맷(보기용)
    _phoneController.addListener(_onPhoneChangedFormat);
    _corpNumberController.addListener(_onCorpChangedFormat);
    _bizNumberController.addListener(_onBizChangedFormat);
  }

  // ===== utils: formatting =====
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatPhone(String digits) {
    // 11자리 기준: 3-4-4
    digits = _digitsOnly(digits);
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) return '${digits.substring(0,3)}-${digits.substring(3)}';
    final p1 = digits.substring(0, 3);
    final p2 = digits.substring(3, 7);
    final p3 = digits.substring(7, digits.length > 11 ? 11 : digits.length);
    return '$p1-$p2-$p3';
  }

  String _formatCorp(String digits) {
    // 13자리: 6-7
    digits = _digitsOnly(digits);
    if (digits.length <= 6) return digits;
    final p1 = digits.substring(0, 6);
    final p2 = digits.substring(6, digits.length > 13 ? 13 : digits.length);
    return '$p1-$p2';
  }

  String _formatBiz(String digits) {
    // 10자리: 3-2-5
    digits = _digitsOnly(digits);
    if (digits.length <= 3) return digits;
    if (digits.length <= 5) return '${digits.substring(0,3)}-${digits.substring(3)}';
    final p1 = digits.substring(0, 3);
    final p2 = digits.substring(3, 5);
    final p3 = digits.substring(5, digits.length > 10 ? 10 : digits.length);
    return '$p1-$p2-$p3';
  }

  void _setFormatted(TextEditingController c, String Function(String) fmt) {
    final old = c.text;
    final formatted = fmt(old);
    if (old != formatted) {
      c.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // ===== field listeners =====
  void _onIdChanged() {
    final id = _userIdController.text.trim();
    _idChecked = false;
    _idMessage = null;
    if (id.isEmpty || !_reUserId.hasMatch(id)) {
      setState(() {});
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await http.post(
          Uri.parse("https://sonjobdamd.com/func/hccheckid.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"userid": id}),
        );
        final data = jsonDecode(res.body);
        final exists = data["exists"] == true;
        setState(() {
          _idChecked = !exists;
          _idMessage = exists ? "이미 사용중인 아이디입니다" : "사용가능한 아이디입니다";
          _idMessageColor = exists ? Colors.red : Colors.green;
        });
      } catch (_) {
        setState(() {
          _idChecked = false;
          _idMessage = "아이디 확인 실패";
          _idMessageColor = Colors.red;
        });
      }
    });
  }

  void _onPwChanged() {
    final pw = _pwdController.text;
    final cf = _confirmPwdController.text;
    setState(() {
      _pwFormatOK = _rePwd.hasMatch(pw);
      _pwSame = pw.isNotEmpty && cf.isNotEmpty && pw == cf;
    });
  }

  void _onNameChanged() {
    setState(() => _nameOK = _reName.hasMatch(_nameController.text.trim()));
  }

  void _onPhoneChangedFormat() {
    _setFormatted(_phoneController, _formatPhone);
    setState(() => _phoneOK = _rePhone.hasMatch(_phoneController.text.trim()));
  }

  void _onEmailChanged() {
    setState(() => _emailOK = _reEmail.hasMatch(_emailController.text.trim()));
  }

  void _onCompanyChanged() {
    setState(() => _companyOK = _companyNameController.text.trim().isNotEmpty);
  }

  void _onAddrMainChanged() {
    setState(() => _addrMainOK = _mainAddressController.text.trim().isNotEmpty);
  }

  void _onAddrDetailChanged() {
    setState(() => _addrDetailOK = _detailAddressController.text.trim().isNotEmpty);
  }

  void _onBizChangedFormat() {
    if (_isClient) {
      _setFormatted(_bizNumberController, _formatBiz);
      setState(() => _bizOK = _reBiz.hasMatch(_bizNumberController.text.trim()));
    }
  }

  void _onCorpChangedFormat() {
    if (_isClient) {
      _setFormatted(_corpNumberController, _formatCorp);
      setState(() => _corpOK = _reCorp.hasMatch(_corpNumberController.text.trim()));
    }
  }

  bool get _allValid {
    final common = _idChecked && _pwFormatOK && _pwSame && _nameOK && _phoneOK && _emailOK && _companyOK;
    if (_isClient) {
      return common && _addrMainOK && _addrDetailOK && _bizOK && _corpOK;
    }
    return common; // actor/master 는 주소/법인/사업자 불필요
  }

  Future<void> _submit() async {
    if (!_allValid) return;

    setState(() => _submitting = true);
    final fullAddress = _isClient
        ? '${_mainAddressController.text.trim()} ${_detailAddressController.text.trim()}'.trim()
        : '';

    try {
      final res = await http.post(
        Uri.parse("https://sonjobdamd.com/func/hcregister.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userType": widget.userType,
          "userId": _userIdController.text.trim(),
          "pwd": _pwdController.text,
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),          // 포맷 포함 문자열
          "email": _emailController.text.trim(),
          "company_name": _companyNameController.text.trim(),
          "address": _isClient ? fullAddress : null,
          "biz_number": _isClient ? _bizNumberController.text.trim() : null,
          "corp_number": _isClient ? _corpNumberController.text.trim() : null,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("회원가입 신청 완료"),
            content: Text("가입 승인 결과는 메일(${_emailController.text})로 전달드리겠습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      } else {
        _showSnack(data['message'] ?? "오류 발생");
      }
    } catch (e) {
      _showSnack("요청 실패: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    super.dispose();
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이디
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: "아이디",
                helperText: _idMessage,
                helperStyle: TextStyle(color: _idMessageColor),
                errorText: _userIdController.text.isEmpty
                    ? null
                    : (!_reUserId.hasMatch(_userIdController.text.trim())
                    ? "영소문자+숫자"
                    : (_idChecked ? null : (_idMessageColor == Colors.red ? _idMessage : null))),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호
            TextField(
              controller: _pwdController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "비밀번호",
                helperText: null,
                helperStyle: const TextStyle(color: Colors.green),
                errorText: _pwdController.text.isEmpty
                    ? null
                    : (_pwFormatOK ? null : "영문/숫자/특수문자(!,@,#,\$,%,^,&,*) 사용 가능, 공백 불가, 1~20자"),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호 확인
            TextField(
              controller: _confirmPwdController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "비밀번호 확인",
                errorText: _confirmPwdController.text.isEmpty
                    ? null
                    : (_pwSame ? null : "비밀번호가 다릅니다"),
              ),
            ),
            const SizedBox(height: 16),

            // 이름
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "이름",
                errorText: _nameController.text.isEmpty
                    ? null
                    : (_nameOK ? null : "한글/영문/숫자 1~15자"),
              ),
            ),
            const SizedBox(height: 16),

            // 전화번호 (숫자입력 + 자동 포맷)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "전화번호",
                hintText: "예) 01012345678 → 010-1234-5678",
                errorText: _phoneController.text.isEmpty
                    ? null
                    : (_phoneOK ? null : "전화번호 형식 오류"),
              ),
            ),
            const SizedBox(height: 16),

            // 이메일
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "이메일",
                errorText: _emailController.text.isEmpty
                    ? null
                    : (_emailOK ? null : "이메일 형식 오류"),
              ),
            ),
            const SizedBox(height: 16),

            // 기업명
            TextField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: "기업명",
                errorText: _companyNameController.text.isEmpty
                    ? null
                    : (_companyOK ? null : "기업명을 입력하세요"),
              ),
            ),
            const SizedBox(height: 16),

            if (_isClient) ...[
              // 주소 + 버튼
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mainAddressController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "주소",
                        errorText: _mainAddressController.text.isEmpty
                            ? null
                            : (_addrMainOK ? null : "주소를 입력하세요"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      KakaoAddressHelper.openAddressPopup((addr) {
                        _mainAddressController.text = addr;
                        _onAddrMainChanged();
                      });
                    },
                    child: const Text("주소 검색"),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 상세주소
              TextField(
                controller: _detailAddressController,
                decoration: InputDecoration(
                  labelText: "상세주소",
                  errorText: _detailAddressController.text.isEmpty
                      ? null
                      : (_addrDetailOK ? null : "상세 주소를 입력하세요"),
                ),
              ),
              const SizedBox(height: 16),

              // 사업자등록번호
              TextField(
                controller: _bizNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "사업자등록번호",
                  hintText: "10자리 입력 → 123-45-12345",
                  errorText: _bizNumberController.text.isEmpty
                      ? null
                      : (_bizOK ? null : "형식 오류"),
                ),
              ),
              const SizedBox(height: 16),

              // 법인번호
              TextField(
                controller: _corpNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "법인번호",
                  hintText: "13자리 입력 → 123456-1234567",
                  errorText: _corpNumberController.text.isEmpty
                      ? null
                      : (_corpOK ? null : "형식 오류"),
                ),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_submitting || !_allValid) ? null : _submit,
                child: Text(_submitting ? "전송 중..." : "회원가입 신청"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

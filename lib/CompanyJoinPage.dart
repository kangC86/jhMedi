import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'KakaoAddressSearchPage.dart';

class CompanyJoinPage extends StatefulWidget {
  final String userType;
  const CompanyJoinPage({super.key, required this.userType});

  @override
  State<CompanyJoinPage> createState() => _CompanyJoinPageState();
}

class _CompanyJoinPageState extends State<CompanyJoinPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _pwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _bizNumberController = TextEditingController();
  final _corpNumberController = TextEditingController();

  String? _idMessage;
  Color? _idMessageColor;
  Timer? _debounce;
  bool _idChecked = false;
  bool _isSubmitting = false;
  bool _isSamePw = false;
  bool _mailChecked = false;

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_onIdChanged);
    _pwdController.addListener(_onPwChanged);
    _confirmPwdController.addListener(_onPwChanged);
    _emailController.addListener(_onEmailChanged);
  }

  void _onIdChanged() {
    final id = _userIdController.text.trim();
    _idChecked = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (id.isEmpty) {
      setState(() => _idMessage = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final response = await http.post(
        Uri.parse("https://sonjobdamd.com/func/hccheckid.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userid": id}),
      );
      final data = jsonDecode(response.body);
      setState(() {
        _idMessage = data["exists"] == true ? "이미 사용중인 아이디입니다" : "사용가능한 아이디입니다";
        _idMessageColor = data["exists"] == true ? Colors.red : Colors.green;
        _idChecked = data["exists"] == false;
      });
    });
  }

  void _onPwChanged() {
    setState(() => _isSamePw = _pwdController.text == _confirmPwdController.text);
  }

  void _onEmailChanged() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() => _mailChecked = emailRegex.hasMatch(_emailController.text.trim()));
  }

  Future<void> submitJoinRequest() async {
    if (!_isSamePw || !_mailChecked || !_formKey.currentState!.validate() || !_idChecked) return;

    setState(() => _isSubmitting = true);
    final response = await http.post(
      Uri.parse("https://sonjobdamd.com/func/hcregister.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userType": widget.userType,
        "userId": _userIdController.text.trim(),
        "pwd": _pwdController.text,
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "company_name": _companyController.text.trim(),
        "address": widget.userType == "actor" ? _addressController.text.trim() : null,
        "biz_number": widget.userType == "actor" ? _bizNumberController.text.trim() : null,
        "corp_number": widget.userType == "actor" ? _corpNumberController.text.trim() : null,
      }),
    );
    setState(() => _isSubmitting = false);
    final result = jsonDecode(response.body);
    if (result['success']) _showJoinCompleteDialog();
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "오류 발생")));
  }

  Future<void> _showJoinCompleteDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("회원가입 신청 완료"),
        content: Text("가입 승인 결과는 메일(${_emailController.text})로 전달드리겠습니다."),
        actions: [TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text("확인"))],
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _pwdController.dispose();
    _confirmPwdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _bizNumberController.dispose();
    _corpNumberController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActor = widget.userType == "actor";

    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTextField(_userIdController, "아이디", r'^[a-z0-9]{1,10}$', "아이디 형식 오류"),
            if (_idMessage != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_idMessage!, style: TextStyle(color: _idMessageColor))),
            const SizedBox(height: 16),
            _buildTextField(_pwdController, "비밀번호", r'^(?=.*[a-z])(?=.*[0-9])[a-z0-9!@#\$%^&*]{1,10}$', "비밀번호 형식 오류", obscure: true),
            const SizedBox(height: 16),
            TextFormField(controller: _confirmPwdController, obscureText: true, decoration: const InputDecoration(labelText: "비밀번호 확인")),
            if (!_isSamePw) const Padding(padding: EdgeInsets.only(top: 4), child: Text("비밀번호가 다릅니다", style: TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            _buildTextField(_nameController, "이름", r'^[\uAC00-\uD7A3a-zA-Z0-9]{1,15}$', "이름 형식 오류"),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, "전화번호", r'^\d{3}-\d{4}-\d{4}$', "전화번호 형식 오류"),
            const SizedBox(height: 16),
            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일', hintText: 'example@example.com'), keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || v.isEmpty) ? "이메일 입력" : null),
            if (_emailController.text.isNotEmpty && !_mailChecked) const Padding(padding: EdgeInsets.only(top: 4), child: Text("이메일 형식이 아닙니다", style: TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            _buildTextField(_companyController, "기업명", r'^[가-힣a-zA-Z0-9]{1,50}$', "기업명 형식 오류"),
            const SizedBox(height: 16),
            if (isActor)
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KakaoAddressSearchPage()),
                  );
                  if (result != null && result is String) {
                    setState(() => _addressController.text = result);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "기업 주소 (주소검색 클릭)"),
                    validator: (v) => v == null || v.isEmpty ? "주소 입력" : null,
                  ),
                ),
              ),
            if (isActor) const SizedBox(height: 16),
            if (isActor) _buildTextField(_bizNumberController, "사업자등록번호/고유번호", r'^(\d{3}-\d{2}-\d{5}|\d{10})$', "형식: 000-00-00000 또는 10자리 숫자"),
            if (isActor) const SizedBox(height: 16),
            if (isActor) _buildTextField(_corpNumberController, "법인번호", r'^\d{6}-\d{7}$', "형식: 000000-0000000"),
            const SizedBox(height: 32),
            Center(child: ElevatedButton(onPressed: _isSubmitting ? null : submitJoinRequest, child: const Text("회원가입 신청")))
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? pattern, String? errorMsg, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final value = v?.trim() ?? "";
        if (value.isEmpty) return "$label 입력";
        if (pattern != null && !RegExp(pattern).hasMatch(value)) return errorMsg;
        return null;
      },
    );
  }
}

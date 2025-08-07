import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class CompanyJoinPage_ extends StatefulWidget {
  final String userType; // 'client' 또는 'actor'

  const CompanyJoinPage_({super.key, required this.userType});

  @override
  State<CompanyJoinPage_> createState() => _CompanyJoinPageState();
}

class _CompanyJoinPageState extends State<CompanyJoinPage_> {
  final _formKey = GlobalKey<FormState>();

  final _userIdController = TextEditingController();
  final _pwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _belongController = TextEditingController();

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
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onIdChanged() {
    final id = _userIdController.text.trim();
    _idChecked = false;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (id.isEmpty) {
      setState(() {
        _idMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final response = await http.post(
        Uri.parse("https://sonjobdamd.com/func/hccheckid.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userid": id}),
      );

      final data = jsonDecode(response.body);
      if (data["exists"] == true) {
        setState(() {
          _idMessage = "이미 사용중인 아이디입니다";
          _idMessageColor = Colors.red;
          _idChecked = false;
        });
      } else {
        setState(() {
          _idMessage = "사용가능한 아이디입니다";
          _idMessageColor = Colors.green;
          _idChecked = true;
        });
      }
    });
  }

  void _onPwChanged() {
    if(_pwdController.text != _confirmPwdController.text)
    {
      setState(() {
        _isSamePw = false;
      });
    }
    else
    {
      setState(() {
        _isSamePw = true;
      });
    }
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _mailChecked = false;
      } else {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        _mailChecked = emailRegex.hasMatch(email);
      }
    });
  }

  void _onPhoneChanged()
  {

  }
  Future<void> submitJoinRequest() async {
    final userid = _userIdController.text.trim();
    final pwd = _pwdController.text;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final belong = widget.userType == "actor" ? _belongController.text.trim() : null;

    if(false == _isSamePw || false == _mailChecked) return;
    if (!_formKey.currentState!.validate() || !_idChecked) return;

    setState(() => _isSubmitting = true);

    final response = await http.post(
      Uri.parse("https://sonjobdamd.com/func/hcregister.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userType": widget.userType,
        "userId": userid,
        "pwd": pwd,
        "name": name,
        "phone": phone,
        "email": email,
        "belong": belong ?? ""
      }),
    );

    final result = jsonDecode(response.body);
    print(jsonEncode(result));
    setState(() => _isSubmitting = false);

    if (result['success']) {
      _showJoinCompleteDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "오류 발생")),
      );
    }
  }

  Future<void> _showJoinCompleteDialog() async {
    final userid = _userIdController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("회원가입 신청 완료"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$name 선생님\n안녕하세요, 손잡다메디컬입니다!\n"),
              Text("손잡다메디컬 가입해 주셔서 진심으로 감사드립니다.\n"),
              Text("심리 검사가 가능한 기관인지 확인한 후에 기관 승인을 해드리고 있습니다.\n"
                  "기관 승인이 될 때까지, 잠시만 기다려 주시기 바랍니다.\n"),
              SizedBox(height: 12),
              Text("가입 승인 결과는 메일($email)로 전달드리겠습니다. \n",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text("손잡다메디컬 고객지원팀 드림"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("확인"),
          ),
        ],
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
    _belongController.dispose();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이디
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: "아이디"),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "아이디를 입력하세요" : null,
              ),
              if (_idMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_idMessage!, style: TextStyle(color: _idMessageColor)),
                ),
              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _pwdController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
                validator: (v) =>
                (v == null || v.isEmpty) ? "비밀번호를 입력하세요" : null,
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인
              TextFormField(
                controller: _confirmPwdController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호 확인"),
              ),
              if (false == _pwdController.text.isEmpty && false == _isSamePw)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text("비밀번호가 다릅니다", style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),

              // 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "이름"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "이름 입력" : null,
              ),
              const SizedBox(height: 16),

              // 전화번호
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: "전화번호",
                    hintText: "-없이 숫자만 입력"
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "전화번호 입력" : null,
              ),
              const SizedBox(height: 16),

              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: 'example@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "이메일 입력" : null,
              ),
              if (false == _emailController.text.trim().isEmpty && false == _mailChecked)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text("이메일 형식이 아닙니다", style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),

              if (isActor)
                TextFormField(
                  controller: _belongController,
                  decoration: const InputDecoration(labelText: "소속"),
                ),

              const SizedBox(height: 32),

              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : submitJoinRequest,
                  child: const Text("회원가입 신청"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

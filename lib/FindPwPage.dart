// lib/FindPwPage.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FindPwPage extends StatefulWidget {
  const FindPwPage({super.key});

  @override
  State<FindPwPage> createState() => _FindPwPageState();
}

class _FindPwPageState extends State<FindPwPage> {
  // 정규식 (회원가입과 동일)
  final RegExp _rePwd = RegExp(r'^[A-Za-z0-9!@#\$%^&*]{1,20}$');

  // 컨트롤러
  final _idController = TextEditingController();
  final _codeController = TextEditingController();
  final _pw1Controller = TextEditingController();
  final _pw2Controller = TextEditingController();

  // 포커스
  final _codeFocus = FocusNode();
  final _pw1Focus = FocusNode();
  final _pw2Focus = FocusNode();

  int _step = 1; // 1: 아이디 입력 -> 코드 전송, 2: 코드 확인, 3: 비번 변경
  String _message = '';
  String _error = '';
  bool _busy = false;

  // 검증 상태
  bool _pwValid = false; // 정규식 통과
  bool _pwSame = true;   // 두 비밀번호 동일

  @override
  void initState() {
    super.initState();

    // 입력 변화 시 즉시 리빌드 → 버튼 활성/비활성 갱신
    _idController.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() {}));
    _pw1Controller.addListener(_validatePw);
    _pw2Controller.addListener(_validatePw);
  }

  @override
  void dispose() {
    _idController.dispose();
    _codeController.dispose();
    _pw1Controller.dispose();
    _pw2Controller.dispose();
    _codeFocus.dispose();
    _pw1Focus.dispose();
    _pw2Focus.dispose();
    super.dispose();
  }

  void _validatePw() {
    final p1 = _pw1Controller.text;
    final p2 = _pw2Controller.text;
    setState(() {
      _pwValid = _rePwd.hasMatch(p1);
      _pwSame = (p1.isEmpty && p2.isEmpty) || (p1 == p2);
      _error = ''; // 다시 입력하면 에러 텍스트 리셋
    });
  }

  Future<void> _sendAuthCode() async {
    final id = _idController.text.trim();
    if (id.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _message = '';
      _error = '';
    });

    try {
      final res = await http
          .post(
        Uri.parse('https://sonjobdamd.com/func/hcsendresetcode.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userid': id}),
      )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _message = '인증번호를 이메일로 전송했습니다.';
          _step = 2;
        });
        if (mounted) {
          Future.microtask(
                () => FocusScope.of(context).requestFocus(_codeFocus),
          );
        }
      } else {
        _showDialog('미확인계정', '아이디를 찾을 수 없습니다');
      }
    } on TimeoutException {
      _showSnack('요청이 지연됩니다. 네트워크 상태를 확인해주세요.');
    } catch (e) {
      _showSnack('요청 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final id = _idController.text.trim();
    final code = _codeController.text.trim();
    if (id.isEmpty || code.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _message = '';
      _error = '';
    });

    try {
      final res = await http
          .post(
        Uri.parse('https://sonjobdamd.com/func/hcverifyresetcode.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userid': id, 'code': code}),
      )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _message = '인증 완료. 새 비밀번호를 입력해주세요.';
          _step = 3;
        });
        if (mounted) {
          Future.microtask(
                () => FocusScope.of(context).requestFocus(_pw1Focus),
          );
        }
      } else {
        setState(() => _message = '인증번호가 틀립니다.');
      }
    } on TimeoutException {
      _showSnack('요청이 지연됩니다. 네트워크 상태를 확인해주세요.');
    } catch (e) {
      _showSnack('요청 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final id = _idController.text.trim();
    final pw1 = _pw1Controller.text;
    final pw2 = _pw2Controller.text;

    if (_busy) return;
    if (!_rePwd.hasMatch(pw1)) {
      setState(() => _error = '비밀번호 형식이 올바르지 않습니다.');
      return;
    }
    if (pw1 != pw2) {
      setState(() => _error = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _busy = true;
      _message = '';
      _error = '';
    });

    try {
      final res = await http
          .post(
        Uri.parse('https://sonjobdamd.com/func/hcresetpwd.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userid': id, 'password': pw1}),
      )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (!mounted) return;
        _showDialog('완료', '비밀번호가 재설정되었습니다.', onOk: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        setState(() => _error = '비밀번호 변경 실패');
      }
    } on TimeoutException {
      setState(() => _error = '요청 타임아웃. 잠시 후 다시 시도해주세요.');
    } catch (e) {
      setState(() => _error = '요청 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDialog(String title, String msg, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk?.call();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 여기 값들은 컨트롤러 리스너(setState)로 매 타이핑마다 갱신됨
    final canSend = _idController.text.trim().isNotEmpty && !_busy;
    final canVerify = _codeController.text.trim().isNotEmpty && !_busy;
    final canReset = _pwValid && _pwSame && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step == 1) ...[
              const Text('가입한 아이디를 입력하세요'),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: '아이디'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendAuthCode(), // Enter → 인증번호 요청
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSend ? _sendAuthCode : null,
                  child: Text(_busy ? '전송 중...' : '인증번호 요청'),
                ),
              ),
            ] else if (_step == 2) ...[
              const Text('이메일로 받은 인증번호를 입력하세요'),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                decoration: const InputDecoration(labelText: '인증번호'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(), // Enter → 확인
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canVerify ? _verifyCode : null,
                  child: Text(_busy ? '확인 중...' : '인증번호 확인'),
                ),
              ),
            ] else if (_step == 3) ...[
              const Text('새 비밀번호를 입력하세요'),
              const SizedBox(height: 8),
              TextField(
                controller: _pw1Controller,
                focusNode: _pw1Focus,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  helperText: '영문/숫자/!@#\$%^&* 사용, 1~20자',
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_pw2Focus),
              ),
              if (_pw1Controller.text.isNotEmpty && !_pwValid)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('비밀번호 형식이 올바르지 않습니다.',
                      style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _pw2Controller,
                focusNode: _pw2Focus,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _resetPassword(), // Enter → 변경
              ),
              if (_pw2Controller.text.isNotEmpty && !_pwSame)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('비밀번호가 일치하지 않습니다.',
                      style: TextStyle(color: Colors.red)),
                ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                  Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canReset ? _resetPassword : null,
                  child: Text(_busy ? '변경 중...' : '비밀번호 변경'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Text(_message, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

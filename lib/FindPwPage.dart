import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindPwPage extends StatefulWidget {
  const FindPwPage({super.key});

  @override
  State<FindPwPage> createState() => _FindPwPageState();
}

class _FindPwPageState extends State<FindPwPage> {
  final _idController = TextEditingController();
  final _codeController = TextEditingController();
  final _pw1Controller = TextEditingController();
  final _pw2Controller = TextEditingController();

  int _step = 1;
  String _message = '';
  String _error = '';

  Future<void> _sendAuthCode() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    final res = await http.post(
      Uri.parse('https://sonjobdamd.com/func/hcsendresetcode.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userid': id}),
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() {
        _message = '인증번호를 이메일로 전송했습니다.';
        _step = 2;
      });
    } else {
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('미확인계정'),
              content: Text('아이디를 찾을 수 없습니다'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    final id = _idController.text.trim();

    final res = await http.post(
      Uri.parse('https://sonjobdamd.com/func/hcverifyresetcode.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userid': id, 'code': code}),
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      setState(() {
        _message = '인증 완료. 새 비밀번호를 입력해주세요.';
        _step = 3;
      });
    } else {
      setState(() {
        _message = '인증번호가 틀립니다.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final id = _idController.text.trim();
    final pw1 = _pw1Controller.text;
    final pw2 = _pw2Controller.text;

    if (pw1 != pw2) {
      setState(() {
        _error = '비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    final res = await http.post(
      Uri.parse('https://sonjobdamd.com/func/hcresetpwd.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userid': id, 'password': pw1}),
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('완료'),
            content: const Text('비밀번호가 재설정되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {
        _error = '비밀번호 변경 실패';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_step == 1) ...[
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: '아이디'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendAuthCode,
                child: const Text('인증번호 요청'),
              ),
            ] else if (_step == 2) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '인증번호 입력'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyCode,
                child: const Text('인증번호 확인'),
              ),
            ] else if (_step == 3) ...[
              TextField(
                controller: _pw1Controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pw2Controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
              ),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('비밀번호 변경'),
              ),
            ],
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

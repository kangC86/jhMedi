import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'TermsPage.dart';
import 'FindIDPage.dart';
import 'FindPwPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idController = TextEditingController();
  final pwController = TextEditingController();

  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _showPendingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("가입 안"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("안녕하세요, 손잡다메디컬입니다!\n"),
              Text("현재 입력하신 계정은 심리 검사가 가능한 기관인지 확인중에 있습니다\n"
                  "기관 승인이 될 때까지, 잠시만 기다려 주시기 바랍니다.\n"),
              SizedBox(height: 12),
              Text("가입이 완료되면 입력하신 메일주소로 안내드리겠습니다.\n",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text("손잡다메디컬 고객지원팀 드림"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
  Future<void> _tryLogin() async {
    final id = idController.text.trim();
    final pw = pwController.text;

    if (id.isEmpty || pw.isEmpty) {
      setState(() {
        _message = '아이디와 비밀번호를 입력해주세요';
        _messageColor = Colors.red;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://sonjobdamd.com/func/hclogin.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userid": id,
          "pwd": pw,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        // JSON 문자열로 변환
        String userJson = jsonEncode(data["user"]);

        // SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userInfo', userJson);
        Navigator.pop(context, true);
      }else if(data["pending"]==true) {
        _showPendingDialog();
        idController.text = "";
        pwController.text = "";
      }else{
          setState(() {
            _message = data["message"] ?? "로그인 실패";
            _messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _message = '서버와 연결할 수 없습니다';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 로고 + 제목
            Row(
              children: [
                Image.asset('assets/logo.png', height: 40),
                const SizedBox(width: 8),
                const Text('로그인', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 40),

            // 아이디 입력
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            const SizedBox(height: 16),

            // 비밀번호 입력
            TextField(
              controller: pwController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 8),

            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(color: _messageColor),
              ),

            const SizedBox(height: 24),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tryLogin,
                child: const Text('로그인'),
              ),
            ),
            const SizedBox(height: 20),

            // 하단 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindIDPage()),
                    );
                  },
                  child: const Text('아이디 찾기'),
                ),
                const Text('|'),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindPwPage()),
                    );
                  },
                  child: const Text('비밀번호 찾기'),
                ),
                const Text('|'),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );
                  },
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

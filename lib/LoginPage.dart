// LoginPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'TermsPage.dart';
import 'FindIDPage.dart';
import 'FindPwPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  // 포커스: 아이디 → 비번 → 로그인 흐름
  final _pwFocus = FocusNode();

  bool _busy = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;

    if (id.isEmpty || pw.isEmpty) {
      _showSnack('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      // TODO: 서버 주소 확인
      final res = await http.post(
        Uri.parse('https://sonjobdamd.com/func/hclogin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userid': id, 'pwd': pw}),
      );

      // 응답 본문 미출력/HTML일 때 대비
      if (res.statusCode != 200 || res.body.isEmpty) {
        throw Exception('서버 통신 오류 (${res.statusCode})');
      }

      final json = jsonDecode(res.body);
      if (json is! Map || json['success'] != true) {
        _showSnack(json['message']?.toString() ?? '로그인에 실패했습니다.');
        return;
      }

      // 서버가 내려주는 유저 정보(비밀번호 제외) 통째로 저장
      final user = Map<String, dynamic>.from(json['user'] ?? {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userInfo', jsonEncode(user)); // JSON 문자열로 저장

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('로그인 중 오류가 발생했습니다. (${e.toString()})');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

            // 아이디
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_pwFocus),
            ),
            const SizedBox(height: 16),

            // 비밀번호 (Enter = 로그인)
            TextField(
              controller: _pwController,
              focusNode: _pwFocus,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(), // ⬅ 엔터로 로그인
            ),
            const SizedBox(height: 24),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _login,
                child: Text(_busy ? '로그인 중...' : '로그인'),
              ),
            ),
            const SizedBox(height: 20),

            // 하단 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: _busy
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FindIDPage()),
                    );
                  },
                  child: const Text('아이디 찾기'),
                ),
                const Text('|'),
                InkWell(
                  onTap: _busy
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FindPwPage()),
                    );
                  },
                  child: const Text('비밀번호 찾기'),
                ),
                const Text('|'),
                InkWell(
                  onTap: _busy
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsPage()),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FindIDPage extends StatefulWidget {
  const FindIDPage({super.key});

  @override
  State<FindIDPage> createState() => _FindIDPageState();
}

class _FindIDPageState extends State<FindIDPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _useEmail = true;
  bool _isLoading = false;

  Future<void> _findId() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || (_useEmail && email.isEmpty) || (!_useEmail && phone.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 필드를 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("https://sonjobdamd.com/func/hcfindid.php");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          if (_useEmail) "email": email,
          if (!_useEmail) "phone": phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true)
        {
          final foundId = data['userid'] ?? '(알 수 없음)';
          showDialog(
            context: context,
            builder: (_) =>
                AlertDialog(
                  title: const Text('아이디 찾기 성공'),
                  content: Text('회원님의 아이디는 $foundId입니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
          );
        }
        else if(data['pending'] == true)
        {
          final foundId = data['userid'] ?? '(알 수 없음)';
          showDialog(
            context: context,
            builder: (_) =>
                AlertDialog(
                  title: const Text('아이디 찾기 성공'),
                  content: Text('회원님의 아이디는 $foundId이며, 현재 기관 심사 진행중입니다'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '일치하는 정보를 찾을 수 없습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이디 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '아이디를 찾을 방법을 선택해주세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Radio(
                  value: true,
                  groupValue: _useEmail,
                  onChanged: (val) => setState(() => _useEmail = true),
                ),
                const Text('가입한 이메일로 찾기'),
              ],
            ),
            Row(
              children: [
                Radio(
                  value: false,
                  groupValue: _useEmail,
                  onChanged: (val) => setState(() => _useEmail = false),
                ),
                const Text('가입한 휴대폰으로 찾기'),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 16),
            if (_useEmail)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
              )
            else
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '전화번호'),
                keyboardType: TextInputType.phone,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _findId,
                child: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('아이디 찾기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

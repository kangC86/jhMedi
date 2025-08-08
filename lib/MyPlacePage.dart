import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'UserManagePage.dart';

class MyPlacePage extends StatefulWidget {
  const MyPlacePage({super.key});

  @override
  State<MyPlacePage> createState() => _MyPlacePageState();
}

class _MyPlacePageState extends State<MyPlacePage> {
  Map<String, dynamic>? curUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userInfo');
    if (userJson != null) {
      setState(() {
        curUser = jsonDecode(userJson);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (curUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = curUser!["name"] ?? "";
    final userEmail = curUser!["email"] ?? "";
    final userType = curUser!["userType"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 사용자 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage('assets/user_profile.png'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$userName 고객님', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.brown),
                        const SizedBox(width: 4),
                        Text(userEmail, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {
                    // 계정 설정 이동
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36)),
                  child: const Text('계정설정'),
                ),
              ],
            ),
          ),

          const Divider(thickness: 8, color: Color(0xfff0f0f0)),

          if (userType == "master") ...[
            _sectionHeader('회원 관리'),
            _simpleListItem('가입 대기중인 회원', routeTo: "pending"),
            _simpleListItem('정회원', routeTo: "approved"),
            const Divider(thickness: 8, color: Color(0xfff0f0f0)),
            _sectionHeader('견적 관리'),
            _simpleListItem('받은 견적'),
            _simpleListItem('완료된 견적'),
          ] else if (userType == "client") ...[
            _sectionHeader('계약 관리'),
            _simpleListItem('수정 중인 견적'),
            _simpleListItem('보낸 견적'),
          ] else if (userType == "actor") ...[
            _sectionHeader('견적 관리'),
            _simpleListItem('받은 견적'),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _simpleListItem(String title, {String? routeTo, bool showDot = false}) {
    return ListTile(
      title: Row(
        children: [
          Text(title),
          if (showDot)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: CircleAvatar(radius: 3, backgroundColor: Colors.red),
            ),
        ],
      ),
      onTap: () {
        if (routeTo == "pending" || routeTo == "approved") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserManagePage(userType: routeTo!),
            ),
          );
        }
        // 다른 페이지 라우팅은 여기 추가 가능
      },
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

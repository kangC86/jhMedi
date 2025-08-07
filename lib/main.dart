// flutter build web --base-href "/jhMedi/"
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage.dart';
import 'TermsPage.dart';
import 'MyPlacePage.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn = false;
  Map<String, dynamic>? curUserInfo;
  bool showInsurance = false;
  double rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
  }

  Future<void> _showJoinCompleteDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("회원가입 신청 완료"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("이정혁 선생님\n안녕하세요, 손잡다메디컬입니다!\n"),
              Text("손잡다메디컬 가입해 주셔서 진심으로 감사드립니다.\n"),
              Text("심리 검사가 가능한 기관인지 확인한 후에 기관 승인을 해드리고 있습니다.\n"
                  "기관 승인이 될 때까지, 잠시만 기다려 주시기 바랍니다.\n"),
              SizedBox(height: 12),
              Text("가입 시 입력한 기관 및 기관관리자 정보는 아래와 같습니다.\n",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("[기관정보]"),
              Text(" - 기관명: 이모티브"),
              Text(" - 사업자 번호: 8948701889"),
              Text(" - 대표자 성함: 임정혁"),
              Text(" - 기관 연락처: 01041024414"),
              SizedBox(height: 8),
              Text("[기관 관리자 정보]"),
              Text(" - 기관관리자 아이디: emotiv01"),
              Text(" - 담당자 성함: 이정혁"),
              Text(" - 담당자 연락처: 01041024414"),
              Text(" - 담당자 이메일: leekh@emotiv.kr"),
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

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = false;
      String? userJson = prefs.getString('userInfo');
      if (userJson != null) {
        isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        curUserInfo = jsonDecode(userJson);
      }
    });
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isLoggedIn = false;
        String? userJson = prefs.getString('userInfo');
        if (userJson != null) {
          isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          curUserInfo = jsonDecode(userJson);
        }
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      isLoggedIn = false;
      curUserInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Image.asset('assets/logo.png', height: 40),
              const Spacer(),

              if (!isLoggedIn) ...[
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsPage()),
                    );

                    if (result == true) {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        isLoggedIn = false;
                        String? userJson = prefs.getString('userInfo');
                        if (userJson != null) {
                          isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
                          curUserInfo = jsonDecode(userJson);
                        }
                      });
                    }
                  },
                  child: const Text('회원가입', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: _handleLogin,
                  child: const Text('로그인', style: TextStyle(color: Colors.black)),
                ),
              ] else ...[
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text('로그아웃', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPlacePage()),
                    );
                  },
                  child: const Text('마이페이지', style: TextStyle(color: Colors.black)),
                ),
              ],

              _AppBarButton('견적요청'),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "${curUserInfo?["name"]}님 환영합니다!",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              '더 나은 임상시험을 위한 변화',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '어떤 서비스가 필요하신가요?',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showInsurance = !showInsurance;
                        rotationAngle = showInsurance ? 0.5 : 0.0;
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedRotation(
                          turns: rotationAngle,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(Icons.expand_more, color: Colors.blue.shade700, size: 28),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '전체보기',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  if (showInsurance) ...[
                    _SectionButton(title: '보험', onTap: () {}),
                    const SizedBox(width: 12),
                    _SectionButton(title: '제휴문의', onTap: () {}),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final String label;
  const _AppBarButton(this.label);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }
}

class _SectionButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

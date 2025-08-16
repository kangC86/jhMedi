import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LoginPage.dart';
import 'TermsPage.dart';
import 'MyPlacePage.dart';
import 'PartnerInquiryPage.dart';
import 'QuoteRequestPage.dart';
import 'auth_service.dart';

// TODO: 의뢰사/파트너사 액션 페이지로 교체

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.load(); // 앱 시작 시 로그인 상태 로드
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 로그인 사용자 정보(SharedPreferences의 userInfo)를 읽어 이름 표시
  Future<Map<String, dynamic>?> _loadUserInfo() async {
    final p = await SharedPreferences.getInstance();
    final j = p.getString('userInfo');
    if (j == null) return null;
    try {
      return jsonDecode(j) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    // LoginPage에서 성공 시 AuthService.setLoggedIn(true) 호출한다고 가정
    // isLoggedIn ValueNotifier가 바뀌므로 여기서 setState는 불필요
    if (ok != true) return;
  }

  Future<void> _handleLogout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();                  // 저장된 사용자 정보/토큰 제거
    await AuthService.setLoggedIn(false); // 전역 로그인 상태 갱신 → UI 자동 리빌드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 로고
              Image.asset('assets/logo.png', height: 36),
              const SizedBox(width: 12),

              // 상단 네비 (의뢰사/파트너사/제휴문의/고객지원)
              _TopNav(
                text: '의뢰사',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuoteRequestPage()),
                  );
                },
              ),
              _TopNav(text: '파트너사', onTap: () {}),
              _TopNav(
                text: '제휴/문의',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PartnerInquiryPage()),
                  );
                },
              ),
              const Spacer(),

              // ⇣⇣ 로그인 상태 구독: 상태 바뀌면 상단 UI 자동 갱신
              ValueListenableBuilder<bool>(
                valueListenable: AuthService.isLoggedIn,
                builder: (context, loggedIn, _) {
                  if (!loggedIn) {
                    // 비로그인
                    return Row(
                      children: [
                        TextButton(
                          onPressed: () => _handleLogin(context),
                          child: const Text('로그인', style: TextStyle(color: Colors.black)),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsPage()),
                          ),
                          child: const Text('회원가입', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    );
                  }

                  // 로그인 상태일 때: SharedPreferences에서 이름만 가볍게 가져와 표시
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _loadUserInfo(),
                    builder: (context, snap) {
                      final name = (snap.data?['name'] ?? '') as String? ?? '';
                      return Row(
                        children: [
                          Text(
                            name.isEmpty ? '안녕하세요' : '$name님',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MyPlacePage()),
                              );
                              // 마이페이지에서 변경된 정보는 SharedPreferences에 반영되어 있을 것이고
                              // 로그인 상태는 그대로 → 이름 갱신은 FutureBuilder가 future 재생성 시 반영
                              setState(() {}); // 이름만 새로고침
                            },
                            child: const Text('마이페이지', style: TextStyle(color: Colors.black)),
                          ),
                          TextButton(
                            onPressed: _handleLogout,
                            child: const Text('로그아웃', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // 히어로 섹션 (중앙정렬)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _H1("국내 유일 임상시험 및 인허가 원클릭 견적 플랫폼!"),
                      const SizedBox(height: 4),
                      const _H1Accent("손잡다매칭"),
                      const SizedBox(height: 8),
                      const Text(
                        "손잡다매칭은 의뢰사·파트너사 임상시험 관련 서비스를 연결하는 플랫폼입니다.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 140,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE7E5EF)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          size: 64,
                          color: Color(0xFF6B5BD2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 두 개 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isWide
                      ? Row(
                    children: [
                      // 의뢰사 카드
                      Expanded(
                        child: _roleCardClient(onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QuoteRequestPage()),
                          );
                        }),
                      ),
                      const SizedBox(width: 20),
                      // 파트너사 카드
                      Expanded(
                        child: _roleCardPartner(onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QuoteRequestPage()),
                          );
                        }),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _roleCardClient(onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuoteRequestPage()),
                        );
                      }),
                      const SizedBox(height: 16),
                      _roleCardPartner(onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuoteRequestPage()),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TopNav({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ),
    );
  }
}

class _H1 extends StatelessWidget {
  final String t;
  const _H1(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w700),
  );
}

class _H1Accent extends StatelessWidget {
  final String t;
  const _H1Accent(this.t);
  @override
  Widget build(BuildContext context) => const Text(
    "손잡다매칭",
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF6B5BD2)),
  );
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  const _Metric({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bubble_chart_outlined, size: 18, color: Color(0xFF6B5BD2)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _roleCardClient({required VoidCallback onTap}) {
  return _RoleCard(
    bg: const Color(0xFF4F77B6),
    title: '의뢰사',
    subtitle: '최소 2개 이상 수행사\n견적받기',
    cta: '업무견적 요청',
    onTap: onTap,
  );
}

Widget _roleCardPartner({required VoidCallback onTap}) {
  return _RoleCard(
    bg: const Color(0xFF5C4787),
    title: '파트너사',
    subtitle: '원스톱 견적 발행',
    cta: '업무견적 발송',
    onTap: onTap,
  );
}

class _RoleCard extends StatelessWidget {
  final Color bg;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _RoleCard({
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(cta, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

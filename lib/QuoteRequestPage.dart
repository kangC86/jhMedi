import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CroQuoteFormPage.dart';
import 'LoginPage.dart';
import 'auth_service.dart';

class QuoteRequestPage extends StatefulWidget {
  const QuoteRequestPage({super.key});

  @override
  State<QuoteRequestPage> createState() => _QuoteRequestPageState();
}

enum QuoteCategory { cro, ra, insurance, biosample }

class _QuoteRequestPageState extends State<QuoteRequestPage> {
  QuoteCategory _selected = QuoteCategory.cro;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('견적요청'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 카테고리 바
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryTab(
                    icon: Icons.local_shipping_outlined,
                    label: '임상시험 파트너찾기',
                    selected: _selected == QuoteCategory.cro,
                    onTap: () => setState(() => _selected = QuoteCategory.cro),
                  ),
                  _CategoryTab(
                    icon: Icons.approval_outlined,
                    label: '인허가 파트너찾기',
                    selected: _selected == QuoteCategory.ra,
                    onTap: () => setState(() => _selected = QuoteCategory.ra),
                  ),
                  _CategoryTab(
                    icon: Icons.star_border,
                    label: '보험 가입하기',
                    selected: _selected == QuoteCategory.insurance,
                    onTap: () => setState(() => _selected = QuoteCategory.insurance),
                  ),
                  _CategoryTab(
                    icon: Icons.school_outlined,
                    label: '인쇄물 파트너 찾기',
                    selected: _selected == QuoteCategory.biosample,
                    onTap: () => setState(() => _selected = QuoteCategory.biosample),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 본문 타이틀
            Text(
              _titleByCategory(_selected),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // 본문 카드/리스트 (반응형)
            Expanded(
              child: isWide
                  ? Row(
                children: [
                  Expanded(child: _LeftMenu(selected: _selected, onChange: _onMenuTap)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _ContentArea(
                      selected: _selected,
                      onCroPressed: _openCroForm,
                      onComingSoon: () => _showWipDialog(context),
                    ),
                  ),
                ],
              )
                  : Column(
                children: [
                  _LeftMenu(selected: _selected, onChange: _onMenuTap),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _ContentArea(
                      selected: _selected,
                      onCroPressed: _openCroForm,
                      onComingSoon: () => _showWipDialog(context),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onMenuTap(QuoteCategory v) => setState(() => _selected = v);

  String _titleByCategory(QuoteCategory c) {
    switch (c) {
      case QuoteCategory.cro:
        return '임상시험(CRO) 파트너사 찾기';
      case QuoteCategory.ra:
        return '인허가(RA) 파트너 찾기';
      case QuoteCategory.insurance:
        return '보험 가입하기';
      case QuoteCategory.biosample:
        return '인쇄물 파트너 찾기';
    }
  }

  Future<void> _openCroForm() async {
    if (!AuthService.isLoggedIn.value) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CroQuoteFormPage()));
  }

  static void _showWipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('안내'),
        content: const Text('준비중인 서비스입니다. 빠른 시일 내에 오픈될 예정입니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFF6B5BD2) : const Color(0xFFE6E6EC)),
            boxShadow: selected
            ? [const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? const Color(0xFF6B5BD2) : Colors.black54),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF6B5BD2) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftMenu extends StatelessWidget {
  final QuoteCategory selected;
  final ValueChanged<QuoteCategory> onChange;

  const _LeftMenu({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _menuButton(
          context,
          title: '임상시험(CRO)\n파트너 찾기',
          active: selected == QuoteCategory.cro,
          onTap: () => onChange(QuoteCategory.cro),
        ),
        const SizedBox(height: 12),
        _menuButton(
          context,
          title: '인허가(RA) 파트너 찾기',
          active: selected == QuoteCategory.ra,
          onTap: () => onChange(QuoteCategory.ra),
        ),
        const SizedBox(height: 12),
        _menuButton(
          context,
          title: '보험 가입하기',
          active: selected == QuoteCategory.insurance,
          onTap: () => onChange(QuoteCategory.insurance),
        ),
        const SizedBox(height: 12),
        _menuButton(
          context,
          title: '인쇄물 파트너 찾기',
          active: selected == QuoteCategory.biosample,
          onTap: () => onChange(QuoteCategory.biosample),
        ),
      ],
    );
  }

  Widget _menuButton(BuildContext context,
      {required String title, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEDF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF6B5BD2) : const Color(0xFFE6E6EC)),
        ),
        child: Text(
          title,
          style: TextStyle(
            height: 1.2,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF2E2A5B) : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final QuoteCategory selected;
  final Future<void> Function() onCroPressed;
  final VoidCallback onComingSoon;

  const _ContentArea({
    required this.selected,
    required this.onCroPressed,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    switch (selected) {
      case QuoteCategory.cro:
        return _contentCard(
          title: '임상시험(CRO) 파트너사 찾기',
          description: '프로토콜/PM/모니터링/데이터관리/통계/의학자문 등 업무 범위를 선택해 의뢰하세요.',
          ctaLabel: '의뢰서 작성하기',
          onPressed: onCroPressed,
        );
      case QuoteCategory.ra:
        return _contentCard(
          title: '인허가(RA) 파트너 찾기',
          description: '식약처 상담, IND/CTA, 제품허가, GMP, DMF 등 인허가 업무를 의뢰하세요.',
          ctaLabel: '의뢰서 작성하기',
          onPressed: () async => onComingSoon(),
        );
      case QuoteCategory.insurance:
        return _contentCard(
          title: '보험 가입하기',
          description: '임상시험 책임보험/피험자보험 등 맞춤 보장 설계를 상담받고 가입하세요.',
          ctaLabel: '상담 신청하기',
          onPressed: () async => onComingSoon(),
        );
      case QuoteCategory.biosample:
        return _contentCard(
          title: '인쇄물 파트너 찾기',
          description: '인쇄물 파트너를 연결해드립니다.',
          ctaLabel: '의뢰서 작성하기',
          onPressed: () async => onComingSoon(),
        );
    }
  }

  Widget _contentCard({
    required String title,
    required String description,
    required String ctaLabel,
    required Future<void> Function() onPressed,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE6E6EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black54)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onPressed(),
                child: Text(ctaLabel),
              ),
            )
          ],
        ),
      ),
    );
  }
}

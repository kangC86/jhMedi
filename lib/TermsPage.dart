import 'package:flutter/material.dart';
import 'CompanyJoinPage.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool agreeAll = false;
  bool agreeTerms = false;
  bool agreePrivacy = false;
  bool termsScrollComplete = false;
  bool privacyScrollComplete = false;

  void _toggleAll(bool? value) {
    final v = value ?? false;
    setState(() {
      agreeAll = v;
      termsScrollComplete = true;
      privacyScrollComplete = true;
      agreeTerms = v;
      agreePrivacy = v;
    });
  }

  void _updateAgreeAll() {
    setState(() {
      agreeAll = agreeTerms && agreePrivacy;
    });
  }

  bool get allRequiredChecked => agreeTerms && agreePrivacy;

  void _showTermsDialog({
    required String title,
    required String content,
    required VoidCallback onScrolledToEnd,
  }) {
    final controller = ScrollController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Scrollbar(
            thumbVisibility: true,
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: Text(content),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollable = controller.position.maxScrollExtent > 0;
      if (!scrollable) {
        onScrolledToEnd();
        controller.dispose();
      } else {
        controller.addListener(() {
          if (controller.offset >= controller.position.maxScrollExtent) {
            onScrolledToEnd();
            controller.dispose();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '서비스 이용을 위해 약관에 동의해주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              title: const Text('전체 동의'),
              value: agreeAll,
              onChanged: _toggleAll,
            ),
            const Divider(),

            CheckboxListTile(
              title: const Text('[필수] 서비스 이용약관 동의'),
              value: agreeTerms,
              onChanged: termsScrollComplete
                  ? (val) {
                setState(() => agreeTerms = val ?? false);
                _updateAgreeAll();
              }
                  : null,
              subtitle: GestureDetector(
                onTap: () {
                  _showTermsDialog(
                    title: '서비스 이용약관',
                    content: _dummyTermsText,
                    onScrolledToEnd: () {
                      setState(() => termsScrollComplete = true);
                    },
                  );
                },
                child: const Text('약관 보기', style: TextStyle(color: Colors.blue)),
              ),
            ),

            CheckboxListTile(
              title: const Text('[필수] 개인정보 처리방침 동의'),
              value: agreePrivacy,
              onChanged: privacyScrollComplete
                  ? (val) {
                setState(() => agreePrivacy = val ?? false);
                _updateAgreeAll();
              }
                  : null,
              subtitle: GestureDetector(
                onTap: () {
                  _showTermsDialog(
                    title: '개인정보 처리방침',
                    content: _dummyPrivacyText,
                    onScrolledToEnd: () {
                      setState(() => privacyScrollComplete = true);
                    },
                  );
                },
                child: const Text('약관 보기', style: TextStyle(color: Colors.blue)),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: allRequiredChecked
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompanyJoinPage(userType: 'client'),
                        ),
                      );
                    }
                        : null,
                    child: const Text('의뢰사 가입하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: allRequiredChecked
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompanyJoinPage(userType: 'actor'),
                        ),
                      );
                    }
                        : null,
                    //style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('수행사 가입하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const String _dummyTermsText = '''
[서비스 이용약관 전문]
여기에 실제 약관 내용을 입력하세요.
스크롤이 끝까지 도달해야 체크할 수 있습니다.
...
''';

const String _dummyPrivacyText = '''
[개인정보 처리방침 전문]
여기에 실제 개인정보 처리방침 내용을 입력하세요.
...
''';

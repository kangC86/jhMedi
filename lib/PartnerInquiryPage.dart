import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PartnerInquiryPage extends StatefulWidget {
  const PartnerInquiryPage({super.key});

  @override
  State<PartnerInquiryPage> createState() => _PartnerInquiryPageState();
}

class _PartnerInquiryPageState extends State<PartnerInquiryPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();     // 소속기관
  final _titleCtrl = TextEditingController();   // 직급/직위
  final _subjectCtrl = TextEditingController(); // 문의 제목
  final _contentCtrl = TextEditingController(); // 문의 내용

  bool _isNotiError = false;
  String? _type; // 드롭다운
  bool _agree = true; // 개인정보 동의(기본 체크)
  bool _busy = false;

  // 전화번호 포맷팅
  void _onPhoneChanged(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    String out = digits;
    if (digits.length >= 4 && digits.length <= 7) {
      out = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length >= 8) {
      out =
      '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
    }
    if (out != _phoneCtrl.text) {
      final pos = out.length;
      _phoneCtrl.value =
          TextEditingValue(text: out, selection: TextSelection.collapsed(offset: pos));
    }
    setState(() {});
  }

  Future<void> _submit() async {
    _isNotiError = true;
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('개인정보 처리방침에 동의해주세요.')));
      return;
    }

    setState(() => _busy = true);
    try {
      final resp = await http.post(
        Uri.parse('https://sonjobdamd.com/func/hcsendpartnerinquiry.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'type': _type,
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'organization': _orgCtrl.text.trim(),
          'position': _titleCtrl.text.trim(),
          'title': _subjectCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('제휴 문의가 제출되었습니다. 빠르게 연락드릴게요.')));
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('제출에 실패했습니다. 다시 시도해주세요.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제출 중 오류가 발생했습니다.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _orgCtrl.dispose();
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('제휴/문의'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isWide ? _buildWide() : _buildNarrow(),
          ),
        ),
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 왼쪽 이미지
        Expanded(
          child: Container(
            height: 520,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E5EF)),
              image: const DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/qna_bg.png'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 오른쪽 폼
        Expanded(child: _formCard()),
      ],
    );
  }

  Widget _buildNarrow() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E5EF)),
            image: const DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/qna_bg.png'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _formCard(),
      ],
    );
  }

  Widget _formCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE7E5EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // 즉시 검증
          child: Column(
            children: [
              // 이름 / 유형
              Row(
                children: [
                  Expanded(child: _field(
                    label: '이름',
                    child: TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          hintText: '홍길동', border: OutlineInputBorder()),
                      validator: (v) =>
                      (_isNotiError && (v == null || v.trim().isEmpty)) ? '이름을 입력해주세요' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _field(
                    label: '유형',
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '유형을 선택해주세요'),
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: '제휴/광고', child: Text('제휴/광고')),
                        DropdownMenuItem(value: '서비스 문의', child: Text('서비스 문의')),
                        DropdownMenuItem(value: '기타', child: Text('기타')),
                      ],
                      onChanged: (v) => setState(() => _type = v),
                      validator: (v) =>
                      (_isNotiError && (v == null || v.isEmpty)) ? '유형을 선택해주세요' : null,
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),

              // 전화 / 이메일
              Row(
                children: [
                  Expanded(child: _field(
                    label: '연락처',
                    child: TextFormField(
                      controller: _phoneCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      onChanged: _onPhoneChanged,
                      decoration: const InputDecoration(
                          hintText: '010-1234-5678', border: OutlineInputBorder()),
                      validator: (v) {
                        if(false == _isNotiError) return null;
                        final ok = RegExp(r'^\d{3}-\d{4}-\d{4}$').hasMatch(v ?? '');
                        return ok ? null : '전화번호 형식이 올바르지 않습니다';
                      },
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _field(
                    label: '이메일',
                    child: TextFormField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          hintText: 'example@mail.com', border: OutlineInputBorder()),
                      validator: (v) {
                        if(false == _isNotiError) return null;
                        final ok = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$')
                            .hasMatch(v ?? '');
                        return ok ? null : '이메일 형식이 올바르지 않습니다';
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),

              // 소속 / 직급
              Row(
                children: [
                  Expanded(child: _field(
                    label: '소속 기관',
                    child: TextFormField(
                      controller: _orgCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          hintText: '(주)손잡다매칭', border: OutlineInputBorder()),
                      validator: (v) =>
                      _isNotiError && (v == null || v.trim().isEmpty) ? '소속을 입력해주세요' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _field(
                    label: '직급/직위',
                    child: TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          hintText: '대표이사', border: OutlineInputBorder()),
                      validator: (v) =>
                      _isNotiError && (v == null || v.trim().isEmpty) ? '직급/직위를 입력해주세요' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),

              // 제목
              _field(
                label: '문의 제목',
                child: TextFormField(
                  controller: _subjectCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      hintText: '문의 내용을 간단히 남겨주세요',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                  _isNotiError && (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),

              // 내용
              _field(
                label: '문의 내용',
                child: TextFormField(
                  controller: _contentCtrl,
                  minLines: 6,
                  maxLines: 12,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _busy ? null : _submit,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) =>
                  _isNotiError && (v == null || v.trim().isEmpty) ? '문의 내용을 입력해주세요' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),

              // 개인정보 동의
              Align(
                alignment: Alignment.centerLeft,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  title: const Text('개인정보 처리방침에 동의합니다.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('문의하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 자주하는질문 - FAQ 목록
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static final _items = [
    ('앱에서 대리운전 어떻게 부르나요?', '24시간 앱 접수 버튼을 누르시면 현재 위치를 기반으로 호출됩니다.'),
    ('전화로도 부를 수 있나요?', '네. 010-2184-8822로 전화 접수 가능합니다. 전화 접수 시 10% 적립됩니다.'),
    ('마일리지는 어떻게 적립되나요?', '가입 시 10,000원 지급, 카드 결제 시 이용금액의 10% 적립됩니다.'),
    ('출금은 어떻게 하나요?', '최대 100만원까지 출금 가능합니다. 20,000원 이상 10,000원 단위로 출금 신청하세요.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('자주하는질문', style: TextStyle(color: Colors.black87)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...List.generate(_items.length, (i) {
            final (q, a) = _items[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _items.length - 1 ? 12 : 20),
              child: _FaqTile(question: q, answer: a),
            );
          }),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            leading: PhosphorIcon(PhosphorIconsRegular.info, color: Colors.grey.shade700),
            title: const Text('앱 정보 · 고객센터', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('버전, 1668-0001, 이용약관·개인정보'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/app-info'),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: PhosphorIcon(PhosphorIconsRegular.question, size: 22, color: Colors.grey.shade600),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        ),
      ],
    );
  }
}

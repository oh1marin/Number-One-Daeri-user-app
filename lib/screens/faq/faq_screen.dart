import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_screen_widgets.dart';

/// 자주하는질문 - FAQ 목록
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _hotline = '010-2184-8822';

  static final _items = [
    ('앱에서 대리운전 어떻게 부르나요?', '24시간 앱 접수 버튼을 누르시면 현재 위치를 기반으로 호출됩니다.'),
    ('전화로도 부를 수 있나요?', '네. $_hotline로 전화 접수 가능합니다. 전화 접수 시 10% 적립됩니다.'),
    ('마일리지는 어떻게 적립되나요?', '가입 시 10,000원 지급, 카드 결제 시 이용금액의 10% 적립됩니다.'),
    ('출금은 어떻게 하나요?', '최대 100만원까지 출금 가능합니다. 20,000원 이상 10,000원 단위로 출금 신청하세요.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('자주하는질문')),
      body: ListView(
        padding: AppTheme.pagePadding,
        children: [
          AppListCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.question,
                    size: 22,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '궁금한 점을 확인하세요',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(4),
                      Text(
                        '고객센터 $_hotline',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          ...List.generate(_items.length, (i) {
            final (q, a) = _items[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _items.length - 1 ? 10 : 16),
              child: _FaqTile(question: q, answer: a),
            );
          }),
          AppNavListTile(
            icon: PhosphorIconsRegular.info,
            title: '앱 정보 · 고객센터',
            subtitle: '버전, $_hotline, 이용약관·개인정보',
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
    return AppListCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const PhosphorIcon(
            PhosphorIconsRegular.chatCircleDots,
            size: 22,
            color: AppTheme.accentBlue,
          ),
          title: Text(
            question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
          ),
          children: [
            Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

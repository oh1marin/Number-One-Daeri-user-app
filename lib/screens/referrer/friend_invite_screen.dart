import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_share_text.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/app_screen_widgets.dart';
import '../../widgets/friend_referral_background.dart';

/// 친구 초대 안내
class FriendInviteScreen extends StatelessWidget {
  const FriendInviteScreen({super.key});

  void _shareApp(BuildContext context) {
    Share.share(AppShareText.build(), subject: '일등대리 앱 추천');
  }

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveLayout.pageHorizontal(context);
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('친구 초대')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _IntroCard(),
            const Gap(16),
            const _FriendInviteBenefitsSection(),
            const Gap(16),
            _ActionTile(
              icon: PhosphorIconsRegular.shareNetwork,
              title: '초대 링크 공유하기',
              subtitle: '친구에게 앱을 추천해 보세요',
              onTap: () => _shareApp(context),
            ),
            const Gap(10),
            _ActionTile(
              icon: PhosphorIconsRegular.chartLineUp,
              title: '내 추천 현황',
              subtitle: '추천한 친구 수와 보상 확인',
              onTap: () => Navigator.pushNamed(context, '/referrer-status'),
            ),
            const Gap(10),
            _ActionTile(
              icon: PhosphorIconsRegular.userPlus,
              title: '추천인 등록',
              subtitle: '나를 추천해 준 분의 전화번호 등록',
              onTap: () => Navigator.pushNamed(context, '/referrer'),
            ),
            const AppScrollSafeGap(extra: 16),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2F7A), AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '친구를 초대하고\n마일리지 혜택을 받아보세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          Gap(8),
          Text(
            '친구가 가입하고 이용하면 나에게도, 친구에게도 혜택이 쌓입니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendInviteBenefitsSection extends StatelessWidget {
  const _FriendInviteBenefitsSection();

  @override
  Widget build(BuildContext context) {
    return FriendReferralBackgroundCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BenefitBlock(
            title: '추천인 혜택',
            content:
                '친구 가입 시 2,000원 → 첫 이용 시 3,000원 추가 → 친구 이용할 때마다 이용금액의 5% 적립!',
          ),
          const Gap(16),
          Divider(color: Colors.grey.shade300),
          const Gap(12),
          _BenefitBlock(
            title: '기본 혜택 (모든 사용자)',
            content: '앱 가입 완료 시 10,000원 적립 (추천 아님)\n카드 결제 시 이용금액의 10% 적립',
          ),
        ],
      ),
    );
  }
}

class _BenefitBlock extends StatelessWidget {
  const _BenefitBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentBlue,
            ),
          ),
        ),
        const Gap(10),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, size: 22, color: AppTheme.primaryDark),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

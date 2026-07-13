import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/referral_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_share_text.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_screen_widgets.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/load_error_view.dart';

/// 내추천인 현황 - 1줄 추천인 요약 + 실적
class ReferrerStatusScreen extends StatefulWidget {
  const ReferrerStatusScreen({super.key});

  @override
  State<ReferrerStatusScreen> createState() => _ReferrerStatusScreenState();
}

class _ReferrerStatusScreenState extends State<ReferrerStatusScreen> {
  int _count = 0;
  bool _loading = true;
  String? _error;
  bool _tier2Earned = false;
  bool _tier5Earned = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ReferralApi.getMy();
      if (!mounted) return;
      if (res.success && res.data != null) {
        final d = res.data!;
        setState(() {
          _count = (d['referredCount'] as num?)?.toInt() ?? 0;
          final tierCoupons = d['tierCoupons'] as List? ?? [];
          _tier2Earned = tierCoupons.any((c) => (c as Map)['tier'] == 2);
          _tier5Earned = tierCoupons.any((c) => (c as Map)['tier'] == 5);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = res.error ?? '추천 현황을 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = loadErrorMessage(e, fallback: '추천 현황을 불러오지 못했습니다.');
        });
      }
    }
  }

  void _shareApp() {
    Share.share(AppShareText.build(), subject: '일등대리 앱 추천');
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityReconnectListener(
      onReconnect: _load,
      child: Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('추천인 현황')),
      body: _loading
          ? const AppPageLoading()
          : _error != null
              ? LoadErrorView(message: _error!, onRetry: _load)
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(count: _count),
                  const Gap(20),
                  const _BenefitsSection(),
                  const Gap(20),
                  _NextRewardCard(count: _count),
                  const Gap(20),
                  _AchievementSection(tier2: _tier2Earned, tier5: _tier5Earned, count: _count),
                  if (_tier2Earned || _tier5Earned || _count >= 2) ...[
                    const Gap(12),
                    _TierCouponHint(
                      onTap: () => Navigator.pushNamed(context, '/coupon'),
                    ),
                  ],
                  const Gap(24),
                  _ShareButton(onTap: _shareApp),
                  const Gap(16),
                  _EmptyStateWithCta(
                    hasData: _count > 0,
                    onTap: _shareApp,
                  ),
                ],
              ),
            ),
    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentBlue,
            AppTheme.lightBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: PhosphorIcon(
              PhosphorIconsRegular.users,
              color: Colors.white,
              size: 32,
            ),
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count명',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const Gap(4),
                Text(
                  '추천받은 사람',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 추천 혜택 안내
class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BenefitBlock(
            title: '추천인 혜택',
            content: '친구 가입 시 2,000원 → 첫 이용 시 3,000원 추가 → 친구 이용할 때마다 이용금액의 5% 적립!',
          ),
          const Gap(16),
          Divider(color: Colors.grey.shade200),
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
        Row(
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
          ],
        ),
        const Gap(10),
        Text(
          content,
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
        ),
      ],
    );
  }
}

class _NextRewardCard extends StatelessWidget {
  const _NextRewardCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    String nextTier;
    String nextReward;
    int remain;
    if (count >= 5) {
      nextTier = '완료';
      nextReward = '모든 보상 달성!';
      remain = 0;
    } else if (count >= 2) {
      nextTier = '5명';
      nextReward = '교촌양념 (22,000원)';
      remain = 5 - count;
    } else {
      nextTier = '2명';
      nextReward = '메가MGC커피 아메리카노 쿠폰 2장';
      remain = 2 - count;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 보상',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Gap(8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  nextTier,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                    fontSize: 14,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  nextReward,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (remain > 0)
                Text(
                  '$remain명 남음',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  const _AchievementSection({
    required this.tier2,
    required this.tier5,
    required this.count,
  });

  final bool tier2;
  final bool tier5;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '실적',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _AchievementBadge(
                label: '2명 추천',
                reward: '메가MGC커피',
                achieved: tier2 || count >= 2,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _AchievementBadge(
                label: '5명 추천',
                reward: '교촌양념',
                achieved: tier5 || count >= 5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TierCouponHint extends StatelessWidget {
  const _TierCouponHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.green.shade700),
              const Gap(10),
              Expanded(
                child: Text(
                  '2명·5명 달성 기프티콘 티켓은 쿠폰함에 지급됩니다. 원할 때 사용하세요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.label,
    required this.reward,
    required this.achieved,
  });

  final String label;
  final String reward;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achieved ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          if (achieved)
            PhosphorIcon(PhosphorIconsRegular.sealCheck, color: Colors.green.shade600, size: 28)
          else
            PhosphorIcon(PhosphorIconsRegular.seal, color: Colors.grey.shade400, size: 28),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const Gap(4),
          Text(
            reward,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: achieved ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
          if (achieved) ...[
            const Gap(4),
            Text(
              '쿠폰함 지급',
              style: TextStyle(fontSize: 11, color: Colors.green.shade700),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: PhosphorIcon(PhosphorIconsRegular.shareNetwork, color: Colors.white, size: 20),
        label: const Text('친구 초대하기'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _EmptyStateWithCta extends StatelessWidget {
  const _EmptyStateWithCta({required this.hasData, required this.onTap});

  final bool hasData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (hasData) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.usersThree,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const Gap(16),
          Text(
            '아직 추천한 친구가 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
          const Gap(8),
          Text(
            '친구 추천하면 2천원! 첫 이용 시 3천원! 이용할 때마다 5%',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const Gap(20),
          TextButton.icon(
            onPressed: onTap,
            icon: PhosphorIcon(PhosphorIconsRegular.userPlus, size: 18, color: AppTheme.accentBlue),
            label: const Text('친구 초대하기'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }
}

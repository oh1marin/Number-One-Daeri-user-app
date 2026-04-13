import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/notices_api.dart';
import '../../config/media_url.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/phone_call_modal.dart';
import '../call/call_map_screen.dart';

void _shareAppLink(BuildContext context) {
  Share.share('일등대리 1668-0001 완전대박! 앱 다운받고 혜택 받아가세요 🚗', subject: '일등대리 앱 추천');
}

/// 홈 화면 (MainScaffold의 body로 사용 - Scaffold 없음)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onMenuTap: onMenuTap),
              _NoticeRow(),
              const Gap(20),
              _MethodSelectRow(),
              const Gap(14),
              _MainAppCard(),
              const Gap(14),
              _TwoCards(),
              const Gap(14),
              _FriendReferralBanner(),
              const Gap(14),
              const _ThreeFeatureCards(),
              const Gap(100),
            ],
          ),
        ),
      ],
    );
  }
}

/// 하단 네비바 (MainScaffold에서 사용)
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BottomNavBar();
  }
}

// ── 상단 바 ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.list,
              color: AppTheme.primaryDark,
            ),
            onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              '일등대리',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _TopBarAction(
            icon: PhosphorIconsRegular.bell,
            onTap: () => Navigator.pushNamed(context, '/notice'),
          ),
          const Gap(4),
          _TopBarAction(
            icon: PhosphorIconsRegular.shareNetwork,
            onTap: () => _shareAppLink(context),
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: PhosphorIcon(icon, size: 22, color: AppTheme.primaryDark),
      ),
    );
  }
}

// ── 공지 띠 ──────────────────────────────────────────────────────────────────

class _NoticeRow extends StatefulWidget {
  const _NoticeRow();

  @override
  State<_NoticeRow> createState() => _NoticeRowState();
}

class _NoticeRowState extends State<_NoticeRow> {
  static const _fallbackTitle = '신규 가입 시 1만원, 친구 추천 이벤트 진행 중!';

  Notice? _latest;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NoticesApi.getList(page: 1, limit: 1);
    if (!mounted) return;
    setState(() {
      _latest = list.isEmpty ? null : list.first;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = (_latest?.title.trim().isNotEmpty ?? false)
        ? _latest!.title
        : _fallbackTitle;
    final thumb = _latest != null
        ? (resolveMediaUrl(_latest!.coverImageUrl) ??
              resolveMediaUrl(_latest!.imageUrl))
        : null;

    return Material(
      color: AppTheme.primaryDark.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/notice'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '공지',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (thumb != null) ...[
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: AppNetworkImage(url: thumb, fit: BoxFit.cover),
                  ),
                ),
              ],
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!_loaded)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade400,
                  ),
                )
              else
                PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 접수 방법 선택 헤더 ───────────────────────────────────────────────────────

class _MethodSelectRow extends StatelessWidget {
  const _MethodSelectRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '접수 방법을 선택하세요',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 14, color: AppTheme.accentBlue),
                const Gap(4),
                Text(
                  'M 10,000원',
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 메인 CTA 카드 ─────────────────────────────────────────────────────────────

class _MainAppCard extends StatelessWidget {
  const _MainAppCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CallMapScreen(key: UniqueKey())),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2F7A), AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '24시간 앱 접수',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 14,
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              '카드 결제 10% 적립',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              softWrap: true,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(20),
              const Text(
                '빠르고 안전한 대리운전',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(6),
              Text(
                '지금 바로 출발지를 설정하고\n가까운 기사님을 배정받으세요.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const Gap(20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '지금 바로 호출하기',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(6),
                    PhosphorIcon(
                      PhosphorIconsRegular.arrowRight,
                      color: AppTheme.primaryDark,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소형 카드 2개 ─────────────────────────────────────────────────────────────

class _TwoCards extends StatelessWidget {
  const _TwoCards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _SmallCard(
              icon: PhosphorIconsRegular.phone,
              iconColor: const Color(0xFF4CAF50),
              title: '전화로 부르기',
              sub: '1668-0001',
              onTap: () => showPhoneCallModal(context),
            ),
          ),
          const Gap(12),
          Expanded(
            child: _SmallCard(
              icon: PhosphorIconsRegular.plant,
              iconColor: const Color(0xFFE91E8C),
              title: '플라워',
              sub: '전국 최저가',
              onTap: () => _openFlowerUrl(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFlowerUrl() async {
    try {
      await launchUrl(
        Uri.parse('https://꽃천사.com'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(icon, size: 22, color: iconColor),
            ),
            const Gap(12),
            Text(
              title,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.primaryDark,
                height: 1.25,
              ),
            ),
            const Gap(3),
            Text(
              sub,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 친구 추천 배너 ────────────────────────────────────────────────────────────

class _FriendReferralBanner extends StatelessWidget {
  const _FriendReferralBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/referrer-status'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2F7A), AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PhosphorIcon(
                  PhosphorIconsRegular.gift,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Badge('10,000원'),
                        const Gap(5),
                        Text(
                          '+',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                        const Gap(5),
                        _Badge('2,000원'),
                      ],
                    ),
                    const Gap(6),
                    const Text(
                      '친구 초대하고 혜택 받기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── 기능 3개 카드 ─────────────────────────────────────────────────────────────

class _ThreeFeatureCards extends StatelessWidget {
  const _ThreeFeatureCards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _FeatureCard(
              icon: PhosphorIconsRegular.car,
              label: '이용내역',
              color: const Color(0xFF5C6BC0),
              onTap: () => Navigator.pushNamed(context, '/ride-history'),
            ),
          ),
          const Gap(10),
          Expanded(
            child: _FeatureCard(
              icon: PhosphorIconsRegular.userPlus,
              label: '친구추천',
              color: const Color(0xFF1A2F7A),
              onTap: () => Navigator.pushNamed(context, '/referrer-status'),
            ),
          ),
          const Gap(10),
          Expanded(
            child: _FeatureCard(
              icon: PhosphorIconsRegular.wallet,
              label: '마일리지',
              color: const Color(0xFF1A2F7A),
              onTap: () => Navigator.pushNamed(context, '/mileage'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, size: 24, color: color),
            ),
            const Gap(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 하단 내비바 ───────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 6,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: PhosphorIconsRegular.megaphone,
            label: '공지사항',
            route: '/notice',
            color: Color(0xFFE53935),
          ),
          _NavItem(
            icon: PhosphorIconsRegular.wallet,
            label: '출금신청',
            route: '/withdrawal',
            color: Color(0xFF1E88E5),
          ),
          _NavItem(
            icon: PhosphorIconsRegular.chatCircle,
            label: '문의하기',
            route: '/qa',
            color: Color(0xFF43A047),
          ),
          _NavItem(
            icon: PhosphorIconsRegular.creditCard,
            label: '카드등록',
            route: '/card',
            color: Color(0xFF1E88E5),
          ),
          _NavItem(
            icon: PhosphorIconsRegular.ticket,
            label: '이벤트',
            route: '/event',
            color: Color(0xFFF9A825),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.color = AppTheme.primaryDark,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(icon, size: 20, color: color),
            ),
            const Gap(4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/ads_api.dart';
import '../../api/events_api.dart';
import '../../api/notices_api.dart';
import '../../services/content_read_store.dart';
import '../../utils/app_share_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/mileage_balance_cache.dart';
import '../../config/media_url.dart';
import '../../routes/navigation.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/phone_call_modal.dart';
import '../call/call_map_screen.dart';

void _shareAppLink(BuildContext context) {
  Share.share(AppShareText.build(), subject: '일등대리 앱 추천');
}

/// 홈 화면 (MainScaffold의 body로 사용 - Scaffold 없음)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  int _mileageBalance = 0;
  bool _mileageLoaded = false;
  int _unreadContentCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMileageBalance();
    _loadUnreadBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadMileageBalance();
      _loadUnreadBadge();
    }
  }

  @override
  void didPopNext() {
    _loadMileageBalance();
    _loadUnreadBadge();
  }

  Future<void> _loadUnreadBadge() async {
    try {
      final results = await Future.wait([
        NoticesApi.getList(page: 1, limit: 20),
        EventsApi.getList(),
        AdsApi.getList(),
      ]);
      final notices = results[0] as List<Notice>;
      final events = results[1] as List<EventItem>;
      final ads = results[2] as List<AdItem>;
      final count = await ContentReadStore.totalUnread(
        noticeIds: notices.map((n) => n.id),
        eventIds: [
          ...events.map((e) => e.id),
          ...ads.map((a) => a.id.isEmpty ? '' : 'ad_${a.id}'),
        ],
      );
      if (!mounted) return;
      setState(() => _unreadContentCount = count);
    } catch (_) {}
  }

  Future<void> _loadMileageBalance({bool force = false}) async {
    try {
      final bal = await MileageBalanceCache.getBalance(force: force);
      if (!mounted) return;
      setState(() {
        _mileageBalance = bal.balance;
        _mileageLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mileageLoaded = true; // keep last known balance; avoid spinner forever
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = 10.0 * ResponsiveLayout.homeScale(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveLayout.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(onMenuTap: widget.onMenuTap),
                  _NoticeRow(unreadCount: _unreadContentCount),
                  Gap(14 * ResponsiveLayout.homeScale(context)),
                  _MethodSelectRow(
                    mileageBalance: _mileageBalance,
                    loaded: _mileageLoaded,
                  ),
                  Gap(gap),
                  const _MainAppCard(),
                  Gap(gap),
                  const _TwoCards(),
                  Gap(gap),
                  const _FriendReferralBanner(),
                  Gap(gap),
                  const _ThreeFeatureCards(),
                  Gap(ResponsiveLayout.homeListBottomSpace(context)),
                ],
              ),
            ),
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
        right: ResponsiveLayout.horizontalPadding(context),
        bottom: 8,
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
              width: (34 * ResponsiveLayout.homeScale(context)).clamp(28.0, 40.0),
              height: (34 * ResponsiveLayout.homeScale(context)).clamp(28.0, 40.0),
              fit: BoxFit.cover,
            ),
          ),
          Gap(10 * ResponsiveLayout.homeScale(context)),
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
            icon: PhosphorIconsRegular.info,
            onTap: () => Navigator.pushNamed(context, '/app-info'),
          ),
          const Gap(4),
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
  const _NoticeRow({this.unreadCount = 0});

  final int unreadCount;

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
          padding: EdgeInsets.symmetric(
            horizontal: (16 * ResponsiveLayout.homeScale(context)).clamp(12.0, 20.0),
            vertical: 9,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                  if (widget.unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
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
  const _MethodSelectRow({required this.mileageBalance, required this.loaded});

  final int mileageBalance;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
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
                  loaded ? 'M ${formatKrw(mileageBalance)}원' : 'M -',
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
    final scale = ResponsiveLayout.homeScale(context);
    final hPad = ResponsiveLayout.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CallMapScreen(key: UniqueKey())),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/banner_call_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryDark.withValues(alpha: 0.92),
                        AppTheme.primaryDark.withValues(alpha: 0.72),
                        AppTheme.primaryDark.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all((20 * scale).clamp(14.0, 22.0)),
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
                        const Gap(8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.credit_card_rounded,
                                  color: AppTheme.primaryDark,
                                  size: 14,
                                ),
                                const Gap(4),
                                Flexible(
                                  child: Text(
                                    '카드 10% 적립',
                                    style: const TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(14 * scale),
                    Text(
                      '빠르고 안전한 대리운전',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (20 * scale).clamp(16.0, 22.0),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Gap(6 * scale),
                    Text(
                      '지금 바로 출발지를 설정하고\n가까운 기사님을 배정받으세요.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: (13 * scale).clamp(12.0, 15.0),
                        height: 1.5,
                      ),
                    ),
                    Gap(14 * scale),
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
            ],
          ),
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
      padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SmallCard(
                icon: PhosphorIconsRegular.phone,
                iconColor: const Color(0xFF4CAF50),
                title: '전화로 부르기',
                sub: '010-2184-8822',
                onTap: () => showPhoneCallModal(context),
              ),
            ),
            Gap(12 * ResponsiveLayout.homeScale(context)),
            Expanded(
              child: _FlowerBannerCard(
                onTap: () => _openFlowerUrl(),
              ),
            ),
          ],
        ),
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

class _FlowerBannerCard extends StatelessWidget {
  const _FlowerBannerCard({required this.onTap});

  final VoidCallback onTap;

  static const _aspectRatio = 593 / 410;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: Image.asset(
            'assets/images/banner_flower.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.all(12),
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
    final scale = ResponsiveLayout.homeScale(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/friend-invite'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all((14 * scale).clamp(12.0, 18.0)),
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
    final g = 10 * ResponsiveLayout.homeScale(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
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
          Gap(g),
          Expanded(
            child: _FeatureCard(
              icon: PhosphorIconsRegular.userPlus,
              label: '친구추천',
              color: const Color(0xFF1A2F7A),
              onTap: () => Navigator.pushNamed(context, '/friend-invite'),
            ),
          ),
          Gap(g),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
    final compact = ResponsiveLayout.isCompactWidth(context);
    final padBottom = MediaQuery.paddingOf(context).bottom;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: PhosphorIconsRegular.megaphone,
          label: '공지사항',
          route: '/notice',
          color: const Color(0xFFE53935),
          compact: compact,
        ),
        _NavItem(
          icon: PhosphorIconsRegular.wallet,
          label: '출금신청',
          route: '/withdrawal',
          color: const Color(0xFF1E88E5),
          compact: compact,
        ),
        _NavItem(
          icon: PhosphorIconsRegular.chatCircle,
          label: '문의하기',
          route: '/qa',
          color: const Color(0xFF43A047),
          compact: compact,
        ),
        _NavItem(
          icon: PhosphorIconsRegular.creditCard,
          label: '카드등록',
          route: '/card',
          color: const Color(0xFF1E88E5),
          compact: compact,
        ),
        _NavItem(
          icon: PhosphorIconsRegular.ticket,
          label: '이벤트',
          route: '/event',
          color: const Color(0xFFF9A825),
          compact: compact,
        ),
      ],
    );
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
      padding: EdgeInsets.only(bottom: padBottom, top: 4),
      child: ResponsiveLayout.isCompactWidth(context)
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: row,
            )
          : row,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.color = AppTheme.primaryDark,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 4.0 : 12.0;
    final iconBg = compact ? 5.0 : 7.0;
    final iconSize = compact ? 18.0 : 20.0;
    final labelSize = compact ? 9.0 : 10.0;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: compact ? 6 : 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconBg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(icon, size: iconSize, color: color),
            ),
            Gap(compact ? 2 : 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
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

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_theme.dart';
import 'home_screen.dart';

/// Drawer + Home 래퍼
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfaceGrey,
      drawer: const _AppDrawer(),
      body: HomeScreen(onMenuTap: openDrawer),
      bottomNavigationBar: const HomeBottomNavBar(),
    );
  }
}

// ── 드로어 ────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  static const _sections = [
    _DrawerSection(title: '서비스', items: [
      _DrawerItem(icon: PhosphorIconsRegular.megaphone,   label: '공지사항',       route: '/notice'),
      _DrawerItem(icon: PhosphorIconsRegular.question,    label: '자주하는질문',   route: '/faq'),
      _DrawerItem(icon: PhosphorIconsRegular.ticket,      label: '쿠폰등록',       route: '/coupon'),
      _DrawerItem(icon: PhosphorIconsRegular.ticket,      label: '이벤트',         route: '/event'),
    ]),
    _DrawerSection(title: '내 정보', items: [
      _DrawerItem(icon: PhosphorIconsRegular.car,         label: '운행내역',       route: '/ride-history'),
      _DrawerItem(icon: PhosphorIconsRegular.wallet,      label: '마일리지내역',   route: '/mileage'),
      _DrawerItem(icon: PhosphorIconsRegular.creditCard,  label: '카드관리',       route: '/card'),
      _DrawerItem(icon: PhosphorIconsRegular.userPlus,    label: '내추천인 등록',  route: '/referrer'),
      _DrawerItem(icon: PhosphorIconsRegular.users,       label: '내추천인 현황',  route: '/referrer-status'),
    ]),
    _DrawerSection(title: '고객 지원', items: [
      _DrawerItem(icon: PhosphorIconsRegular.warning,     label: '사고/과태료',    route: '/accident-penalty'),
      _DrawerItem(icon: PhosphorIconsRegular.flag,        label: '불편신고',       route: '/complaint'),
    ]),
    _DrawerSection(title: '설정', items: [
      _DrawerItem(icon: PhosphorIconsRegular.bell,        label: '알림설정',       route: '/notification-settings'),
      _DrawerItem(icon: PhosphorIconsRegular.trash,       label: '계정삭제',       route: '/account-delete'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.primaryDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '일등대리',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '1668-0001',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

            // 메뉴 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _sections.map((s) => _SectionWidget(section: s)).toList(),
              ),
            ),

            // 하단 앱 버전
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '일등대리 ⓒ 2026',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection {
  const _DrawerSection({required this.title, required this.items});
  final String title;
  final List<_DrawerItem> items;
}

class _DrawerItem {
  const _DrawerItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({required this.section});
  final _DrawerSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            section.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...section.items.map((item) => _DrawerTile(item: item)),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.item});
  final _DrawerItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: PhosphorIcon(item.icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
      title: Text(
        item.label,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: PhosphorIcon(
        PhosphorIconsRegular.caretRight,
        color: Colors.white.withValues(alpha: 0.25),
        size: 14,
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, item.route);
      },
    );
  }
}

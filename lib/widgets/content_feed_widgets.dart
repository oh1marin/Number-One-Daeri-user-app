import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// 공지·이벤트 배지 색 (badgeColor Tailwind 문자열 또는 라벨 기반)
class ContentBadgeStyle {
  const ContentBadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static ContentBadgeStyle resolve({String? badgeColor, String badge = '공지'}) {
    final hint = (badgeColor ?? badge).toLowerCase();
    if (hint.contains('red')) {
      return const ContentBadgeStyle(
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFFDC2626),
      );
    }
    if (hint.contains('amber') || hint.contains('yellow') || hint.contains('orange')) {
      return const ContentBadgeStyle(
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFFD97706),
      );
    }
    if (hint.contains('green') || hint.contains('emerald')) {
      return const ContentBadgeStyle(
        background: Color(0xFFD1FAE5),
        foreground: Color(0xFF059669),
      );
    }
    if (hint.contains('blue') || hint.contains('indigo')) {
      return const ContentBadgeStyle(
        background: Color(0xFFDBEAFE),
        foreground: Color(0xFF2563EB),
      );
    }
    if (badge.contains('이벤트')) {
      return const ContentBadgeStyle(
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFFD97706),
      );
    }
    if (badge.contains('안내')) {
      return const ContentBadgeStyle(
        background: Color(0xFFDBEAFE),
        foreground: Color(0xFF2563EB),
      );
    }
    return ContentBadgeStyle(
      background: AppTheme.primaryDark.withValues(alpha: 0.08),
      foreground: AppTheme.primaryDark,
    );
  }
}

class ContentBadgeChip extends StatelessWidget {
  const ContentBadgeChip({
    super.key,
    required this.label,
    this.badgeColor,
    this.compact = false,
  });

  final String label;
  final String? badgeColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final style = ContentBadgeStyle.resolve(badgeColor: badgeColor, badge: label);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: style.foreground,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// 공지·이벤트 목록 카드 (16px radius, borderGrey)
class ContentListCard extends StatelessWidget {
  const ContentListCard({
    super.key,
    required this.child,
    this.onTap,
    this.isUnread = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppTheme.accentBlue.withValues(alpha: 0.35)
                  : AppTheme.borderGrey,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

class ContentUnreadDot extends StatelessWidget {
  const ContentUnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
    );
  }
}

class ContentSectionHeader extends StatelessWidget {
  const ContentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const Gap(4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ContentHeroBanner extends StatelessWidget {
  const ContentHeroBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.28),
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
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(icon, color: Colors.white, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
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

class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                icon,
                size: 40,
                color: AppTheme.textSecondary,
              ),
            ),
            const Gap(16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.primaryDark,
              ),
            ),
            if (subtitle != null) ...[
              const Gap(6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContentDetailSheetHandle extends StatelessWidget {
  const ContentDetailSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.borderGrey,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(16),
      ],
    );
  }
}

class ContentEventStatusChip extends StatelessWidget {
  const ContentEventStatusChip({super.key, required this.startAt, required this.endAt});

  final String? startAt;
  final String? endAt;

  @override
  Widget build(BuildContext context) {
    final status = _eventStatus(startAt, endAt);
    if (status == null) return const SizedBox.shrink();
    final (label, bg, fg) = switch (status) {
      _EventStatus.ongoing => ('진행중', const Color(0xFFD1FAE5), const Color(0xFF059669)),
      _EventStatus.upcoming => ('예정', const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      _EventStatus.ended => ('종료', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

enum _EventStatus { ongoing, upcoming, ended }

_EventStatus? _eventStatus(String? startIso, String? endIso) {
  DateTime? parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  final now = DateTime.now();
  final start = parse(startIso);
  final end = parse(endIso);
  if (start == null && end == null) return null;
  if (end != null && now.isAfter(end)) return _EventStatus.ended;
  if (start != null && now.isBefore(start)) return _EventStatus.upcoming;
  return _EventStatus.ongoing;
}

String? formatEventDateRange(String? startIso, String? endIso) {
  String? fmt(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
    return m != null ? '${m[1]}.${m[2]}.${m[3]}' : iso;
  }

  final s = fmt(startIso);
  final e = fmt(endIso);
  if (s == null && e == null) return null;
  if (s != null && e != null) return '$s ~ $e';
  return s ?? e;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

enum TopAppNoticeType { success, warning, error, info }

/// 화면 상단(앱바 아래)에 잠깐 뜨는 알림 카드 — 하단 UI를 가리지 않음.
void showTopAppNotice(
  BuildContext context, {
  required String title,
  required String message,
  TopAppNoticeType type = TopAppNoticeType.success,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  void removeEntry() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _TopAppNoticeBanner(
      title: title,
      message: message,
      type: type,
      onDismiss: removeEntry,
    ),
  );

  overlay.insert(entry);
  Timer(duration, removeEntry);
}

class _TopAppNoticeBanner extends StatefulWidget {
  const _TopAppNoticeBanner({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final TopAppNoticeType type;
  final VoidCallback onDismiss;

  @override
  State<_TopAppNoticeBanner> createState() => _TopAppNoticeBannerState();
}

class _TopAppNoticeBannerState extends State<_TopAppNoticeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  _NoticeStyle _style() {
    switch (widget.type) {
      case TopAppNoticeType.success:
        return const _NoticeStyle(
          bg: Color(0xFFE8F5E9),
          border: Color(0xFFA5D6A7),
          iconBg: Color(0xFF2E7D32),
          icon: PhosphorIconsRegular.checkCircle,
          titleColor: Color(0xFF1B5E20),
          bodyColor: Color(0xFF2E7D32),
        );
      case TopAppNoticeType.warning:
        return const _NoticeStyle(
          bg: Color(0xFFFFF8E1),
          border: Color(0xFFFFE082),
          iconBg: Color(0xFFF57C00),
          icon: PhosphorIconsRegular.warningCircle,
          titleColor: Color(0xFFE65100),
          bodyColor: Color(0xFFBF360C),
        );
      case TopAppNoticeType.error:
        return const _NoticeStyle(
          bg: Color(0xFFFFEBEE),
          border: Color(0xFFEF9A9A),
          iconBg: Color(0xFFC62828),
          icon: PhosphorIconsRegular.xCircle,
          titleColor: Color(0xFFB71C1C),
          bodyColor: Color(0xFFC62828),
        );
      case TopAppNoticeType.info:
        return const _NoticeStyle(
          bg: Color(0xFFE3F2FD),
          border: Color(0xFF90CAF9),
          iconBg: AppTheme.accentBlue,
          icon: PhosphorIconsRegular.mapPin,
          titleColor: AppTheme.primaryDark,
          bodyColor: Color(0xFF1565C0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
    final style = _style();

    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('top_app_notice'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: style.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: style.iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: PhosphorIcon(
                          style.icon,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: style.titleColor,
                              ),
                            ),
                            const Gap(3),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: style.bodyColor,
                                height: 1.35,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Gap(6),
                      PhosphorIcon(
                        PhosphorIconsRegular.x,
                        size: 14,
                        color: style.bodyColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeStyle {
  const _NoticeStyle({
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.icon,
    required this.titleColor,
    required this.bodyColor,
  });

  final Color bg;
  final Color border;
  final Color iconBg;
  final IconData icon;
  final Color titleColor;
  final Color bodyColor;
}

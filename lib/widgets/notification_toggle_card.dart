import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';

/// 공지·설정 등에서 공통으로 쓰는 푸시 알림 토글 카드.
class NotificationToggleCard extends StatefulWidget {
  const NotificationToggleCard({
    super.key,
    this.compact = false,
  });

  /// 공지 목록 상단용 — 설명 문구 축소.
  final bool compact;

  @override
  State<NotificationToggleCard> createState() => _NotificationToggleCardState();
}

class _NotificationToggleCardState extends State<NotificationToggleCard> {
  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PushNotificationService.isNotificationEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (_saving) return;
    setState(() {
      _enabled = value;
      _saving = true;
    });
    try {
      await PushNotificationService.setNotificationEnabled(value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PhosphorIcon(
              PhosphorIconsRegular.bell,
              size: widget.compact ? 18 : 20,
              color: AppTheme.accentBlue,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '푸시 알림',
                  style: TextStyle(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const Gap(4),
                Text(
                  widget.compact
                      ? '공지·이벤트·문의 답변을 알려드립니다.'
                      : '마일리지 입금, 1:1 문의 답변, 이벤트 등을 알려드립니다.\n원치 않을 경우 토글을 해제해 주세요.',
                  style: TextStyle(
                    fontSize: widget.compact ? 11 : 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          if (_loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: _enabled,
              onChanged: _saving ? null : _toggle,
            ),
        ],
      ),
    );
  }
}

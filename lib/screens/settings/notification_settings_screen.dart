import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/notification_toggle_card.dart';

/// 알림설정
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림설정')),
      body: Column(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: NotificationToggleCard(),
            ),
          ),
          const _SettingsFooter(),
        ],
      ),
    );
  }
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        border: Border(top: BorderSide(color: AppTheme.borderGrey)),
      ),
      child: const Center(
        child: Text(
          'ⓒ 2026 일등대리. All rights reserved.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ),
    );
  }
}

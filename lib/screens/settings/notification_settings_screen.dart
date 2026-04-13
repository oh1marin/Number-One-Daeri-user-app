import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

/// 알림설정
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _prefKey = 'notification_enabled';
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _enabled = prefs.getBool(_prefKey) ?? true);
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림설정')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.notifications_outlined,
                              color: AppTheme.accentBlue, size: 20),
                        ),
                        const Gap(12),
                        const Text(
                          '푸시 알림 설정',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(
                      '마일리지 입금, 1:1 문의 답변, 기타 유익한 이벤트 등을 알려드리는 기능입니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                    ),
                    const Gap(8),
                    Text(
                      '원치 않을 경우 아래 토글을 해제해 주세요.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.6),
                    ),
                    const Gap(20),
                    Divider(color: AppTheme.borderGrey),
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '알림(푸시)을 받겠습니다.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch.adaptive(
                          value: _enabled,
                          onChanged: _toggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

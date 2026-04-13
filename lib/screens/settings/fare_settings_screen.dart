import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FareSettingsScreen extends StatelessWidget {
  const FareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요금 설정')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              '요금 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '준비 중입니다.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

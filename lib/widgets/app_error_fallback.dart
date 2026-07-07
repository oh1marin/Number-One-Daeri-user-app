import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 릴리즈에서 위젯 빌드 실패 시 빨간 Debug 화면 대신 표시.
class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceGrey,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 12),
              const Text(
                '화면을 불러오지 못했습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '앱을 다시 시작하거나 잠시 후 다시 시도해 주세요.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

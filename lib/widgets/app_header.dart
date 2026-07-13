import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_theme.dart';

/// 온보딩 상단 — 스플래시·앱정보와 같은 네이비 톤 + 로고
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.height,
  });

  final double? height;

  static const _hotline = '010-2184-8822';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? 200,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            Color(0xFF1A2F6B),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Gap(14),
          const Text(
            '일등대리',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Gap(6),
          Text(
            _hotline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// @deprecated AppTheme 사용. 하위 호환용 alias.
typedef AppColors = AppTheme;

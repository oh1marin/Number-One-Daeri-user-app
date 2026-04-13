import 'package:flutter/material.dart';

/// 다크 네이비 헤더 + 로고 + 1668 0001
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.height,
  });

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? 200,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LogoWidget(),
          const SizedBox(height: 16),
          Text(
            '1668 0001',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.directions_car, size: 48, color: Colors.white.withValues(alpha: 0.9)),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightBlue, width: 2),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: Icon(Icons.trending_up, color: AppColors.lightBlue, size: 24),
        ),
      ],
    );
  }
}

class AppColors {
  static const Color primaryDark = Color(0xFF0D1B48);
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);
}

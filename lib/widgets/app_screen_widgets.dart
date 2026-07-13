import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import 'app_loading_indicator.dart';

/// 앱 정보·공지와 동일한 흰 카드 (16px, borderGrey)
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: child,
    );
  }
}

/// 설정·FAQ 하단 링크 타일
class AppNavListTile extends StatelessWidget {
  const AppNavListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, size: 22, color: AppTheme.primaryDark),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (subtitle != null) ...[
                      const Gap(4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppPageLoading extends StatelessWidget {
  const AppPageLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: AppLoadingIndicator());
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
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
              decoration: const BoxDecoration(
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
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const Gap(6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 스크롤 콘텐츠 하단 safe area 보정.
class AppScrollSafeGap extends StatelessWidget {
  const AppScrollSafeGap({super.key, this.extra = 16});

  final double extra;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ResponsiveLayout.bottomSafeInset(context, extra: extra));
  }
}

import 'package:flutter/material.dart';

abstract final class FriendReferralAssets {
  static const bannerPath = 'assets/images/banner_friend_referral.png';
}

/// 친구 초대 배너를 은은한 뒷배경으로 깔아 주는 카드
class FriendReferralBackgroundCard extends StatelessWidget {
  const FriendReferralBackgroundCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 16,
    this.boxShadow,
    this.imageAlignment = Alignment.center,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final overlay = gradient ??
        LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.50),
            Colors.white.withValues(alpha: 0.36),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                FriendReferralAssets.bannerPath,
                fit: BoxFit.cover,
                alignment: imageAlignment,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: overlay),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

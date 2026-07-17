import 'package:flutter/material.dart';

/// 마일리지·기프티콘 배너 이미지 경로
abstract final class MileageGifticonAssets {
  static const bannerPath = 'assets/images/banner_mileage_gifticon.png';
}

/// 잔액 카드 뒤에 깔리는 은은한 마일리지 배너 배경
class MileageGifticonBackgroundCard extends StatelessWidget {
  const MileageGifticonBackgroundCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 16,
    this.boxShadow,
    this.imageAlignment = Alignment.centerRight,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                MileageGifticonAssets.bannerPath,
                fit: BoxFit.cover,
                alignment: imageAlignment,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Reference width (~iPhone 14). Scales horizontal spacing between phones / small tablets.
abstract final class ResponsiveLayout {
  static const double _refWidth = 390;

  /// Body layout scale (not full-bleed typography — use with padding / gaps).
  static double scale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / _refWidth).clamp(0.85, 1.12);
  }

  /// 홈 화면 전용 — 한 화면에 더 많이 보이도록 약간 축소.
  static double homeScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final widthFactor = (w / _refWidth).clamp(0.82, 1.0);
    final heightFactor = h < 700 ? 0.88 : (h < 760 ? 0.92 : 0.96);
    return (widthFactor * heightFactor).clamp(0.68, 0.88);
  }

  /// Horizontal inset for page sections (home cards, banners, etc.).
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final base = 20 * scale(context);
    if (w > 600) return base.clamp(28.0, 40.0);
    return base;
  }

  /// Keeps line length readable on foldables / tablets; full width on phones.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 600) return w;
    return 560;
  }

  /// Trailing space in primary scroll views so last cards don’t feel clipped.
  static double homeListBottomSpace(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.02).clamp(12.0, 32.0);
  }

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// 앱 전체 텍스트 — 한눈에 더 많이 보이도록 체감 가능하게 축소.
  static TextScaler appTextScaler(BuildContext context) {
    final raw = MediaQuery.textScalerOf(context).scale(1);
    final clamped = raw.clamp(0.78, 1.15);
    return TextScaler.linear((clamped * 0.82).clamp(0.66, 1.0));
  }

  /// 패딩·간격용 배율 (홈 외 화면 공통).
  static double compactScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / _refWidth * 0.9).clamp(0.78, 0.95);
  }

  /// 하단 가상 버튼·시스템 영역 + 여유 공간.
  static double bottomSafeInset(BuildContext context, {double extra = 16}) {
    return MediaQuery.paddingOf(context).bottom + extra;
  }

  /// 스크롤 뷰 하단 패딩 (safe area 포함).
  static EdgeInsets scrollBottomPadding(BuildContext context, {double extra = 16}) {
    return EdgeInsets.only(bottom: bottomSafeInset(context, extra: extra));
  }

  /// 페이지 좌우 패딩 (compactScale 반영).
  static double pageHorizontal(BuildContext context) {
    return (horizontalPadding(context) * compactScale(context)).clamp(12.0, 24.0);
  }
}

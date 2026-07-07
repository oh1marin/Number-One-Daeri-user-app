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
    return (widthFactor * heightFactor).clamp(0.78, 0.96);
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

  /// Clamps system font scaling so large accessibility sizes don’t break dense rows.
  static TextScaler clampedTextScaler(BuildContext context) {
    final raw = MediaQuery.textScalerOf(context).scale(100) / 100.0;
    final t = raw.clamp(0.85, 1.35);
    return TextScaler.linear(t);
  }
}

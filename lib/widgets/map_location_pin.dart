import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 지도 중앙 기준점(좌표)에 맞춰 하단 끝이 찍히는 플랫 스타일 위치 핀 (항상 `CustomPaint` — PlatformView 위에서도 안정적)
class MapLocationPin extends StatelessWidget {
  const MapLocationPin({
    super.key,
    required this.label,
    required this.pinColor,
    this.baseColor = const Color(0xFF26A69A),
    this.width = 44,
    this.pinHeight = 52,
  });

  /// `drawShadow`/받침 타원이 잘리지 않도록 CustomPaint 주변 여백
  static const double _paintPadTop = 12;
  static const double _paintPadBottom = 10;
  static const double _paintPadX = 10;

  final String label;
  final Color pinColor;
  final Color baseColor;
  final double width;
  final double pinHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          if (label.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pinColor.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: pinColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        SizedBox(
          width: width + 2 * _paintPadX,
          height: pinHeight + _paintPadTop + _paintPadBottom,
          child: CustomPaint(
            painter: _FlatMapPinPainter(
              pinColor: pinColor,
              baseColor: baseColor,
              logicalWidth: width,
              logicalHeight: pinHeight,
              padLeft: _paintPadX,
              padTop: _paintPadTop,
            ),
          ),
        ),
      ],
    );
  }

  /// 오버레이 `Positioned`용: 핀 끝이 `point`에 오도록 `top: point.dy - totalOverlayHeight(...)`
  static double totalOverlayHeight({required bool hasLabel, double pinHeight = 52}) {
    // 라벨 칩(패딩·글자) + 핀과의 간격 — `Positioned`가 핀 끝을 좌표에 맞추도록 실제 레이아웃과 맞춤
    return pinHeight +
        _paintPadTop +
        _paintPadBottom +
        (hasLabel ? 24 : 0);
  }
}

class _FlatMapPinPainter extends CustomPainter {
  _FlatMapPinPainter({
    required this.pinColor,
    required this.baseColor,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.padLeft,
    required this.padTop,
  });

  final Color pinColor;
  final Color baseColor;
  final double logicalWidth;
  final double logicalHeight;
  final double padLeft;
  final double padTop;

  /// 원 머리와 뾰족한 아래가 **한 덩어리**로 이어지는 티어드롭 (참고: 부드러운 곡선 + 좌·우 빨강 대비)
  Path _teardropPinPath({
    required double cx,
    required double cyH,
    required double r,
    required double tipY,
  }) {
    final jxL = cx - r * math.sqrt(3) / 2;
    final jxR = cx + r * math.sqrt(3) / 2;
    final jy = cyH + r * 0.5;

    final p = Path()..moveTo(cx, tipY);
    // 아래 끝 → 원 쪽: 넓게 붙여서 세모가 작아 보이지 않게
    p.cubicTo(
      cx - r * 0.15,
      tipY - (tipY - jy) * 0.42,
      jxL + r * 0.12,
      jy + r * 0.22,
      jxL,
      jy,
    );
    // 원 위쪽 호만 따라감 (5π/6 → π/6, 위로 돌아감)
    p.arcTo(
      Rect.fromCircle(center: Offset(cx, cyH), radius: r),
      5 * math.pi / 6,
      4 * math.pi / 3,
      false,
    );
    p.cubicTo(
      jxR - r * 0.12,
      jy + r * 0.22,
      cx + r * 0.15,
      tipY - (tipY - jy) * 0.42,
      cx,
      tipY,
    );
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(padLeft, padTop);
    final w = logicalWidth;
    final h = logicalHeight;
    final cx = w / 2;
    final r = w * 0.36;
    final cyH = 10 + r;
    final tipY = h - 1;

    final pinPath = _teardropPinPath(cx: cx, cyH: cyH, r: r, tipY: tipY);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, tipY + 3.5), width: w * 0.48, height: 6),
      Paint()..color = baseColor,
    );

    canvas.drawShadow(
      pinPath,
      Colors.black.withValues(alpha: 0.3),
      3.5,
      true,
    );

    final bounds = pinPath.getBounds();
    final shaderRect = bounds.isEmpty ? Rect.fromLTWH(0, 0, w, h) : bounds.inflate(1.5);
    final darkSide = Color.lerp(pinColor, const Color(0xFF4A0000), 0.45)!;
    final brightSide = Color.lerp(pinColor, const Color(0xFFFF8A80), 0.22)!;
    canvas.drawPath(
      pinPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            darkSide,
            Color.lerp(darkSide, pinColor, 0.55)!,
            pinColor,
            Color.lerp(pinColor, brightSide, 0.5)!,
            brightSide,
          ],
          stops: const [0.0, 0.38, 0.5, 0.72, 1.0],
        ).createShader(shaderRect),
    );

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.034)
        ..strokeJoin = StrokeJoin.round,
    );

    // 머리 직경의 약 1/3 크기 화이트 홀
    final holeR = r * 0.34;
    final holeCenter = Offset(cx, cyH - r * 0.08);
    canvas.drawCircle(holeCenter, holeR, Paint()..color = Colors.white);
    canvas.drawCircle(
      holeCenter,
      holeR,
      Paint()
        ..color = darkSide.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _FlatMapPinPainter old) =>
      old.pinColor != pinColor ||
      old.baseColor != baseColor ||
      old.logicalWidth != logicalWidth ||
      old.logicalHeight != logicalHeight ||
      old.padLeft != padLeft ||
      old.padTop != padTop;
}

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 커스텀 마커 이미지 생성 (출발/도착 핀)
class MarkerImageUtils {
  MarkerImageUtils._();

  static const int _size = 64;

  /// 출발 마커 (파란색 핀)
  static Uint8List createDeparturePin() => _createPin(
        color: img.ColorRgb8(33, 150, 243), // AppTheme.accentBlue
        label: null,
      );

  /// 도착 마커 (주황색 핀)
  static Uint8List createArrivalPin() => _createPin(
        color: img.ColorRgb8(255, 152, 0),
        label: null,
      );

  static Uint8List _createPin({
    required img.ColorRgb8 color,
    String? label,
  }) {
    final w = _size;
    final h = _size;
    final image = img.Image(width: w, height: h, numChannels: 4);

    // 투명 배경
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

    final cx = w ~/ 2;
    final headY = h ~/ 3;
    final headR = w ~/ 3;

    // 흰색 테두리용 바깥 원
    img.fillCircle(image, x: cx, y: headY, radius: headR + 2, color: img.ColorRgb8(255, 255, 255));

    // 핀 머리 (원)
    img.fillCircle(image, x: cx, y: headY, radius: headR, color: color);

    // 핀 꼬리 (삼각형)
    final tailTop = headY + headR - 2;
    final tailBottom = h - 4;
    final tailWidth = headR - 2;
    final pts = [
      img.Point(cx, tailTop),
      img.Point(cx - tailWidth, tailBottom),
      img.Point(cx + tailWidth, tailBottom),
    ];
    img.fillPolygon(image, vertices: pts, color: color);

    final png = img.encodePng(image);
    return Uint8List.fromList(png ?? <int>[]);
  }
}

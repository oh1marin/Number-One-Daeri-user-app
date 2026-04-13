// dart run tool/pad_marker_png.dart — 네이티브 마커가 SDK/모서리에서 잘리지 않도록 축소 + 투명 여백
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final root = Directory.current.path;
  final path = '$root/assets/map/marker_departure.png';
  final raw = File(path).readAsBytesSync();
  final dec = img.decodePng(raw);
  if (dec == null) {
    stderr.writeln('decode failed');
    exit(1);
  }
  const maxSide = 72;
  int tw, th;
  if (dec.width >= dec.height) {
    tw = maxSide;
    th = (maxSide * dec.height / dec.width).round().clamp(1, 9999);
  } else {
    th = maxSide;
    tw = (maxSide * dec.width / dec.height).round().clamp(1, 9999);
  }
  final scaled = img.copyResize(
    dec,
    width: tw,
    height: th,
    interpolation: img.Interpolation.cubic,
  );
  const pad = 18;
  final out = img.Image(width: tw + pad * 2, height: th + pad * 2, numChannels: 4);
  img.fill(out, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(out, scaled, dstX: pad, dstY: pad);
  File(path).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Wrote ${out.width}x${out.height} (icon ${tw}x$th + pad $pad)');
}

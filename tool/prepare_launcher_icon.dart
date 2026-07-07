import 'dart:io';

import 'package:image/image.dart' as img;

/// logo.png 안의 그래픽이 작아 보이는 문제 — 중앙 크롭 후 확대한 런처 에셋 생성.
void main() {
  const srcPath = 'assets/icons/logo.png';
  const launcherPath = 'assets/icons/logo_launcher.png';
  const foregroundPath = 'assets/icons/logo_foreground.png';
  const bgR = 27;
  const bgG = 77;
  const bgB = 184;

  final bytes = File(srcPath).readAsBytesSync();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode $srcPath');
    exit(1);
  }

  const cropRatio = 0.68;
  final cw = (src.width * cropRatio).round();
  final ch = (src.height * cropRatio).round();
  final x = (src.width - cw) ~/ 2;
  final y = (src.height - ch) ~/ 2;
  final cropped = img.copyCrop(src, x: x, y: y, width: cw, height: ch);

  const size = 1024;
  const margin = 48;
  final inner = size - margin * 2;
  final scaled = img.copyResize(
    cropped,
    width: inner,
    height: inner,
    interpolation: img.Interpolation.cubic,
  );

  final launcher = img.Image(width: size, height: size);
  img.fill(launcher, color: img.ColorRgb8(bgR, bgG, bgB));
  img.compositeImage(launcher, scaled, dstX: margin, dstY: margin);
  File(launcherPath).writeAsBytesSync(img.encodePng(launcher));

  final foreground = img.Image(width: size, height: size, numChannels: 4);
  img.compositeImage(foreground, scaled, dstX: margin, dstY: margin);
  File(foregroundPath).writeAsBytesSync(img.encodePng(foreground));

  stdout.writeln('Wrote $launcherPath and $foregroundPath');
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// S3 등 원격 이미지 표시 (메모리·디스크 캐시, 로딩·오류 처리 공통)
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  int? _memCacheDim(double? logical, BuildContext context) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(1, 2048);
  }

  @override
  Widget build(BuildContext context) {
    final memW = _memCacheDim(width, context);
    final memH = _memCacheDim(height, context);

    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      memCacheWidth: memW,
      memCacheHeight: memH,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => errorWidget ??
          const Icon(Icons.broken_image_outlined, size: 32),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

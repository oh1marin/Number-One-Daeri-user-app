import '../../models/gifticon.dart';

/// 로컬 더미 카탈로그 — 운영에서는 사용하지 않음 (서버 `/gifticon/products`만 표시)
class GifticonCatalog {
  GifticonCatalog._();

  static const products = <GifticonProduct>[];

  static GifticonProduct? findById(String id) => null;

  static List<GifticonProduct> byCategory(GifticonCategory? category) {
    return const [];
  }
}

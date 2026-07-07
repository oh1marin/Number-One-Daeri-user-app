import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/gifticon.dart';
import '../services/gifticon/gifticon_order_store.dart';
import '../utils/mileage_balance_cache.dart';
import 'mileage_api.dart';
import 'api_client.dart';

/// 기프티콘 교환 API — ride-be `/gifticon/*` 연동 (더미 카탈로그 미사용)
class GifticonApi {
  GifticonApi._();

  static const _cacheTtl = Duration(minutes: 5);
  static List<GifticonProduct>? _cachedProducts;
  static DateTime? _cachedAt;

  static void invalidateProductsCache() {
    _cachedProducts = null;
    _cachedAt = null;
  }

  static List<Map<String, dynamic>> _mapList(List list) {
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// ride-be: `{ success, data: { items: [...] } }` 또는 `{ data: [...] }`
  static List<Map<String, dynamic>>? _itemsFromPayload(dynamic body) {
    if (body == null) return null;
    if (body is List) return _mapList(body);
    if (body is! Map) return null;

    final root = Map<String, dynamic>.from(body);
    final data = root['data'];

    if (data is List) return _mapList(data);
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      final items = inner['items'] ?? inner['results'] ?? inner['products'];
      if (items is List) return _mapList(items);
    }

    final top = root['items'] ?? root['results'] ?? root['products'];
    if (top is List) return _mapList(top);

    return null;
  }

  static bool _isUnavailable(dynamic v) {
    if (v == null) return false;
    if (v is bool) return !v;
    final s = v.toString().trim().toLowerCase();
    return s == 'false' || s == '0' || s == 'n';
  }

  /// GET gifticon/products — 서버 응답만 사용 (실패/빈 목록 시 더미 없음)
  static Future<List<GifticonProduct>> getProducts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedProducts != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return List<GifticonProduct>.from(_cachedProducts!);
    }

    final res = await ApiClient.get('gifticon/products');
    final items = _itemsFromPayload(res.data);

    if (items == null) {
      if (kDebugMode) {
        debugPrint('[GifticonApi] unrecognized payload: ${res.data}');
      }
      throw Exception('기프티콘 상품 목록 형식을 읽을 수 없습니다.');
    }

    final products = <GifticonProduct>[];
    for (final raw in items) {
      final p = _productFromApi(raw);
      if (p != null) products.add(p);
    }

    if (kDebugMode) {
      debugPrint('[GifticonApi] raw=${items.length} parsed=${products.length}');
      for (final p in products.take(5)) {
        debugPrint('  - id=${p.id} name=${p.name} price=${p.mileagePrice} img=${p.imageUrl}');
      }
    }

    _cachedProducts = products;
    _cachedAt = DateTime.now();
    return List<GifticonProduct>.from(products);
  }

  static String _pickString(dynamic v) => v?.toString().trim() ?? '';

  static GifticonCategory _resolveCategory(String raw, String name) {
    final hay = '${raw.toLowerCase()} ${name.toLowerCase()}';
    if (hay.contains('chicken') ||
        hay.contains('치킨') ||
        hay.contains('bbq') ||
        hay.contains('교촌')) {
      return GifticonCategory.chicken;
    }
    return GifticonCategory.coffee;
  }

  static GifticonBrand _resolveBrand(String categoryRaw, String name) {
    final hay = '${categoryRaw.toLowerCase()} ${name.toLowerCase()}';
    if (hay.contains('bbq') || hay.contains('치킨') || hay.contains('chicken')) {
      return GifticonBrand.bbq;
    }
    return GifticonBrand.mega;
  }

  /// 백엔드 필드만 사용: id/goodsCode, name, price/mileagePrice, imageUrl
  static GifticonProduct? _productFromApi(Map<String, dynamic> json) {
    final id = _pickString(json['id'] ?? json['goodsCode'] ?? json['productId']);
    if (id.isEmpty) return null;
    if (_isUnavailable(json['available'])) return null;

    final name = _pickString(json['name'] ?? json['title'] ?? json['goodsName']);
    if (name.isEmpty) return null;

    final mileagePrice = _pickInt(
      json['mileagePrice'] ?? json['price'] ?? json['amount'],
    );
    if (mileagePrice <= 0) return null;

    final imageUrl = _pickString(
      json['imageUrl'] ??
          json['coverImageUrl'] ??
          json['thumbnailUrl'] ??
          json['thumbUrl'] ??
          json['image'],
    );

    // UI 레이아웃용 기본값(표시는 name/price/imageUrl만 사용)
    final category = _resolveCategory('', name);
    final brand = _resolveBrand('', name);

    return GifticonProduct(
      id: id,
      name: name,
      subtitle: '',
      mileagePrice: mileagePrice,
      brand: brand,
      category: category,
      faceValue: mileagePrice,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
    );
  }

  static int _pickInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  /// POST gifticon/exchange
  static Future<GifticonPurchaseResult> purchase({
    required GifticonProduct product,
    required int currentBalance,
    String? phone,
  }) async {
    try {
      final res = await ApiClient.post('gifticon/exchange', {
        'productId': product.id,
        'goodsCode': product.id,
        'mileageAmount': product.mileagePrice,
      });
      final map = res.data as Map<String, dynamic>? ?? {};
      final data = map['data'] as Map<String, dynamic>? ?? map;
      final order = GifticonOrder.fromJson({
        ...data,
        'productId': product.id,
        'productName': product.name,
        'brandLabel': product.brandLabel,
        'mileageUsed': product.mileagePrice,
      });
      await GifticonOrderStore.saveOrder(order);
      MileageBalanceCache.invalidate();
      final remaining = (data['mileageBalance'] as num?)?.toInt() ??
          (data['remainingBalance'] as num?)?.toInt() ??
          (currentBalance - product.mileagePrice);
      return GifticonPurchaseResult(order: order, remainingBalance: remaining);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString() ??
          (e.response?.data as Map?)?['message']?.toString();
      throw Exception(msg ?? '기프티콘 교환에 실패했습니다.');
    }
  }

  /// GET gifticon/orders
  static Future<List<GifticonOrder>> getOrders() async {
    try {
      final res = await ApiClient.get('gifticon/orders');
      final items = _itemsFromPayload(res.data);
      if (items != null) {
        return items
            .map(GifticonOrder.fromJson)
            .toList()
          ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
    return GifticonOrderStore.getOrders();
  }

  static Future<MileageBalance> fetchMileageBalance() async {
    return MileageBalanceCache.getBalance(force: true);
  }

  static Future<int> fetchBalance() async {
    final bal = await fetchMileageBalance();
    return bal.balance;
  }
}

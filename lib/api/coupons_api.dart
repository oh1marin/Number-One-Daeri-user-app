import 'package:dio/dio.dart';

import '../utils/coupon_display.dart';
import 'api_client.dart';

/// 쿠폰 관련 API
class CouponsApi {
  /// 테스트용 더미 쿠폰 — 실제 배포 시 제거
  static List<UserCoupon> get _mockCoupons => [
    UserCoupon(
      id: 'mock_starbucks_01',
      code: 'STAR_MOCK_01',
      name: '스타벅스 아메리카노 Tall',
      amount: 5500,
      validUntil: '2026-06-30T00:00:00Z',
      receivedAt: '2026-04-01T00:00:00Z',
      usedAt: null,
      status: 'active',
      brand: CouponBrand.starbucks,
    ),
    UserCoupon(
      id: 'mock_chicken_01',
      code: 'KYOCHON_MOCK_01',
      name: '교촌치킨 오리지널 세트',
      amount: 22000,
      validUntil: '2026-05-31T00:00:00Z',
      receivedAt: '2026-04-01T00:00:00Z',
      usedAt: null,
      status: 'active',
      brand: CouponBrand.chicken,
    ),
    UserCoupon(
      id: 'mock_starbucks_02',
      code: 'STAR_MOCK_02',
      name: '스타벅스 케이크 교환권',
      amount: 8500,
      validUntil: '2026-05-15T00:00:00Z',
      receivedAt: '2026-03-20T00:00:00Z',
      usedAt: null,
      status: 'pending_delivery',
      brand: CouponBrand.starbucks,
    ),
    UserCoupon(
      id: 'mock_cu_01',
      code: 'CU_MOCK_01',
      name: 'CU 편의점 5천원권',
      amount: 5000,
      validUntil: '2026-04-30T00:00:00Z',
      receivedAt: '2026-03-10T00:00:00Z',
      usedAt: '2026-03-15T00:00:00Z',
      status: 'delivered',
      brand: CouponBrand.convenience,
    ),
  ];

  /// 쿠폰 수령 신청 — status: pending_delivery 로 변경
  static Future<void> redeem(String couponId) async {
    // 더미 쿠폰은 백엔드 호출 없이 성공 처리 (테스트용)
    if (couponId.startsWith('mock_')) {
      await Future.delayed(const Duration(milliseconds: 800)); // 로딩 효과
      return;
    }
    try {
      await ApiClient.post('coupons/$couponId/redeem', {});
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message']?.toString();
      throw Exception(msg ?? '쿠폰 신청 실패 (${e.response?.statusCode})');
    }
  }

  static Future<List<UserCoupon>> getMyCoupons() async {
    try {
      // NOTE: apiBaseUrl ends with `/api/v1/`, so we avoid leading slash here.
      final res = await ApiClient.get('users/me/coupons');
      final data = res.data;

      List<UserCoupon> real = [];
      if (data is Map<String, dynamic>) {
        final d = data['data'];
        if (d is Map<String, dynamic>) {
          final itemsRaw = d['items'];
          if (itemsRaw is List) {
            real = itemsRaw.whereType<Map<String, dynamic>>().map(UserCoupon.fromJson).toList();
          }
        } else if (d is List) {
          real = d.whereType<Map<String, dynamic>>().map(UserCoupon.fromJson).toList();
        }
      }
      // TODO: 테스트 완료 후 아래 줄 제거
      return [..._mockCoupons, ...real];
    } on DioException catch (_) {
      return _mockCoupons;
    }
  }
}

/// 쿠폰 종류 — 마일리지와 완전히 분리된 실물 상품형 쿠폰
enum CouponBrand {
  starbucks,   // 스타벅스
  chicken,     // 치킨 (교촌, BBQ 등)
  convenience, // 편의점 (CU, GS25)
  giftcard,    // 상품권
  other,
}

class UserCoupon {
  const UserCoupon({
    required this.id,
    required this.code,
    this.name,
    required this.amount,
    required this.validUntil,
    required this.receivedAt,
    required this.usedAt,
    this.status = 'active',
    this.brand = CouponBrand.other,
    this.imageUrl,
  });

  final String id;
  final String code;
  final String? name;
  final int amount;
  final String? validUntil;
  final String? receivedAt;
  final String? usedAt;
  /// active | pending_delivery | delivered
  final String status;
  final CouponBrand brand;
  final String? imageUrl;

  bool get isUsed => usedAt != null && usedAt!.isNotEmpty;
  bool get isPendingDelivery => status == 'pending_delivery';
  bool get isDelivered => status == 'delivered';

  String get displayTitle {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return CouponDisplay.titleFromCode(code);
  }

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    String? toStr(dynamic v) => v?.toString();

    final code = (json['code'] ?? '').toString().toUpperCase();
    final typeRaw = (json['type'] ?? json['couponType'] ?? json['brandType'] ?? '').toString().toLowerCase();
    final name = (json['name'] ?? json['title'] ?? json['label'] ?? json['displayName'] ?? '').toString().toLowerCase();

    CouponBrand brand;
    if (typeRaw.contains('star') || name.contains('스타벅스') || code.contains('STAR')) {
      brand = CouponBrand.starbucks;
    } else if (typeRaw.contains('chicken') || name.contains('치킨') || code.contains('CHICKEN') || code.contains('KYOCHON')) {
      brand = CouponBrand.chicken;
    } else if (typeRaw.contains('convenience') || name.contains('편의점') || code.contains('CU') || code.contains('GS')) {
      brand = CouponBrand.convenience;
    } else if (typeRaw.contains('gift') || name.contains('상품권')) {
      brand = CouponBrand.giftcard;
    } else {
      brand = CouponBrand.other;
    }

    return UserCoupon(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: toStr(json['name'] ?? json['title'] ?? json['label'] ?? json['displayName']),
      amount: toInt(json['amount']),
      validUntil: toStr(json['validUntil'] ?? json['validUntilAt']),
      receivedAt: toStr(json['receivedAt'] ?? json['issuedAt']),
      usedAt: toStr(json['usedAt']),
      status: (json['status'] ?? 'active').toString(),
      brand: brand,
      imageUrl: toStr(json['imageUrl'] ?? json['image']),
    );
  }
}


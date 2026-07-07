import 'api_client.dart';

/// 마일리지 API
/// GET /users/me/mileage - 잔액
/// GET /mileage/history - 적립/사용 내역
class MileageApi {
  static Future<MileageBalance> getBalance() async {
    final res = await ApiClient.get('/users/me/mileage');
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};

    int pickInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) {
        // allow "10,000" style strings
        final cleaned = v.replaceAll(',', '').trim();
        return int.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    // Be tolerant to backend field naming differences between admin/web/app.
    // Common candidates: balance, mileageBalance, mileage, points, wallet.balance.
    final balance = pickInt(
      data['balance'] ??
          data['mileageBalance'] ??
          data['mileage'] ??
          data['points'] ??
          (data['wallet'] is Map ? (data['wallet'] as Map)['balance'] : null),
    );

    final withdrawable = pickInt(
      data['withdrawable'] ??
          data['withdrawableBalance'] ??
          data['withdrawableMileage'] ??
          balance,
    );
    final signupBonusRemaining = pickInt(
      data['signupBonusRemaining'] ?? data['signupBonusLocked'],
    );
    final gifticonSpendable = pickInt(
      data['gifticonSpendable'] ??
          data['gifticonBalance'] ??
          (balance - signupBonusRemaining).clamp(0, balance),
    );
    return MileageBalance(
      balance: balance,
      withdrawable: withdrawable,
      gifticonSpendable: gifticonSpendable,
      signupBonusRemaining: signupBonusRemaining,
    );
  }

  static Future<MileageHistoryResponse> getHistory({int page = 1, int limit = 20}) async {
    final res = await ApiClient.get(
      '/mileage/history',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    final items = (data['items'] as List<dynamic>?) ?? [];
    return MileageHistoryResponse(
      items: items.map((e) => MileageHistoryItem.fromJson(e as Map<String, dynamic>)).toList(),
      total: (data['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class MileageBalance {
  const MileageBalance({
    required this.balance,
    required this.withdrawable,
    int? gifticonSpendable,
    this.signupBonusRemaining = 0,
  }) : gifticonSpendable = gifticonSpendable ?? balance;

  final int balance;
  final int withdrawable;
  /// 기프티콘 교환에 사용 가능 (가입 보너스 제외, 신규 가입자만)
  final int gifticonSpendable;
  final int signupBonusRemaining;
}

class MileageHistoryItem {
  MileageHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.balance,
    this.description,
    this.createdAt,
    this.category,
    this.kind,
    this.source,
  });
  final String id;
  final String type; // earn | use | withdraw
  final int amount;
  final int balance;
  final String? description;
  final String? createdAt;
  /// 백엔드가 내리는 분류(있다면 쿠폰 여부 판별에 사용).
  final String? category;
  final String? kind;
  final String? source;

  /// 쿠폰 발급·사용·상품권 등 마일리지 **이용 내역 목록에서 제외**할 항목.
  /// (잔액 숫자는 서버 `GET /users/me/mileage` 응답 그대로이며, 쿠폰을 잔액에서 빼는 것은 백엔드 책임.)
  bool get isCouponRelated {
    final fields = <String?>[type, category, kind, source, description];
    for (final raw in fields) {
      if (raw == null || raw.isEmpty) continue;
      final x = raw.toLowerCase();
      if (x.contains('coupon') || x.contains('쿠폰')) return true;
      if (x.contains('voucher') || x.contains('상품권') || x.contains('바우처')) return true;
      if (x.contains('giftcard') || x.contains('gift_card')) return true;
      if (x.contains('usercoupon') || x.contains('user_coupon')) return true;
    }
    return false;
  }

  factory MileageHistoryItem.fromJson(Map<String, dynamic> json) {
    return MileageHistoryItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      createdAt: json['createdAt']?.toString(),
      category: json['category']?.toString() ??
          json['sourceType']?.toString() ??
          json['transactionType']?.toString(),
      kind: json['kind']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

class MileageHistoryResponse {
  const MileageHistoryResponse({required this.items, required this.total});
  final List<MileageHistoryItem> items;
  final int total;
}

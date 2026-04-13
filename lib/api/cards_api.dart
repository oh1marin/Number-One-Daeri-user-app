import 'api_client.dart';

/// 카드 등록/관리 API
/// POST /cards - 등록 (cardToken은 PG에서 발급)
/// GET /cards - 목록
/// DELETE /cards/:id - 삭제
class CardsApi {
  static const _base = '/cards';

  static Future<List<RegisteredCard>> getList() async {
    try {
      final res = await ApiClient.get(_base);
      final raw = res.data;
      List? items;
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        final data = (raw['data'] ?? raw) as dynamic;
        items = data is List ? data : (data is Map ? data['items'] : null) as List?;
      }
      if (items == null) return [];
      return items
          .map((e) => RegisteredCard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// cardToken: PG(PortOne 등) 연동 시 발급받은 토큰
  static Future<RegisteredCard> register({
    required String cardToken,
    required String cardName,
    String? expiryDate,
    String? option,
  }) async {
    final body = <String, dynamic>{
      'cardToken': cardToken,
      'cardName': cardName,
    };
    if (expiryDate != null && expiryDate.isNotEmpty) body['expiryDate'] = expiryDate;
    if (option != null && option.isNotEmpty) body['option'] = option;

    final res = await ApiClient.post(_base, body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    return RegisteredCard.fromJson(data is Map ? data : {});
  }

  static Future<void> delete(String cardId) async {
    await ApiClient.delete('$_base/$cardId');
  }
}

class RegisteredCard {
  RegisteredCard({
    required this.id,
    required this.cardName,
    this.last4Digits,
    this.expiryDate,
  });

  final String id;
  final String cardName;
  final String? last4Digits;
  final String? expiryDate;

  factory RegisteredCard.fromJson(Map<String, dynamic> json) {
    return RegisteredCard(
      id: (json['id'] ?? '').toString(),
      cardName: (json['cardName'] ?? '').toString(),
      last4Digits: json['last4Digits']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
    );
  }
}

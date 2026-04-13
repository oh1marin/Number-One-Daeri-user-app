import 'api_client.dart';

/// 결제 연동 — 결제 완료 시 백엔드 전송 (관리자 조회용)
/// 스펙: POST /payments, 인증 Bearer {userAccessToken}
class PaymentsApi {
  static const _base = '/payments';

  /// 저장된 카드로 결제 (빌링키 청구)
  /// 백엔드에서 cardId로 빌링키 조회 후 PortOne API로 결제 처리
  static Future<void> chargeWithCard({
    required String rideId,
    required int amount,
    required String cardId,
  }) async {
    await ApiClient.post('$_base/charge-with-card', {
      'rideId': rideId,
      'amount': amount,
      'cardId': cardId,
    });
  }

  /// 결제 완료 시 호출. amount 필수, 나머지 선택.
  /// pgProvider: 'portone' | 'kakaopay' | 'tosspay'
  /// billingKey, cardName: 빌링키 발급+초회 결제 시 백엔드가 카드 자동 저장
  /// 반환: { cardSaved: true } 이면 "카드가 저장되었습니다" 안내
  static Future<Map<String, dynamic>?> post({
    required int amount,
    String? rideId,
    String? cardId,
    String? pgTid,
    String? pgProvider,
    String? billingKey,
    String? cardName,
    String? receiptUrl,
    Map<String, dynamic>? rawResponse,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
      if (cardId != null && cardId.isNotEmpty) 'cardId': cardId,
      if (pgTid != null && pgTid.isNotEmpty) 'pgTid': pgTid,
      if (pgProvider != null && pgProvider.isNotEmpty) 'pgProvider': pgProvider,
      if (billingKey != null && billingKey.isNotEmpty) 'billingKey': billingKey,
      if (cardName != null && cardName.isNotEmpty) 'cardName': cardName,
      if (receiptUrl != null && receiptUrl.isNotEmpty) 'receiptUrl': receiptUrl,
      if (rawResponse != null) 'rawResponse': rawResponse,
    };
    final res = await ApiClient.post(_base, body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}

import '../models/call_options.dart';
import 'api_client.dart';

/// 대리호출 생성 API
/// 스펙: POST /rides/call
/// Body: latitude, longitude, address, addressDetail, phone + paymentMethod + 옵션 + estimatedDistanceKm, estimatedFare, fareType
class RidesCallApi {
  static const _base = '/rides/call';

  /// paymentMethod: 'cash' | 'mileage' | 'card' | 'kakaopay' | 'tosspay'
  /// cardId: 등록 카드 결제 시 사용할 카드 ID
  static Future<String?> createCall({
    required double latitude,
    required double longitude,
    required String address,
    required String addressDetail,
    required String phone,
    required String paymentMethod,
    CallOptions? options,
    double? estimatedDistanceKm,
    int? estimatedFare,
    String? fareType,
    String? cardId,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'addressDetail': addressDetail,
      'phone': phone,
      'paymentMethod': paymentMethod,
    };
    if (options != null) {
      body.addAll(options.toJson());
    }
    if (estimatedDistanceKm != null) {
      body['estimatedDistanceKm'] = estimatedDistanceKm;
    }
    if (estimatedFare != null) {
      body['estimatedFare'] = estimatedFare;
    }
    if (fareType != null) {
      body['fareType'] = fareType;
    }
    if (cardId != null && cardId.isNotEmpty) {
      body['cardId'] = cardId;
    }
    final res = await ApiClient.post(_base, body);

    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    final rideId = data?['rideId'] as String?;
    return rideId;
  }
}


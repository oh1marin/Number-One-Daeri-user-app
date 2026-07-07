import '../models/call_options.dart';
import '../models/ride_waypoint.dart';
import 'api_client.dart';
import '../utils/idempotency.dart';

/// 대리호출 생성 API
class RidesCallApi {
  static const _base = '/rides/call';

  static Future<String?> createCall({
    required double latitude,
    required double longitude,
    required String address,
    required String addressDetail,
    required String phone,
    required String paymentMethod,
    String? clientCallId,
    CallOptions? options,
    double? estimatedDistanceKm,
    int? estimatedFare,
    String? fareType,
    String? cardId,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationAddress,
    List<RideWaypoint>? waypoints,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'addressDetail': addressDetail,
      'phone': phone,
      'paymentMethod': paymentMethod,
      if ((clientCallId ?? '').isNotEmpty)
        'clientCallId': clientCallId
      else
        'clientCallId': generateClientCallId(),
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
    if (destinationLatitude != null && destinationLongitude != null) {
      body['destinationLatitude'] = destinationLatitude;
      body['destinationLongitude'] = destinationLongitude;
    }
    if (destinationAddress != null && destinationAddress.isNotEmpty) {
      body['destinationAddress'] = destinationAddress;
    }
    if (waypoints != null && waypoints.isNotEmpty) {
      body['waypoints'] = waypoints.map((w) => w.toJson()).toList();
    }
    final res = await ApiClient.post(_base, body);

    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    final rideId = data?['rideId'] as String?;
    return rideId;
  }
}

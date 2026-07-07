import 'api_client.dart';

/// 예상 요금 산정 API (경유지 포함)
class RidesEstimateApi {
  static const _path = '/rides/estimate';

  static Future<EstimateResult?> estimate({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    List<Map<String, dynamic>>? waypoints,
  }) async {
    final body = <String, dynamic>{
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      if (waypoints != null && waypoints.isNotEmpty) 'waypoints': waypoints,
    };
    final res = await ApiClient.post(_path, body);

    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    if (data == null) return null;

    final distanceKm = (data['distanceKm'] as num?)?.toDouble();
    final fares = data['fares'] as Map<String, dynamic>?;
    if (distanceKm == null || fares == null) return null;

    return EstimateResult(
      distanceKm: distanceKm,
      normal: (fares['normal'] as num?)?.toInt() ?? 0,
      fast: (fares['fast'] as num?)?.toInt() ?? 0,
      premium: (fares['premium'] as num?)?.toInt() ?? 0,
      waypointCount: (data['waypointCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class EstimateResult {
  const EstimateResult({
    required this.distanceKm,
    required this.normal,
    required this.fast,
    required this.premium,
    this.waypointCount = 0,
  });

  final double distanceKm;
  final int normal;
  final int fast;
  final int premium;
  final int waypointCount;
}

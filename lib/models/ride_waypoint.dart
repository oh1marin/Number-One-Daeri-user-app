import '../services/kakao_local_service.dart';

/// 경유지 1곳 (출발·도착 사이)
class RideWaypoint {
  const RideWaypoint({
    required this.sequence,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final int sequence;
  final String name;
  final String address;
  final double lat;
  final double lng;

  factory RideWaypoint.fromPlace(PlaceSearchResult place, int sequence) {
    return RideWaypoint(
      sequence: sequence,
      name: place.name,
      address: place.address.isNotEmpty ? place.address : place.name,
      lat: place.lat,
      lng: place.lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'name': name,
        'address': address,
        'latitude': lat,
        'longitude': lng,
      };
}

String buildRouteSummaryText({
  required String pickup,
  required List<RideWaypoint> waypoints,
  required String dropoff,
}) {
  final parts = [
    pickup.trim(),
    ...waypoints.map((w) => w.name.trim()),
    dropoff.trim(),
  ].where((s) => s.isNotEmpty);
  return parts.join(' → ');
}

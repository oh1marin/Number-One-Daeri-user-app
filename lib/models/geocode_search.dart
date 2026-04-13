/// 백엔드 geocode API 응답 모델
class GeocodeSearchItem {
  GeocodeSearchItem({
    required this.addressName,
    this.address,
    this.roadAddress,
    this.buildingName,
    this.placeName,
    required this.lat,
    required this.lng,
  });

  final String addressName;
  final String? address;
  final String? roadAddress;
  final String? buildingName;
  final String? placeName;
  final double lat;
  final double lng;

  /// 표시용 주소 (장소명 > 도로명 > 지번)
  String get displayAddress =>
      placeName ?? buildingName ?? roadAddress ?? address ?? addressName;

  factory GeocodeSearchItem.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse((json['lat'] ?? json['y'] ?? '0').toString()) ?? 0;
    final lng = double.tryParse((json['lng'] ?? json['x'] ?? '0').toString()) ?? 0;
    return GeocodeSearchItem(
      addressName: (json['address_name'] ?? '').toString(),
      address: json['address']?.toString(),
      roadAddress: (json['road_address'] ?? json['road_address_name'] ?? '').toString().isEmpty
          ? null
          : (json['road_address'] ?? json['road_address_name']).toString(),
      buildingName: json['building_name']?.toString(),
      placeName: json['place_name']?.toString(),
      lat: lat,
      lng: lng,
    );
  }
}

class GeocodeSearchResponse {
  GeocodeSearchResponse({
    required this.items,
    required this.totalCount,
    required this.isEnd,
  });

  final List<GeocodeSearchItem> items;
  final int totalCount;
  final bool isEnd;

  factory GeocodeSearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final itemsList = (data['items'] as List<dynamic>?) ??
        (data['content'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        [];
    return GeocodeSearchResponse(
      items: itemsList
          .map((e) => GeocodeSearchItem.fromJson(e as Map<String, dynamic>))
          .where((r) => r.lat != 0 && r.lng != 0)
          .toList(),
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      isEnd: data['isEnd'] as bool? ?? true,
    );
  }
}

import 'api_client.dart';
import '../config/kakao_config.dart';
import '../models/geocode_search.dart';
import '../services/kakao_local_service.dart';

/// 백엔드 geocode API
/// GET /geocode/search - 주소 검색
/// GET /geocode/keyword - 장소명 검색 (서울역, 스타벅스 강남점 등)
class GeocodeApi {
  static const _searchPath = '/geocode/search';
  static const _keywordPath = '/geocode/keyword';
  static const _reversePath = '/geocode/reverse';

  /// 위경도 → 주소 (역지오코딩)
  /// GET /geocode/reverse?lat=...&lng=...
  /// Response: { "address", "addressDetail", "region" }
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final res = await ApiClient.get(
        _reversePath,
        queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
      );
      final map = res.data as Map<String, dynamic>?;
      final data = map?['data'] as Map<String, dynamic>? ?? map;
      final address = data?['address']?.toString() ?? data?['region']?.toString();
      final detail = data?['addressDetail']?.toString();
      if (address != null && address.isNotEmpty) {
        return detail != null && detail.isNotEmpty ? '$address $detail' : address;
      }
    } catch (_) {}
    if (kakaoRestApiKey.isNotEmpty) {
      return KakaoLocalService.reverseGeocode(lat, lng);
    }
    return null;
  }

  /// 주소 검색
  static Future<GeocodeSearchResponse> searchAddress(
    String query, {
    int page = 1,
    int size = 15,
  }) async {
    if (query.trim().isEmpty) {
      return GeocodeSearchResponse(items: [], totalCount: 0, isEnd: true);
    }
    try {
      final res = await ApiClient.get(
        _searchPath,
        queryParameters: {
          'query': query.trim(),
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      final map = res.data as Map<String, dynamic>? ?? {};
      return GeocodeSearchResponse.fromJson(map);
    } catch (_) {
      return GeocodeSearchResponse(items: [], totalCount: 0, isEnd: true);
    }
  }

  /// 장소명 검색 (place_name 중심)
  static Future<GeocodeSearchResponse> searchKeyword(
    String query, {
    int page = 1,
    int size = 15,
  }) async {
    if (query.trim().isEmpty) {
      return GeocodeSearchResponse(items: [], totalCount: 0, isEnd: true);
    }
    try {
      final res = await ApiClient.get(
        _keywordPath,
        queryParameters: {
          'query': query.trim(),
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      final map = res.data as Map<String, dynamic>? ?? {};
      return GeocodeSearchResponse.fromJson(map);
    } catch (_) {
      return GeocodeSearchResponse(items: [], totalCount: 0, isEnd: true);
    }
  }

  static String _dedupKey(double lat, double lng, String label) {
    final rLat = (lat * 10000).round();
    final rLng = (lng * 10000).round();
    return '$rLat,$rLng:${label.hashCode}';
  }

  /// 통합 검색: 백엔드 주소·키워드 + **카카오 로컬 API** (백엔드 미동작·로컬 개발 시에도 검색 가능)
  static Future<List<PlaceSearchResult>> search(
    String query, {
    double? originLat,
    double? originLng,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final futures = <Future<dynamic>>[
      searchAddress(q),
      searchKeyword(q),
    ];
    if (kakaoRestApiKey.isNotEmpty) {
      futures.add(
        KakaoLocalService.search(q, lat: originLat, lng: originLng),
      );
    }

    final out = await Future.wait(futures);
    final addressRes = out[0] as GeocodeSearchResponse;
    final keywordRes = out[1] as GeocodeSearchResponse;
    final kakaoList = futures.length > 2 ? out[2] as List<PlaceSearchResult> : <PlaceSearchResult>[];

    final seen = <String>{};
    final merged = <PlaceSearchResult>[];

    void addPlace(PlaceSearchResult p) {
      if (p.lat == 0 && p.lng == 0) return;
      final key = _dedupKey(p.lat, p.lng, p.name);
      if (seen.add(key)) merged.add(p);
    }

    for (final item in addressRes.items) {
      addPlace(_toPlaceSearchResult(item));
    }
    for (final item in keywordRes.items) {
      addPlace(_toPlaceSearchResult(item));
    }
    for (final p in kakaoList) {
      addPlace(p);
    }

    return merged;
  }

  static PlaceSearchResult _toPlaceSearchResult(GeocodeSearchItem item) {
    return PlaceSearchResult(
      name: item.displayAddress,
      address: item.addressName,
      lat: item.lat,
      lng: item.lng,
    );
  }
}

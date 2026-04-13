import 'package:dio/dio.dart';

import '../config/kakao_config.dart';

/// 카카오 로컬 API - 장소/주소 검색
class KakaoLocalService {
  KakaoLocalService._();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://dapi.kakao.com',
    headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    connectTimeout: const Duration(seconds: 5),
  ));

  /// 키워드로 장소 검색 (서울아산병원 등)
  static Future<List<PlaceSearchResult>> searchKeyword(
    String query, {
    double? lat,
    double? lng,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final params = <String, dynamic>{'query': query, 'size': 15};
      if (lat != null && lng != null) {
        params['x'] = lng.toString();
        params['y'] = lat.toString();
        params['sort'] = 'distance';
      }
      final res = await _dio.get('/v2/local/search/keyword.json', queryParameters: params);
      final list = res.data['documents'] as List?;
      if (list == null) return [];
      return list.map((e) => PlaceSearchResult.fromKeyword(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 주소로 검색
  static Future<List<PlaceSearchResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await _dio.get(
        '/v2/local/search/address.json',
        queryParameters: {'query': query, 'size': 30},
      );
      final list = res.data['documents'] as List?;
      if (list == null) return [];
      return list.map((e) => PlaceSearchResult.fromAddress(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 좌표 → 주소 (역지오코딩) — Kakao coord2address API 직접 호출
  /// 도로명 주소 우선, 없으면 지번 주소 반환
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final res = await _dio.get(
        '/v2/local/geo/coord2address.json',
        queryParameters: {'x': lng.toString(), 'y': lat.toString()},
      );
      final docs = res.data['documents'] as List?;
      if (docs == null || docs.isEmpty) return null;
      final doc = docs.first as Map<String, dynamic>;

      // 도로명 주소 우선
      final road = doc['road_address'] as Map<String, dynamic>?;
      if (road != null) {
        final base = road['address_name']?.toString() ?? '';
        final building = road['building_name']?.toString() ?? '';
        return building.isNotEmpty ? '$base ($building)' : base;
      }

      // 지번 주소 fallback
      final jibun = doc['address'] as Map<String, dynamic>?;
      return jibun?['address_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// 통합 검색 (키워드 + 주소 + 대표지역)
  static Future<List<PlaceSearchResult>> search(String query, {double? lat, double? lng}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 키워드(장소) + 주소 검색으로 해당 지역 관련 결과 최대한 수집
    final keyword = searchKeyword(query, lat: lat, lng: lng);
    final address = searchAddress(query);
    final results = await Future.wait([keyword, address]);
    final seen = <String>{};
    final merged = <PlaceSearchResult>[];

    // 대표지역(부산광역시 등)은 맨 앞에 1개만 추가
    final regionResult = _getRegionCenter(q);
    if (regionResult != null) {
      merged.add(regionResult);
      seen.add('${regionResult.lat},${regionResult.lng}');
    }
    // 키워드 결과 (장소들) - 부산 검색 시 부산 내 수많은 장소
    for (final r in results[0]) {
      final key = '${r.lat},${r.lng}_${r.name}';
      if (!seen.contains(key) && r.lat != 0 && r.lng != 0) {
        seen.add(key);
        merged.add(r);
      }
    }
    // 주소 결과 - 부산 내 수많은 주소
    for (final r in results[1]) {
      final key = '${r.lat},${r.lng}_${r.address}';
      if (!seen.contains(key) && r.lat != 0 && r.lng != 0) {
        seen.add(key);
        merged.add(r);
      }
    }
    return merged;
  }

  /// 주요 도시/지역명 → 대표 좌표 (시청 등)
  static PlaceSearchResult? _getRegionCenter(String query) {
    final normalized = query.replaceAll(' ', '');
    const regions = {
      '부산': ('부산광역시', 35.1796, 129.0756),
      '부산광역시': ('부산광역시', 35.1796, 129.0756),
      '서울': ('서울특별시', 37.5665, 126.9780),
      '서울특별시': ('서울특별시', 37.5665, 126.9780),
      '인천': ('인천광역시', 37.4563, 126.7052),
      '대구': ('대구광역시', 35.8714, 128.6014),
      '대전': ('대전광역시', 36.3504, 127.3845),
      '광주': ('광주광역시', 35.1595, 126.8526),
      '울산': ('울산광역시', 35.5384, 129.3114),
      '세종': ('세종특별자치시', 36.4801, 127.2892),
      '경기': ('경기도', 37.4138, 127.5183),
      '강원': ('강원도', 37.8228, 128.1555),
      '충북': ('충청북도', 36.6357, 127.4912),
      '충남': ('충청남도', 36.5184, 126.8),
      '전북': ('전북특별자치도', 35.8204, 127.1089),
      '전남': ('전라남도', 34.8161, 126.4629),
      '경북': ('경상북도', 36.5760, 128.5056),
      '경남': ('경상남도', 35.4606, 128.2132),
      '제주': ('제주특별자치도', 33.4996, 126.5312),
      '제주도': ('제주특별자치도', 33.4996, 126.5312),
    };
    for (final e in regions.entries) {
      if (normalized.contains(e.key) || e.key.contains(normalized)) {
        final r = e.value;
        return PlaceSearchResult(name: r.$1, address: r.$1, lat: r.$2, lng: r.$3);
      }
    }
    return null;
  }
}

class PlaceSearchResult {
  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.distance,
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? distance;

  factory PlaceSearchResult.fromKeyword(Map<String, dynamic> e) {
    return PlaceSearchResult(
      name: (e['place_name'] ?? e['address_name'] ?? '').toString(),
      address: (e['address_name'] ?? e['road_address_name'] ?? '').toString(),
      lat: double.tryParse((e['y'] ?? '0').toString()) ?? 0,
      lng: double.tryParse((e['x'] ?? '0').toString()) ?? 0,
      distance: double.tryParse((e['distance'] ?? '').toString()),
    );
  }

  factory PlaceSearchResult.fromAddress(Map<String, dynamic> e) {
    return PlaceSearchResult(
      name: (e['address_name'] ?? '').toString(),
      address: (e['address_name'] ?? '').toString(),
      lat: double.tryParse((e['y'] ?? e['address']?['y'] ?? '0').toString()) ?? 0,
      lng: double.tryParse((e['x'] ?? e['address']?['x'] ?? '0').toString()) ?? 0,
    );
  }
}

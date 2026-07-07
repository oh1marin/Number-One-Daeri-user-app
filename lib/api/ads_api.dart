import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 광고/프로모션 API
///
/// GET /ads
/// Response 예시(가정):
/// { success: true, data: [{ id, imageUrl, content, linkUrl, shareText }] }
class AdsApi {
  // apiBaseUrl ends with `/api/v1/`, so avoid leading slash to prevent `//ads`.
  static const _path = 'ads';
  static const _cacheTtl = Duration(minutes: 5);

  static List<AdItem>? _cached;
  static DateTime? _cachedAt;

  static void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  static Future<List<AdItem>> getList({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return List<AdItem>.from(_cached!);
    }

    try {
      final res = await ApiClient.get(_path);
      final data = res.data;
      debugPrint('[AdsApi] requestUri=${res.requestOptions.uri}');

      dynamic raw = data;
      if (data is Map<String, dynamic>) {
        raw = data['data'] ?? data['items'] ?? data;
      }

      if (raw is List) {
        final list = raw
            .whereType<Map<String, dynamic>>()
            .map(AdItem.fromJson)
            .toList();
        debugPrint('[AdsApi] GET /ads list size=${list.length} runtimeType=${res.data.runtimeType}');
        if (list.isNotEmpty) {
          debugPrint('[AdsApi] first ad id=${list.first.id} content="${list.first.content}"');
        }
        _cached = list;
        _cachedAt = DateTime.now();
        return list;
      }

      if (raw is Map<String, dynamic>) {
        final items = raw['items'];
        if (items is List) {
          final list = items
              .whereType<Map<String, dynamic>>()
              .map(AdItem.fromJson)
              .toList();
          _cached = list;
          _cachedAt = DateTime.now();
          return list;
        }

        // If backend returns a single ad object (not a list),
        // treat the whole map as one AdItem.
        final hasAdFields = raw.containsKey('imageUrl') ||
            raw.containsKey('content') ||
            raw.containsKey('linkUrl') ||
            raw.containsKey('shareText');
        if (hasAdFields) {
          final ad = AdItem.fromJson(raw);
          debugPrint('[AdsApi] GET /ads single ad id=${ad.id} content="${ad.content}"');
          final single = [ad];
          _cached = single;
          _cachedAt = DateTime.now();
          return single;
        }
      }

      _cached = const [];
      _cachedAt = DateTime.now();
      return [];
    } on DioException catch (e) {
      debugPrint('[AdsApi] GET /ads failed: status=${e.response?.statusCode}, data=${e.response?.data}');
      if (_cached != null) return List<AdItem>.from(_cached!);
      return [];
    }
  }
}

class AdItem {
  const AdItem({
    required this.id,
    required this.imageUrl,
    required this.content,
    required this.linkUrl,
    required this.shareText,
  });

  final String id;
  final String? imageUrl;
  final String? content;
  final String? linkUrl;
  final String? shareText;

  factory AdItem.fromJson(Map<String, dynamic> json) {
    String? toStr(dynamic v) => v?.toString();

    return AdItem(
      id: (json['id'] ?? '').toString(),
      imageUrl: toStr(json['imageUrl']),
      content: toStr(json['content']),
      linkUrl: toStr(json['linkUrl']),
      shareText: toStr(json['shareText']),
    );
  }
}


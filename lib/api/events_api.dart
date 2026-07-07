import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/default_notices_content.dart';
import 'api_client.dart';

/// 이벤트 API
///
/// GET /events
/// Response (문서 기준): [{ "id", "title", "imageUrl", "startAt", "endAt", "url" }]
class EventsApi {
  static const _path = 'events';
  static const _cacheTtl = Duration(minutes: 5);
  static const _maxExtraPages = 5;

  static List<EventItem>? _cached;
  static DateTime? _cachedAt;

  static void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  /// 응답 body에서 EventItem 리스트를 파싱한다.
  static List<EventItem> _parse(dynamic body) {
    dynamic raw = body;
    if (body is Map<String, dynamic>) {
      raw = body['data'] ?? body['items'] ?? body;
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(EventItem.fromJson).toList();
    }
    if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().map(EventItem.fromJson).toList();
      }
    }
    return [];
  }

  static Future<List<EventItem>> _fetchPage({
    required int page,
    required int limit,
  }) async {
    final res = await ApiClient.get(_path, queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      'take': limit.toString(),
      'per_page': limit.toString(),
      'pageSize': limit.toString(),
      'size': limit.toString(),
      'offset': ((page - 1) * limit).toString(),
      'skip': ((page - 1) * limit).toString(),
    });
    return _parse(res.data);
  }

  /// 이벤트 목록 (메모리 캐시 + 최대 6회 API 호출).
  ///
  /// 백엔드 스펙 변경 없이: 1차 limit=100, 부족할 때만 page 2~6 추가 시도.
  static Future<List<EventItem>> getList({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return List<EventItem>.from(_cached!);
    }

    final seen = <String>{};
    final all = <EventItem>[];

    void absorb(List<EventItem> items) {
      for (final e in items) {
        if (seen.add(e.id.isNotEmpty ? e.id : e.title)) {
          all.add(e);
        }
      }
    }

    const firstLimit = 100;

    try {
      final items = await _fetchPage(page: 1, limit: firstLimit);
      debugPrint('[EventsApi] page=1 count=${items.length}');
      absorb(items);

      if (items.length >= firstLimit) {
        for (var page = 2; page <= _maxExtraPages + 1; page++) {
          final more = await _fetchPage(page: page, limit: firstLimit);
          if (more.isEmpty) break;
          final before = all.length;
          absorb(more);
          if (all.length == before) break;
        }
      } else if (all.length <= 1) {
        for (var page = 2; page <= _maxExtraPages + 1; page++) {
          final more = await _fetchPage(page: page, limit: 20);
          if (more.isEmpty) break;
          final before = all.length;
          absorb(more);
          if (all.length == before) break;
        }
      }
    } on DioException catch (e) {
      debugPrint('[EventsApi] fetch failed: status=${e.response?.statusCode}');
      if (_cached != null) return List<EventItem>.from(_cached!);
      return DefaultNoticesContent.events;
    }

    debugPrint('[EventsApi] final count=${all.length}');
    if (all.isEmpty) {
      final fallback = DefaultNoticesContent.events;
      debugPrint('[EventsApi] empty — using ${fallback.length} default events');
      _cached = fallback;
      _cachedAt = DateTime.now();
      return fallback;
    }

    _cached = all;
    _cachedAt = DateTime.now();
    return all;
  }
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.startAt,
    required this.endAt,
    required this.url,
    this.content,
    this.date,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? startAt;
  final String? endAt;
  final String? url;
  final String? content;
  final String? date;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    String? toStr(dynamic v) => v?.toString();

    String title = _pickFirstString(
      json,
      candidates: const [
        'title',
        'name',
        'content',
        'description',
        'desc',
        'question',
      ],
    );
    title = title.trim().isEmpty ? '이벤트' : title.trim();

    final startAt = toStr(
      json['startAt'] ?? json['start_at'] ?? json['startDate'] ?? json['date'] ?? json['createdAt'],
    );
    final endAt = toStr(json['endAt'] ?? json['end_at'] ?? json['endDate']);

    final url = toStr(json['url'] ?? json['linkUrl'] ?? json['link']);

    return EventItem(
      id: (json['id'] ?? '').toString(),
      title: title,
      imageUrl: toStr(json['imageUrl']),
      startAt: startAt,
      endAt: endAt,
      url: url,
      content: toStr(json['content'] ?? json['description'] ?? json['desc']),
      date: toStr(json['date']),
    );
  }

  static String _pickFirstString(
    Map<String, dynamic> json, {
    required List<String> candidates,
  }) {
    for (final k in candidates) {
      final v = json[k];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return '';
  }
}

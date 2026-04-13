import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 이벤트 API
///
/// GET /events
/// Response (문서 기준): [{ "id", "title", "imageUrl", "startAt", "endAt", "url" }]
class EventsApi {
  // apiBaseUrl ends with `/api/v1/`, so avoid leading slash to prevent `//events`.
  static const _path = 'events';

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

  /// GET /events 를 여러 파라미터 조합으로 반복 호출해서 이벤트 목록을 모아 반환한다.
  ///
  /// 백엔드가 어떤 페이지네이션 파라미터를 쓰는지 모르기 때문에:
  ///  1) 첫 번째 호출: limit/take/perPage 등 모든 변형 파라미터를 동시에 전송 → 한 번에 전부 가져오길 기대.
  ///  2) 1건 이하로 오면: skip/offset/page 를 1씩 늘리면서 최대 50번 추가 호출, 새 이벤트가 없으면 중단.
  static Future<List<EventItem>> getList() async {
    final seen = <String>{};
    final all = <EventItem>[];

    void absorb(List<EventItem> items) {
      for (final e in items) {
        if (seen.add(e.id.isNotEmpty ? e.id : e.title)) {
          all.add(e);
        }
      }
    }

    // ── 1차 호출: 한 번에 전부 ─────────────────────────────────────────────
    try {
      final res = await ApiClient.get(_path, queryParameters: {
        'limit': '100',
        'take': '100',
        'per_page': '100',
        'pageSize': '100',
        'size': '100',
        'page': '1',
        'offset': '0',
        'skip': '0',
      });
      debugPrint('[EventsApi] requestUri=${res.requestOptions.uri}');
      debugPrint('[EventsApi] raw body type=${res.data.runtimeType}');
      final items = _parse(res.data);
      debugPrint('[EventsApi] 1차 호출 count=${items.length}');
      absorb(items);
    } on DioException catch (e) {
      debugPrint('[EventsApi] 1차 호출 실패: status=${e.response?.statusCode}');
    }

    // 2건 이상이면 완료
    if (all.length > 1) {
      debugPrint('[EventsApi] 최종 이벤트 수=${all.length}');
      return all;
    }

    // ── 2차 ~ N차 호출: skip 기반 페이지네이션 ────────────────────────────
    for (int idx = 1; idx <= 49; idx++) {
      try {
        final res = await ApiClient.get(_path, queryParameters: {
          'page': '${idx + 1}',
          'limit': '1',
          'take': '1',
          'offset': '$idx',
          'skip': '$idx',
        });
        final items = _parse(res.data);
        if (items.isEmpty) {
          debugPrint('[EventsApi] skip=$idx 에서 빈 응답, 페이지네이션 종료');
          break;
        }
        final before = all.length;
        absorb(items);
        if (all.length == before) {
          debugPrint('[EventsApi] skip=$idx 에서 중복 응답, 페이지네이션 종료');
          break;
        }
      } on DioException {
        break;
      }
    }

    debugPrint('[EventsApi] 최종 이벤트 수=${all.length}');
    for (final e in all.take(5)) {
      debugPrint('[EventsApi]  └ id=${e.id} title="${e.title}"');
    }
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


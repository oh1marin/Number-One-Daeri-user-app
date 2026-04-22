import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 공지사항 API (공개, 인증 불필요할 수 있음)
/// GET …/api/v1/notices?page=1&limit=20
///
/// Dio: `baseUrl`이 `…/api/v1/`일 때 경로는 **슬래시 없이** `notices`만 써야 함.
/// `/notices`로 호출하면 호스트 루트 `/notices`로 나가 `/api/v1/notices`와 달라짐.
class NoticesApi {
  static const _path = 'notices';

  static List<Notice>? _itemsFromPayload(dynamic data) {
    if (data is List) return _parseNoticeList(data);
    if (data is! Map) return null;

    final root = data;
    if (root['items'] is List) return _parseNoticeList(root['items'] as List);
    if (root['notices'] is List) {
      return _parseNoticeList(root['notices'] as List);
    }
    if (root['results'] is List) {
      return _parseNoticeList(root['results'] as List);
    }

    final inner = root['data'];
    if (inner is List) return _parseNoticeList(inner);
    if (inner is Map) {
      final m = inner;
      if (m['items'] is List) return _parseNoticeList(m['items'] as List);
      if (m['notices'] is List) return _parseNoticeList(m['notices'] as List);
      if (m['results'] is List) return _parseNoticeList(m['results'] as List);
    }
    return null;
  }

  static List<Notice> _parseNoticeList(List list) {
    return list
        .whereType<Map>()
        .map((e) => Notice.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Notice>> getList({int page = 1, int limit = 20}) async {
    try {
      final res = await ApiClient.get(
        _path,
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      final parsed = _itemsFromPayload(res.data);
      if (parsed != null) return parsed;
      if (kDebugMode) {
        debugPrint('[NoticesApi] unexpected shape: ${res.data.runtimeType}');
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NoticesApi] GET notices failed: $e\n$st');
      }
      return [];
    }
  }
}

String? _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
  return match != null ? '${match[1]}.${match[2]}.${match[3]}' : iso;
}

class Notice {
  Notice({
    required this.id,
    required this.title,
    required this.content,
    this.badge = '공지',
    this.badgeColor,
    this.date = '',
    this.views = 0,
    this.imageUrl,
    this.coverImageUrl,
    this.events = const [],
  });

  final String id;
  final String badge;
  final String? badgeColor;
  final String title;
  final String date;
  final int views;
  final String content;

  /// 본문/목록용 이미지 (S3 publicUrl 등)
  final String? imageUrl;

  /// 상단 커버·배너용
  final String? coverImageUrl;
  final List<NoticeEvent> events;

  factory Notice.fromJson(Map<String, dynamic> json) {
    final dateStr =
        json['date']?.toString() ??
        _formatDate(json['createdAt']?.toString()) ??
        '';
    return Notice(
      id: (json['id'] ?? '').toString(),
      badge: (json['badge'] ?? '공지').toString(),
      badgeColor: json['badgeColor']?.toString(),
      title: (json['title'] ?? '').toString(),
      date: dateStr,
      views: (json['views'] as num?)?.toInt() ?? 0,
      content: (json['content'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      events:
          (json['events'] as List?)
              ?.map((e) => NoticeEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class NoticeEvent {
  NoticeEvent({required this.title, this.date, this.desc, this.imageUrl});

  final String title;
  final String? date;
  final String? desc;
  final String? imageUrl;

  factory NoticeEvent.fromJson(Map<String, dynamic> json) {
    return NoticeEvent(
      title: (json['title'] ?? '').toString(),
      date: json['date']?.toString(),
      desc: json['desc']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

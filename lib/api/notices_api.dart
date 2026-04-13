import 'api_client.dart';

/// 공지사항 API (공개, 인증 불필요할 수 있음)
/// GET /notices?page=1&limit=10
class NoticesApi {
  static const _path = '/notices';

  static Future<List<Notice>> getList({int page = 1, int limit = 20}) async {
    try {
      final res = await ApiClient.get(
        _path,
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      final data = res.data;
      List? items;
      if (data is Map) {
        items = (data['data']?['items'] ?? data['items'] ?? data) as List?;
      } else if (data is List) {
        items = data;
      }
      if (items == null) return [];
      return items
          .map((e) => Notice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
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

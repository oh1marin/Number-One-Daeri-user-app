import '../models/api_response.dart';
import 'api_client.dart';

/// 1:1 문의 API (로그인 필요)
///
/// [백엔드 필요 엔드포인트]
/// POST   /inquiries                    → 새 문의 세션 생성
/// GET    /inquiries/my/active          → 진행 중인 문의 조회 (없으면 404)
/// GET    /inquiries/:id/messages       → 메시지 목록 (폴링용)
/// POST   /inquiries/:id/messages       → 메시지 전송
class InquiryApi {
  static const _base = '/inquiries';

  /// 새 문의 세션 생성 → { id, status, createdAt }
  static Future<InquirySession?> create({String? initialMessage}) async {
    final body = initialMessage != null ? {'content': initialMessage} : <String, dynamic>{};
    final res = await ApiClient.post(_base, body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    if (data == null) return null;
    return InquirySession.fromJson(data);
  }

  /// 진행 중인 문의 조회. 없으면 null 반환
  static Future<InquirySession?> getActive() async {
    try {
      final res = await ApiClient.get('$_base/my/active');
      final map = res.data as Map<String, dynamic>?;
      final data = map?['data'] as Map<String, dynamic>? ?? map;
      if (data == null) return null;
      return InquirySession.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 메시지 목록 조회 (폴링)
  /// GET /inquiries/:id/messages?after=<lastMessageId>
  static Future<List<InquiryMessage>> getMessages(
    String inquiryId, {
    String? afterId,
  }) async {
    final params = <String, dynamic>{};
    if (afterId != null) params['after'] = afterId;
    final res = await ApiClient.get(
      '$_base/$inquiryId/messages',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    final list = (data['messages'] ?? data['items'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(InquiryMessage.fromJson)
        .toList();
  }

  /// 메시지 전송
  /// POST /inquiries/:id/messages { content }
  static Future<InquiryMessage?> sendMessage(
    String inquiryId,
    String content,
  ) async {
    final res = await ApiClient.post(
      '$_base/$inquiryId/messages',
      {'content': content},
    );
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    if (data == null) return null;
    return InquiryMessage.fromJson(data);
  }

  /// [구버전 호환] 기존 단순 문의 등록 (AI 자동응답용)
  static Future<ApiResponse<Map<String, dynamic>>> createLegacy({
    required String content,
  }) async {
    final res = await ApiClient.post(_base, {'content': content});
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d as Map<String, dynamic>,
    );
  }
}

// ── 모델 ──────────────────────────────────────────────────────────────────────

class InquirySession {
  const InquirySession({
    required this.id,
    required this.status,
    this.createdAt,
  });

  final String id;

  /// pending | active | closed
  final String status;
  final String? createdAt;

  bool get isClosed => status == 'closed';

  factory InquirySession.fromJson(Map<String, dynamic> json) => InquirySession(
        id: (json['id'] ?? '').toString(),
        status: (json['status'] ?? 'pending').toString(),
        createdAt: json['createdAt']?.toString(),
      );
}

class InquiryMessage {
  const InquiryMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.senderName,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String content;

  /// 'user' | 'admin'
  final String sender;
  final String? senderName;
  final String? createdAt;
  final bool isRead;

  bool get isFromUser => sender == 'user';
  bool get isFromAdmin => sender == 'admin';

  factory InquiryMessage.fromJson(Map<String, dynamic> json) => InquiryMessage(
        id: (json['id'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        sender: (json['sender'] ?? 'user').toString(),
        senderName: json['senderName']?.toString(),
        createdAt: json['createdAt']?.toString(),
        isRead: json['isRead'] == true,
      );
}

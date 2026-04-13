import 'api_client.dart';
import 'inquiry_api.dart';

/// 관리자용 1:1 문의 API
///
/// [백엔드 필요 엔드포인트]
/// GET    /admin/inquiries                  → 문의 목록 (전체)
/// GET    /admin/inquiries/:id/messages     → 특정 문의 메시지 목록
/// POST   /admin/inquiries/:id/messages     → 관리자 답장 전송
/// PATCH  /admin/inquiries/:id             → 상태 변경 (close 등)
class AdminInquiryApi {
  static const _base = '/admin/inquiries';

  /// 문의 목록 (최신순)
  static Future<List<AdminInquiryItem>> getList({
    int page = 1,
    int limit = 20,
    String? status, // pending | active | closed
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final res = await ApiClient.get(_base, queryParameters: params);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    final list = (data['items'] ?? data['inquiries'] ?? []) as List<dynamic>;
    return list.whereType<Map<String, dynamic>>().map(AdminInquiryItem.fromJson).toList();
  }

  /// 특정 문의의 메시지 전체 조회
  static Future<List<InquiryMessage>> getMessages(String inquiryId) async {
    final res = await ApiClient.get('$_base/$inquiryId/messages');
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    final list = (data['messages'] ?? data['items'] ?? []) as List<dynamic>;
    return list.whereType<Map<String, dynamic>>().map(InquiryMessage.fromJson).toList();
  }

  /// 관리자 답장 전송 (sender: "admin")
  static Future<InquiryMessage?> sendReply(String inquiryId, String content) async {
    final res = await ApiClient.post('$_base/$inquiryId/messages', {'content': content});
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    if (data == null) return null;
    return InquiryMessage.fromJson(data);
  }

  /// 문의 상태 변경 (close / reopen)
  static Future<void> updateStatus(String inquiryId, String status) async {
    await ApiClient.put('$_base/$inquiryId', {'status': status});
  }
}

// ── 모델 ──────────────────────────────────────────────────────────────────────

class AdminInquiryItem {
  const AdminInquiryItem({
    required this.id,
    required this.status,
    required this.customerPhone,
    this.customerName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;

  /// pending | active | closed
  final String status;
  final String customerPhone;
  final String? customerName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  bool get isClosed => status == 'closed';
  bool get hasUnread => unreadCount > 0;

  factory AdminInquiryItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return AdminInquiryItem(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      customerPhone: (customer?['phone'] ?? json['customerPhone'] ?? '-').toString(),
      customerName: (customer?['name'] ?? json['customerName'])?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: (json['lastMessageAt'] ?? json['updatedAt'])?.toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

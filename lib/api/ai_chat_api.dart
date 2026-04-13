import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// AI 자동답변 API
/// POST /ai/chat  { "message": string }
/// Response: {
///   "success": true,
///   "data": {
///     "reply_text": string,
///     "needs_human_handoff": bool,   // true면 전화 연결 버튼 표시
///     "reply": string                // 구버전 호환
///   }
/// }
class AiChatApi {
  static const _path = 'ai/chat';

  static Future<AiChatReply?> getReply(String message) async {
    try {
      final res = await ApiClient.post(_path, {'message': message});
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];

        if (data is Map<String, dynamic>) {
          final text = (data['reply_text'] ?? data['reply'])?.toString();
          if (text != null && text.trim().isNotEmpty) {
            return AiChatReply(
              replyText: text.trim(),
              needsHumanHandoff: data['needs_human_handoff'] == true,
            );
          }
        }

        // data가 바로 문자열인 경우 (구버전 호환)
        if (data is String && data.trim().isNotEmpty) {
          return AiChatReply(replyText: data.trim());
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[AiChatApi] POST /ai/chat failed: status=${e.response?.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiChatApi] error: $e');
      return null;
    }
  }
}

class AiChatReply {
  const AiChatReply({
    required this.replyText,
    this.needsHumanHandoff = false,
  });

  final String replyText;

  /// true이면 채팅 버블 아래 "전화 연결" 버튼 표시
  final bool needsHumanHandoff;
}

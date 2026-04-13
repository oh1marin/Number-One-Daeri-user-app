import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import 'api_client.dart';

/// 불편신고 API
/// POST /complaints  (Bearer 토큰 필수)
/// Body: { "content": string, "attachments"?: string[] }
/// Response: { "success": true, "data": { "id", "createdAt", ... } }
class ComplaintsApi {
  static const _path = 'complaints';

  static Future<ApiResponse<Map<String, dynamic>>> create({
    required String content,
    List<String>? attachments,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (attachments != null && attachments.isNotEmpty) {
      body['attachments'] = attachments;
    }

    try {
      final res = await ApiClient.post(_path, body);
      debugPrint('[ComplaintsApi] POST /complaints status=${res.statusCode}');
      final map = res.data as Map<String, dynamic>?;
      return ApiResponse.fromJson(map ?? {}, (d) => d as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[ComplaintsApi] POST /complaints failed: status=${e.response?.statusCode}, data=${e.response?.data}');
      final errBody = e.response?.data;
      String? errMsg;
      if (errBody is Map<String, dynamic>) {
        errMsg = errBody['error']?.toString() ?? errBody['message']?.toString();
      }
      return ApiResponse(success: false, error: errMsg ?? '접수 실패 (${e.response?.statusCode ?? 'network error'})');
    }
  }
}

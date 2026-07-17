import 'package:dio/dio.dart';

import 'api_client.dart';

/// 앱 오류를 백엔드 관리자 페이지(/app-errors)로 전송
class ErrorReportsApi {
  ErrorReportsApi._();

  static const _path = '/error-reports';

  /// fire-and-forget — 실패해도 앱 흐름에 영향 없음
  static Future<void> report({
    required String message,
    StackTrace? stack,
    String? route,
    String? screen,
    String? source,
    bool fatal = false,
    String? platform,
    String? appVersion,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await ApiClient.post(_path, {
        'message': message.length > 8000 ? message.substring(0, 8000) : message,
        if (stack != null)
          'stack': stack.toString().length > 16000
              ? stack.toString().substring(0, 16000)
              : stack.toString(),
        if (route != null) 'route': route,
        if (screen != null) 'screen': screen,
        'source': source ?? 'flutter',
        'fatal': fatal,
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
        if (metadata != null) 'metadata': metadata,
      });
    } on DioException {
      // ignore — reporting must not break the app
    } catch (_) {
      // ignore
    }
  }
}

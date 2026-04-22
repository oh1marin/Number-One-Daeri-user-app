import 'package:connect_secure/connect_secure.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';

class ApiClient {
  ApiClient._();

  static late final Dio _dio;
  static bool _loggedBaseUrl = false;

  static Dio get dio => _dio;

  /// refresh 실패 시 호출 (로그인 화면 이동 등)
  static void Function()? onAuthRequired;

  static bool _isRefreshRequest(RequestOptions opts) {
    final path = opts.uri.path;
    return path.contains('auth/refresh') || path.contains('/refresh');
  }

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    if (!_loggedBaseUrl) {
      _loggedBaseUrl = true;
      // debugPrint는 release에서 출력이 제한될 수 있어 print 사용
      // ignore: avoid_print
      print('[ApiClient] baseUrl=${_dio.options.baseUrl}');
    }

    // Release 모드 + 인증서 핀닝 설정 시 MITM 방지
    if (kReleaseMode) {
      final pin = dotenv.env['API_CERT_PIN']?.trim();
      if (pin != null && pin.isNotEmpty) {
        final host = Uri.tryParse(apiBaseUrl)?.host;
        final byHost = (host != null && host.isNotEmpty)
            ? <String, List<String>>{host: [pin]}
            : <String, List<String>>{};
        _dio.httpClientAdapter = DioSslPinning(
          allowedFingerprints: [pin],
          fingerprintsByHost: byHost,
        );
      }
    }

    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          // ignore: avoid_print
          print(
            '[ApiClient] error status=$status url=${error.requestOptions.uri} msg=${error.message}',
          );
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          // refresh 요청이 401이면 재시도 금지 → 즉시 실패
          if (_isRefreshRequest(error.requestOptions)) {
            debugPrint('[ApiClient] refresh 401 → 토큰 삭제, 로그인 필요');
            await AuthService.logout();
            onAuthRequired?.call();
            return handler.next(error);
          }

          try {
            final refreshed = await AuthService.refreshToken();
            if (refreshed) {
              final token = await AuthService.getAccessToken();
              if (token != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            }
          } catch (_) {
            debugPrint('[ApiClient] refresh 실패');
          }

          // refresh 실패 → 토큰 삭제, 에러 전파
          await AuthService.logout();
          onAuthRequired?.call();
          return handler.next(error);
        },
      ),
    );
  }

  static void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  static Future<Response<T>> post<T>(String path, [dynamic data]) =>
      _dio.post<T>(path, data: data);

  static Future<Response<T>> postWithHeaders<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );

  static Future<Response<T>> put<T>(String path, [dynamic data]) =>
      _dio.put<T>(path, data: data);

  static Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  static Future<Response<T>> deleteWithBody<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );
}

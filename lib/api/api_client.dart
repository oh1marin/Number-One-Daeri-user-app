import 'package:connect_secure/connect_secure.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/api_config.dart';
import '../services/app_quality_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class ApiClient {
  ApiClient._();

  static late final Dio _dio;
  static bool _loggedBaseUrl = false;

  static Dio get dio => _dio;

  /// refresh 실패 시 호출 (로그인 화면 이동 등)
  static void Function()? onAuthRequired;

  /// logout/계정삭제 중 401 재시도·재귀 logout 방지
  static bool suppressAuthRecovery = false;

  static Future<bool>? _refreshFuture;

  static bool _isRefreshRequest(RequestOptions opts) {
    final path = opts.uri.path;
    return path.contains('auth/refresh') || path.contains('/refresh');
  }

  static bool _isAuthPhoneRequest(RequestOptions opts) {
    final path = opts.uri.path;
    return path.contains('auth/phone');
  }

  static Future<void> _handleSessionInvalid({
    required bool accountDeleted,
  }) async {
    await SessionService.handleUnauthorized(accountDeleted: accountDeleted);
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
      // ignore: avoid_print
      print('[ApiClient] baseUrl=${_dio.options.baseUrl}');
    }

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

          if (SessionService.isAuthInvalid && (status == 401 || status == 403)) {
            return handler.next(error);
          }

          final accountDeleted =
              SessionService.errorIndicatesAccountDeleted(error);

          if (!suppressAuthRecovery && accountDeleted) {
            await _handleSessionInvalid(accountDeleted: true);
            return handler.next(error);
          }

          if (status != 401) {
            if (status != null && status >= 500) {
              AppQualityService.logNonFatal(
                'API $status ${error.requestOptions.method} ${error.requestOptions.uri}',
                error.stackTrace,
                error.requestOptions.uri.path,
              );
            }
            return handler.next(error);
          }

          if (suppressAuthRecovery || _isAuthPhoneRequest(error.requestOptions)) {
            return handler.next(error);
          }

          if (_isRefreshRequest(error.requestOptions)) {
            debugPrint('[ApiClient] refresh 401 → 세션 삭제');
            await _handleSessionInvalid(accountDeleted: accountDeleted);
            return handler.next(error);
          }

          try {
            final refreshed = await _refreshOnce();
            if (refreshed) {
              final token = await AuthService.getAccessToken();
              if (token != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            }
          } catch (_) {
            debugPrint('[ApiClient] refresh 실패');
          }

          await _handleSessionInvalid(accountDeleted: accountDeleted);
          return handler.next(error);
        },
      ),
    );
  }

  static Future<bool> _refreshOnce() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = AuthService.refreshToken();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
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
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        options: Options(
          headers: headers,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
        ),
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

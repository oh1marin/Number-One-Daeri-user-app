import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/admin.dart';
import '../models/api_response.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthApi {
  static const _base = '/auth';

  static Future<ApiResponse<AuthResponse>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await ApiClient.post('$_base/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => AuthResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('$_base/login', {
      'email': email,
      'password': password,
    });
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => AuthResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> refresh(String refreshToken) async {
    final res = await ApiClient.post('$_base/refresh', {
      'refreshToken': refreshToken,
    });
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d as Map<String, dynamic>,
    );
  }

  /// 전화번호로 SMS 인증번호 발송
  static Future<ApiResponse<Map<String, dynamic>>> sendPhoneOtp({
    required String phone,
  }) async {
    final phoneClean = phone.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('[AuthApi] sendPhoneOtp phone=$phoneClean');
    final res = await ApiClient.post('$_base/phone/send', {
      'phone': phoneClean,
    });
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d as Map<String, dynamic>,
    );
  }

  /// OTP 검증 + 로그인/회원가입
  /// Response: { success, data?: { accessToken, refreshToken }, accessToken?, refreshToken? }
  static Future<ApiResponse<Map<String, dynamic>>> verifyPhoneOtp({
    required String phone,
    required String code,
  }) async {
    final res = await ApiClient.post('$_base/phone/verify', {
      'phone': phone.replaceAll(RegExp(r'[^\d]'), ''),
      'code': code,
    });
    final map = res.data as Map<String, dynamic>? ?? {};
    final data = map['data'] as Map<String, dynamic>? ?? map;
    return ApiResponse(
      success: map['success'] as bool? ?? false,
      data: data,
      error: map['error'] as String?,
    );
  }

  /// 백엔드 연결 테스트 (connect-test)
  /// Returns (success, message) for debugging
  static Future<(bool, String)> testConnection() async {
    try {
      final res = await ApiClient.get('connect-test');
      if (res.statusCode == 200) {
        return (true, '연동됨');
      }
      return (false, 'HTTP ${res.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return (false, '연결 불가 (서버 확인/실기기는 PC IP로 변경)');
      }
      if (e.response != null) {
        return (false, 'HTTP ${e.response?.statusCode}');
      }
      return (false, e.message ?? '${e.type}');
    } catch (e) {
      return (false, e.toString());
    }
  }

  static Future<ApiResponse<Admin>> me() async {
    final res = await ApiClient.get('$_base/me');
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => Admin.fromJson(d as Map<String, dynamic>),
    );
  }
}

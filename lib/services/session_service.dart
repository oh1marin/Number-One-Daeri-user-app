import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';

import '../api/ads_api.dart';
import '../api/api_client.dart';
import '../api/events_api.dart';
import '../routes/navigation.dart';
import '../utils/mileage_balance_cache.dart';
import 'local_data_wipe.dart';
import 'onboarding_service.dart';
import 'push_notification_service.dart';
import 'token_storage.dart';

/// 로그아웃·탈퇴·401/ACCOUNT_DELETED 시 로컬 세션 정리 및 화면 이동.
class SessionService {
  SessionService._();

  static bool _clearing = false;
  static bool _redirectPending = false;
  static bool _authInvalid = false;
  static bool _handlingUnauthorized = false;

  /// 로그아웃·탈퇴·401 처리 직후 — 연쇄 401 스낵바/리다이렉트 억제
  static bool get isAuthInvalid => _authInvalid;

  static bool shouldSuppressAuthError(int? status) {
    if (!_authInvalid) return false;
    return status == 401 || status == 403;
  }

  static void markAuthValid() {
    _authInvalid = false;
    _handlingUnauthorized = false;
  }

  static void markAuthInvalid() {
    _authInvalid = true;
  }

  /// 401/탈퇴 계정 — 한 번만 세션 정리 + 화면 이동
  static Future<void> handleUnauthorized({required bool accountDeleted}) async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    markAuthInvalid();
    ApiClient.suppressAuthRecovery = true;
    try {
      if (accountDeleted) {
        await wipeAllLocalData(navigateToOnboarding: true);
      } else {
        await clearSession(navigateToLogin: true);
      }
    } finally {
      Future<void>.delayed(const Duration(seconds: 2), () {
        ApiClient.suppressAuthRecovery = false;
        _handlingUnauthorized = false;
      });
    }
  }

  static bool responseIndicatesAccountDeleted(Response<dynamic>? response) {
    if (response == null) return false;
    return _payloadIndicatesAccountDeleted(response.data) ||
        _headerIndicatesAccountDeleted(response.headers.map);
  }

  static bool errorIndicatesAccountDeleted(DioException error) {
    if (responseIndicatesAccountDeleted(error.response)) return true;
    final status = error.response?.statusCode;
    return status == 410 &&
        _payloadIndicatesAccountDeleted(error.response?.data);
  }

  static bool shouldTreatDeleteAsSuccess(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403 || status == 404) return true;
    return errorIndicatesAccountDeleted(e);
  }

  static bool _payloadIndicatesAccountDeleted(dynamic data) {
    if (data == null) return false;
    if (data is String) {
      return data.toUpperCase().contains('ACCOUNT_DELETED');
    }
    if (data is Map) {
      for (final key in ['code', 'errorCode', 'error', 'message', 'detail']) {
        final v = data[key];
        if (v != null &&
            v.toString().toUpperCase().contains('ACCOUNT_DELETED')) {
          return true;
        }
      }
      final nested = data['data'];
      if (nested is Map) return _payloadIndicatesAccountDeleted(nested);
    }
    return false;
  }

  static bool _headerIndicatesAccountDeleted(Map<String, List<String>> headers) {
    for (final entry in headers.entries) {
      final name = entry.key.toLowerCase();
      if (!name.contains('account') && name != 'x-error-code') continue;
      for (final v in entry.value) {
        if (v.toUpperCase().contains('ACCOUNT_DELETED')) return true;
      }
    }
    return false;
  }

  /// 일반 로그아웃·401 — 토큰만 삭제 (설정·온보딩·이미지 캐시는 유지).
  static Future<void> clearSession({
    bool resetOnboarding = false,
    bool navigateToLogin = true,
  }) async {
    if (_clearing) {
      if (navigateToLogin) scheduleLoginRedirect();
      return;
    }
    _clearing = true;
    markAuthInvalid();
    ApiClient.suppressAuthRecovery = true;
    try {
      await TokenStorage.clear();
      ApiClient.setToken(null);
      MileageBalanceCache.invalidate();
      EventsApi.invalidateCache();
      AdsApi.invalidateCache();
      if (resetOnboarding) {
        await OnboardingService.resetOnboarding();
      }
      unawaited(_deletePushTokenBestEffort());
    } finally {
      if (!_authInvalid) {
        ApiClient.suppressAuthRecovery = false;
      }
      _clearing = false;
    }
    if (navigateToLogin) {
      scheduleLoginRedirect();
    }
  }

  /// 계정 삭제 — 재설치와 같이 로컬 전부 삭제 후 첫 화면(권한)으로.
  static Future<void> wipeAllLocalData({
    bool navigateToOnboarding = true,
  }) async {
    if (_clearing) {
      if (navigateToOnboarding) scheduleOnboardingRedirect();
      return;
    }
    _clearing = true;
    markAuthInvalid();
    ApiClient.suppressAuthRecovery = true;
    try {
      await LocalDataWipe.wipeAll();
      ApiClient.setToken(null);
      unawaited(_deletePushTokenBestEffort());
    } finally {
      if (!_authInvalid) {
        ApiClient.suppressAuthRecovery = false;
      }
      _clearing = false;
    }
    if (navigateToOnboarding) {
      scheduleOnboardingRedirect();
    }
  }

  static Future<void> forceReLogin({bool accountDeleted = false}) async {
    if (accountDeleted) {
      await wipeAllLocalData();
      return;
    }
    await clearSession(navigateToLogin: true);
  }

  static Future<void> _deletePushTokenBestEffort() async {
    try {
      await PushNotificationService.deleteTokenFromBackend()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static void scheduleLoginRedirect() {
    _scheduleRedirect('/logged-out');
  }

  static void scheduleOnboardingRedirect() {
    _scheduleRedirect('/permission');
  }

  static void _scheduleRedirect(String route) {
    if (_redirectPending) return;
    _redirectPending = true;

    void attempt() {
      final nav = navigatorKey.currentState;
      if (nav == null) {
        Future.delayed(const Duration(milliseconds: 80), attempt);
        return;
      }
      _redirectPending = false;
      nav.pushNamedAndRemoveUntil(route, (route) => false);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) => attempt());
  }
}

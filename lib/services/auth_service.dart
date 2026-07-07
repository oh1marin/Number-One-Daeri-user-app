import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/admin.dart';
import 'push_notification_service.dart';
import 'session_service.dart';
import 'token_storage.dart';

class AuthService {
  static Future<String?> getAccessToken() => TokenStorage.getAccessToken();

  static Future<bool> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;
    final res = await AuthApi.refresh(refreshToken);
    if (res.success && res.data != null) {
      final newAccess = res.data!['accessToken'] as String?;
      if (newAccess != null) {
        await TokenStorage.saveAccessToken(newAccess);
        ApiClient.setToken(newAccess);
        return true;
      }
    }
    await TokenStorage.clear();
    return false;
  }

  static Future<Admin?> getMe() async {
    final res = await AuthApi.me();
    return res.success ? res.data : null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout({bool navigateToLoggedOut = true}) async {
    SessionService.markAuthInvalid();
    ApiClient.suppressAuthRecovery = true;
    try {
      await SessionService.clearSession(navigateToLogin: false);
      if (navigateToLoggedOut) {
        SessionService.scheduleLoginRedirect();
      }
    } finally {
      Future<void>.delayed(const Duration(seconds: 2), () {
        ApiClient.suppressAuthRecovery = false;
      });
    }
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    SessionService.markAuthValid();
    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    ApiClient.setToken(accessToken);
    try {
      await PushNotificationService.syncTokenToBackend();
    } catch (_) {}
  }
}

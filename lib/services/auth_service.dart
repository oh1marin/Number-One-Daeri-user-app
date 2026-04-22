import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/admin.dart';
import 'push_notification_service.dart';
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

  static Future<void> logout() async {
    // best-effort: unregister token mapping for this user
    try {
      await PushNotificationService.deleteTokenFromBackend();
    } catch (_) {}
    await TokenStorage.clear();
    ApiClient.setToken(null);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    ApiClient.setToken(accessToken);
    // best-effort: register current device token to this user
    try {
      await PushNotificationService.syncTokenToBackend();
    } catch (_) {}
  }
}

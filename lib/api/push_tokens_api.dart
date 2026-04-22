import 'api_client.dart';

class PushTokensApi {
  PushTokensApi._();

  static const _base = '/push-tokens';

  static Future<Map<String, dynamic>?> upsert({
    required String token,
    String platform = 'android',
  }) async {
    final res = await ApiClient.post(
      _base,
      {
        'token': token,
        'platform': platform,
      },
    );
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> delete({required String token}) async {
    await ApiClient.deleteWithBody(_base, data: {'token': token});
  }
}


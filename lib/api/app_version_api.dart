import 'api_client.dart';

class AppVersionPolicy {
  const AppVersionPolicy({
    required this.targetBuildNumber,
    required this.forceUpdate,
    required this.message,
    required this.storeUrlAndroid,
  });

  /// Play Store `versionCode`와 동일한 값
  final int targetBuildNumber;

  /// true = 필수(닫기 불가), false = 권장(나중에 가능)
  final bool forceUpdate;
  final String message;
  final String storeUrlAndroid;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      final s = (v as String?)?.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    // 구 API(min/latest) 호환
    final legacyMin = parseInt(json['minBuildNumber']);
    final legacyLatest = parseInt(json['latestBuildNumber']);
    var target = parseInt(json['targetBuildNumber']);
    if (target <= 0) {
      target = legacyMin > 0 ? legacyMin : legacyLatest;
    }

    var force = json.containsKey('forceUpdate')
        ? parseBool(json['forceUpdate'])
        : legacyMin > 0 && legacyMin >= legacyLatest;

    return AppVersionPolicy(
      targetBuildNumber: target,
      forceUpdate: force,
      message: (json['message'] as String?)?.trim().isNotEmpty == true
          ? json['message'] as String
          : '새 버전이 있습니다. 스토어에서 업데이트해 주세요.',
      storeUrlAndroid:
          (json['storeUrlAndroid'] as String?)?.trim().isNotEmpty == true
              ? json['storeUrlAndroid'] as String
              : '',
    );
  }
}

class AppVersionApi {
  static const _path = 'app-version';

  static AppVersionPolicy? _fromPayload(dynamic data) {
    if (data is! Map) return null;
    final root = Map<String, dynamic>.from(data);
    final inner = root['data'];
    if (inner is Map) {
      return AppVersionPolicy.fromJson(Map<String, dynamic>.from(inner));
    }
    return AppVersionPolicy.fromJson(root);
  }

  static Future<AppVersionPolicy?> fetchPolicy() async {
    try {
      final res = await ApiClient.get(_path);
      return _fromPayload(res.data);
    } catch (_) {
      return null;
    }
  }
}

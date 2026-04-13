import 'api_config.dart';

/// 백엔드가 전체 https URL을 주면 그대로 사용하고, 상대 경로면 API 호스트 기준으로 붙입니다.
String? resolveMediaUrl(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  return Uri.parse(apiBaseUrl).resolve(s).toString();
}

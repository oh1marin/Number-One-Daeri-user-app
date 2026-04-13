import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 카카오맵 네이티브 앱 키
/// https://developers.kakao.com/console/app → 플랫폼 키 → 네이티브 앱 키 추가
///
/// 우선순위: --dart-define > .env
String get kakaoMapApiKey {
  const k = 'KAKAO_MAP_API_KEY';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

/// 카카오 로컬 API (주소/장소 검색) - REST API 키
/// 개발자콘솔 > 앱 > 앱 키 > REST API 키
String get kakaoRestApiKey {
  const k = 'KAKAO_REST_API_KEY';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

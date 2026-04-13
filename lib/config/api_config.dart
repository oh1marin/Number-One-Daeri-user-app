import 'package:flutter/foundation.dart';

/// 빌드 시 오버라이드 (`flutter-sideload-api-base-url.md` 참고):
/// `--dart-define=API_BASE_URL=https://<도메인>/api/v1/`
/// 끝 슬래시가 없으면 자동으로 붙입니다.
const String _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

/// Release 기본 플레이스홀더 (저장소에는 실제 운영 호스트를 넣지 않음).
/// 실제 배포 빌드는 `--dart-define=API_BASE_URL=...` 로 운영 URL을 넘기는 것을 권장.
const String _releaseDefaultApiBase =
    'https://your-api-host.invalid/api/v1/';

String _normalizeApiBaseUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  return t.endsWith('/') ? t : '$t/';
}

/// 공개 API 베이스 URL — 백엔드는 보통 `/api/v1` 아래에 마운트.
///
/// 우선순위:
/// 1. `API_BASE_URL` dart-define
/// 2. Release → [_releaseDefaultApiBase], Debug → 로컬
///    (USB 실기기는 `adb reverse tcp:5174 tcp:5174`)
String get apiBaseUrl {
  final fromEnv = _normalizeApiBaseUrl(_apiBaseUrlFromEnv);
  if (fromEnv.isNotEmpty) return fromEnv;
  return kReleaseMode
      ? _releaseDefaultApiBase
      : 'http://127.0.0.1:5174/api/v1/';
}

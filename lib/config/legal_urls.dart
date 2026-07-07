import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 약관·정책 웹 URL (온보딩 약관 항목과 동일 페이지)
class LegalUrls {
  LegalUrls._();

  /// 일등대리 공식 웹 (개인정보: /privacy)
  static const _defaultWeb = 'https://www.xn--vk1bv0b35gbnr.kr';

  static String get webBase {
    final fromEnv = dotenv.env['WEB_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return _defaultWeb;
  }

  static String _resolve(String envKey, String path) {
    final override = dotenv.env[envKey]?.trim();
    if (override != null && override.isNotEmpty) return override;
    final base = webBase.endsWith('/') ? webBase.substring(0, webBase.length - 1) : webBase;
    return '$base$path';
  }

  static String get serviceTerms => _resolve('LEGAL_SERVICE_TERMS_URL', '/terms');
  static String get privacy => _resolve('LEGAL_PRIVACY_URL', '/privacy');
  /// 별도 페이지 없음 — 개인정보처리방침 내 위치정보 항목과 동일 문서
  static String get location => _resolve('LEGAL_LOCATION_TERMS_URL', '/privacy');
}

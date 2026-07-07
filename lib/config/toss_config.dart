import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 토스페이먼츠 앱 스킴 (카카오페이·토스페이·빌링 인증 외부앱 복귀)
const String tossAppScheme = 'numberonedarri://';

/// WebView URL scheme 가로채기용 (콜론·슬래시 없음)
const String tossAppSchemeHost = 'numberonedarri';

bool isTossApiClientKey(String key) {
  final k = key.trim();
  return k.startsWith('test_ck_') || k.startsWith('live_ck_');
}

String tossBillingKeySetupMessage() {
  return tossBillingContractRequiredMessage;
}

/// 사용자 안내 — 빌링(등록 카드·자동결제) 미계약
const String tossBillingContractRequiredMessage =
    '카드 자동결제(빌링)는 아직 계약되지 않았습니다.\n'
    '토스페이먼츠 자동결제 계약 후 이용할 수 있습니다. (1544-7772)';

/// 결제위젯 연동 클라이언트 키 — test_gck_ / live_gck_
String get tossWidgetClientKeyFallback {
  const widgetKey = 'TOSS_WIDGET_CLIENT_KEY';
  final fromDefine = String.fromEnvironment(widgetKey, defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine;

  final fromEnv = dotenv.env[widgetKey]?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  const legacyKey = 'TOSS_CLIENT_KEY';
  final legacyDefine = String.fromEnvironment(legacyKey, defaultValue: '');
  final legacy = legacyDefine.isNotEmpty
      ? legacyDefine
      : (dotenv.env[legacyKey]?.trim() ?? '');
  if (isTossWidgetClientKey(legacy)) return legacy;
  return '';
}

bool isTossWidgetClientKey(String key) {
  final k = key.trim();
  return k.startsWith('test_gck_') || k.startsWith('live_gck_');
}

bool isTossWidgetSecretKey(String key) {
  final k = key.trim();
  return k.startsWith('test_gsk_') || k.startsWith('live_gsk_');
}

String tossWidgetKeySetupMessage() {
  final legacyClient = dotenv.env['TOSS_CLIENT_KEY']?.trim() ?? '';
  if (legacyClient.isNotEmpty && !isTossWidgetClientKey(legacyClient)) {
    return '결제위젯 연동 키가 필요합니다.\n\n'
        '• 앱(클라이언트): TOSS_WIDGET_CLIENT_KEY=test_gck_...\n'
        '• 서버(승인): TOSS_WIDGET_SECRET_KEY=test_gsk_...\n\n'
        'test_ck_/test_sk_ 는 결제창용이며 위젯에는 사용할 수 없습니다.\n'
        '(토스 샘플: github.com/tosspayments/tosspayments-sample/express-javascript)';
  }
  return '결제위젯 키를 설정해 주세요.\n\n'
      '• TOSS_WIDGET_CLIENT_KEY=test_gck_...\n'
      '• TOSS_WIDGET_SECRET_KEY=test_gsk_... (서버 env)';
}

/// @deprecated [tossWidgetClientKeyFallback] 사용
String get tossClientKeyFallback => tossWidgetClientKeyFallback;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// PortOne PG 설정
/// - storeId: PortOne 콘솔 Store 설정에서 확인
/// - channelKey: 채널 설정에서 발급
///
/// 우선순위: --dart-define > .env
String get portoneStoreId {
  const k = 'PORTONE_STORE_ID';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

String get portoneChannelKey {
  const k = 'PORTONE_CHANNEL_KEY';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

/// 카카오페이 채널
String get portoneChannelKeyKakaopay {
  const k = 'PORTONE_CHANNEL_KEY_KAKAOPAY';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

const String portoneAppScheme = 'numberonedarri';

String get portoneClientKey {
  const k = 'PORTONE_CLIENT_KEY';
  final d = String.fromEnvironment(k, defaultValue: '');
  return d.isNotEmpty ? d : (dotenv.env[k] ?? '');
}

/// Secret Key는 서버 전용 - 클라이언트에서는 사용하지 마세요

/// 테스트 채널 사용 (100원 인증 등 — 테스트 카드로 결제 가능)
bool get portoneUseTestChannel {
  const k = 'PORTONE_USE_TEST_CHANNEL';
  final d = String.fromEnvironment(k, defaultValue: '');
  final v = d.isNotEmpty ? d : (dotenv.env[k] ?? '');
  return v.toLowerCase() == 'true' || v == '1';
}

bool get isPortoneConfigured =>
    portoneStoreId.isNotEmpty && portoneChannelKey.isNotEmpty;

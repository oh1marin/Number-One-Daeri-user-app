import 'dart:math';

/// Generate a stable-length idempotency key / clientCallId without extra deps.
///
/// - 128자 제한을 피하기 위해 UUIDv4(36자) 형식으로 생성합니다.
String generateIdempotencyKey() => _uuidV4();

/// Client-side call id for POST /rides/call idempotency.
String generateClientCallId() => _uuidV4();

String _uuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

  // RFC 4122 version 4
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int v) => v.toRadixString(16).padLeft(2, '0');
  final b = bytes.map(hex).toList(growable: false);
  return '${b.sublist(0, 4).join()}-'
      '${b.sublist(4, 6).join()}-'
      '${b.sublist(6, 8).join()}-'
      '${b.sublist(8, 10).join()}-'
      '${b.sublist(10, 16).join()}';
}


import '../api/mileage_api.dart';

/// 홈 등에서 마일리지 잔액 API 호출을 줄이기 위한 짧은 TTL 캐시.
class MileageBalanceCache {
  MileageBalanceCache._();

  static const _ttl = Duration(seconds: 30);

  static MileageBalance? _balance;
  static DateTime? _fetchedAt;

  static bool get isFresh {
    final at = _fetchedAt;
    if (_balance == null || at == null) return false;
    return DateTime.now().difference(at) < _ttl;
  }

  static MileageBalance? get cached => isFresh ? _balance : null;

  static Future<MileageBalance> getBalance({bool force = false}) async {
    if (!force) {
      final hit = cached;
      if (hit != null) return hit;
    }
    final bal = await MileageApi.getBalance();
    _balance = bal;
    _fetchedAt = DateTime.now();
    return bal;
  }

  static void invalidate() {
    _balance = null;
    _fetchedAt = null;
  }
}

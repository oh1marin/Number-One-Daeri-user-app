import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ads_api.dart';
import '../api/events_api.dart';
import '../utils/mileage_balance_cache.dart';
import 'token_storage.dart';

/// 계정 삭제 시 재설치와 같이 로컬 데이터 전부 삭제.
class LocalDataWipe {
  LocalDataWipe._();

  static Future<void> wipeAll() async {
    await Future.wait([
      TokenStorage.deleteAll(),
      _clearSharedPreferences(),
      _clearImageDiskCache(),
    ]);
    MileageBalanceCache.invalidate();
    EventsApi.invalidateCache();
    AdsApi.invalidateCache();
  }

  static Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> _clearImageDiskCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }
}

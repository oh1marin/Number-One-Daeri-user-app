import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/gifticon.dart';

/// 로컬 주문 내역 (API 미연동·데모·오프라인 복구용)
class GifticonOrderStore {
  GifticonOrderStore._();

  static const _key = 'gifticon_orders_v1';

  static Future<List<GifticonOrder>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return GifticonOrder.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<GifticonOrder>()
        .toList()
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
  }

  static Future<void> saveOrder(GifticonOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.insert(0, jsonEncode(order.toJson()));
    await prefs.setStringList(_key, list.take(50).toList());
  }

  static String generatePin() {
    final r = Random.secure();
    return List.generate(4, (_) => r.nextInt(10)).join();
  }

  static String generateBarcode() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(10)).join();
  }

  static String maskPhone(String? phone) {
    if (phone == null || phone.length < 8) return '010-****-****';
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) return '010-****-****';
    return '${digits.substring(0, 3)}-****-${digits.substring(digits.length - 4)}';
  }
}

import '../models/driver.dart';
import '../models/ride.dart';
import 'api_client.dart';

class DriversApi {
  static const _base = '/drivers';

  static Future<List<Driver>> list() async {
    final res = await ApiClient.get(_base);
    final map = res.data as Map<String, dynamic>?;
    final list = map?['data'] as List? ?? map as List? ?? [];
    return list.map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Driver?> get(String id) async {
    final res = await ApiClient.get('$_base/$id');
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] ?? map;
    return data != null ? Driver.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<List<Ride>> getRides(String id) async {
    final res = await ApiClient.get('$_base/$id/rides');
    final map = res.data as Map<String, dynamic>?;
    final raw = map?['data'];
    final list = raw is List ? raw : <dynamic>[];
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Driver?> create(Map<String, dynamic> body) async {
    final res = await ApiClient.post(_base, body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'];
    return data != null ? Driver.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<Driver?> update(String id, Map<String, dynamic> body) async {
    final res = await ApiClient.put('$_base/$id', body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'];
    return data != null ? Driver.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<void> delete(String id) => ApiClient.delete('$_base/$id');
}

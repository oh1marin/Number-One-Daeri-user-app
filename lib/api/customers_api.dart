import '../models/customer.dart';
import '../models/ride.dart';
import 'api_client.dart';

class CustomersApi {
  static const _base = '/customers';

  static Future<List<Customer>> list({String? field, String? q}) async {
    final params = <String, dynamic>{};
    if (field != null) params['field'] = field;
    if (q != null) params['q'] = q;
    final res = await ApiClient.get(_base, queryParameters: params.isEmpty ? null : params);
    final map = res.data as Map<String, dynamic>?;
    final raw = map?['data'];
    final list = raw is List ? raw : <dynamic>[];
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Customer?> get(String id) async {
    final res = await ApiClient.get('$_base/$id');
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] ?? map;
    return data != null ? Customer.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<List<Ride>> getRides(String id) async {
    final res = await ApiClient.get('$_base/$id/rides');
    final map = res.data as Map<String, dynamic>?;
    final raw = map?['data'];
    final list = raw is List ? raw : <dynamic>[];
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Customer?> create(Map<String, dynamic> body) async {
    final res = await ApiClient.post(_base, body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'];
    return data != null ? Customer.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<Customer?> update(String id, Map<String, dynamic> body) async {
    final res = await ApiClient.put('$_base/$id', body);
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'];
    return data != null ? Customer.fromJson(data as Map<String, dynamic>) : null;
  }

  static Future<void> delete(String id) => ApiClient.delete('$_base/$id');
}

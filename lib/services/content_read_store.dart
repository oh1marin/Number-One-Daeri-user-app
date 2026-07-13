import 'package:shared_preferences/shared_preferences.dart';

/// 공지·이벤트 읽음 ID (로컬)
class ContentReadStore {
  ContentReadStore._();

  static const _noticeKey = 'read_notice_ids_v1';
  static const _eventKey = 'read_event_ids_v1';

  static Future<Set<String>> _readSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? const []).toSet();
  }

  static Future<void> _writeSet(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }

  static Future<void> markNoticeRead(String id) async {
    if (id.isEmpty) return;
    final set = await _readSet(_noticeKey);
    set.add(id);
    await _writeSet(_noticeKey, set);
  }

  static Future<void> markEventRead(String id) async {
    if (id.isEmpty) return;
    final set = await _readSet(_eventKey);
    set.add(id);
    await _writeSet(_eventKey, set);
  }

  static Future<Set<String>> noticeReadIds() => _readSet(_noticeKey);

  static Future<Set<String>> eventReadIds() => _readSet(_eventKey);

  static Future<bool> isNoticeRead(String id) async {
    if (id.isEmpty) return true;
    final read = await _readSet(_noticeKey);
    return read.contains(id);
  }

  static Future<bool> isEventRead(String id) async {
    if (id.isEmpty) return true;
    final read = await _readSet(_eventKey);
    return read.contains(id);
  }

  static Future<int> unreadNoticeCount(Iterable<String> ids) async {
    final read = await _readSet(_noticeKey);
    return ids.where((id) => id.isNotEmpty && !read.contains(id)).length;
  }

  static Future<int> unreadEventCount(Iterable<String> ids) async {
    final read = await _readSet(_eventKey);
    return ids.where((id) => id.isNotEmpty && !read.contains(id)).length;
  }

  static Future<int> totalUnread({
    required Iterable<String> noticeIds,
    required Iterable<String> eventIds,
  }) async {
    final n = await unreadNoticeCount(noticeIds);
    final e = await unreadEventCount(eventIds);
    return n + e;
  }
}

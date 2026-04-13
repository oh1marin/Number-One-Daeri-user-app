import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../api/admin_inquiry_api.dart';
import '../../theme/app_theme.dart';
import 'admin_chat_screen.dart';

/// 관리자 — 1:1 문의 목록
class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading = true;
  List<AdminInquiryItem> _all = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await AdminInquiryApi.getList(limit: 100);
      if (mounted) setState(() => _all = items);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<AdminInquiryItem> _filtered(String? status) {
    if (status == null) return _all;
    return _all.where((e) => e.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('1:1 문의'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.accentBlue,
          tabs: [
            Tab(text: '전체 (${_all.length})'),
            Tab(text: '미답변 (${_filtered('pending').length})'),
            Tab(text: '종료 (${_filtered('closed').length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _InquiryList(items: _all, onRefresh: _load),
                _InquiryList(items: _filtered('pending'), onRefresh: _load),
                _InquiryList(items: _filtered('closed'), onRefresh: _load),
              ],
            ),
    );
  }
}

class _InquiryList extends StatelessWidget {
  const _InquiryList({required this.items, required this.onRefresh});
  final List<AdminInquiryItem> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('문의가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (_, i) => _InquiryTile(item: items[i], onRefresh: onRefresh),
      ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({required this.item, required this.onRefresh});
  final AdminInquiryItem item;
  final Future<void> Function() onRefresh;

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  Color get _statusColor {
    switch (item.status) {
      case 'pending': return Colors.orange;
      case 'active': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case 'pending': return '미답변';
      case 'active': return '진행 중';
      case 'closed': return '종료';
      default: return item.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.hasUnread
            ? Border.all(color: AppTheme.accentBlue, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminChatScreen(inquiry: item),
            ),
          );
          onRefresh();
        },
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: AppTheme.primaryDark, size: 22),
            ),
            if (item.hasUnread)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      item.unreadCount > 9 ? '9+' : '${item.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.customerName ?? item.customerPhone,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                item.lastMessage ?? '내용 없음',
                style: TextStyle(
                  color: item.hasUnread ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: item.hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            Text(_formatTime(item.lastMessageAt),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

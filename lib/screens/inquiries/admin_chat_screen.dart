import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../api/admin_inquiry_api.dart';
import '../../api/inquiry_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

/// 관리자 — 고객과 1:1 채팅 (폴링 4초)
class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key, required this.inquiry});

  final AdminInquiryItem inquiry;

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<InquiryMessage> _messages = [];
  String? _lastId;
  bool _sending = false;
  bool _closing = false;
  Timer? _pollTimer;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.inquiry.status;
    _loadAll();
    if (!widget.inquiry.isClosed) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final msgs = await AdminInquiryApi.getMessages(widget.inquiry.id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        if (_messages.isNotEmpty) _lastId = _messages.last.id;
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _poll() async {
    if (_lastId == null) return;
    try {
      // afterId 기반 폴링은 고객 앱과 동일하게 전체 재조회로 단순화
      final msgs = await AdminInquiryApi.getMessages(widget.inquiry.id);
      if (!mounted) return;
      final existingIds = _messages.map((m) => m.id).toSet();
      final newMsgs = msgs.where((m) => !existingIds.contains(m.id)).toList();
      if (newMsgs.isEmpty) return;
      setState(() {
        _messages.addAll(newMsgs);
        _lastId = _messages.last.id;
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _send() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty || _sending || _status == 'closed') return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add(InquiryMessage(
      id: tempId, content: content, sender: 'admin',
      createdAt: DateTime.now().toIso8601String(),
    )));
    _scrollToBottom();

    try {
      final sent = await AdminInquiryApi.sendReply(widget.inquiry.id, content);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (sent != null) {
          if (idx != -1) _messages[idx] = sent;
          else _messages.add(sent);
          _lastId = _messages.last.id;
        } else {
          if (idx != -1) _messages.removeAt(idx);
        }
        _status = 'active';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == tempId));
        showErrorSnackBar(context, '전송 실패. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleClose() async {
    final isClose = _status != 'closed';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isClose ? '문의 종료' : '문의 재개'),
        content: Text(isClose
            ? '이 문의를 종료하면 고객이 더 이상 메시지를 보낼 수 없습니다.'
            : '이 문의를 다시 활성화합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isClose ? '종료' : '재개', style: TextStyle(color: isClose ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _closing = true);
    try {
      final newStatus = isClose ? 'closed' : 'active';
      await AdminInquiryApi.updateStatus(widget.inquiry.id, newStatus);
      if (!mounted) return;
      setState(() => _status = newStatus);
      if (isClose) _pollTimer?.cancel();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '상태 변경 실패');
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _status == 'closed';
    final customerLabel = widget.inquiry.customerName ?? widget.inquiry.customerPhone;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(widget.inquiry.customerPhone,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          _closing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _toggleClose,
                  child: Text(
                    isClosed ? '재개' : '종료',
                    style: TextStyle(color: isClosed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade100,
              child: Text('종료된 문의입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          Expanded(child: _buildMessageList()),
          _buildInputBar(isClosed),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text('메시지가 없습니다.', style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return msg.isFromAdmin
            ? _AdminBubble(message: msg, formatTime: _formatTime)
            : _CustomerBubble(message: msg, formatTime: _formatTime);
      },
    );
  }

  Widget _buildInputBar(bool disabled) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  enabled: !disabled && !_sending,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                  decoration: InputDecoration(
                    hintText: disabled ? '종료된 문의입니다.' : '답장 입력...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: (!disabled && !_sending) ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (!disabled && !_sending) ? AppTheme.primaryDark : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _sending
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(Icons.send_rounded,
                          color: (!disabled && !_sending) ? Colors.white : Colors.grey.shade400,
                          size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 말풍선 ────────────────────────────────────────────────────────────────────

/// 고객 메시지 (왼쪽)
class _CustomerBubble extends StatelessWidget {
  const _CustomerBubble({required this.message, required this.formatTime});
  final InquiryMessage message;
  final String Function(String?) formatTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const Gap(8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Text(message.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4),
                  child: Text(formatTime(message.createdAt),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 관리자 메시지 (오른쪽)
class _AdminBubble extends StatelessWidget {
  const _AdminBubble({required this.message, required this.formatTime});
  final InquiryMessage message;
  final String Function(String?) formatTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16),
                  ),
                  boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(message.content, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 4),
                child: Text(formatTime(message.createdAt),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ),
            ],
          ),
          const Gap(8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryDark,
            child: const Icon(Icons.support_agent, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/ai_chat_api.dart';
import '../../api/inquiry_api.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_loading_indicator.dart';

const String _kSupportPhone = '01021848822';

// ── 로컬 메시지 모델 ──────────────────────────────────────────────────────────

enum _MsgType { user, ai, admin }

class _Msg {
  _Msg({
    required this.id,
    required this.content,
    required this.type,
    required this.time,
    this.needsHandoff = false,
    this.isThinking = false,
    this.showAccidentButton = false,
  });

  final String id;
  final String content;
  final _MsgType type;
  final DateTime time;
  final bool needsHandoff;        // AI가 needs_human_handoff: true 일 때
  final bool isThinking;          // AI 답변 대기 중 (점 3개 애니메이션)
  final bool showAccidentButton;  // 사고/과태료 페이지 이동 버튼
}

/// AI 응답 텍스트에서 사고/과태료 관련 키워드를 감지
bool _detectAccidentKeywords(String text) {
  const keywords = [
    '사고', '교통사고', '과태료', '팩스', '031-247-1988',
    '사고 처리', '보험', '접촉사고', '차량사고',
  ];
  final lower = text;
  return keywords.any((k) => lower.contains(k));
}

// ── 화면 ─────────────────────────────────────────────────────────────────────

/// 고객 1:1 채팅
/// - 메시지 전송 → AI 즉시 자동응답 + 백엔드 저장
/// - 4초 폴링 → 관리자 직접 답장 수신
class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _msgCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  InquirySession? _session;
  final List<_Msg> _messages = [];

  /// 폴링 시 중복 방지용 — 백엔드에서 받은 메시지 id 세트
  final Set<String> _backendIds = {};

  bool _initializing    = true;
  bool _sending         = false;
  bool _loggedIn        = false;
  bool _closed          = false;
  bool _agentRequested  = false; // 상담사 호출 여부

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 초기화 ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    _loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    if (!_loggedIn) { setState(() => _initializing = false); return; }

    // 진입할 때마다 새 세션 생성 (이전 대화 초기화)
    final session = await InquiryApi.create();
    if (!mounted) return;
    if (session == null) {
      setState(() => _initializing = false);
      showErrorSnackBar(context, '채팅을 시작할 수 없습니다.');
      return;
    }

    _session = session;
    _closed  = session.isClosed;

    // 첫 인사
    _addLocal(_Msg(
      id: 'greeting',
      content: '안녕하세요! 일등대리 AI 상담원입니다 😊\n요금, 쿠폰, 마일리지 등 궁금한 점을 편하게 물어보세요.',
      type: _MsgType.ai,
      time: DateTime.now(),
    ));

    setState(() => _initializing = false);

    // 4초 폴링 시작 (관리자 답장 감지)
    if (!_closed) {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchAdminMessages());
    }
  }

  // ── 백엔드 관리자 메시지 폴링 ───────────────────────────────────────────────

  Future<void> _fetchAdminMessages({bool initial = false}) async {
    final id = _session?.id;
    if (id == null) return;
    try {
      final msgs = await InquiryApi.getMessages(id);
      if (!mounted) return;

      bool added = false;
      for (final m in msgs) {
        if (_backendIds.contains(m.id)) continue;
        _backendIds.add(m.id);

        // 관리자 메시지만 채팅에 추가 (user 메시지는 로컬에서 이미 표시 중)
        if (m.isFromAdmin) {
          // 폴링 중 새 관리자 답장이 도착할 때만 상담원 모드로 전환
          // (initial=true 초기 로드 시에는 AI 모드 유지)
          if (!initial && !_agentRequested) setState(() => _agentRequested = true);

          _addLocal(_Msg(
            id: m.id,
            content: m.content,
            type: _MsgType.admin,
            time: _parseTime(m.createdAt),
          ));
          added = true;
        }
      }
      if (added) _scrollToBottom();
    } catch (_) {}
  }

  // ── 상담사 호출 ──────────────────────────────────────────────────────────────

  void _onAgentRequested() {
    if (_agentRequested || !mounted) return;
    setState(() => _agentRequested = true);
    _addLocal(_Msg(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      content: '상담원 연결을 요청했습니다.\n잠시만 기다려 주세요.',
      type: _MsgType.admin,  // 시스템 메시지 스타일로
      time: DateTime.now(),
    ));
    _scrollToBottom();
  }

  // ── 전송 ────────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty || _sending || _session == null || _closed) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    // 1. 내 메시지 즉시 표시
    final userMsgId = 'u_${DateTime.now().millisecondsSinceEpoch}';
    _addLocal(_Msg(id: userMsgId, content: content, type: _MsgType.user, time: DateTime.now()));
    _scrollToBottom();

    // 2. AI 생각 중 표시
    const thinkingId = 'ai_thinking';
    _addLocal(_Msg(id: thinkingId, content: '', type: _MsgType.ai, time: DateTime.now(), isThinking: true));
    _scrollToBottom();

    // 3. 백엔드 저장 + AI 응답 동시 요청
    await Future.wait([
      _saveToBackend(content),
      _getAiReply(content, thinkingId),
    ]);

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _saveToBackend(String content) async {
    try {
      final sent = await InquiryApi.sendMessage(_session!.id, content);
      // 백엔드에서 받은 user 메시지 id를 등록 (폴링 중복 방지)
      if (sent != null) _backendIds.add(sent.id);
    } catch (_) {}
  }

  Future<void> _getAiReply(String content, String thinkingId) async {
    try {
      final reply = await AiChatApi.getReply(content);
      if (!mounted) return;

      // 생각 중 버블 제거 후 실제 응답 추가
      setState(() {
        _messages.removeWhere((m) => m.id == thinkingId);
        final replyText = reply?.replyText ??
            '문의해 주셔서 감사합니다. 상담원이 확인 후 빠르게 답변드리겠습니다.\n\n📞 영업시간: 평일 09:00~18:00';
        _messages.add(_Msg(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          content: replyText,
          type: _MsgType.ai,
          time: DateTime.now(),
          needsHandoff: reply?.needsHumanHandoff ?? false,
          showAccidentButton: _detectAccidentKeywords(replyText),
        ));
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _messages.removeWhere((m) => m.id == thinkingId));
    }
  }

  // ── 유틸 ────────────────────────────────────────────────────────────────────

  void _addLocal(_Msg msg) => setState(() => _messages.add(msg));

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

  DateTime _parseTime(String? iso) {
    if (iso == null) return DateTime.now();
    try { return DateTime.parse(iso).toLocal(); } catch (_) { return DateTime.now(); }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── 빌드 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _buildAppBar(),
      body: _initializing
          ? const Center(child: AppLoadingIndicator())
          : !_loggedIn
              ? _buildLoginRequired()
              : Column(
                  children: [
                    if (_closed) _ClosedBanner(),
                    Expanded(child: _buildList()),
                    _buildInput(),
                  ],
                ),
    );
  }

  AppBar _buildAppBar() {
    final isAgent = _agentRequested;
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // 아이콘: AI → 보라 그라데이션 / 상담원 → 다크 네이비
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: isAgent
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isAgent ? AppTheme.primaryDark : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isAgent ? Icons.support_agent : Icons.auto_awesome,
                color: Colors.white, size: 20,
              ),
            ),
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isAgent ? '상담원' : 'AI 상담원',
                  key: ValueKey(isAgent),
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87,
                  ),
                ),
              ),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _closed
                        ? Colors.grey
                        : isAgent
                            ? Colors.orange  // 상담원 연결 대기
                            : const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _closed ? '종료' : isAgent ? '연결 대기 중' : '온라인',
                    key: ValueKey('$_closed$isAgent'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text('메시지를 입력해 주세요.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final msg = _messages[i];
          return switch (msg.type) {
            _MsgType.user  => _UserBubble(msg: msg, fmt: _formatTime),
              _MsgType.ai    => _AiBubble(
                  msg: msg,
                  fmt: _formatTime,
                  session: _session,
                  onAgentRequested: _onAgentRequested,
                ),
            _MsgType.admin => _AdminBubble(msg: msg, fmt: _formatTime),
          };
        },
      ),
    );
  }

  Widget _buildInput() {
    final disabled = _closed || !_loggedIn;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, -2),
          )],
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
                  focusNode: _focusNode,
                  enabled: !disabled && !_sending,
                  minLines: 1, maxLines: 5,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: disabled ? '채팅이 종료되었습니다.' : '메시지 입력...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
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
                  gradient: (!disabled && !_sending)
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: (!disabled && !_sending) ? null : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(Icons.arrow_upward_rounded,
                          color: (!disabled && !_sending) ? Colors.white : Colors.grey.shade400,
                          size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.lockKey, size: 48, color: Colors.grey.shade300),
            const Gap(16),
            Text('로그인 후 이용 가능합니다.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          ],
        ),
      );
}

// ── 배너 ─────────────────────────────────────────────────────────────────────

class _ClosedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.grey.shade100,
        child: Text('종료된 대화입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      );
}

// ── 말풍선 ────────────────────────────────────────────────────────────────────

/// 내 메시지 (오른쪽, 파란색)
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.msg, required this.fmt});
  final _Msg msg;
  final String Function(DateTime) fmt;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18), topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    boxShadow: [BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Text(msg.content,
                      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(fmt(msg.time),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ),
              ],
            ),
            const Gap(8),
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, color: AppTheme.accentBlue, size: 20),
            ),
          ],
        ),
      );
}

/// AI 메시지 (왼쪽, 보라 그라데이션 아이콘)
class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.msg,
    required this.fmt,
    this.session,
    this.onAgentRequested,
  });
  final _Msg msg;
  final String Function(DateTime) fmt;
  final InquirySession? session;
  final VoidCallback? onAgentRequested;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // AI 아이콘
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 18)),
            ),
            const Gap(8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 + AI 뱃지
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(children: [
                      Text('AI 상담원',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Gap(5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AI',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),

                  // 말풍선 or 타이핑
                  msg.isThinking
                      ? _ThinkingBubble()
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8, offset: const Offset(0, 2),
                            )],
                          ),
                          child: Text(msg.content,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                        ),

                  // 전화 연결 + 상담사 호출 버튼 (needs_human_handoff)
                  if (!msg.isThinking && msg.needsHandoff) ...[
                    const Gap(8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CallButton(),
                        const Gap(8),
                        _RequestAgentButton(
                          session: session,
                          onRequested: onAgentRequested,
                        ),
                      ],
                    ),
                  ],

                  // 사고/과태료 페이지 이동 버튼
                  if (!msg.isThinking && msg.showAccidentButton) ...[
                    const Gap(8),
                    _AccidentPageButton(),
                  ],

                  if (!msg.isThinking)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(fmt(msg.time),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// 관리자 메시지 (왼쪽, 다크 네이비 아이콘)
class _AdminBubble extends StatelessWidget {
  const _AdminBubble({required this.msg, required this.fmt});
  final _Msg msg;
  final String Function(DateTime) fmt;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: const BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.support_agent, color: Colors.white, size: 18)),
            ),
            const Gap(8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(children: [
                      Text('상담원',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Gap(5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('직원',
                            style: TextStyle(fontSize: 9, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.15)),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Text(msg.content,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(fmt(msg.time),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── 타이핑 애니메이션 ─────────────────────────────────────────────────────────

class _ThinkingBubble extends StatefulWidget {
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with TickerProviderStateMixin {
  late final List<AnimationController> _ctls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(3, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));
    _anims = _ctls.map((c) =>
        Tween<double>(begin: 0, end: -8).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => AnimatedBuilder(
            animation: _anims[i],
            builder: (context, child) => Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Transform.translate(
                offset: Offset(0, _anims[i].value),
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          )),
        ),
      );
}

// ── 상담사 호출 버튼 (주황) ───────────────────────────────────────────────────

class _RequestAgentButton extends StatefulWidget {
  const _RequestAgentButton({this.session, this.onRequested});
  final InquirySession? session;
  final VoidCallback? onRequested;

  @override
  State<_RequestAgentButton> createState() => _RequestAgentButtonState();
}

class _RequestAgentButtonState extends State<_RequestAgentButton> {
  bool _requested = false;
  bool _loading   = false;

  Future<void> _request() async {
    if (_requested || _loading || widget.session == null) return;
    setState(() => _loading = true);
    try {
      await InquiryApi.sendMessage(
        widget.session!.id,
        '[상담사 호출 요청] 고객이 직접 상담을 요청했습니다.',
      );
      if (mounted) {
        setState(() => _requested = true);
        widget.onRequested?.call(); // 부모 State에 알림 → 앱바 전환
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요청에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _requested ? null : _request,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _requested ? Colors.orange.shade200 : null,
          gradient: _requested
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _requested
              ? []
              : [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: _loading
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _requested ? Icons.check_circle_outline : Icons.support_agent,
                    color: Colors.white,
                    size: 16,
                  ),
                  const Gap(6),
                  Text(
                    _requested ? '호출 완료' : '상담사 호출',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── 전화 연결 버튼 (초록) ─────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: _kSupportPhone);
          try { await launchUrl(uri); } catch (_) {}
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.35),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_rounded, color: Colors.white, size: 16),
              Gap(8),
              Text('전화 연결', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      );
}

// ── 사고/과태료 페이지 이동 버튼 ───────────────────────────────────────────

class _AccidentPageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/accident-penalty'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: Colors.red.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
            Gap(8),
            Text(
              '사고/과태료 안내 바로가기',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/ai_chat_api.dart';
import '../api/inquiry_api.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'app_loading_indicator.dart';

const String _kSupportPhone = '01021848822';

/// 1:1 문의 공통 폼 (AI 채팅 UI)
class InquiryForm extends StatefulWidget {
  const InquiryForm({
    super.key,
    required this.greeting,
    this.hintText = '메시지 입력...',
    this.successMessage = '접수되었습니다.',
  });

  final String greeting;
  final String hintText;
  final String successMessage;

  @override
  State<InquiryForm> createState() => _InquiryFormState();
}

class _InquiryFormState extends State<InquiryForm> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <_ChatMessage>[];
  bool _loggedIn = false;
  bool _sending = false;
  bool _aiThinking = false;

  @override
  void initState() {
    super.initState();
    _addMessage(_ChatMessage(
      isAgent: true,
      text: widget.greeting,
      time: _nowTime(),
      isAi: true,
    ));
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final ok = await AuthService.isLoggedIn();
    if (mounted) setState(() => _loggedIn = ok);
  }

  void _addMessage(_ChatMessage msg) {
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) return;

    if (!_loggedIn) {
      showInfoSnackBar(context, '로그인이 필요합니다.', title: '로그인');
      return;
    }

    setState(() => _sending = true);
    _controller.clear();

    _addMessage(_ChatMessage(isAgent: false, text: content, time: _nowTime()));

    try {
      await InquiryApi.create(content: content);
    } catch (_) {}

    if (mounted) setState(() => _aiThinking = true);
    _scrollToBottom();

    final aiReply = await AiChatApi.getReply(content);

    if (mounted) {
      setState(() => _aiThinking = false);
      _addMessage(_ChatMessage(
        isAgent: true,
        isAi: true,
        text: aiReply?.replyText ??
            '문의해 주셔서 감사합니다. 담당 상담원이 확인 후 빠르게 답변드리겠습니다.\n\n📞 영업시간: 평일 09:00~18:00',
        time: _nowTime(),
        showCallButton: aiReply?.needsHumanHandoff ?? false,
      ));
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 채팅 메시지 목록 ──────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: () => _focusNode.unfocus(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              itemCount: _messages.length + (_aiThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (_aiThinking && i == _messages.length) {
                  return _TypingIndicatorBubble();
                }
                return _AnimatedMessage(
                  key: ValueKey(_messages[i].hashCode),
                  child: _MessageBubble(message: _messages[i]),
                );
              },
            ),
          ),
        ),

        // ── 로그인 안내 ─────────────────────────────────────────────────
        if (!_loggedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.warningCircle,
                    color: Colors.amber.shade700, size: 16),
                const Gap(8),
                const Expanded(
                  child: Text('로그인 후 메시지를 보낼 수 있습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.black87)),
                ),
              ],
            ),
          ),

        // ── 입력창 ───────────────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 텍스트 입력 필드
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minHeight: 44, maxHeight: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: _loggedIn && !_sending,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _loggedIn ? widget.hintText : '로그인이 필요합니다.',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(8),

                // 전송 버튼
                GestureDetector(
                  onTap: (_loggedIn && !_sending) ? _send : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: (_loggedIn && !_sending)
                          ? const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: (_loggedIn && !_sending) ? null : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AppLoadingIndicator(size: 20),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: (_loggedIn && !_sending)
                                  ? Colors.white
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 메시지 입장 애니메이션 래퍼 ──────────────────────────────────────────────

class _AnimatedMessage extends StatefulWidget {
  const _AnimatedMessage({super.key, required this.child});
  final Widget child;

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
  }
}

// ── 메시지 모델 ───────────────────────────────────────────────────────────────

class _ChatMessage {
  _ChatMessage({
    required this.isAgent,
    required this.text,
    required this.time,
    this.isAi = false,
    this.showCallButton = false,
  });

  final bool isAgent;
  final bool isAi;
  final String text;
  final String time;

  /// true이면 버블 아래 "전화 연결" 버튼 표시
  final bool showCallButton;
}

// ── 메시지 버블 라우터 ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) =>
      message.isAgent ? _AgentBubble(message: message) : _UserBubble(message: message);
}

// ── 상담원/AI 버블 (왼쪽) ─────────────────────────────────────────────────────

class _AgentBubble extends StatelessWidget {
  const _AgentBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 아바타
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              gradient: message.isAi
                  ? const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: message.isAi ? null : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                message.isAi ? Icons.auto_awesome : Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Gap(10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 + AI 뱃지
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 5),
                  child: Row(
                    children: [
                      Text(
                        message.isAi ? 'AI 상담원' : '상담원',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (message.isAi) ...[
                        const Gap(5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 말풍선
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                ),
                // 시간
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4),
                  child: Text(
                    message.time,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),

                // 전화 연결 버튼 (needs_human_handoff == true)
                if (message.showCallButton) ...[
                  const Gap(10),
                  _CallButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 유저 버블 (오른쪽) ────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 말풍선
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                ),
              ),
              // 시간
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 4),
                child: Text(
                  message.time,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ),
            ],
          ),
          const Gap(10),
          // 아바타
          Container(
            width: 38,
            height: 38,
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
}

// ── AI 타이핑 표시기 (튀어오르는 점 3개) ─────────────────────────────────────

class _TypingIndicatorBubble extends StatefulWidget {
  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _ctls
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // 순차적으로 튀어오르기
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(bottom: 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 18)),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) => Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    child: Transform.translate(
                      offset: Offset(0, _anims[i].value),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 전화 연결 버튼 ────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: _kSupportPhone);
        try {
          await launchUrl(uri);
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_rounded, color: Colors.white, size: 16),
            Gap(8),
            Text(
              '전화 연결',
              style: TextStyle(
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

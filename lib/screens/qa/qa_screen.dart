import 'package:flutter/material.dart';

import 'live_chat_screen.dart';

/// 고객센터 1:1 문의 → LiveChatScreen으로 위임
class QaScreen extends StatelessWidget {
  const QaScreen({super.key});

  @override
  Widget build(BuildContext context) => const LiveChatScreen();
}

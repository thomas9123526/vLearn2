import 'package:flutter/material.dart';
import '../../shared/widgets/stub_screen.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => StubScreen(
        title: 'Conversation',
        section: '§05 Flutter screens',
        subtitle: 'Session: $sessionId',
      );
}

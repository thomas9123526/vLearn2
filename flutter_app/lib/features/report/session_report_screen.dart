import 'package:flutter/material.dart';
import '../../shared/widgets/stub_screen.dart';

class SessionReportScreen extends StatelessWidget {
  const SessionReportScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => StubScreen(
        title: 'Session report',
        section: '§05 Flutter screens',
        subtitle: 'Session: $sessionId',
      );
}

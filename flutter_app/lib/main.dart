import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: VLearn2App()));
}

class VLearn2App extends StatelessWidget {
  const VLearn2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vLearn2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B47), // apricot accent
        ),
      ),
      home: const _BootstrapScreen(),
    );
  }
}

/// Minimal placeholder shown while routing + theme + auth flow are wired up
/// in later todoList tasks (04 / 05). Confirms the app launches and Riverpod
/// is in place.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'vLearn2',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'English learning with your virtual tutor',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Text(
              'Bootstrap complete — routing + screens land in §04 / §05.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/app_apis.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(WidgetRef ref, BuildContext context) async {
    await ref.read(usersApiProvider).updateProfile({'onboardingDone': true});
    await ref.read(authProvider.notifier).refreshProfile();
    if (context.mounted) context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.waving_hand_rounded, size: 96, color: Color(0xFFFF6B47)),
              const SizedBox(height: 24),
              Text(
                'Welcome${user != null ? ", ${user.displayName}" : ""}!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Practice English with virtual tutors — at your own pace, in your own scenarios.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _completeOnboarding(ref, context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text("Let's go"),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

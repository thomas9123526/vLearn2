import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/scenarios/scenarios_screen.dart';
import '../../features/conversation/conversation_screen.dart';
import '../../features/report/session_report_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/course/course_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/profile_edit_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/app_shell.dart';

class AppRoute {
  AppRoute._();
  static const splash = '/';
  static const signIn = '/signin';
  static const signUp = '/signup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const scenarios = '/scenarios';
  static const progress = '/progress';
  static const settings = '/settings';
  static const profileEdit = '/settings/profile';
  static String conversation(String sessionId) => '/conversation/$sessionId';
  static String report(String sessionId) => '/report/$sessionId';
  static String course(String idOrSlug) => '/courses/$idOrSlug';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoute.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final signedIn = auth.isSignedIn;
      final checking = auth.status == AuthStatus.checking;
      final isPublic = loc == AppRoute.signIn ||
          loc == AppRoute.signUp ||
          loc == AppRoute.splash;

      if (checking) return null; // keep current — splash will animate
      if (!signedIn && !isPublic) return AppRoute.signIn;
      if (signedIn && (loc == AppRoute.signIn || loc == AppRoute.signUp)) {
        return auth.user!.onboardingDone ? AppRoute.home : AppRoute.onboarding;
      }
      if (signedIn && loc == AppRoute.splash) {
        return auth.user!.onboardingDone ? AppRoute.home : AppRoute.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoute.splash,     builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoute.signIn,     builder: (_, _) => const SignInScreen()),
      GoRoute(path: AppRoute.signUp,     builder: (_, _) => const SignUpScreen()),
      GoRoute(path: AppRoute.onboarding, builder: (_, _) => const OnboardingScreen()),

      // Fullscreen routes (no shell)
      GoRoute(
        path: '/conversation/:sessionId',
        builder: (_, s) =>
            ConversationScreen(sessionId: s.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/report/:sessionId',
        builder: (_, s) =>
            SessionReportScreen(sessionId: s.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/courses/:idOrSlug',
        builder: (_, s) =>
            CourseDetailScreen(idOrSlug: s.pathParameters['idOrSlug']!),
      ),
      GoRoute(path: AppRoute.profileEdit, builder: (_, _) => const ProfileEditScreen()),

      // Shell-wrapped main tabs
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: AppRoute.home,      builder: (_, _) => const HomeScreen()),
          GoRoute(path: AppRoute.scenarios, builder: (_, _) => const ScenariosScreen()),
          GoRoute(path: AppRoute.progress,  builder: (_, _) => const ProgressScreen()),
          GoRoute(path: AppRoute.settings,  builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

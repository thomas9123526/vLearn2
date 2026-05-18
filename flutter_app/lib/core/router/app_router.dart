import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../storage/model_registry.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/scenarios/scenarios_screen.dart';
import '../../features/scenarios/scenario_brief_screen.dart';
import '../../features/conversation/conversation_screen.dart';
import '../../features/news/news_detail_screen.dart';
import '../../features/news/news_list_screen.dart';
import '../../features/setup/models_not_installed_screen.dart';
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
  static String scenarioBrief(String idOrSlug) => '/scenarios/$idOrSlug/brief';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable();
  ref.listen<AuthState>(authProvider, (_, _) => refresh.bump());
  // Refresh the router whenever the model bundle status resolves so the
  // "speech models not installed" redirect kicks in once the snapshot is
  // available (rather than on the next navigation).
  ref.listen(modelRegistrySnapshotProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoute.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final signedIn = auth.isSignedIn;
      final checking = auth.status == AuthStatus.checking;
      final isPublic = loc == AppRoute.signIn ||
          loc == AppRoute.signUp ||
          loc == AppRoute.splash;

      if (checking) return null; // keep current — splash will animate
      // Auth resolved & no token: leave splash for the sign-in screen.
      if (!signedIn && loc == AppRoute.splash) return AppRoute.signIn;
      if (!signedIn && !isPublic) return AppRoute.signIn;
      if (signedIn && (loc == AppRoute.signIn || loc == AppRoute.signUp)) {
        return auth.user!.onboardingDone ? AppRoute.home : AppRoute.onboarding;
      }
      if (signedIn && loc == AppRoute.splash) {
        return auth.user!.onboardingDone ? AppRoute.home : AppRoute.onboarding;
      }

      // Once the user is signed in AND past onboarding, gate them on the
      // sherpa-onnx model bundle. We only redirect when the snapshot has
      // actually resolved (skip while still loading) and we honor the
      // text-only opt-out so the user isn't repeatedly forced back.
      if (signedIn && auth.user!.onboardingDone && !isPublic) {
        final settings = ref.read(appSettingsProvider);
        final snapshot = ref.read(modelRegistrySnapshotProvider).valueOrNull;
        final isSetup = loc == '/setup/models';
        final isConversation = loc.startsWith('/conversation/');
        if (snapshot != null &&
            !snapshot.isReady &&
            !settings.textOnlyAcknowledged &&
            !isSetup &&
            isConversation) {
          // Only force the setup screen when the user is actively trying to
          // start a conversation; the rest of the app (home, scenarios,
          // settings, etc.) still works without speech models.
          return '/setup/models';
        }
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
      GoRoute(
        path: '/setup/models',
        builder: (_, _) => const ModelsNotInstalledScreen(),
      ),
      GoRoute(
        path: '/scenarios/:idOrSlug/brief',
        builder: (_, s) =>
            ScenarioBriefScreen(scenarioId: s.pathParameters['idOrSlug']!),
      ),
      GoRoute(path: '/news', builder: (_, _) => const NewsListScreen()),
      GoRoute(
        path: '/news/:idOrSlug',
        builder: (_, s) =>
            NewsDetailScreen(idOrSlug: s.pathParameters['idOrSlug']!),
      ),

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

class _AuthRefreshListenable extends ChangeNotifier {
  void bump() => notifyListeners();
}

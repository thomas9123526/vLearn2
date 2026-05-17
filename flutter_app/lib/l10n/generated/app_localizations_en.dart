// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'vLearn2';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Display name';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get createAccount => 'Create account';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get letsGo => 'Let\'s go';

  @override
  String get loading => 'Loading...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorAuth => 'Session expired. Please sign in again.';

  @override
  String get accountSuspendedTitle => 'Your account is suspended';

  @override
  String get accountSuspendedBody =>
      'Please contact support if you believe this is an error.';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeStreakDays(int days) {
    return '$days day streak';
  }

  @override
  String get homeRecommended => 'Recommended scenarios';

  @override
  String get homeStatSessions => 'Sessions';

  @override
  String get homeStatMinutes => 'Minutes';

  @override
  String get homeStatTopics => 'Topics';

  @override
  String get scenariosTitle => 'Scenarios';

  @override
  String get scenariosSearchHint => 'Search scenarios…';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryDaily => 'Daily';

  @override
  String get conversationEnd => 'End';

  @override
  String get conversationInputHint => 'Type your message…';

  @override
  String get conversationGreatWork => 'Great work!';

  @override
  String conversationSummary(int words, int turns) {
    return 'You spoke $words words across $turns turns.';
  }

  @override
  String get backToHome => 'Back to home';

  @override
  String get practiceAnother => 'Practice another scenario';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsCompressionLabel => 'Compress large responses';

  @override
  String settingsCompressionHint(int thresholdKb) {
    return 'Save bandwidth by compressing server responses larger than $thresholdKb KB. Small responses stay uncompressed for speed.';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get guardBlockedTitle => 'We can\'t send this';

  @override
  String get guardBlockedBody =>
      'Let\'s keep our conversation respectful. Try rephrasing your message.';

  @override
  String get guardWarnTitle => 'Watch your language';

  @override
  String get guardWarnBody =>
      'Your message contains some strong language. Send anyway?';

  @override
  String get guardWarnContinue => 'Continue anyway';
}

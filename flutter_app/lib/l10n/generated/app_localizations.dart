import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Virtual Foreign Language'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Save my account'**
  String get signInRememberMe;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get letsGo;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorAuth;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Please contact support if you believe this is an error.'**
  String get accountSuspendedBody;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String homeStreakDays(int days);

  /// No description provided for @homeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended scenarios'**
  String get homeRecommended;

  /// No description provided for @homeStatSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get homeStatSessions;

  /// No description provided for @homeStatMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get homeStatMinutes;

  /// No description provided for @homeStatTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get homeStatTopics;

  /// No description provided for @scenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenariosTitle;

  /// No description provided for @scenariosSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search scenarios…'**
  String get scenariosSearchHint;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get categoryBusiness;

  /// No description provided for @categorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// No description provided for @categoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get categoryDaily;

  /// No description provided for @conversationEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get conversationEnd;

  /// No description provided for @conversationInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message…'**
  String get conversationInputHint;

  /// No description provided for @conversationGreatWork.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get conversationGreatWork;

  /// No description provided for @conversationSummary.
  ///
  /// In en, this message translates to:
  /// **'You spoke {words} words across {turns} turns.'**
  String conversationSummary(int words, int turns);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @practiceAnother.
  ///
  /// In en, this message translates to:
  /// **'Practice another scenario'**
  String get practiceAnother;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsNetwork;

  /// No description provided for @settingsCompressionLabel.
  ///
  /// In en, this message translates to:
  /// **'Compress large responses'**
  String get settingsCompressionLabel;

  /// No description provided for @settingsCompressionHint.
  ///
  /// In en, this message translates to:
  /// **'Save bandwidth by compressing server responses larger than {thresholdKb} KB. Small responses stay uncompressed for speed.'**
  String settingsCompressionHint(int thresholdKb);

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @settingsFontGroup.
  ///
  /// In en, this message translates to:
  /// **'Font group'**
  String get settingsFontGroup;

  /// No description provided for @fontGroupEditorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get fontGroupEditorial;

  /// No description provided for @fontGroupModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get fontGroupModern;

  /// No description provided for @fontGroupFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get fontGroupFriendly;

  /// No description provided for @fontGroupClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get fontGroupClassic;

  /// No description provided for @settingsConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get settingsConversation;

  /// No description provided for @settingsDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default mode'**
  String get settingsDefaultMode;

  /// No description provided for @conversationModeFace.
  ///
  /// In en, this message translates to:
  /// **'Tutor mode (face-to-face)'**
  String get conversationModeFace;

  /// No description provided for @conversationModeFaceHint.
  ///
  /// In en, this message translates to:
  /// **'Speak with the animated tutor. The tutor speaks back.'**
  String get conversationModeFaceHint;

  /// No description provided for @conversationModeChat.
  ///
  /// In en, this message translates to:
  /// **'Chat mode'**
  String get conversationModeChat;

  /// No description provided for @conversationModeChatHint.
  ///
  /// In en, this message translates to:
  /// **'Type back and forth with the tutor.'**
  String get conversationModeChatHint;

  /// No description provided for @settingsBubbleStyle.
  ///
  /// In en, this message translates to:
  /// **'Bubble style'**
  String get settingsBubbleStyle;

  /// No description provided for @bubbleStyleClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get bubbleStyleClassic;

  /// No description provided for @bubbleStyleModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get bubbleStyleModern;

  /// No description provided for @bubbleStyleTail.
  ///
  /// In en, this message translates to:
  /// **'Speech tail'**
  String get bubbleStyleTail;

  /// No description provided for @bubbleStyleSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft pastel'**
  String get bubbleStyleSoft;

  /// No description provided for @bubbleStyleNotebook.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get bubbleStyleNotebook;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @newsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No news yet.'**
  String get newsEmpty;

  /// No description provided for @newsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get newsMarkAllRead;

  /// No description provided for @newsUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get newsUnreadBadge;

  /// No description provided for @newsPublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String newsPublishedOn(String date);

  /// No description provided for @guardBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'We can\'t send this'**
  String get guardBlockedTitle;

  /// No description provided for @guardBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s keep our conversation respectful. Try rephrasing your message.'**
  String get guardBlockedBody;

  /// No description provided for @guardWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch your language'**
  String get guardWarnTitle;

  /// No description provided for @guardWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Your message contains some strong language. Send anyway?'**
  String get guardWarnBody;

  /// No description provided for @guardWarnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get guardWarnContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

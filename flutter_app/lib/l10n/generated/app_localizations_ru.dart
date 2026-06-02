// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Виртуальный иностранный язык';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get signIn => 'Войти';

  @override
  String get signInRememberMe => 'Сохранить аккаунт';

  @override
  String get signUp => 'Регистрация';

  @override
  String get signOut => 'Выйти';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get displayName => 'Имя пользователя';

  @override
  String get preferredLanguage => 'Предпочитаемый язык';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get dontHaveAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get letsGo => 'Вперёд';

  @override
  String get loading => 'Загрузка...';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get errorNetwork => 'Нет подключения к интернету.';

  @override
  String get errorAuth => 'Сессия истекла. Пожалуйста, войдите снова.';

  @override
  String get accountSuspendedTitle => 'Ваш аккаунт заблокирован';

  @override
  String get accountSuspendedBody =>
      'Обратитесь в службу поддержки, если считаете это ошибкой.';

  @override
  String get homeGreetingMorning => 'Доброе утро';

  @override
  String get homeGreetingAfternoon => 'Добрый день';

  @override
  String get homeGreetingEvening => 'Добрый вечер';

  @override
  String homeStreakDays(int days) {
    return 'Серия $days дней';
  }

  @override
  String get homeRecommended => 'Рекомендуемые сценарии';

  @override
  String get homeStatSessions => 'Сессии';

  @override
  String get homeStatMinutes => 'Минуты';

  @override
  String get homeStatTopics => 'Темы';

  @override
  String get scenariosTitle => 'Сценарии';

  @override
  String get scenariosSearchHint => 'Поиск сценариев…';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryTravel => 'Путешествия';

  @override
  String get categoryBusiness => 'Бизнес';

  @override
  String get categorySocial => 'Общение';

  @override
  String get categoryDaily => 'Ежедневное';

  @override
  String get conversationEnd => 'Завершить';

  @override
  String get conversationInputHint => 'Введите сообщение…';

  @override
  String get conversationGreatWork => 'Отличная работа!';

  @override
  String conversationSummary(int words, int turns) {
    return 'Вы произнесли $words слов за $turns ходов.';
  }

  @override
  String get backToHome => 'На главную';

  @override
  String get practiceAnother => 'Практиковать другой сценарий';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsNetwork => 'Сеть';

  @override
  String get settingsCompressionLabel => 'Сжимать большие ответы';

  @override
  String settingsCompressionHint(int thresholdKb) {
    return 'Экономьте трафик, сжимая ответы сервера размером более $thresholdKb КБ.';
  }

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get settingsFontGroup => 'Группа шрифтов';

  @override
  String get fontGroupEditorial => 'Редакционный';

  @override
  String get fontGroupModern => 'Современный';

  @override
  String get fontGroupFriendly => 'Дружелюбный';

  @override
  String get fontGroupClassic => 'Классический';

  @override
  String get settingsConversation => 'Разговор';

  @override
  String get settingsDefaultMode => 'Режим по умолчанию';

  @override
  String get conversationModeFace => 'Режим репетитора (лицом к лицу)';

  @override
  String get conversationModeFaceHint =>
      'Общайтесь с анимированным репетитором. Репетитор отвечает голосом.';

  @override
  String get conversationModeChat => 'Режим чата';

  @override
  String get conversationModeChatHint => 'Переписывайтесь с репетитором.';

  @override
  String get settingsBubbleStyle => 'Стиль пузырей';

  @override
  String get bubbleStyleClassic => 'Классический';

  @override
  String get bubbleStyleModern => 'Современный';

  @override
  String get bubbleStyleTail => 'С хвостом';

  @override
  String get bubbleStyleSoft => 'Мягкий пастель';

  @override
  String get bubbleStyleNotebook => 'Блокнот';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get newsTitle => 'Новости';

  @override
  String get newsEmpty => 'Новостей пока нет.';

  @override
  String get newsMarkAllRead => 'Отметить все как прочитанные';

  @override
  String get newsUnreadBadge => 'Непрочитанные';

  @override
  String newsPublishedOn(String date) {
    return 'Опубликовано $date';
  }

  @override
  String get guardBlockedTitle => 'Не можем отправить это';

  @override
  String get guardBlockedBody =>
      'Давайте сохраним вежливый тон. Попробуйте перефразировать сообщение.';

  @override
  String get guardWarnTitle => 'Следите за языком';

  @override
  String get guardWarnBody =>
      'Ваше сообщение содержит сильные выражения. Отправить всё равно?';

  @override
  String get guardWarnContinue => 'Продолжить';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'vLearn2';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signIn => '登录';

  @override
  String get signUp => '注册';

  @override
  String get signOut => '退出登录';

  @override
  String get email => '电子邮件';

  @override
  String get password => '密码';

  @override
  String get displayName => '显示名称';

  @override
  String get preferredLanguage => '首选语言';

  @override
  String get createAccount => '创建账户';

  @override
  String get dontHaveAccount => '还没有账户？注册';

  @override
  String get letsGo => '开始';

  @override
  String get loading => '加载中...';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get errorGeneric => '发生错误,请重试。';

  @override
  String get errorNetwork => '无网络连接。';

  @override
  String get errorAuth => '会话已过期,请重新登录。';

  @override
  String get accountSuspendedTitle => '您的账户已被暂停';

  @override
  String get accountSuspendedBody => '如果您认为这是错误,请联系支持。';

  @override
  String get homeGreetingMorning => '早上好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String homeStreakDays(int days) {
    return '连续 $days 天';
  }

  @override
  String get homeRecommended => '推荐场景';

  @override
  String get homeStatSessions => '次数';

  @override
  String get homeStatMinutes => '分钟';

  @override
  String get homeStatTopics => '主题';

  @override
  String get scenariosTitle => '场景';

  @override
  String get scenariosSearchHint => '搜索场景…';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryTravel => '旅游';

  @override
  String get categoryBusiness => '商务';

  @override
  String get categorySocial => '社交';

  @override
  String get categoryDaily => '日常';

  @override
  String get conversationEnd => '结束';

  @override
  String get conversationInputHint => '输入消息…';

  @override
  String get conversationGreatWork => '做得好!';

  @override
  String conversationSummary(int words, int turns) {
    return '您在 $turns 轮中说了 $words 个词。';
  }

  @override
  String get backToHome => '返回首页';

  @override
  String get practiceAnother => '练习另一个场景';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsNetwork => '网络';

  @override
  String get settingsCompressionLabel => '压缩大响应';

  @override
  String settingsCompressionHint(int thresholdKb) {
    return '压缩大于 $thresholdKb KB 的服务器响应以节省带宽。';
  }

  @override
  String get settingsAccount => '账户';

  @override
  String get guardBlockedTitle => '无法发送';

  @override
  String get guardBlockedBody => '让我们保持对话的礼貌。请尝试重新表述您的消息。';

  @override
  String get guardWarnTitle => '注意您的语言';

  @override
  String get guardWarnBody => '您的消息包含一些强烈的语言。仍然发送吗?';

  @override
  String get guardWarnContinue => '仍然继续';
}

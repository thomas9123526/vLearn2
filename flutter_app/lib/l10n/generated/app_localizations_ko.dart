// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '가상 외국어 회화';

  @override
  String get welcomeBack => '다시 오신 걸 환영합니다';

  @override
  String get signIn => '로그인';

  @override
  String get signInRememberMe => '이 기기에서 로그인 정보 기억하기';

  @override
  String get signUp => '회원가입';

  @override
  String get signOut => '로그아웃';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get displayName => '표시 이름';

  @override
  String get preferredLanguage => '선호 언어';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get dontHaveAccount => '계정이 없으신가요? 가입하기';

  @override
  String get letsGo => '시작하기';

  @override
  String get loading => '로딩 중...';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get retry => '다시 시도';

  @override
  String get errorGeneric => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get errorNetwork => '인터넷 연결이 없습니다.';

  @override
  String get errorAuth => '세션이 만료되었습니다. 다시 로그인해 주세요.';

  @override
  String get accountSuspendedTitle => '계정이 정지되었습니다';

  @override
  String get accountSuspendedBody => '오류라고 생각되시면 지원팀에 문의해 주세요.';

  @override
  String get homeGreetingMorning => '좋은 아침입니다';

  @override
  String get homeGreetingAfternoon => '좋은 오후입니다';

  @override
  String get homeGreetingEvening => '좋은 저녁입니다';

  @override
  String homeStreakDays(int days) {
    return '$days일 연속';
  }

  @override
  String get homeRecommended => '추천 시나리오';

  @override
  String get homeStatSessions => '세션';

  @override
  String get homeStatMinutes => '분';

  @override
  String get homeStatTopics => '주제';

  @override
  String get scenariosTitle => '시나리오';

  @override
  String get scenariosSearchHint => '시나리오 검색…';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryTravel => '여행';

  @override
  String get categoryBusiness => '비즈니스';

  @override
  String get categorySocial => '사교';

  @override
  String get categoryDaily => '일상';

  @override
  String get conversationEnd => '종료';

  @override
  String get conversationInputHint => '메시지 입력…';

  @override
  String get conversationGreatWork => '잘 하셨어요!';

  @override
  String conversationSummary(int words, int turns) {
    return '$turns번의 차례 동안 $words개 단어를 말했습니다.';
  }

  @override
  String get backToHome => '홈으로';

  @override
  String get practiceAnother => '다른 시나리오 연습';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppearance => '외관';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsNetwork => '네트워크';

  @override
  String get settingsCompressionLabel => '큰 응답 압축';

  @override
  String settingsCompressionHint(int thresholdKb) {
    return '${thresholdKb}KB 이상의 서버 응답을 압축하여 대역폭을 절약합니다.';
  }

  @override
  String get settingsFont => '글꼴';

  @override
  String get settingsFontGroup => '글꼴 그룹';

  @override
  String get fontGroupEditorial => '에디토리얼';

  @override
  String get fontGroupModern => '모던';

  @override
  String get fontGroupFriendly => '프렌들리';

  @override
  String get fontGroupClassic => '클래식';

  @override
  String get settingsConversation => '대화';

  @override
  String get settingsDefaultMode => '기본 모드';

  @override
  String get conversationModeFace => '튜터 모드 (대면)';

  @override
  String get conversationModeFaceHint => '애니메이션 튜터와 음성으로 대화합니다.';

  @override
  String get conversationModeChat => '채팅 모드';

  @override
  String get conversationModeChatHint => '튜터와 텍스트로 주고받습니다.';

  @override
  String get settingsBubbleStyle => '말풍선 스타일';

  @override
  String get bubbleStyleClassic => '클래식';

  @override
  String get bubbleStyleModern => '모던';

  @override
  String get bubbleStyleTail => '꼬리형';

  @override
  String get bubbleStyleSoft => '소프트 파스텔';

  @override
  String get bubbleStyleNotebook => '노트북';

  @override
  String get settingsAccount => '계정';

  @override
  String get newsTitle => '소식';

  @override
  String get newsEmpty => '아직 소식이 없습니다.';

  @override
  String get newsMarkAllRead => '모두 읽음 표시';

  @override
  String get newsUnreadBadge => '안 읽음';

  @override
  String newsPublishedOn(String date) {
    return '$date 게시';
  }

  @override
  String get guardBlockedTitle => '보낼 수 없습니다';

  @override
  String get guardBlockedBody => '예의 있는 대화를 유지해 주세요. 메시지를 다시 작성해 보세요.';

  @override
  String get guardWarnTitle => '언어에 주의해 주세요';

  @override
  String get guardWarnBody => '메시지에 강한 표현이 포함되어 있습니다. 그래도 보낼까요?';

  @override
  String get guardWarnContinue => '계속 보내기';
}

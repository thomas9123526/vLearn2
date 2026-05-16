// Plain Dart models. Freezed/json_serializable would add codegen overhead
// the project doesn't need yet — these are simple wire types.

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarEmoji,
    required this.uiLanguage,
    required this.currentLevel,
    required this.xpTotal,
    required this.streakDays,
    required this.activePersonaId,
    required this.activeTheme,
    required this.onboardingDone,
    required this.role,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String,
        avatarEmoji: j['avatarEmoji'] as String? ?? '🐣',
        uiLanguage: j['uiLanguage'] as String? ?? 'en',
        currentLevel: (j['currentLevel'] as num).toInt(),
        xpTotal: (j['xpTotal'] as num).toInt(),
        streakDays: (j['streakDays'] as num).toInt(),
        activePersonaId: j['activePersonaId'] as String?,
        activeTheme: j['activeTheme'] as String? ?? 'apricot',
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        role: j['role'] as String? ?? 'user',
        status: j['status'] as String? ?? 'active',
      );

  final String id;
  final String email;
  final String displayName;
  final String avatarEmoji;
  final String uiLanguage;
  final int currentLevel;
  final int xpTotal;
  final int streakDays;
  final String? activePersonaId;
  final String activeTheme;
  final bool onboardingDone;
  final String role;
  final String status;
}

class Persona {
  const Persona({
    required this.id,
    required this.slug,
    required this.name,
    required this.accent,
    required this.style,
    required this.specialties,
    required this.gradientFrom,
    required this.gradientTo,
    this.imageUrl,
  });

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        accent: j['accent'] as String,
        style: j['style'] as String,
        specialties: (j['specialties'] as List<dynamic>? ?? []).cast<String>(),
        gradientFrom: j['gradient_from'] as String? ?? j['gradientFrom'] as String? ?? '#FF6B47',
        gradientTo: j['gradient_to'] as String? ?? j['gradientTo'] as String? ?? '#FFB997',
        imageUrl: j['image_url'] as String? ?? j['imageUrl'] as String?,
      );

  final String id;
  final String slug;
  final String name;
  final String accent;
  final String style;
  final List<String> specialties;
  final String gradientFrom;
  final String gradientTo;
  final String? imageUrl;
}

class I18nText {
  const I18nText({required this.en, this.ko, this.zh});

  factory I18nText.fromJson(Map<String, dynamic> j) => I18nText(
        en: j['en'] as String? ?? '',
        ko: j['ko'] as String?,
        zh: j['zh'] as String?,
      );

  final String en;
  final String? ko;
  final String? zh;

  String forLocale(String locale) {
    switch (locale) {
      case 'ko':
        return ko ?? en;
      case 'zh':
        return zh ?? en;
      default:
        return en;
    }
  }
}

class Scenario {
  const Scenario({
    required this.id,
    required this.slug,
    required this.category,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.xpReward,
    this.imageUrl,
  });

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
        id: j['id'] as String,
        slug: j['slug'] as String,
        category: j['category'] as String,
        difficulty: (j['difficulty'] as num).toInt(),
        title: I18nText.fromJson(j['title'] as Map<String, dynamic>),
        description: I18nText.fromJson(j['description'] as Map<String, dynamic>),
        estimatedMinutes: (j['estimated_minutes'] as num? ?? j['estimatedMinutes'] as num? ?? 5).toInt(),
        xpReward: (j['xp_reward'] as num? ?? j['xpReward'] as num? ?? 50).toInt(),
        imageUrl: j['image_url'] as String? ?? j['imageUrl'] as String?,
      );

  final String id;
  final String slug;
  final String category;
  final int difficulty;
  final I18nText title;
  final I18nText description;
  final int estimatedMinutes;
  final int xpReward;
  final String? imageUrl;
}

class ConversationSession {
  const ConversationSession({
    required this.id,
    required this.personaId,
    required this.mode,
    required this.status,
    required this.startedAt,
    required this.turnCount,
    required this.xpEarned,
    this.scenarioId,
    this.endedAt,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> j) => ConversationSession(
        id: j['id'] as String,
        personaId: j['personaId'] as String,
        mode: j['mode'] as String,
        status: j['status'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        turnCount: (j['turnCount'] as num? ?? 0).toInt(),
        xpEarned: (j['xpEarned'] as num? ?? 0).toInt(),
        scenarioId: j['scenarioId'] as String?,
        endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt'] as String),
      );

  final String id;
  final String? scenarioId;
  final String personaId;
  final String mode;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int turnCount;
  final int xpEarned;
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.sequence,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> j) => ConversationMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        sequence: (j['sequence'] as num).toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  final String id;
  final String role;
  final String content;
  final int sequence;
  final DateTime createdAt;
}

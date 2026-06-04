// Plain Dart models. Freezed/json_serializable would add codegen overhead
// the project doesn't need yet — these are simple wire types.

class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarUrl,
    required this.gender,
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
    email: j['email'] as String?,
    displayName: j['displayName'] as String,
    avatarEmoji: j['avatarEmoji'] as String? ?? '🐣',
    avatarUrl: j['avatarUrl'] as String?,
    gender: j['gender'] as String? ?? 'unspecified',
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
  final String? email;
  final String displayName;
  final String avatarEmoji;

  /// Server-side path, joined with the API base URL on render.
  /// e.g. `/uploads/avatars/<id>.jpg`. Null = use [avatarEmoji].
  final String? avatarUrl;
  final String gender;
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
    this.gender = 'neutral',
    this.voiceId,
    this.ttsAge,
    this.ttsVoiceSid,
    this.riveAsset,
    this.imageUrl,
  });

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    accent: j['accent'] as String,
    style: j['style'] as String,
    specialties: (j['specialties'] as List<dynamic>? ?? []).cast<String>(),
    gradientFrom:
        j['gradient_from'] as String? ??
        j['gradientFrom'] as String? ??
        '#FF6B47',
    gradientTo:
        j['gradient_to'] as String? ?? j['gradientTo'] as String? ?? '#FFB997',
    gender: j['gender'] as String? ?? 'neutral',
    voiceId: j['voice_id'] as String? ?? j['voiceId'] as String?,
    ttsAge: j['tts_age'] as String? ?? j['ttsAge'] as String?,
    ttsVoiceSid: (j['tts_voice_sid'] as num?)?.toInt() ??
        (j['ttsVoiceSid'] as num?)?.toInt(),
    riveAsset: j['rive_asset'] as String? ?? j['riveAsset'] as String?,
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

  /// `'female' | 'male' | 'neutral'`. Drives avatar animation and voice selection.
  final String gender;

  /// TTS voice id (name string) from `manifest.tts.voices`. Null = use heuristic.
  final String? voiceId;

  /// Admin-assigned voice age hint: `'young' | 'adult' | 'elder' | null`.
  /// Used as a tiebreaker when [voiceId] and [ttsVoiceSid] are both null.
  final String? ttsAge;

  /// Direct VITS speaker-index override. When set, wins over [voiceId] and
  /// [ttsAge]. The app clamps this to the available voice count.
  final int? ttsVoiceSid;

  /// `.riv` filename under `assets/animations/`. Null = use default character.
  final String? riveAsset;

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

  Map<String, dynamic> toJson() => {
    'en': en,
    if (ko != null) 'ko': ko,
    if (zh != null) 'zh': zh,
  };

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

class Category {
  const Category({required this.slug, required this.title, this.description});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    slug: j['slug'] as String,
    title: I18nText.fromJson((j['title'] as Map).cast<String, dynamic>()),
    description: j['description'] == null
        ? null
        : I18nText.fromJson((j['description'] as Map).cast<String, dynamic>()),
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title.toJson(),
    if (description != null) 'description': description!.toJson(),
  };

  final String slug;
  final I18nText title;
  final I18nText? description;
}

class Scenario {
  const Scenario({
    required this.id,
    required this.slug,
    required this.category,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.xpReward,
    this.cefrLevel,
    this.imageUrl,
    this.backgroundImageUrl,
  });

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
    id: j['id'] as String,
    slug: j['slug'] as String,
    category: j['category'] as String,
    title: I18nText.fromJson(j['title'] as Map<String, dynamic>),
    description: I18nText.fromJson(j['description'] as Map<String, dynamic>),
    estimatedMinutes:
        (j['estimated_minutes'] as num? ?? j['estimatedMinutes'] as num? ?? 5)
            .toInt(),
    xpReward: (j['xp_reward'] as num? ?? j['xpReward'] as num? ?? 50).toInt(),
    cefrLevel: (j['cefr_level'] as num? ?? j['cefrLevel'] as num?)?.toInt(),
    imageUrl: j['image_url'] as String? ?? j['imageUrl'] as String?,
    backgroundImageUrl:
        j['background_image_url'] as String? ??
        j['backgroundImageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'category': category,
    'title': title.toJson(),
    'description': description.toJson(),
    'estimated_minutes': estimatedMinutes,
    'xp_reward': xpReward,
    if (cefrLevel != null) 'cefr_level': cefrLevel,
    if (imageUrl != null) 'image_url': imageUrl,
    if (backgroundImageUrl != null) 'background_image_url': backgroundImageUrl,
  };

  final String id;
  final String slug;
  final String category;
  final I18nText title;
  final I18nText description;
  final int estimatedMinutes;
  final int xpReward;
  /// Target CEFR level for this scenario (1=A1 … 6=C2). When set, the tutor
  /// system prompt uses this level instead of the learner's current level.
  final int? cefrLevel;
  final String? imageUrl;
  final String? backgroundImageUrl;
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
    this.scenarioTitle,
    this.cefrLevel,
    this.endedAt,
    this.timeConstrained = false,
    this.estimatedMinutes = 5,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> j) =>
      ConversationSession(
        id: j['id'] as String,
        personaId: j['personaId'] as String,
        mode: j['mode'] as String,
        status: j['status'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        turnCount: (j['turnCount'] as num? ?? 0).toInt(),
        xpEarned: (j['xpEarned'] as num? ?? 0).toInt(),
        scenarioId: j['scenarioId'] as String?,
        scenarioTitle: j['scenarioTitle'] as String?,
        cefrLevel: (j['cefrLevel'] as num?)?.toInt(),
        endedAt: j['endedAt'] == null
            ? null
            : DateTime.parse(j['endedAt'] as String),
        timeConstrained: j['timeConstrained'] as bool? ?? false,
        estimatedMinutes: (j['estimatedMinutes'] as num? ?? 5).toInt(),
      );

  final String id;
  final String? scenarioId;
  final String? scenarioTitle;
  final int? cefrLevel;
  final String personaId;
  final String mode;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int turnCount;
  final int xpEarned;
  final bool timeConstrained;
  final int estimatedMinutes;
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.sequence,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> j) =>
      ConversationMessage(
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

class NewsPost {
  const NewsPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    this.summary,
    this.imageUrl,
    required this.status,
    required this.pinned,
    this.publishedAt,
    required this.read,
  });

  factory NewsPost.fromJson(Map<String, dynamic> j) => NewsPost(
    id: j['id'] as String,
    slug: j['slug'] as String,
    title: (j['title'] as Map).cast<String, dynamic>(),
    body: (j['body'] as Map).cast<String, dynamic>(),
    summary: j['summary'] == null
        ? null
        : (j['summary'] as Map).cast<String, dynamic>(),
    imageUrl: j['image_url'] as String?,
    status: j['status'] as String,
    pinned: (j['pinned'] as bool?) ?? false,
    publishedAt: j['published_at'] == null
        ? null
        : DateTime.parse(j['published_at'] as String),
    read: (j['read'] as bool?) ?? false,
  );

  final String id;
  final String slug;
  final Map<String, dynamic> title;
  final Map<String, dynamic> body;
  final Map<String, dynamic>? summary;
  final String? imageUrl;
  final String status;
  final bool pinned;
  final DateTime? publishedAt;
  final bool read;

  /// Resolve i18n text for the current locale, falling back to English.
  String titleFor(String lang) => _pick(title, lang);
  String bodyFor(String lang) => _pick(body, lang);
  String? summaryFor(String lang) =>
      summary == null ? null : _pick(summary!, lang);

  static String _pick(Map<String, dynamic> m, String lang) {
    final v = m[lang] as String?;
    if (v != null && v.isNotEmpty) return v;
    return (m['en'] as String?) ?? '';
  }
}

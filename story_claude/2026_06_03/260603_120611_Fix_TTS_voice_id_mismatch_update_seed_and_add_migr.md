# Conversation - Fix TTS voice_id mismatch: update seed and add migration for manifest-compatible voice IDs

| Field | Value |
|---|---|
| Saved | 2026-06-03 12:06:11 |
| Commit | Fix TTS voice_id mismatch: update seed and add migration for manifest-compatible voice IDs |
| Project | C:\project\vLearn2 |

---

## User

<ide_opened_file>The user opened the file c:\project\vLearn2\models\manifest.json in the IDE. This may or may not be related to the current task.</ide_opened_file>

ok tts is some changed.
But when i switch from Leo to Theo, and the tts speaker is female, but Theo is male on the database.
It always say the same voice, not change per tutor specific.

## Claude

Let me find the TTS voice selection code in the Flutter app.

**Tool - Agent**

```
{"description":"Find TTS voice selection code","subagent_type":"Explore","prompt":"In the Flutter project at c:\\project\\vLearn2\\flutter_app, find all code related to TTS (text-to-speech) voice selection. Specifically look for:\n1. How the TTS voice/speaker is set or selected\n2. Any tutor/character models that have a gender or voice field\n3. Any FreeTalk or chat screen that uses TTS\n4. Any TTS service or provider\n\nSearch for: tts, TextToSpeech, speak, voice, speaker, gender, tutor, FreeTalk\nReport file paths and relevant line numbers."}
```

**Result**

```
Perfect! Now I have a complete picture. Let me create a final summary document:

## TTS Voice Selection Code in vLearn2 Flutter Project

I've found all TTS (text-to-speech) voice selection code in the Flutter project. Here's the comprehensive report:

### 1. **TTS Service Implementation**

**File:** `c:\project\vLearn2\flutter_app\lib\core\speech\sherpa_onnx_tts.dart` (382 lines)

- **Lines 27-84**: Main `SherpaOnnxTtsService` class - Real on-device TTS backed by sherpa-onnx VITS (Piper-style) model
- **Lines 52, 99**: `_voices` list stores available voice names from manifest
- **Lines 79-84**: `capabilities` property exposes `availableVoices: List.unmodifiable(_voices)`
- **Line 166-203**: `speak()` method - takes `voiceId` parameter, converts voice name to speaker index (SID) via `_voiceIdToSid()`
- **Line 288**: `_voiceIdToSid()` - maps voice ID string to speaker index using `_voices.indexOf()`
- **Line 268-305**: `synthesize()` method - performs actual TTS synthesis with caching

**Streams for avatar animation:**
- **Line 66**: `isSpeakingStream` - broadcasts when audio starts/stops (drives Rive tutor mouth state)
- **Line 73**: `amplitudeStream` - emits 0.0–1.0 loudness envelo
...[truncated]
```

## Claude

Now let me look at the exact `_pickVoice()` and `_maybeSpeakLatestAssistantReply()` code, plus how the persona is loaded when switching tutors.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
120	    if (!mounted) return;
121	    setState(() {
122	      _mood = TutorMood.disappointed;
123	      _idleSuggestion = null;
124	    });
125	    // Mochi rig auto-returns to Idle visually after ~1.5 s;
126	    // sync Flutter mood after the same delay.
127	    Future<void>.delayed(const Duration(milliseconds: 1500), () {
128	      if (mounted) setState(() => _mood = TutorMood.idle);
129	    });
130	  }
131	
132	  void _maybeSpeakLatestAssistantReply() {
133	    if (widget.messages.isEmpty) return;
134	    final last = widget.messages.last;
135	    if (last.role != 'assistant') return;
136	    if (last.id == _lastSpokenId) return;
137	    _lastSpokenId = last.id;
138	
139	    if (!ref.read(speechReadyProvider)) return;
140	    final tts = ref.read(ttsServiceProvider);
141	    final voiceId = _pickVoice(tts.capabilities.availableVoices, widget.persona);
142	    final preview = last.content.length > 80
143	        ? '${last.content.substring(0, 80)}…'
144	        : last.content;
145	    debugPrint('[tts] speak voice=$voiceId len=${last.content.length} "$preview"');
146	    tts.speak(last.content, voiceId: voiceId).catchError((Object e, StackTrace st) {
147	      debugPrint('[tts] f
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\core\models\models.dart
```

**Result**

```
60	
61	class Persona {
62	  const Persona({
63	    required this.id,
64	    required this.slug,
65	    required this.name,
66	    required this.accent,
67	    required this.style,
68	    required this.specialties,
69	    required this.gradientFrom,
70	    required this.gradientTo,
71	    this.gender = 'neutral',
72	    this.voiceId,
73	    this.ttsAge,
74	    this.ttsVoiceSid,
75	    this.riveAsset,
76	    this.imageUrl,
77	  });
78	
79	  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
80	    id: j['id'] as String,
81	    slug: j['slug'] as String,
82	    name: j['name'] as String,
83	    accent: j['accent'] as String,
84	    style: j['style'] as String,
85	    specialties: (j['specialties'] as List<dynamic>? ?? []).cast<String>(),
86	    gradientFrom:
87	        j['gradient_from'] as String? ??
88	        j['gradientFrom'] as String? ??
89	        '#FF6B47',
90	    gradientTo:
91	        j['gradient_to'] as String? ?? j['gradientTo'] as String? ?? '#FFB997',
92	    gender: j['gender'] as String? ?? 'neutral',
93	    voiceId: j['voice_id'] as String? ?? j['voiceId'] as String?,
94	    ttsAge: j['tts_age'] as String? ?? j['ttsAge'] as String?,
95	    ttsVoiceSid: (j['tt
...[truncated]
```

## Claude

Let me check the manifest voices and how the persona is passed when switching tutors.

**Tool - Read**

```
c:\project\vLearn2\models\manifest.json
```

**Result**

```
1	{
2	  "version": "2026-06-03-1",
3	  "stt": {
4	    "name": "zipformer-streaming-en"
5	  },
6	  "tts": {
7	    "name": "vits-piper-en",
8	    "voices": [
9	      "en_VCTK-amy",
10	      "en_VCTK-james"
11	    ]
12	  },
13	  "vad": {
14	    "name": "silero-v4"
15	  },
16	  "files": [
17	    {
18	      "path": "stt/decoder.onnx",
19	      "sha256": "9da02b77cb08826756ec6a88635f35a40374e4164e7c6359121a9145958a6ceb",
20	      "size": 2092566
21	    },
22	    {
23	      "path": "stt/encoder.onnx",
24	      "sha256": "b584884daad8cd4e60a5258e6da11876460089f1c4d3b5a92e19f0f104edb77a",
25	      "size": 353707185
26	    },
27	    {
28	      "path": "stt/joiner.onnx",
29	      "sha256": "bd5c26ad6a41cbd90c2cfa239c0b55b145af878ce1d79b4739d90f8be93359ba",
30	      "size": 1026405
31	    },
32	    {
33	      "path": "stt/tokens.txt",
34	      "sha256": "49e3c2646595fd907228b3c6787069658f67b17377c60aeb8619c4551b2316fb",
35	      "size": 5048
36	    },
37	    {
38	      "path": "tts/lexicon.txt",
39	      "sha256": "4b862055ff17db41310498d3f121a8e343829df63aba016c2dc26bf82ea3b8aa",
40	      "size": 36727245
41	    },
42	    {
43	      "path": "tts/model.onnx",
44	      "sha256": "1981e43d4aee9a
...[truncated]
```

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib\features\conversation
```

**Result**

```
flutter_app\lib\features\conversation\conversation_screen.dart:14:import '../../core/providers/personas_provider.dart';
flutter_app\lib\features\conversation\conversation_screen.dart:45:/// Looks up the active persona for the session so Tutor mode can render
flutter_app\lib\features\conversation\conversation_screen.dart:47:// personaByIdProvider lives in core/providers/personas_provider.dart
flutter_app\lib\features\conversation\conversation_screen.dart:258:              personaId: d.session.personaId,
flutter_app\lib\features\conversation\conversation_screen.dart:742:/// Hydrates the active persona for the session, then renders [TutorModeView].
flutter_app\lib\features\conversation\conversation_screen.dart:743:/// Done in its own widget so the persona FutureProvider stays scoped and
flutter_app\lib\features\conversation\conversation_screen.dart:748:    required this.personaId,
flutter_app\lib\features\conversation\conversation_screen.dart:759:  final String personaId;
flutter_app\lib\features\conversation\conversation_screen.dart:771:        ref.watch(tutorDisplayPersonaIdProvider(personaId));
flutter_app\lib\features\conversation\conversation_screen.dart:772:    final persona = r
...[truncated]
```

## Claude

The manifest only has two voices: `en_VCTK-amy` (female) and `en_VCTK-james` (male). The logic looks correct, but I suspect the TTS audio cache isn't keyed by voiceId. Let me check.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\core\speech\sherpa_onnx_tts.dart
```

**Result**

```
255	        if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(0.0);
256	      }
257	    });
258	  }
259	
260	  void _stopAmplitudeEmitter() {
261	    _amplitudeTimer?.cancel();
262	    _amplitudeTimer = null;
263	    _ampSma = 0.0;
264	    if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(0.0);
265	  }
266	
267	  @override
268	  Future<Uint8List> synthesize(
269	    String text, {
270	    required String voiceId,
271	    String? language,
272	    double rate = 1.0,
273	  }) async {
274	    if (!_initialized) await initialize();
275	    if (!_available || _engine == null) {
276	      throw TtsUnavailableException(
277	        'Speech models are not installed yet. Ask your admin to drop the '
278	        'sherpa-onnx bundle into the models folder.',
279	      );
280	    }
281	
282	    // Cache check.
283	    final cacheFile = await _cachePath(text, voiceId, rate);
284	    if (cacheFile.existsSync()) {
285	      return cacheFile.readAsBytes();
286	    }
287	
288	    final sid = _voiceIdToSid(voiceId);
289	    final audio = _engine!.generate(
290	      text: text,
291	      sid: sid,
292	      speed: rate,
293	    );
294	    final wav = _pcmToWav(audio.samples, audio.sampleRate);
295	
29
...[truncated]
```

## Claude

The cache is fine (keyed by voiceId). Let me check how the persona is fetched — if `gender` field isn't returned in the API response, it defaults to `'neutral'` and falls back to the first voice (female).

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\core\providers\personas_provider.dart
```

**Result**

```
1	import 'package:flutter_riverpod/flutter_riverpod.dart';
2	
3	import '../api/app_apis.dart';
4	import '../models/models.dart';
5	import 'auth_provider.dart';
6	
7	/// Fetches one tutor persona by id. Shared by settings, scenario brief,
8	/// and conversation tutor mode.
9	final personaByIdProvider =
10	    FutureProvider.family<Persona?, String>((ref, personaId) async {
11	  final raw = await ref.read(personasApiProvider).get(personaId);
12	  return Persona.fromJson(raw);
13	});
14	
15	final personasListProvider = FutureProvider<List<Persona>>((ref) async {
16	  final raw = await ref.read(personasApiProvider).list();
17	  return raw.map(Persona.fromJson).toList();
18	});
19	
20	/// Persona shown in tutor mode: user's chosen default tutor when set,
21	/// otherwise the persona locked on the conversation session.
22	final tutorDisplayPersonaIdProvider = Provider.family<String, String>(
23	  (ref, sessionPersonaId) {
24	    final activePersonaId =
25	        ref.watch(authProvider.select((s) => s.user?.activePersonaId));
26	    if (activePersonaId != null && activePersonaId.isNotEmpty) {
27	      return activePersonaId;
28	    }
29	    return sessionPersonaId;
30	  },
31	);
32
```

## Claude

Let me check the personas API implementation to see if `gender` is included in the response.

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib\core\api
```

**Result**

```
flutter_app\lib\core\api\app_apis.dart:57:class PersonasApi {
flutter_app\lib\core\api\app_apis.dart:58:  PersonasApi(this._dio);
flutter_app\lib\core\api\app_apis.dart:369:final personasApiProvider = Provider<PersonasApi>(
flutter_app\lib\core\api\app_apis.dart:370:  (ref) => PersonasApi(ref.watch(apiClientProvider)),
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\core\api\app_apis.dart
```

**Result**

```
57	class PersonasApi {
58	  PersonasApi(this._dio);
59	  final Dio _dio;
60	
61	  Future<List<Map<String, dynamic>>> list() async {
62	    final res = await _dio.get<List<dynamic>>('/teachers');
63	    return res.data!.cast<Map<String, dynamic>>();
64	  }
65	
66	  Future<Map<String, dynamic>> get(String id) async {
67	    final res = await _dio.get<Map<String, dynamic>>('/teachers/$id');
68	    return res.data!;
69	  }
70	}
71	
72	// ─── Scenarios ──────────────────────────────────────────────
73	class ScenariosApi {
74	  ScenariosApi(this._dio);
75	  final Dio _dio;
76	
77	  Future<List<Map<String, dynamic>>> list({
78	    String? category,
79	    int? difficulty,
80	    String? q,
81	  }) async {
82	    final res = await _dio.get<List<dynamic>>(
83	      '/scenarios',
84	      queryParameters: <String, Object?>{
85	        'category': category,
86	        'difficulty': difficulty,
87	        'q': q,
88	      }..removeWhere((_, v) => v == null),
89	    );
90	    return res.data!.cast<Map<String, dynamic>>();
91	  }
92	
93	  Future<Map<String, dynamic>> get(String idOrSlug) async {
94	    final res = await _dio.get<Map<String, dynamic>>('/scenarios/$idOrSlug');
95	    return res.da
...[truncated]
```

## Claude

Let me check the backend teacher DTO to see if `gender` is included in the API response.

**Tool - Grep**

```
c:\project\vLearn2
```

**Result**

```
docs\guidelines.md:72:| `{{persona.gender}}` | `vl_personas.gender` |
backend\src\users\users.service.ts:53:    if (dto.gender !== undefined) user.gender = dto.gender;
backend\src\users\users.service.ts:98:      gender: u.gender,
backend\src\users\dto\user.dto.ts:18:  @ApiProperty() gender!: string;
backend\src\users\dto\user.dto.ts:51:  gender?: string;
backend\src\database\seeds\seeds\personas.seed.ts:14:    gender: 'female' as const,
backend\src\database\seeds\seeds\personas.seed.ts:26:    gender: 'male' as const,
backend\src\database\seeds\seeds\personas.seed.ts:38:    gender: 'female' as const,
backend\src\database\seeds\seeds\personas.seed.ts:50:    gender: 'male' as const,
backend\docs\openapi.json:2924:          "gender": {
backend\docs\openapi.json:2964:          "gender",
backend\docs\openapi.json:2986:          "gender": {
backend\docs\openapi.json:3344:          "gender": {
backend\docs\openapi.json:3399:          "gender": {
backend\docs\openapi.html:13:[Omitted long matching line]
backend\src\database\migrations\1779700000000-users-gender.ts:4: * Adds a `gender` column to the users table so the profile-edit dialog in
backend\src\database\migrations\1779700000000-users
...[truncated]
```

## Claude

Let me check the backend teachers controller to see if `gender` is included in the API response.

**Tool - Glob**

```
backend/src/**/*teacher*
```

**Result**

```
No files found
```

**Tool - Glob**

```
backend/src/**/*persona*
```

**Result**

```
backend\src\database\seeds\seeds\personas.seed.ts
backend\src\database\migrations\1779600000000-personas-gender-voice.ts
backend\src\personas\personas.module.ts
backend\src\admin\admin-personas.controller.ts
backend\src\database\entities\persona.entity.ts
backend\src\database\migrations\1782100000000-personas-voice-config.ts
```

**Tool - Glob**

```
backend/src/personas/**/*.ts
```

**Result**

```
backend\src\personas\personas.module.ts
```

**Tool - Glob**

```
backend/src/**/*teacher*
```

**Tool - Glob**

```
backend/src/**/*.controller.ts
```

**Result**

```
No files found
```

**Result**

```
backend\src\health.controller.ts
backend\src\admin\admin-categories.controller.ts
backend\src\admin\admin-leaderboard.controller.ts
backend\src\admin\admin-prompt-templates.controller.ts
backend\src\admin\admins\admin-admins.controller.ts
backend\src\admin\admins\admin-auth.controller.ts
backend\src\admin\audit\admin-audit.controller.ts
backend\src\auth\auth.controller.ts
backend\src\admin\admin-scenarios.controller.ts
backend\src\users\users.controller.ts
backend\src\admin\admin-personas.controller.ts
backend\src\admin\admin-users.controller.ts
backend\src\admin\stats\admin-stats.controller.ts
```

**Tool - Grep**

```
c:\project\vLearn2\backend\src
```

**Result**

```
backend\src\personas\personas.module.ts:41:@Controller('teachers')
backend\src\admin\admin-personas.controller.ts:175:@Controller('admin/teachers')
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\personas\personas.module.ts
```

**Result**

```
1	import { Module } from '@nestjs/common';
2	import { TypeOrmModule } from '@nestjs/typeorm';
3	import { Controller, Get, UseGuards } from '@nestjs/common';
4	import { Injectable, NotFoundException, Param } from '@nestjs/common';
5	import { InjectRepository } from '@nestjs/typeorm';
6	import { Repository } from 'typeorm';
7	import {
8	  ApiBearerAuth,
9	  ApiOkResponse,
10	  ApiOperation,
11	  ApiTags,
12	} from '@nestjs/swagger';
13	import { PersonaEntity } from '../database/entities/persona.entity';
14	import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
15	
16	@Injectable()
17	class PersonasService {
18	  constructor(
19	    @InjectRepository(PersonaEntity)
20	    private readonly repo: Repository<PersonaEntity>,
21	  ) {}
22	
23	  list() {
24	    return this.repo.find({
25	      where: { is_active: true },
26	      order: { name: 'ASC' },
27	    });
28	  }
29	
30	  async get(id: string) {
31	    const p = await this.repo.findOne({ where: { id } });
32	    if (!p || !p.is_active)
33	      throw new NotFoundException({ i18nKey: 'persona.not_found' });
34	    return p;
35	  }
36	}
37	
38	@ApiTags('Teachers')
39	@ApiBearerAuth()
40	@UseGuards(JwtAuthGuard)
41	@Controller('
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\database\entities\persona.entity.ts
```

**Result**

```
1	import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
2	
3	/**
4	 * "Tutor" persona presented to the user in conversation mode. Owned by
5	 * the admin panel (see AdminPersonasController) but read-only from the
6	 * mobile client (PersonasController).
7	 *
8	 * Mapping into runtime behavior:
9	 *   * `gender` drives the avatar's body/face Rive state machine so the
10	 *     animations match the persona's stated identity.
11	 *   * `voice_id` is the sherpa-onnx TTS voice id used when speaking lines
12	 *     for this persona. Matches an entry in `manifest.tts.voices`.
13	 *   * `rive_asset` is the .riv file dropped under assets/animations/ in
14	 *     the Flutter app (only the filename, not the full path).
15	 */
16	@Entity({ name: 'vl_personas' })
17	export class PersonaEntity {
18	  @PrimaryGeneratedColumn('uuid')
19	  id!: string;
20	
21	  @Column({ type: 'varchar', length: 50, unique: true })
22	  slug!: string;
23	
24	  @Column({ type: 'varchar', length: 50 })
25	  name!: string;
26	
27	  @Column({ type: 'varchar', length: 100 })
28	  accent!: string;
29	
30	  @Column({ type: 'varchar', length: 100 })
31	  style!: string;
32	
33	  @Column({ type: 'jsonb', default
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\database\seeds\seeds\personas.seed.ts
```

**Result**

```
1	import { DataSource } from 'typeorm';
2	import { PersonaEntity } from '../../entities/persona.entity';
3	
4	const PERSONAS = [
5	  {
6	    slug: 'maya',
7	    name: 'Maya',
8	    accent: 'Warm American',
9	    style: 'Encouraging, patient',
10	    specialties: ['Travel', 'Daily life', 'Beginner-friendly'],
11	    gradient_from: '#FFB997',
12	    gradient_to: '#FF6B47',
13	    rive_asset: 'persona_maya.riv',
14	    gender: 'female' as const,
15	    voice_id: 'en_US-amy',
16	  },
17	  {
18	    slug: 'leo',
19	    name: 'Leo',
20	    accent: 'Casual British',
21	    style: 'Energetic, fun',
22	    specialties: ['Slang', 'Social conversation', 'Pop culture'],
23	    gradient_from: '#A8E6CF',
24	    gradient_to: '#5DBE9C',
25	    rive_asset: 'persona_leo.riv',
26	    gender: 'male' as const,
27	    voice_id: 'en_GB-alan',
28	  },
29	  {
30	    slug: 'sofia',
31	    name: 'Sofia',
32	    accent: 'Crisp British',
33	    style: 'Precise, professional',
34	    specialties: ['Business', 'Formal English', 'Grammar'],
35	    gradient_from: '#C9B6FF',
36	    gradient_to: '#7C6BE6',
37	    rive_asset: 'persona_sofia.riv',
38	    gender: 'female' as const,
39	    voice_id: 'en_GB-jenny',
40	  }
...[truncated]
```

## Claude

Found the root cause. The seed data has voice IDs (`en_GB-alan`, `en_AU-james`) that **don't exist in the manifest** (`en_VCTK-amy`, `en_VCTK-james`). So when the DB stores these, the Flutter `_pickVoice()` priority-2 check (`voices.contains(persona.voiceId)`) fails for all personas, and falls through to the gender heuristic — which should work.

BUT the more likely issue: the DB was probably populated when only `en_VCTK-amy` existed, so all personas have `voice_id = 'en_VCTK-amy'` stored. Since that IS in the manifest, priority-2 wins and returns `'en_VCTK-amy'` for every tutor.

The fix: update the seed so male personas get `'en_VCTK-james'` and re-run it.

**Tool - Edit**

```
c:\project\vLearn2\backend\src\database\seeds\seeds\personas.seed.ts
```

**Result**

```
The file c:\project\vLearn2\backend\src\database\seeds\seeds\personas.seed.ts has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now I also need to add a DB migration so re-seeding isn't required — the migration can directly fix the voice IDs in the live DB.

**Tool - Glob**

```
backend/src/database/migrations/*.ts
```

**Result**

```
backend\src\database\migrations\1716000000000-news-tables.ts
backend\src\database\migrations\1779600000000-personas-gender-voice.ts
backend\src\database\migrations\1779700000000-users-gender.ts
backend\src\database\migrations\1780300000000-prompt-templates.ts
backend\src\database\migrations\1715800000000-initial-schema.ts
backend\src\database\migrations\1779800000000-add-vl-prefix.ts
backend\src\database\migrations\1779900000000-users-name-cid.ts
backend\src\database\migrations\1780000000000-extract-vl-user-info.ts
backend\src\database\migrations\1780100000000-cid-auth.ts
backend\src\database\migrations\1780200000000-cid-username-length.ts
backend\src\database\migrations\1780400000000-categories.ts
backend\src\database\migrations\1780600000000-rename-vl-users-back-to-users.ts
backend\src\database\migrations\1779100000000-admins-separate-table.ts
backend\src\database\migrations\1780700000000-license-config.ts
backend\src\database\migrations\1780800000000-user-avatar-image.ts
backend\src\database\migrations\1780900000000-users-license-columns.ts
backend\src\database\migrations\1781000000000-users-cid-unique.ts
backend\src\database\migrations\1781100000000-users-license-platform.ts
ba
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\database\migrations\1782100000000-personas-voice-config.ts
```

**Result**

```
1	import { MigrationInterface, QueryRunner } from 'typeorm';
2	
3	/**
4	 * Adds `tts_age` and `tts_voice_sid` to the vl_personas table.
5	 *
6	 * `tts_age` gives the admin a high-level voice character label
7	 * ('young' | 'adult' | 'elder') that the Flutter app uses as a fallback
8	 * hint when `voice_id` is not set.
9	 *
10	 * `tts_voice_sid` is a direct speaker-index override (0-based) for the
11	 * on-device VITS model. When set it wins over both `voice_id` and the
12	 * `tts_age` heuristic, letting admins pin a specific SID without knowing
13	 * the voice name string.
14	 */
15	export class PersonasVoiceConfig1782100000000 implements MigrationInterface {
16	  name = 'PersonasVoiceConfig1782100000000';
17	
18	  public async up(q: QueryRunner): Promise<void> {
19	    await q.query(
20	      `ALTER TABLE "vl_personas" ADD COLUMN IF NOT EXISTS "tts_age" VARCHAR(20);`,
21	    );
22	    await q.query(
23	      `ALTER TABLE "vl_personas" ADD COLUMN IF NOT EXISTS "tts_voice_sid" SMALLINT;`,
24	    );
25	  }
26	
27	  public async down(q: QueryRunner): Promise<void> {
28	    await q.query(`ALTER TABLE "vl_personas" DROP COLUMN IF EXISTS "tts_voice_sid";`);
29	    await q.query(`ALTER TA
...[truncated]
```

## Claude

I'll create a migration that directly updates the `voice_id` in the DB for all personas to match the manifest voices.

**Tool - Write**

```
c:\project\vLearn2\backend\src\database\migrations\1782200000000-personas-voice-id-fix.ts
```

**Result**

```
File created successfully at: c:\project\vLearn2\backend\src\database\migrations\1782200000000-personas-voice-id-fix.ts (file state is current in your context — no need to Read it back)
```

## Claude

Now I need to register this migration in the TypeORM data source config.

**Tool - Grep**

```
c:\project\vLearn2\backend\src
```

**Result**

```
backend\src\database\typeorm-config.factory.ts:20:  migrations: [join(__dirname, 'migrations', '*.{ts,js}').replace(/\\/g, '/')],
backend\src\database\data-source.ts:19:  migrations: [join(__dirname, 'migrations', '*.{ts,js}').replace(/\\/g, '/')],
backend\src\database\migrations\1782100000000-personas-voice-config.ts:15:export class PersonasVoiceConfig1782100000000 implements MigrationInterface {
backend\src\database\migrations\1782100000000-personas-voice-config.ts:16:  name = 'PersonasVoiceConfig1782100000000';
```

## Claude

Migrations are auto-discovered by glob, so no registration needed. Let me commit now.

**Tool - Bash**

```
git add backend/src/database/seeds/seeds/personas.seed.ts backend/src/database/migrations/1782200000000-personas-voice-id-fix.ts && git status
```

**Tool - Bash**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
warning: in the working copy of 'backend/src/database/seeds/seeds/personas.seed.ts', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'backend/src/database/migrations/1782200000000-personas-voice-id-fix.ts', LF will be replaced by CRLF the next time Git touches it
On branch dev_0601_vmware
Your branch is ahead of 'origin/dev_0601_vmware' by 6 commits.
  (use "git push" to publish your local commits)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   backend/src/database/migrations/1782200000000-personas-voice-id-fix.ts
	modified:   backend/src/database/seeds/seeds/personas.seed.ts
```

**Result**

```
Exit code 127
/usr/bin/bash: line 1: Get-Date: command not found
```

**Tool - PowerShell**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
260603_120547
```

**Tool - Write**

```
c:\project\vLearn2\story_claude\2026_06_03\260603_120547_Fix_TTS_voice_not_changing_per_tutor.md
```

**Result**

```
File created successfully at: c:\project\vLearn2\story_claude\2026_06_03\260603_120547_Fix_TTS_voice_not_changing_per_tutor.md (file state is current in your context — no need to Read it back)
```

**Tool - Bash**

```
git add story_claude/2026_06_03/260603_120547_Fix_TTS_voice_not_changing_per_tutor.md && git commit -m "Fix TTS voice_id mismatch: update seed and add migration for manifest-compatible voice IDs"
```

---

## User prompts (verbatim)

### Prompt 1

```
<ide_opened_file>The user opened the file c:\project\vLearn2\models\manifest.json in the IDE. This may or may not be related to the current task.</ide_opened_file>

ok tts is some changed.
But when i switch from Leo to Theo, and the tts speaker is female, but Theo is male on the database.
It always say the same voice, not change per tutor specific.
```


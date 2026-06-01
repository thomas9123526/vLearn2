# Conversation - Add conversation.mode config: tutor/message/both with admin UI and Flutter enforcement

| Field | Value |
|---|---|
| Saved | 2026-06-01 15:15:54 |
| Commit | Add conversation.mode config: tutor/message/both with admin UI and Flutter enforcement |
| Project | C:\project\vLearn2 |

---

## User

<ide_opened_file>The user opened the file c:\project\vLearn2\cmds\seed_fetch.ps1 in the IDE. This may or may not be related to the current task.</ide_opened_file>

I want this app to check a certain apk installed on the android device.
So when the app first launch, it checks the application for "com.ryongma.cid" and if it doesn't installed on the android device then alert message to install the app and exit the application.

## Claude

Let me look at the Flutter app structure to find the right place to add this check.

**Tool - Agent**

```
{"description":"Explore Flutter app entry points and main files","subagent_type":"Explore","prompt":"In the Flutter project at c:\\project\\vLearn2\\flutter_app, find:\n1. The main.dart entry point (full path)\n2. The root widget/app file (e.g. app.dart or similar)\n3. Any existing package dependencies in pubspec.yaml related to device apps, package info, or installed apps\n4. The lib/ folder structure (top level only)\n\nSearch breadth: quick"}
```

**Result**

```
Perfect! Here's what I found for your Flutter project:

## Results

**1. Main Entry Point:**
`c:\project\vLearn2\flutter_app\lib\main.dart`

**2. Root Widget/App File:**
The root widget is **`VLearn2App`** (a `ConsumerWidget`) defined in `c:\project\vLearn2\flutter_app\lib\main.dart` at line 92. There's no separate `app.dart` file — the root widget is defined directly in `main.dart`.

**3. Device/Package Dependencies in pubspec.yaml:**
- **`package_info_plus: ^8.0.0`** (line 71) — Access app package information
- **`device_info_plus: ^10.1.0`** (line 72) — Get device information

**No installed apps package** — The project does not have dependencies for detecting or listing installed apps on the device.

**4. Top-Level lib/ Folder Structure:**
```
lib/
├── main.dart
├── core/          (core app logic: config, router, theme, API clients, etc.)
├── features/      (feature modules)
├── l10n/          (localization)
└── shared/        (shared widgets and utilities)
```

The architecture uses Riverpod for state management, go_router for navigation, and is structured in a layered pattern (core, features, shared).
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
1	// vLearn2 — entry point.
2	//
3	// Architecture summary:
4	//   * State: Riverpod. Every cross-screen thing (auth, settings, model
5	//     registry, API clients) lives behind a Provider so widgets stay
6	//     stateless and tests can override.
7	//   * Navigation: go_router. The single source of truth is
8	//     [routerProvider] (see core/router/app_router.dart) which wires auth
9	//     redirects, the speech-models gate, and per-route deeplinks.
10	//   * Theming: built per-(theme key × font group) pair via [AppTheme.build]
11	//     and rebuilt automatically when either changes.
12	//
13	// The runApp call uses `UncontrolledProviderScope` so we can warm one
14	// provider (the on-disk config) before the first widget tree builds. This
15	// avoids a flash of fallback config during cold start.
16	
17	import 'dart:io';
18	import 'package:flutter/material.dart';
19	import 'package:flutter_localizations/flutter_localizations.dart';
20	import 'package:flutter_riverpod/flutter_riverpod.dart';
21	import 'package:permission_handler/permission_handler.dart';
22	import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
23	import 'package:rive/rive.dart' as rive;
24	import 'core/ca
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\pubspec.yaml
```

**Result**

```
1	name: flutter_app
2	description: "vLearn2 — English learning with virtual tutor"
3	publish_to: 'none'
4	version: 1.0.0+1
5	
6	environment:
7	  sdk: ^3.11.5
8	
9	dependencies:
10	  flutter:
11	    sdk: flutter
12	  flutter_localizations:
13	    sdk: flutter
14	
15	  # State management
16	  flutter_riverpod: ^2.5.1
17	  riverpod_annotation: ^2.3.5
18	
19	  # Navigation
20	  go_router: ^14.2.0
21	
22	  # Network
23	  dio: ^5.4.3+1
24	  retrofit: ^4.1.0
25	  pretty_dio_logger: ^1.4.0
26	
27	  # Local DB
28	  drift: ^2.18.0
29	  sqlite3_flutter_libs: ^0.5.22
30	  path_provider: ^2.1.3
31	  path: ^1.9.0
32	
33	  # Models / Serialization
34	  freezed_annotation: ^2.4.2
35	  json_annotation: ^4.9.0
36	
37	  # Animation. 0.14 was a major rewrite — RiveAnimation widget removed,
38	  # replaced by RiveWidget + a (Stateless)RiveWidgetController loaded
39	  # from File.asset(...). See features/conversation/widgets/tutor_avatar.dart.
40	  rive: ^0.14.7
41	
42	  # i18n
43	  intl: ^0.20.2
44	
45	  # UI
46	  cupertino_icons: ^1.0.8
47	  cached_network_image: ^3.3.1
48	  flutter_svg: ^2.0.10+1
49	  fl_chart: ^0.68.0
50	
51	  # Network reachability — Wi-Fi/mobile detection on Android, NLM
52	  # qu
...[truncated]
```

## Claude

Now let me check the Android native setup.

**Tool - Agent**

```
{"description":"Find Android MainActivity and manifest","subagent_type":"Explore","prompt":"In c:\\project\\vLearn2\\flutter_app\\android, find:\n1. The MainActivity file (full path and content)\n2. The AndroidManifest.xml (full path)\n\nSearch breadth: quick"}
```

**Result**

```
## Results

**1. MainActivity File:**
- **Full Path:** `c:\project\vLearn2\flutter_app\android\app\src\main\kotlin\com\ryongma\vfls\MainActivity.kt`
- **Content:** The file is a Kotlin-based Flutter activity that implements three method channels for native Android communication:
  - `com.vlearn2/machine_id` - retrieves device ID via `AndroidDevID.getDeviceId()`
  - `com.vlearn2/qr_scan` - handles QR code scanning via `QRScanActivity` with two methods: "scan" (camera-based) and "scanPngDir" (directory scanning for PNG files)
  - `com.vlearn2/license_scan` - scans for license files on mounted volumes using `LicenseFileScanner`

The class extends `FlutterActivity` and uses deprecated `onActivityResult` to handle results from the QR scan activity.

**2. AndroidManifest.xml:**
- **Full Path:** `c:\project\vLearn2\flutter_app\android\app\src\main\AndroidManifest.xml`

The manifest declares permissions for:
- Internet and audio recording (for STT/mic capture)
- Camera (for QR scanning)
- External storage (READ/WRITE for Android ≤12, MANAGE_EXTERNAL_STORAGE for Android 11+)

The MainActivity is configured as the main launcher activity with single-top launch mode, and includes intent filter
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\android\app\src\main\kotlin\com\ryongma\vfls\MainActivity.kt
```

**Result**

```
1	package com.ryongma.vfls
2	
3	import android.app.Activity
4	import android.content.Intent
5	import com.example.qrscanactivity.QRScanActivity
6	import com.vlearn2.devid.AndroidDevID
7	import io.flutter.embedding.android.FlutterActivity
8	import io.flutter.embedding.engine.FlutterEngine
9	import io.flutter.plugin.common.MethodChannel
10	import io.flutter.plugin.common.MethodChannel.Result
11	
12	class MainActivity : FlutterActivity() {
13	
14	    private val QR_REQUEST_CODE = 1001
15	    private val QR_PNG_REQUEST_CODE = 1002
16	    private var pendingQrResult: Result? = null
17	    private var pendingQrPngResult: Result? = null
18	
19	    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
20	        super.configureFlutterEngine(flutterEngine)
21	
22	        // ── Machine ID channel ───────────────────────────────────────────────
23	        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vlearn2/machine_id")
24	            .setMethodCallHandler { call, result ->
25	                if (call.method == "get") {
26	                    try {
27	                        result.success(AndroidDevID.getDeviceId(applicationContext))
28	                    } ca
...[truncated]
```

## Claude

I have everything I need. I'll:
1. Add a `com.vlearn2/app_check` method channel in `MainActivity.kt` using Android's `PackageManager`
2. Add the check in `main()` and run a minimal "install required" screen if the app is missing

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\android\app\src\main\kotlin\com\ryongma\vfls\MainActivity.kt
```

**Result**

```
The file c:\project\vLearn2\flutter_app\android\app\src\main\kotlin\com\ryongma\vfls\MainActivity.kt has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now update `main.dart` to add the companion-app check before `runApp`:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

The import will be used once I add the `MethodChannel` call. Now adding the check in `main()` and the fallback screen:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now I'll add the `_checkRequiredApp` function and the fallback screen widget:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now adding the `_RequiredAppMissingScreen` widget at the bottom of `main.dart`:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Fixing the missing `const` keywords:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

These are just `Information` hints. Let me read the relevant lines to fix them precisely.

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
118	/// exits on user confirmation.
119	class _RequiredAppMissingScreen extends StatelessWidget {
120	  const _RequiredAppMissingScreen();
121	
122	  @override
123	  Widget build(BuildContext context) {
124	    return MaterialApp(
125	      debugShowCheckedModeBanner: false,
126	      home: Scaffold(
127	        body: Center(
128	          child: Padding(
129	            padding: const EdgeInsets.symmetric(horizontal: 32),
130	            child: Column(
131	              mainAxisSize: MainAxisSize.min,
132	              children: [
133	                const Icon(Icons.error_outline, size: 64, color: Colors.red),
134	                const SizedBox(height: 24),
135	                const Text(
136	                  'Required app not installed',
137	                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
138	                  textAlign: TextAlign.center,
139	                ),
140	                const SizedBox(height: 12),
141	                const Text(
142	                  'Please install the CID app (com.ryongma.cid) before using this application.',
143	                  textAlign: TextAlign.center,
144	                ),
145	                const SizedBox(h
...[truncated]
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\main.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\main.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## User

In the admin  panel, I want put configuration in http://localhost:4101/vAdmin/config/ page.

So three options 
Tutor Mode,
Message Mode,
Both Mode.

The admin should choose one at least. the default is Both Mode.
If the admin check message mode then the application should only show message mode conversation screen. There's no toggle button.
If the admin check Tutor mode then the application should only show Tutor mode character screen. There's no toggle button.
If the admin check Both mode, the application should show both along with the toggle button.

## Claude

Let me explore both the admin panel and Flutter app to understand the current structure.

**Tool - Agent**

```
{"description":"Explore admin panel config page and Flutter conversation screen","subagent_type":"Explore","prompt":"In c:\\project\\vLearn2, explore these areas and report back with file paths and key details:\n\n1. Admin panel (likely in admin/ or backend/ folder):\n   - Find the vAdmin/config/ route/page - what file handles it? Show its full content.\n   - Find where app config is stored/served (NestJS controller/service for config)\n   - What config fields currently exist?\n\n2. Flutter app (flutter_app/lib/):\n   - Find the conversation screen(s) - specifically tutor mode (character/avata ...[truncated]
```

**Result**

```
Now I have a comprehensive picture. Let me provide the final report:

## Exploration Complete - vLearn2 Config Architecture

### 1. Admin Panel Configuration System

**File:** `c:\project\vLearn2\admin_panel\src\app\(dashboard)\config\page.tsx`

The admin config page is a Next.js app route that:
- Fetches config entries via `/admin/config` API
- Displays flags organized by tabs (home, scenarios, conversation, progress, settings, report, navigation, system)
- Flags are categorized as "big" (major layout toggles) or "fine" (advanced tuning)
- Supports editing via PATCH `/admin/config/{key}` with permission gate (`config.edit`)
- Uses a flag catalog for structured metadata

**Flag Catalog File:** `c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts`

Current config fields include:
- `conversation.face_mode_available` — Tutor (face) mode reachable
- `conversation.mode_toggle` — Chat / Face mode toggle button visibility
- `conversation.mic_button` — Voice input button
- `conversation.live_caption` — Live caption in Face mode
- Plus 50+ other flags across home, scenarios, progress, settings, report, navigation, and system tabs

### 2. Backend Config Storage & Service

**Entity:** `c:\
...[truncated]
```

## Claude

Now let me read the key files in detail before implementing.

**Tool - Read**

```
c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts
```

**Tool - Read**

```
c:\project\vLearn2\admin_panel\src\app\(dashboard)\config\page.tsx
```

**Result**

```
1	// Catalog of visibility flags grouped by app tab, with "big layout" entries
2	// separated from fine-grained sub-knobs. The admin Config page reads this to
3	// render one tab per app screen, with big toggles up top and an Advanced
4	// expander for the rest.
5	//
6	// Keep keys in sync with `flutter_app/lib/core/config/layout_config_provider.dart`
7	// and `backend/src/database/seeds/seeds/app-config.seed.ts`.
8	
9	export type AppTab =
10	  | 'home'
11	  | 'scenarios'
12	  | 'conversation'
13	  | 'progress'
14	  | 'settings'
15	  | 'report'
16	  | 'navigation'
17	  | 'system';
18	
19	export interface FlagDescriptor {
20	  key: string;
21	  label: string;
22	  tier: 'big' | 'fine';
23	  tab: AppTab;
24	}
25	
26	export const APP_TABS: { id: AppTab; label: string; hint: string }[] = [
27	  { id: 'home', label: 'Home', hint: 'Daily dashboard — what the user sees on launch.' },
28	  { id: 'scenarios', label: 'Scenarios', hint: 'Topic picker and category filters.' },
29	  { id: 'conversation', label: 'Conversation', hint: 'Live chat and Tutor (face) mode.' },
30	  { id: 'progress', label: 'Progress', hint: 'CEFR card, weekly chart, skills, completions.' },
31	  { id: 'settings', labe
...[truncated]
```

**Result**

```
1	'use client';
2	
3	import { useState } from 'react';
4	import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
5	import { ChevronDown, ChevronRight } from 'lucide-react';
6	import { Card } from '@/components/ui/card';
7	import { api } from '@/lib/api';
8	import { usePermission } from '@/hooks/use-permission';
9	import {
10	  APP_TABS,
11	  FLAG_CATALOG,
12	  type AppTab,
13	  type FlagDescriptor,
14	} from '@/lib/flag-catalog';
15	
16	interface ConfigEntry {
17	  key: string;
18	  value: unknown;
19	  value_type: 'boolean' | 'string' | 'number' | 'object' | 'array';
20	  category: string;
21	  description: string;
22	  default_value: unknown;
23	  is_visible_to_app: boolean;
24	  updated_at: string;
25	}
26	
27	export default function ConfigPage() {
28	  const canEdit = usePermission('config.edit');
29	  const qc = useQueryClient();
30	  const [activeTab, setActiveTab] = useState<AppTab>('home');
31	  const [showAdvanced, setShowAdvanced] = useState(false);
32	
33	  const { data, isLoading } = useQuery<ConfigEntry[]>({
34	    queryKey: ['admin-config'],
35	    queryFn: () => api<ConfigEntry[]>('/admin/config'),
36	  });
37	
38	  const update = useMutation({
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\backend\src\database\seeds\seeds\app-config.seed.ts
```

**Result**

```
1	import { DataSource } from 'typeorm';
2	import { AppConfigEntity } from '../../entities/app-config.entity';
3	
4	/**
5	 * Default catalog of remote-config flags (see todoList/12 §12.6).
6	 * The deploy reconciler inserts any keys missing from the DB without
7	 * overwriting admin edits to existing keys.
8	 */
9	interface ConfigSeed {
10	  key: string;
11	  value: unknown;
12	  value_type: 'boolean' | 'string' | 'number' | 'object' | 'array';
13	  category:
14	    | 'home'
15	    | 'evaluation'
16	    | 'progress'
17	    | 'conversation'
18	    | 'scenarios'
19	    | 'settings'
20	    | 'system';
21	  description: string;
22	  is_visible_to_app?: boolean;
23	}
24	
25	const CATALOG: ConfigSeed[] = [
26	  // ── Evaluation ───────────────────────────────────────────
27	  {
28	    key: 'evaluation.radar.skills.pronunciation',
29	    value: true,
30	    value_type: 'boolean',
31	    category: 'evaluation',
32	    description: 'Pronunciation axis on the radar chart',
33	  },
34	  {
35	    key: 'evaluation.radar.skills.fluency',
36	    value: true,
37	    value_type: 'boolean',
38	    category: 'evaluation',
39	    description: 'Fluency axis on the radar chart',
40	  },
41	  {
42	    key
...[truncated]
```

## Claude

Now let me read the Flutter conversation screen:

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
1	import 'dart:async';
2	
3	import 'package:flutter/material.dart';
4	import 'package:flutter_riverpod/flutter_riverpod.dart';
5	import 'package:go_router/go_router.dart';
6	
7	import '../../core/api/app_apis.dart';
8	import '../../core/errors/polite_error.dart';
9	import '../../core/guard/content_guard.dart';
10	import '../../core/models/models.dart';
11	import '../../core/providers/settings_provider.dart';
12	import '../../core/providers/personas_provider.dart';
13	import '../../core/router/app_router.dart';
14	import '../../core/speech/audio_recorder.dart';
15	import '../../core/speech/speech_service.dart';
16	import '../../core/storage/model_registry.dart';
17	import '../../core/theme/bubble_style.dart';
18	import 'widgets/chat_bubble.dart';
19	import 'widgets/tutor_mode_view.dart';
20	
21	/// Materialised view of one session: the session row + every message we
22	/// have for it, in ascending sequence order.
23	class _SessionData {
24	  const _SessionData({required this.session, required this.messages});
25	  final ConversationSession session;
26	  final List<ConversationMessage> messages;
27	}
28	
29	/// Fetcher used by both Chat and Tutor modes. Family-keyed by session id so
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\core\config\layout_config_provider.dart
```

**Result**

```
1	import 'dart:async';
2	
3	import 'package:dio/dio.dart';
4	import 'package:flutter_riverpod/flutter_riverpod.dart';
5	import '../api/api_client.dart';
6	
7	class LayoutConfig {
8	  const LayoutConfig({required this.flags, this.fetchedAt});
9	  final Map<String, dynamic> flags;
10	  final DateTime? fetchedAt;
11	
12	  bool isVisible(String key, {bool fallback = true}) {
13	    final v = flags[key];
14	    return v is bool ? v : fallback;
15	  }
16	
17	  T? get<T>(String key) {
18	    final v = flags[key];
19	    return v is T ? v : null;
20	  }
21	}
22	
23	class LayoutConfigNotifier extends AsyncNotifier<LayoutConfig> {
24	  static const _bakedDefaults = <String, dynamic>{
25	    // Mirror of the §12.6 catalog defaults — used when the server is unreachable
26	    'evaluation.radar.skills.pronunciation': true,
27	    'evaluation.radar.skills.fluency': true,
28	    'evaluation.radar.skills.vocabulary': true,
29	    'evaluation.radar.skills.grammar': true,
30	    'evaluation.radar.skills.listening': true,
31	    'home.streak_banner': true,
32	    'home.continue_course': true,
33	    'home.recommended_scenarios': true,
34	    'home.notification_bell': true,
35	    'progress.skill_rada
...[truncated]
```

## Claude

Let me read the tutor mode view widget and the `_TutorModeWrapper`:

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
1	import 'dart:async';
2	import 'dart:math' as math;
3	
4	import 'package:flutter/material.dart';
5	import 'package:flutter_riverpod/flutter_riverpod.dart';
6	import 'package:go_router/go_router.dart';
7	
8	import '../../../core/errors/polite_error.dart';
9	import '../../../core/models/models.dart';
10	import '../../../core/speech/audio_recorder.dart';
11	import '../../../core/speech/speech_service.dart';
12	import '../../../core/storage/model_registry.dart';
13	import 'tutor_avatar.dart';
14	
15	/// Fullscreen voice-only tutor mode. Flexible layout (no fixed % heights),
16	/// large avatar, compact latest-speech cards, tap-to-toggle mic dock.
17	class TutorModeView extends ConsumerStatefulWidget {
18	  const TutorModeView({
19	    required this.sessionId,
20	    required this.persona,
21	    required this.messages,
22	    required this.turnCount,
23	    required this.onSendText,
24	    required this.onIdleSuggestion,
25	    required this.onSwitchToChat,
26	    required this.onEnd,
27	    required this.ending,
28	    super.key,
29	  });
30	
31	  final String sessionId;
32	  final Persona persona;
33	  final List<ConversationMessage> messages;
34	  final int turnCount;
35	  final Fu
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
268	
269	/// Splits chat mode into its own widget so the build method stays
270	/// readable. Same chat-bubble list + send box as before, now with an
271	/// optional mic button for voice input.
272	class _ChatModeBody extends ConsumerStatefulWidget {
273	  const _ChatModeBody({
274	    required this.scroll,
275	    required this.messages,
276	    required this.bubbleStyle,
277	    required this.sending,
278	    required this.scheme,
279	    required this.input,
280	    required this.onSend,
281	    required this.onSendVoiceText,
282	    this.readOnly = false,
283	    this.status,
284	  });
285	
286	  final ScrollController scroll;
287	  final List<ConversationMessage> messages;
288	  final BubbleStyle bubbleStyle;
289	  final bool sending;
290	  final ColorScheme scheme;
291	  final TextEditingController input;
292	  final VoidCallback onSend;
293	
294	  /// Called with the transcribed text when voice input completes and
295	  /// passes the content guard. Bypasses the text field.
296	  final Future<void> Function(String) onSendVoiceText;
297	
298	  /// When true, hides the send composer and shows a banner explaining the
299	  /// session is finished. Used for completed and abando
...[truncated]
```

## Claude

Let me see where `onSwitchToChat` is used in the tutor mode view:

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib
```

**Result**

```
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:25:    required this.onSwitchToChat,
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:37:  final VoidCallback onSwitchToChat;
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:241:            onSwitchToChat: widget.onSwitchToChat,
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:295:    required this.onSwitchToChat,
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:302:  final VoidCallback onSwitchToChat;
flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart:332:                onPressed: onSwitchToChat,
flutter_app\lib\features\conversation\conversation_screen.dart:246:              onSwitchToChat: () => setState(() => _viewMode = 'chat'),
flutter_app\lib\features\conversation\conversation_screen.dart:623:    required this.onSwitchToChat,
flutter_app\lib\features\conversation\conversation_screen.dart:634:  final VoidCallback onSwitchToChat;
flutter_app\lib\features\conversation\conversation_screen.dart:662:          onSwitchToChat: onSwitchToChat,
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
280	                await _startRecording();
281	              }
282	            },
283	          ),
284	        ],
285	      ),
286	    );
287	  }
288	}
289	
290	class _TutorTopBar extends StatelessWidget {
291	  const _TutorTopBar({
292	    required this.turnCount,
293	    required this.ending,
294	    required this.onBack,
295	    required this.onSwitchToChat,
296	    required this.onEnd,
297	  });
298	
299	  final int turnCount;
300	  final bool ending;
301	  final VoidCallback onBack;
302	  final VoidCallback onSwitchToChat;
303	  final VoidCallback onEnd;
304	
305	  @override
306	  Widget build(BuildContext context) {
307	    final scheme = Theme.of(context).colorScheme;
308	    return Material(
309	      color: scheme.surface,
310	      child: SafeArea(
311	        bottom: false,
312	        child: SizedBox(
313	          height: 56,
314	          child: Row(
315	            children: [
316	              IconButton(
317	                icon: const Icon(Icons.arrow_back),
318	                onPressed: onBack,
319	              ),
320	              Expanded(
321	                child: Text(
322	                  'Turn $turnCount',
323	                  textAlign: TextAlign.ce
...[truncated]
```

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
610	}
611	
612	/// Hydrates the active persona for the session, then renders [TutorModeView].
613	/// Done in its own widget so the persona FutureProvider stays scoped and
614	/// chat mode doesn't pay the lookup cost.
615	class _TutorModeWrapper extends ConsumerWidget {
616	  const _TutorModeWrapper({
617	    required this.sessionId,
618	    required this.personaId,
619	    required this.messages,
620	    required this.turnCount,
621	    required this.onSendText,
622	    required this.onIdleSuggestion,
623	    required this.onSwitchToChat,
624	    required this.onEnd,
625	    required this.ending,
626	  });
627	
628	  final String sessionId;
629	  final String personaId;
630	  final List<ConversationMessage> messages;
631	  final int turnCount;
632	  final Future<void> Function(String text) onSendText;
633	  final Future<String?> Function() onIdleSuggestion;
634	  final VoidCallback onSwitchToChat;
635	  final VoidCallback onEnd;
636	  final bool ending;
637	
638	  @override
639	  Widget build(BuildContext context, WidgetRef ref) {
640	    final displayPersonaId =
641	        ref.watch(tutorDisplayPersonaIdProvider(personaId));
642	    final persona = ref.watch(personaByIdProvider
...[truncated]
```

**Tool - Grep**

```
c:\project\vLearn2\flutter_app\lib
```

**Result**

```
flutter_app\lib\shared\widgets\app_shell.dart:42:    final cfgAsync = ref.watch(layoutConfigProvider);
flutter_app\lib\shared\widgets\layout_visibility.dart:22:    final config = ref.watch(layoutConfigProvider).valueOrNull;
flutter_app\lib\features\settings\settings_screen.dart:34:    // gate Settings rows on) lives in layoutConfigProvider's cache.
flutter_app\lib\features\settings\settings_screen.dart:38:      () => ref.read(layoutConfigProvider.notifier).refresh(),
flutter_app\lib\features\settings\settings_screen.dart:122:          // `license.enabled` on. The flag rides on layoutConfigProvider
flutter_app\lib\features\settings\settings_screen.dart:124:          if (ref.watch(layoutConfigProvider).maybeWhen(
flutter_app\lib\core\config\layout_config_provider.dart:82:final layoutConfigProvider =
```

## Claude

Now I have a complete picture. Here's what needs to change across 6 files:

1. **Seed** — add `conversation.mode` string flag
2. **Flag catalog** — add `type/options` to descriptor, add select entry, drop superseded toggles
3. **Config page** — render pill-button group for `type: 'select'` flags
4. **Flutter layout defaults** — bake in `conversation.mode: 'both'`
5. **TutorModeView** — make `onSwitchToChat` nullable, hide button when null
6. **ConversationScreen** — read `conversationMode`, enforce it

**Tool - Edit**

```
c:\project\vLearn2\backend\src\database\seeds\seeds\app-config.seed.ts
```

**Result**

```
The file c:\project\vLearn2\backend\src\database\seeds\seeds\app-config.seed.ts has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts
```

**Result**

```
The file c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts
```

**Result**

```
The file c:\project\vLearn2\admin_panel\src\lib\flag-catalog.ts has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now update the config page `FlagRow` to render pill buttons for `type: 'select'`:

**Tool - Edit**

```
c:\project\vLearn2\admin_panel\src\app\(dashboard)\config\page.tsx
```

**Result**

```
The file c:\project\vLearn2\admin_panel\src\app\(dashboard)\config\page.tsx has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now update Flutter baked defaults and the conversation screen. Starting with the layout config provider:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\core\config\layout_config_provider.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\core\config\layout_config_provider.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now make `onSwitchToChat` nullable in `TutorModeView` and `_TutorTopBar`:

**Tool - Read**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
218	        // `speaking` the moment audio playback starts; until then,
219	        // hand back to `idle` so the mic re-enables and the user
220	        // can interrupt with a new turn if they want.
221	        setState(() => _mood = TutorMood.idle);
222	      }
223	    }
224	  }
225	
226	  @override
227	  Widget build(BuildContext context) {
228	    final scheme = Theme.of(context).colorScheme;
229	    final latestTutor = _latestForRole('assistant');
230	    final latestUser = _latestForRole('user');
231	    final recording = _mood == TutorMood.listening;
232	
233	    return ColoredBox(
234	      color: scheme.surface,
235	      child: Column(
236	        children: [
237	          _TutorTopBar(
238	            turnCount: widget.turnCount,
239	            ending: widget.ending,
240	            onBack: () => context.pop(),
241	            onSwitchToChat: widget.onSwitchToChat,
242	            onEnd: widget.onEnd,
243	          ),
244	          Expanded(
245	            child: Column(
246	              children: [
247	                Expanded(
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Need to make `_TutorTopBar.onSwitchToChat` nullable too and conditionally hide the button:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now hide the switch-to-chat button when `onSwitchToChat` is null:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\widgets\tutor_mode_view.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now update `_TutorModeWrapper` to accept a nullable `onSwitchToChat`, then update `ConversationScreen` to read `conversationMode` and enforce it:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

Now update the `build` method in `_ConversationScreenState` to read `conversationMode` and enforce it. First add the import:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

## Claude

The import will be used once I update the `build` method. Now rewrite the core `build` logic to enforce `conversationMode`:

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart has been updated successfully. (file state is current in your context — no need to Read it back)
```

**Tool - Edit**

```
c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart
```

**Result**

```
The file c:\project\vLearn2\flutter_app\lib\features\conversation\conversation_screen.dart has been updated. All occurrences were successfully replaced. (file state is current in your context — no need to Read it back)
```

## Claude

Now commit everything:

**Tool - Bash**

```
git add backend/src/database/seeds/seeds/app-config.seed.ts admin_panel/src/lib/flag-catalog.ts "admin_panel/src/app/(dashboard)/config/page.tsx" flutter_app/lib/core/config/layout_config_provider.dart flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart flutter_app/lib/features/conversation/conversation_screen.dart && git diff --cached --stat
```

**Result**

```
warning: in the working copy of 'admin_panel/src/lib/flag-catalog.ts', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'backend/src/database/seeds/seeds/app-config.seed.ts', LF will be replaced by CRLF the next time Git touches it
 admin_panel/src/app/(dashboard)/config/page.tsx    | 30 +++++++++++++++++++--
 admin_panel/src/lib/flag-catalog.ts                | 14 ++++++++--
 .../src/database/seeds/seeds/app-config.seed.ts    |  8 ++++++
 .../lib/core/config/layout_config_provider.dart    |  1 +
 .../features/conversation/conversation_screen.dart | 31 +++++++++++++++++-----
 .../conversation/widgets/tutor_mode_view.dart      | 19 ++++++-------
 6 files changed, 84 insertions(+), 19 deletions(-)
```

**Tool - Bash**

```
cd c:\project\vLearn2 && powershell -Command "Get-Date -Format 'yyMMdd_HHmmss'"
```

**Result**

```
Exit code 1
/usr/bin/bash: line 1: cd: c:projectvLearn2: No such file or directory
```

**Tool - PowerShell**

```
Get-Date -Format 'yyMMdd_HHmmss'
```

**Result**

```
260601_151527
```

**Tool - Write**

```
c:\project\vLearn2\story_claude\2026_06_01\260601_151527_Admin_conversation_mode_config.md
```

**Result**

```
File created successfully at: c:\project\vLearn2\story_claude\2026_06_01\260601_151527_Admin_conversation_mode_config.md (file state is current in your context — no need to Read it back)
```

**Tool - PowerShell**

```
git add story_claude/2026_06_01/260601_151527_Admin_conversation_mode_config.md && git commit -m "Add conversation.mode config: tutor/message/both with admin UI and Flutter enforcement"
```

---

## User prompts (verbatim)

### Prompt 1

```
<ide_opened_file>The user opened the file c:\project\vLearn2\cmds\seed_fetch.ps1 in the IDE. This may or may not be related to the current task.</ide_opened_file>

I want this app to check a certain apk installed on the android device.
So when the app first launch, it checks the application for "com.ryongma.cid" and if it doesn't installed on the android device then alert message to install the app and exit the application.
```

### Prompt 2

```
In the admin  panel, I want put configuration in http://localhost:4101/vAdmin/config/ page.

So three options 
Tutor Mode,
Message Mode,
Both Mode.

The admin should choose one at least. the default is Both Mode.
If the admin check message mode then the application should only show message mode conversation screen. There's no toggle button.
If the admin check Tutor mode then the application should only show Tutor mode character screen. There's no toggle button.
If the admin check Both mode, the application should show both along with the toggle button.
```


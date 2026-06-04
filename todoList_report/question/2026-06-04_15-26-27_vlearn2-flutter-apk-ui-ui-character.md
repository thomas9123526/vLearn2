# 당신은 vLearn2 flutter apk가 실기기에서 유연하게 동작하고 사용자가 ui가 굳거나 이상증상을 느끼지 않는지 확인할수 있는가? 특히

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-04T06:26:27.458Z

## User

당신은 vLearn2 flutter apk가 실기기에서 유연하게 동작하고 사용자가 ui가 굳거나 이상증상을 느끼지 않는지 확인할수 있는가? 특히 음성인식과 음성발성을 할때 ui가 유연하며 character가 자연스럽게 반응하는것처럼 보여야 하는데 실지 그렇게 된다고 담보할수 있는가?

## Assistant

솔직하게 답변드리겠습니다. 저는 **실기기에서 직접 실행하거나 테스트할 수 없기 때문에 보장(guarantee)은 불가능합니다.** 대신 코드를 직접 분석해서 실제 위험 요소가 있는지 확인하겠습니다.

특히 고위험 영역인 sherpa-onnx STT/TTS 파이프라인, PCM amplitude → Rive 연동, UI thread 차단 여부를 집중 점검합니다.

## Assistant

분석 결과가 나왔습니다. 코드에서 실제 문제점을 직접 확인하겠습니다.

## Assistant

이제 실제 코드를 확인했습니다. **솔직하게 말씀드립니다.**

---

## 보장 불가 — 그리고 이유

저는 실기기 APK를 실행할 수 없으므로 동작을 담보할 수 없습니다. 코드 분석으로 **구체적인 위험 지점 3개**를 발견했습니다.

---

## 확인된 실제 문제점

### 🔴 문제 1 — STT 추론이 UI 스레드를 차단 (고위험)

[sherpa_onnx_stt.dart:189-204](flutter_app/lib/core/speech/sherpa_onnx_stt.dart#L189-L204)

```dart
// 이 while 루프 전체가 메인 UI isolate에서 동기 실행됨
while (_online!.isReady(stream)) {
  _online!.decode(stream);  // ← 동기 FFI 블로킹 호출
}
// 또는 오프라인 Whisper:
_offline!.decode(stream);   // ← 동기 FFI 블로킹 호출
```

`async` 키워드가 있지만 Dart에서 `async`는 별도 스레드를 만들지 않습니다. FFI 호출은 메인 isolate를 **완전히 점유**합니다. 녹음 종료 후 STT 추론이 끝날 때까지 UI 애니메이션, 터치 입력, 캐릭터 움직임이 모두 멈춥니다. `compute()` / `Isolate.run()` 사용 없음 — **확인됨**.

### 🔴 문제 2 — TTS 첫 합성이 UI 스레드를 차단 (중~고위험)

[sherpa_onnx_tts.dart:289](flutter_app/lib/core/speech/sherpa_onnx_tts.dart#L289)

```dart
final audio = _engine!.generate(   // ← VITS 추론, 동기 FFI
  text: text,
  sid: sid,
  speed: rate,
);
```

처음 보는 텍스트는 캐시가 없어서 VITS 모델 추론이 그대로 메인 스레드에서 실행됩니다. 두 번째부터는 캐시 덕분에 빠르지만:

```dart
if (cacheFile.existsSync()) {
  return cacheFile.readAsBytes();  // ← 동기 파일 I/O (async가 아님)
}
```

캐시 읽기/쓰기도 동기입니다.

### 🟡 문제 3 — TTS 재생 중 setState() 초당 60회 호출 (저~중위험)

[tutor_mode_view.dart:79-82](flutter_app/lib/features/conversation/widgets/tutor_mode_view.dart#L79-L82)

```dart
_ampSub = tts.amplitudeStream.listen((double amp) {
  if (!mounted) return;
  setState(() => _amplitude = amp);  // ← 16ms마다 전체 위젯 재빌드
});
```

TTS가 말하는 동안 `TutorModeView` 전체를 초당 60번 재빌드합니다. 고사양 기기에서는 문제없지만 저~중사양 기기에서 프레임 드롭 원인이 됩니다.

---

## 지금 바로 고칠 수 있는 것 vs 아닌 것

| 문제 | 수정 난이도 | 설명 |
|---|---|---|
| setState() 60회/초 | **쉬움** — 지금 가능 | `ValueNotifier` + `ValueListenableBuilder`로 교체 |
| 동기 파일 I/O | **쉬움** — 지금 가능 | `readAsBytes()` → `await file.readAsBytes()` |
| STT FFI 메인스레드 차단 | **어려움** — 구조 변경 필요 | sherpa-onnx 객체를 별도 Isolate로 이전해야 함. FFI 핸들은 isolate 간 전달 불가라 통신 구조 전체 재설계 필요 |
| TTS FFI 메인스레드 차단 | **어려움** — 구조 변경 필요 | 동일 |

---

## 어떻게 하시겠습니까?

**옵션 A — 지금 가능한 것만 수정** (빠름, 10-15분):
- setState() → ValueNotifier 교체 (문제 3 해결)
- 동기 파일 I/O → async 교체 (문제 2 부분 완화)
- TTS 첫 합성을 앱 시작 시 pre-warm으로 숨기기

**옵션 B — STT/TTS 전체를 백그라운드 Isolate로 이전** (크고 위험한 변경):
- STT 서비스를 전용 Isolate에서 실행, PCM 데이터를 `SendPort`로 전달
- TTS도 동일한 패턴
- 구조가 크게 바뀌므로 회귀 위험이 높음

**옵션 C — 실기기에서 먼저 직접 테스트**:
- 실제 기기에서 APK 설치 후 음성 입력 → 결과 대기 시간을 직접 측정
- 만약 딜레이가 느껴지면 Isolate 분리 작업 진행

솔직히 말씀드리면 **옵션 C가 먼저**가 맞습니다. 기기 성능(ARM64 칩 속도)에 따라 STT 추론이 200ms일 수도 있고 3초일 수도 있습니다. 느껴질 만큼 얼어붙는지 실측 없이는 알 수 없습니다.

어떻게 진행하시겠습니까?

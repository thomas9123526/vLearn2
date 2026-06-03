# Conversation - Fix AhnLab ASProxy64.dll crash in Gradle/Java 21

| Field | Value |
|---|---|
| Saved | 2026-06-03 01:36:39 |
| Commit | fix: force legacy Windows selector to avoid AhnLab ASProxy64.dll crash on Java 21 |
| Project | C:\project\vLearn2 |

---

## User

(flutter build apk --debug crash log showing EXCEPTION_ILLEGAL_INSTRUCTION in ASProxy64.dll)

## Assistant

Root cause: AhnLab security software (ASProxy64.dll) injects into Java processes and hooks Windows I/O calls. Java 21 introduced a new WEPoll-based selector (`sun.nio.ch.WEPollSelectorProvider`) which AhnLab's hook crashes with an illegal instruction at `WEPoll.ctl`. Fixed by adding `-Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.WindowsSelectorProvider` to `org.gradle.jvmargs` in `gradle.properties`, forcing the older Windows selector that AhnLab doesn't crash.

---

## Prompt

(flutter build apk --debug crash with ASProxy64.dll EXCEPTION_ILLEGAL_INSTRUCTION)

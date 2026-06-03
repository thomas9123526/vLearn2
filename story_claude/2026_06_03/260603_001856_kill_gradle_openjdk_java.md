# Conversation - Kill Gradle and OpenJDK Java processes

| Field | Value |
|---|---|
| Saved | 2026-06-03 00:18:56 |
| Commit | feat: extend kill_gradle_java_pid.ps1 to also match jre/openjdk/jdk patterns |
| Project | C:\project\vLearn2 |

---

## User

also want kill java openjdk related process

## Assistant

Updated `cmds/kill_gradle_java_pid.ps1` to match four patterns: `*gradle*`, `*openjdk*`, `*jdk*`, `*jre*`. Added `*jre*` after discovering the VS Code redhat.java extension uses a `jre`-pathed bundled OpenJDK (not `jdk`). Tested — correctly killed PID 19420 (Eclipse JDT language server).

---

## Prompt

also want kill java openjdk related process

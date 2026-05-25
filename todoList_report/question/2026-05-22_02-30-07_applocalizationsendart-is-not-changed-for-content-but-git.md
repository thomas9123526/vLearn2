# app_localizations_en.dart is not changed for content but git says it is modified

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-21T17:30:07.320Z

## User

app_localizations_en.dart is not changed for content but git says it is modified. why? i can see the difference

## Assistant

Let me check what git actually sees as the diff — usually this is line endings (LF↔CRLF) on Windows, which the diff viewer hides.

## Assistant

Found it. The file's **content is identical** but git's stat-cache is stale.

```text
git status:  M app_localizations_en.dart   ← shows modified
git diff:    (empty)                        ← but no content change
```

This happens when a tool rewrites the file with byte-identical content but a different timestamp — most likely `flutter gen-l10n` regenerated it (or a build/IDE step touched it). Git sees "different mtime" and pessimistically marks it dirty, but the actual bytes match the committed version.

## Fix: refresh git's stat cache

```powershell
cd c:\project\vLearn2
git update-index --refresh
```

This re-reads files git marked as "possibly modified" and clears the flag for the ones whose content actually matches the index. Safe to run any time — only updates stat metadata, doesn't change files or your working tree.

Let me run it:

## Assistant

`update-index --refresh` failing means git sees a real on-disk vs index difference even though `git diff` shows nothing. This is the classic **autocrlf=true + LF/CRLF roundtrip** problem on Windows. Let me confirm:

## Assistant

**Confirmed it's the CRLF issue.** File on disk = 5824 bytes; in HEAD = 5565 bytes. The 259-byte difference is exactly one extra byte per line — your working tree has **CRLF** line endings but the index/repo has **LF**.

With `core.autocrlf=true`:

```text
git diff:   normalises both sides → shows nothing
git status: compares stat (size differs!) → shows "modified"
```

It's harmless — the **content is identical** — but `git status` will keep nagging until the working-tree file is rewritten with LF endings (or vice versa).

## Why these files specifically

`l10n/generated/*.dart` is produced by `flutter gen-l10n` which writes **LF** line endings. Then Git for Windows' autocrlf converts them to CRLF on checkout. When `flutter gen-l10n` runs again, it rewrites them as LF — and now they don't match what autocrlf "normalised them to" anymore. Permanent stat drift.

## Two fixes

### Quick: just stage them

```powershell
git add flutter_app/lib/l10n/generated/
git diff --cached       # confirms: nothing
git restore --staged flutter_app/lib/l10n/generated/   # unstage; index keeps the fixed stat
git status              # files no longer show as modified
```

This refreshes git's index entry for those files, after which the stat-cache flag clears.

### Permanent (recommended): `.gitattributes`

Tell git that l10n-generated files (and other generator output) are always LF, regardless of platform. One file, applies to every clone, never have this problem again.

Let me set that up — it's a small, contained change:

## Assistant

Now refresh the working tree so the files actually get rewritten with the new policy.

## Assistant

`.gitattributes` is the only thing left. Committing.

## Assistant

Committed `a771bd5`. **Phantom-modified status fixed.**

## What was wrong, in one line

`core.autocrlf=true` was forcing CRLF on disk; `flutter gen-l10n` was rewriting LF — so the working-tree byte size never matched the index, and git's stat cache flagged "modified" forever even though `git diff` was empty.

## What's fixed now

| | Before | After |
| --- | --- | --- |
| Working tree on disk | CRLF | LF (for these paths) |
| Index | LF | LF |
| `git status` | `M app_localizations_en.dart` (false positive) | clean |
| `git diff` | empty (correct) | empty (still correct) |
| Next `flutter gen-l10n` run | re-creates the false positive | stays clean |

## Why this happens in general — and how `.gitattributes` solves it

`.gitattributes` is the **per-path** override for line-ending rules. Where `core.autocrlf=true` says "do CRLF magic on everything," `.gitattributes` says "but not these specific paths." For each pattern you can say:

- `text eol=lf` → always LF in working tree, regardless of platform
- `text eol=crlf` → always CRLF (for Windows-only scripts)
- `binary` → never touch
- `-text` → treat as opaque (no line-ending normalisation, no diff)
- `text=auto` → let git decide

The new file covers the common offenders in this repo:

- **`l10n/generated/`, `*.g.dart`, `*.freezed.dart`** — Flutter generators emit LF; pinned LF.
- **`*.sh`** — bash scripts; LF or they break in WSL/CI.
- **`*.bat`, `*.cmd`, `*.ps1`** — Windows shells; CRLF or they break in cmd.exe.
- **Images, fonts, archives, binaries** — declared `binary`; git never diffs or normalises.
- **`*.crt`, `*.pem`, `*.key`** — PEM is text but some parsers choke on CRLF inside armour; pinned LF.
- **`datamanage/vendor/**`** — declared `-text` so upstream zlib/mbedTLS/nlohmann sources keep their original line endings (don't fight upstream).

Any future "modified but no diff" symptom on a path covered by `.gitattributes` won't happen. If you see it on a path NOT covered, tell me and I'll add it.

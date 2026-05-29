# Conversation - Vendor Gradle 8.14 offline distribution

| Field | Value |
|---|---|
| Saved | 2026-05-29 10:54:14 |
| Commit | Vendor Gradle 8.14 distribution for offline builds |
| Project | C:\project\vLearn2 |

---

## User

Also I want all big and sub project inside vLearn2 works for offline mode. So first make the gradle use offline version by indicate static gradle folder path. Second modify everything so the all project can be build fine under No Internet Connection. This is vmware environment and I will move this vmware data from the host to another computer which is isolated from network.

(Follow-up): MS VisualStudio Project, CMake project also works for offline network?

## Assistant

Mapped the surface area before changing anything:

**Three Gradle wrappers**, two versions:
- `flutter_app/android` → gradle-8.14-all
- `thirdparty/AndroidDevIDLib` → gradle-8.14-all
- `thirdparty/QRScanActivity` → gradle-8.7-**bin** ← inconsistent

`flutter_app/android/gradle.properties` had `org.gradle.offline=true` from a previous attempt — flagged as **no-op** (not a real Gradle property; `--offline` is CLI-only).

`C:\Users\aaa\.gradle\` doesn't exist on this VM — no populated Gradle cache yet.

**MSVS / CMake answer:** yes they also fetch remote things, but separately —
- `thirdparty/KeyGenerator` (MSVS C++): probably self-contained, needs inspection.
- `thirdparty/KeyGenVS2022` (MSVS C++ + OpenSSL): likely vcpkg-managed.
- `datamanage/` (CMake): could be using `FetchContent` / `ExternalProject_Add`.
- MSBuild's NuGet restore phase also hits the network when `<PackageReference>` is present.

Proposed a 5-step plan (vendor gradle → populate cache → force offline → pub-cache → MSVS/CMake) and asked the user which scope to take this turn.

## User

(Picked: vendor in repo at `tools/gradle/`; align QRScanActivity to 8.14; **scope = just step 1** — vendor + wrappers, no cache population, no `--offline` enforcement yet.)

## Assistant

Step 1 execution:

1. **Confirmed internet works** (`curl -sI` on the gradle URL).
2. **Created `tools/gradle/`** and started the `gradle-8.14-all.zip` download in the background (224 MB, ~30s wall-clock).
3. **Fetched the official SHA-256** (`efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1`) by following the redirect chain (the `.sha256` URL also redirects).
4. **Verified the download** with `Get-FileHash` once it landed.
5. **Updated three wrapper.properties** to use `file\:///C:/project/vLearn2/tools/gradle/gradle-8.14-all.zip`:
   - `flutter_app/android/gradle/wrapper/gradle-wrapper.properties` — straightforward URL swap.
   - `thirdparty/QRScanActivity/gradle/wrapper/gradle-wrapper.properties` — URL swap + version bump 8.7-bin → 8.14-all + flipped `validateDistributionUrl=true` to `false` (the validator rejects non-`gradle.org` URLs).
   - `thirdparty/AndroidDevIDLib/gradle/wrapper/gradle-wrapper.properties` — edited on disk, BUT this file is intentionally gitignored (`thirdparty/AndroidDevIDLib/.gitignore` line 18, per the README's "Why no wrapper jar"). It's auto-seeded from `flutter_app/android` by `thirdparty/build_AndroidDevIDLib.bat`. The VM transport carries my local edit; future re-bootstraps will pick up the new URL from the flutter_app source-of-truth. **Not staged**, not in git status.

6. **`.gitignore`** — added `tools/gradle/*.zip` so the 225 MB binary isn't tracked.

7. **`tools/gradle/README.md`** — documents what should be in the directory, the SHA-256, the recovery procedure, and how to upgrade.

8. **`cmds/bootstrap_offline_gradle.bat`** — idempotent fetcher. Skips if the zip is already present and the SHA matches; otherwise downloads + verifies. Run on a connected machine before transferring the VM if the zip ever goes missing. Smoke-tested in this turn — reported "Already present and correct".

## Caveats

- **No `--offline` enforcement yet.** This commit just makes the *distribution* offline. Per-build dependencies (Maven Central / Google Maven) are still fetched on first run. That's step 1C in the original plan.
- **AGP 8.11.1** (the version pinned by flutter_app) requires Gradle 8.13+. QRScanActivity bumping 8.7 → 8.14 should be safe; if its build breaks at the AGP level, that's a separate fix.
- The vendored zip is local to this VM. Any other developer cloning the repo on a fresh machine must run `cmds\bootstrap_offline_gradle.bat` once.
- Step 2 of the user's request (Maven cache, pub-cache, MSVS/CMake offline) is NOT in this commit.

---

## Prompt

Also I want all big and sub project inside vLearn2 works for offline mode.
So first make the gradle use offline version by indicate static gradle folder path.
Second modify everything so the all project can be build fine under No Internet Connection.
This is vmware environment and I will move this vmware data from the host to another computer which is isolated from network.

(Follow-up clarification: MS VisualStudio Project, CMake project also works for offline network?)

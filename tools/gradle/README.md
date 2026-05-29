# Vendored Gradle distribution

This directory holds a checked-out-of-band copy of the Gradle binary so all
`gradle-wrapper.properties` files in the repo can resolve their `distributionUrl`
from disk instead of `https://services.gradle.org`. Required for the offline-build
workflow (this VM will be moved to a network-isolated machine).

## Expected contents

| File | Purpose |
|---|---|
| `gradle-8.14-all.zip` | The Gradle 8.14 "all" distribution (binaries + sources + docs). Referenced by every `gradle-wrapper.properties` in this repo. |

The zip itself is **gitignored** (~225 MB, not appropriate for the repo). It travels
with the VMware data when the VM is migrated.

## How wrappers reference it

Each `gradle-wrapper.properties` (in `flutter_app/android/`, `thirdparty/AndroidDevIDLib/`,
and `thirdparty/QRScanActivity/`) has:

```
distributionUrl=file\:///C:/project/vLearn2/tools/gradle/gradle-8.14-all.zip
```

The `file:///` URL is absolute. The project path `C:\project\vLearn2` is fixed for
this VM (see [memory: vm-environment](../../../Users/aaa/.claude/projects/c--project-vLearn2/memory/vm-environment.md)).
If the project root ever moves, update every wrapper.

## Re-fetching the zip

If `tools/gradle/gradle-8.14-all.zip` is missing (fresh checkout on a connected
machine), run from a Windows shell with internet:

```
cmds\bootstrap_offline_gradle.bat
```

Or manually:

```
curl -fL -o tools\gradle\gradle-8.14-all.zip ^
    https://services.gradle.org/distributions/gradle-8.14-all.zip
```

Then verify SHA-256 = `efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1`.

## Upgrading Gradle

1. Download the new `gradle-X.Y-all.zip` into this directory.
2. Update `distributionUrl` in every `gradle-wrapper.properties` to the new filename.
3. Update the bootstrap script (`cmds\bootstrap_offline_gradle.bat`) version + SHA-256.
4. Delete the old zip.

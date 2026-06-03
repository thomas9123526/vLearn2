# -----------------------------------------------------------------------------
#  vLearn2 - First-time machine setup / path reset
#
#  Run once after `git pull` on a new machine, or any time you want to change
#  tool paths.
#
#  Steps performed:
#    1. Auto-detects Android Studio, Java, SDK, Gradle, pub-cache paths
#    2. Prompts to confirm or override each
#    3. Saves to cmds\env-local.ps1  (gitignored, machine-specific)
#    4. Writes .vscode\settings.json  (gitignored) so VS Code Java/Gradle
#       extensions use the same GRADLE_USER_HOME as env-local.ps1
#    5. Generates flutter_app\android\local.properties  (sdk.dir)
#    6. Runs `flutter config --android-studio-dir` so flutter doctor is happy
#    7. Seeds the vendored Gradle wrapper zip into the Gradle dists cache
#    8. Installs the offline Gradle init script
#
#  Re-run any time to reset paths.
# -----------------------------------------------------------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT             = Split-Path $PSScriptRoot -Parent
$ENV_LOCAL        = "$PSScriptRoot\env-local.ps1"
$GRADLE_VERSION   = '8.14'
$GRADLE_VARIANT   = 'all'
$GRADLE_ZIP_NAME  = "gradle-$GRADLE_VERSION-$GRADLE_VARIANT.zip"
$GRADLE_DIST_HASH = '6umpftuah39kegplpls29ixk'   # deterministic hash of the gradle-8.14-all URL
$VENDORED_ZIP     = "$ROOT\tools\gradle\$GRADLE_ZIP_NAME"

# -- helpers -------------------------------------------------------------------

function Ask-Path {
    param([string]$Label, [string]$Default)
    Write-Host "  $Label"
    Write-Host "  Detected: $Default" -ForegroundColor DarkGray
    $ans = Read-Host "  New value (Enter to keep)"
    if ([string]::IsNullOrWhiteSpace($ans)) { return $Default }
    return $ans.Trim().TrimEnd('\')
}

# Try a list of candidate paths and return the first that exists.
function Find-First {
    param([string[]]$Candidates)
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

# -- load existing env-local.ps1 so defaults reflect prior choices -------------
if (Test-Path $ENV_LOCAL) {
    Write-Host "Loading existing config from cmds\env-local.ps1 ..."
    . $ENV_LOCAL
}

# -- auto-detect Android Studio ------------------------------------------------
$defaultStudio = Find-First @(
    $env:ANDROID_STUDIO_HOME,
    'C:\Program Files\Android\Android Studio',
    'C:\Android\Android Studio',
    'D:\Android Studio',
    'E:\Android Studio',
    'E:\vm_share\Android Studio',
    'E:\vm_share\AndroidStudio'
)
if (-not $defaultStudio) { $defaultStudio = 'C:\Program Files\Android\Android Studio' }

# -- auto-detect JAVA_HOME: prefer JDK bundled in Android Studio ---------------
$defaultJava = Find-First @(
    $env:JAVA_HOME,
    "$defaultStudio\jbr",   # Android Studio >= Flamingo
    "$defaultStudio\jre",   # older Android Studio
    'C:\Program Files\Java\jdk-17',
    'C:\Program Files\Eclipse Adoptium\jdk-17*',
    'C:\Program Files\Microsoft\jdk-17*'
)
if (-not $defaultJava) { $defaultJava = "$defaultStudio\jbr" }

# -- auto-detect Android SDK ---------------------------------------------------
$defaultSdk = Find-First @(
    $env:ANDROID_SDK_ROOT,
    $env:ANDROID_HOME,
    'C:\Users\aaa\AppData\Local\Android\Sdk',
    "$env:LOCALAPPDATA\Android\Sdk",
    'E:\vm_share\Sdk',
    'C:\Android\Sdk'
)
if (-not $defaultSdk) { $defaultSdk = "$env:LOCALAPPDATA\Android\Sdk" }

# -- auto-detect Gradle cache --------------------------------------------------
$defaultGradle = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } `
                 else                        { "$env:USERPROFILE\.gradle" }

# -- auto-detect pub cache -----------------------------------------------------
$defaultPub = if ($env:PUB_CACHE) { $env:PUB_CACHE } `
              else                 { "$env:LOCALAPPDATA\Pub\Cache" }

# -- interactive prompts -------------------------------------------------------
Write-Host ''
Write-Host '=== vLearn2 machine setup ===' -ForegroundColor Cyan
Write-Host 'Press Enter to keep the detected value, or type a new absolute path.'
Write-Host ''

$studioDir  = Ask-Path 'Android Studio dir  (ANDROID_STUDIO_HOME)' $defaultStudio
$javaHome   = Ask-Path 'Java / JDK dir      (JAVA_HOME)'           $defaultJava
$sdkDir     = Ask-Path 'Android SDK dir     (ANDROID_SDK_ROOT)'    $defaultSdk
$gradleHome = Ask-Path 'Gradle cache dir    (GRADLE_USER_HOME)'    $defaultGradle
$pubCache   = Ask-Path 'Pub cache dir       (PUB_CACHE)'           $defaultPub

# -- confirm -------------------------------------------------------------------
Write-Host ''
Write-Host 'Will configure:' -ForegroundColor Cyan
Write-Host "  ANDROID_STUDIO_HOME = $studioDir"
Write-Host "  JAVA_HOME           = $javaHome"
Write-Host "  ANDROID_SDK_ROOT    = $sdkDir"
Write-Host "  GRADLE_USER_HOME    = $gradleHome"
Write-Host "  PUB_CACHE           = $pubCache"
Write-Host ''
$ok = Read-Host 'Proceed? [Y/n]'
if ($ok -match '^[Nn]') { Write-Host 'Aborted.'; exit 0 }

# -- 1. Write cmds\env-local.ps1 -----------------------------------------------
Write-Host ''
Write-Host '--- Writing cmds\env-local.ps1 ---'
@"
# Machine-specific paths - generated by cmds\setup.ps1.  DO NOT commit.
`$env:ANDROID_STUDIO_HOME = '$studioDir'
`$env:JAVA_HOME           = '$javaHome'
`$env:ANDROID_SDK_ROOT    = '$sdkDir'
`$env:ANDROID_HOME        = '$sdkDir'
`$env:GRADLE_USER_HOME    = '$gradleHome'
`$env:PUB_CACHE           = '$pubCache'
`$env:PATH                = '$sdkDir\platform-tools;$sdkDir\cmdline-tools\latest\bin;' + `$env:PATH
"@ | Set-Content $ENV_LOCAL -Encoding UTF8
# Apply immediately in this session
$env:ANDROID_STUDIO_HOME = $studioDir
$env:JAVA_HOME           = $javaHome
$env:ANDROID_SDK_ROOT    = $sdkDir
$env:ANDROID_HOME        = $sdkDir
$env:GRADLE_USER_HOME    = $gradleHome
$env:PUB_CACHE           = $pubCache
# Remove any stale persistent user-level GRADLE_USER_HOME so VS Code
# extensions don't bypass .vscode/settings.json with the wrong path.
[Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', $null, 'User')
Write-Host 'Written.'

# -- 2. Write .vscode\settings.json (gitignored, machine-specific) ------------
Write-Host ''
Write-Host '--- Writing .vscode\settings.json (Gradle user home for VS Code extensions) ---'
$vscodeDir      = "$ROOT\.vscode"
$vscodeSettings = "$vscodeDir\settings.json"
New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null
@{ 'java.import.gradle.user.home' = $gradleHome; 'gradle.gradleUserHome' = $gradleHome } |
    ConvertTo-Json | Set-Content $vscodeSettings -Encoding UTF8
Write-Host "Written: $vscodeSettings"

# -- 3. Generate flutter_app\android\local.properties -------------------------
Write-Host ''
Write-Host '--- Generating flutter_app\android\local.properties ---'
$localProps = "$ROOT\flutter_app\android\local.properties"
$sdkEscaped = $sdkDir -replace '\\', '\\'
"sdk.dir=$sdkEscaped" | Set-Content $localProps -Encoding UTF8
Write-Host "Written: $localProps"

# -- 4. Register Android Studio with Flutter -----------------------------------
Write-Host ''
Write-Host '--- Registering Android Studio with Flutter ---'
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter config --android-studio-dir="$studioDir" 2>&1 | Write-Host
    Write-Host 'Done.'
} else {
    Write-Warning 'flutter not found in PATH - skipping flutter config.'
    Write-Warning 'Add Flutter to PATH, then run: flutter config --android-studio-dir="$studioDir"'
}

# -- 5. Seed Gradle wrapper dists cache ---------------------------------------
Write-Host ''
Write-Host '--- Seeding Gradle wrapper dists cache ---'
if (-not (Test-Path $VENDORED_ZIP)) {
    Write-Warning "Vendored zip not found: $VENDORED_ZIP"
    Write-Warning 'Run cmds\bootstrap_offline_gradle.bat first to download it, then re-run setup.'
} else {
    $distDir = "$gradleHome\wrapper\dists\gradle-$GRADLE_VERSION-$GRADLE_VARIANT\$GRADLE_DIST_HASH"
    $destZip = "$distDir\$GRADLE_ZIP_NAME"
    if (-not (Test-Path $destZip)) {
        New-Item -ItemType Directory -Force -Path $distDir | Out-Null
        Copy-Item $VENDORED_ZIP -Destination $destZip
        Write-Host "Seeded: $destZip"
    } else {
        Write-Host 'Already seeded - skipping.'
    }
}

# -- 6. Install offline Gradle init script ------------------------------------
Write-Host ''
Write-Host '--- Installing offline Gradle init script ---'
$initSrc  = "$ROOT\tools\gradle\init.d\offline.init.gradle"
$initDest = "$gradleHome\init.d\offline.init.gradle"
if (Test-Path $initSrc) {
    New-Item -ItemType Directory -Force -Path (Split-Path $initDest) | Out-Null
    Copy-Item $initSrc -Destination $initDest -Force
    Write-Host "Installed: $initDest"
} else {
    Write-Warning "Init script not found: $initSrc - skipping."
}

# -- done ----------------------------------------------------------------------
Write-Host ''
Write-Host '=== Setup complete ===' -ForegroundColor Green
Write-Host ''
Write-Host '  Paths are active in this shell session.'
Write-Host '  To reload them in a NEW shell, run:'
Write-Host '      . cmds\env-local.ps1' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Run flutter doctor:  flutter doctor'
Write-Host '  Build offline:       flutter build apk --debug'
Write-Host '  Go online:           cmds\vlearn2-online.ps1 on'
Write-Host '  Go offline:          cmds\vlearn2-online.ps1 off'

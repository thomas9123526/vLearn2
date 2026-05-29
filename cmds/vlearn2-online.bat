@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Toggle / check the VLEARN2_ONLINE env var.
REM
REM  Recap: the Gradle init script at %GRADLE_USER_HOME%\init.d\
REM  offline.init.gradle reads this var and decides offline vs network:
REM    VLEARN2_ONLINE=1  → gradle uses the network (fetch new deps)
REM    unset / anything else → gradle.startParameter.offline = true
REM
REM  Usage:
REM    cmds\vlearn2-online.bat              (alias for `status`)
REM    cmds\vlearn2-online.bat status       Show current shell + persistent
REM    cmds\vlearn2-online.bat on           Set =1 in THIS shell
REM    cmds\vlearn2-online.bat off          Clear in THIS shell
REM    cmds\vlearn2-online.bat persist-on   setx =1 for User scope (every
REM                                          new cmd will inherit ON — only
REM                                          use if you want online as the
REM                                          permanent default; discouraged)
REM    cmds\vlearn2-online.bat persist-off  reg-delete from User scope
REM                                          (revert persist-on)
REM
REM  IMPORTANT: NO `setlocal` in this script. Env-var changes from a batch
REM  file only persist into the calling cmd if the script avoids setlocal
REM  scoping. So `on` / `off` actually take effect in your interactive
REM  prompt rather than dying with the child cmd.
REM ─────────────────────────────────────────────────────────────────────────

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"

if /I "%ACTION%"=="on"          goto :on
if /I "%ACTION%"=="off"         goto :off
if /I "%ACTION%"=="status"      goto :status
if /I "%ACTION%"=="persist-on"  goto :persist_on
if /I "%ACTION%"=="persist-off" goto :persist_off

echo ERROR: unknown action "%ACTION%"
echo Usage: %~nx0 [on^|off^|status^|persist-on^|persist-off]
exit /b 1


:on
set "VLEARN2_ONLINE=1"
echo VLEARN2_ONLINE = 1   ^(this shell only; gradle will use the network^)
exit /b 0


:off
set "VLEARN2_ONLINE="
echo VLEARN2_ONLINE cleared ^(this shell; gradle is offline-by-default^)
exit /b 0


:status
echo === VLEARN2_ONLINE status ===

REM Current shell
if "%VLEARN2_ONLINE%"=="1" (
    echo Current shell:     ON   ^(network allowed^)
) else if "%VLEARN2_ONLINE%"=="" (
    echo Current shell:     off  ^(offline; default^)
) else (
    echo Current shell:     unrecognized value [%VLEARN2_ONLINE%]
)

REM Persistent (HKCU\Environment) — via reg query, no powershell needed
reg query "HKCU\Environment" /v VLEARN2_ONLINE >nul 2>&1
if errorlevel 1 (
    echo Persistent ^(User^):  off / unset
) else (
    for /f "tokens=3" %%a in ('reg query "HKCU\Environment" /v VLEARN2_ONLINE ^| findstr VLEARN2_ONLINE') do echo Persistent ^(User^):  %%a
)
exit /b 0


:persist_on
setx VLEARN2_ONLINE 1 >nul
set "VLEARN2_ONLINE=1"
echo VLEARN2_ONLINE = 1 persisted to HKCU\Environment ^(setx^).
echo New cmd windows will inherit ON. Current shell is also ON.
echo NOTE: this defeats "offline by default". Prefer `on` per-session.
exit /b 0


:persist_off
reg delete "HKCU\Environment" /F /V VLEARN2_ONLINE >nul 2>&1
set "VLEARN2_ONLINE="
echo VLEARN2_ONLINE removed from HKCU\Environment.
echo Current shell also cleared. Fresh cmds will be offline-by-default.
exit /b 0

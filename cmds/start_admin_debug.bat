@echo off
REM Start the Next.js admin panel in dev mode.
REM Usage: cmds\start_admin_debug.bat
setlocal
pushd "%~dp0..\admin_panel"
if not exist node_modules (
  call npm install || goto :error
)
call npm run dev
popd
exit /b 0
:error
echo npm install failed.
popd
exit /b 1

@echo off
REM Build the Next.js admin panel for production.
REM Usage: cmds\build_admin.bat
setlocal
pushd "%~dp0..\admin_panel"
if not exist node_modules (
  call npm ci || goto :error
)
call npm run build || goto :error
popd
echo Build succeeded. Output in admin_panel\.next\
exit /b 0
:error
echo Build failed.
popd
exit /b 1

@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Build backend for PRODUCTION deployment
REM
REM  Steps:
REM    1. Clean install dependencies from package-lock.json (npm ci)
REM    2. Clean compile to dist/ (nest build)
REM
REM  After this, the deployable artifact is:
REM    - backend/dist/        (compiled JS)
REM    - backend/node_modules/ (deps; prune to production-only with
REM                              `npm prune --omit=dev` to slim down for deploy)
REM    - backend/package.json + package-lock.json
REM    - backend/.env         (configure for production target)
REM
REM  At runtime use cmds/start_service.bat (sets NODE_ENV=production, runs dist/).
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\backend" || (
  echo [ERROR] Could not find backend/ next to this script.
  pause
  exit /b 1
)

echo.
echo === vLearn2 Backend RELEASE Build ===
echo Working dir: %CD%
echo.

echo === Step 1/3: clean dist/ ===
if exist "dist" rmdir /S /Q "dist"

echo.
echo === Step 2/3: clean install dependencies (npm ci) ===
call npm ci
if errorlevel 1 (
  popd
  echo [ERROR] npm ci failed.
  pause
  exit /b 1
)

echo.
echo === Step 3/3: compile to dist/ ===
call npm run build
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
  echo.
  echo === Build succeeded ===
  echo Output: %CD%\dist\
  echo.
  echo Next steps for deployment:
  echo   1. Edit backend\.env for the production target (DB, JWT, AI_PROVIDER, etc.)
  echo   2. Optionally slim deps: npm prune --omit=dev
  echo   3. Run: cmds\start_service.bat
)

popd
pause
exit /b %RC%

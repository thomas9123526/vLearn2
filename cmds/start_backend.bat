@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  vLearn2 — Start the NestJS backend in dev mode (watch + auto-restart)
REM
REM  Listens on http://localhost:3000 (or whatever PORT is set to in
REM  backend\.env). Swagger docs at http://localhost:3000/api/docs.
REM
REM  Reads backend\.env for DB_*, JWT_*, AI_PROVIDER, OPENAI_* etc.
REM  If you change .env, restart this script — NestJS doesn't watch .env.
REM
REM  Prerequisites:
REM    - PostgreSQL running with the credentials in backend\.env
REM    - LM Studio running on http://localhost:1234 (if AI_PROVIDER=openai-compatible)
REM ─────────────────────────────────────────────────────────────────────────
setlocal

pushd "%~dp0..\backend" || (
  echo [ERROR] Could not find backend\ next to this script.
  pause
  exit /b 1
)

if not exist "node_modules" (
  echo Installing dependencies...
  call npm install
  if errorlevel 1 (
    popd
    echo [ERROR] npm install failed.
    pause
    exit /b 1
  )
)

if not exist ".env" (
  echo.
  echo [WARNING] backend\.env is missing. Copy .env.example and fill it in.
  echo The server will probably crash on DB connect.
  echo.
)

echo.
echo === vLearn2 Backend (dev, watch mode) ===
echo Working dir:  %CD%
echo API:          http://localhost:3000/api
echo Swagger docs: http://localhost:3000/api/docs
echo Stop:         Ctrl+C
echo.

call npm run start:dev
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%

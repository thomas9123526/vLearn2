# Backend debug launch config

## What this task did

Added Cursor/VS Code debug configurations under `.vscode/launch.json` for NestJS (`npm run start:debug` and attach on port 9229). Added `backend/start_debug.bat` to free port 5101 and start the inspector. Updated `stop_start_service.bat` default port to 5101 to match `backend/.env`.

## Conversation summary

- User asked to debug the backend after sign-in troubleshooting.
- Wired standard NestJS Node inspector workflow for breakpoints in `backend/src`.

## Decisions / call-outs

- Flutter should use `http://localhost:5101/api` when debugging locally.

## User prompt (verbatim)

> i want debug backend

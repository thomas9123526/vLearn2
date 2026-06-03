# sorry , it's better to add v1 in .env

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-02T07:49:21.442Z

## User

sorry , it's better to add v1 in .env

## Assistant

Reverting the normalization from both files — `.env` is the source of truth.

## Assistant

Done. Just set it explicitly in `.env`:

```env
OPENAI_BASE_URL=http://192.168.135.32:8080/v1
```

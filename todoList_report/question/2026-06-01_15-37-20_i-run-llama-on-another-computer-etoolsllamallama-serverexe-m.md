# I run llama on another computer. E:\tools\llama>llama-server.exe -m D:\models\Qw

Session: `71339df6-6ed8-4dd3-bc2e-a364a11a973e`
Saved: 2026-06-01T06:37:20.556Z

## User

I run llama on another computer.

E:\tools\llama>llama-server.exe -m D:\models\Qwen3-8B-UD-Q4_K_XL.gguf -ngl 80 -c 32768 --host 0.0.0.0 --port 8080 --log-verbose --log-prefix --log-timestamps

so what is the paramter that i can put .env for the following .

AI_PROVIDER=openai-compatible
#for server
# AI_CHAT_MODEL=Qwen3-4B-Q4_K_M.gguf
# AI_ANALYSIS_MODEL=Qwen3-4B-Q4_K_M.gguf
#20b
# AI_CHAT_MODEL=openai/gpt-oss-20b
# AI_ANALYSIS_MODEL=openai/gpt-oss-20b
#small b
AI_CHAT_MODEL=openai/gpt-oss-20b
AI_ANALYSIS_MODEL=openai/gpt-oss-20b
ANTHROPIC_API_KEY=

#for server
OPENAI_BASE_URL=http://192.168.135.32:8080/v1
OPENAI_API_KEY=not-needed
#local gpt.
# OPENAI_BASE_URL=http://127.0.0.1:1234/v1
# OPENAI_API_KEY=not-needed
AI_PROVIDER_LABEL=lmstudio

## Assistant

For llama.cpp server, the model name is typically the filename of the loaded model. You can verify by hitting `http://192.168.135.32:8080/v1/models` — it will return the exact model ID the server reports.

Based on your command (`-m D:\models\Qwen3-8B-UD-Q4_K_XL.gguf`), the model name is usually just the filename:

```env
AI_PROVIDER=openai-compatible
AI_CHAT_MODEL=Qwen3-8B-UD-Q4_K_XL.gguf
AI_ANALYSIS_MODEL=Qwen3-8B-UD-Q4_K_XL.gguf

OPENAI_BASE_URL=http://192.168.135.32:8080/v1
OPENAI_API_KEY=not-needed
AI_PROVIDER_LABEL=llama-qwen3-8b
```

Note: llama.cpp server actually **ignores** the model name in requests — it always uses whichever model was loaded at startup. So any non-empty string works for `AI_CHAT_MODEL`/`AI_ANALYSIS_MODEL`. Using the actual filename is just good practice for clarity.

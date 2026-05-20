# 2026-05-21 06:06:03 [DEBUG]  LlamaV4::load called with model path: C:\Users\aaa\

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-20T21:08:12.467Z

## User

2026-05-21 06:06:03 [DEBUG]
 LlamaV4::load called with model path: C:\Users\aaa\.lmstudio\models\bartowski\sum-small-GGUF\sum-small-IQ1_S.gguf
LlamaV4::load config: n_parallel=4 n_ctx=4096 kv_unified=true
2026-05-21 06:06:03 [DEBUG]
 ggml_cuda_init: found 1 CUDA devices (Total VRAM: 4095 MiB):
2026-05-21 06:06:03 [DEBUG]
   Device 0: NVIDIA GeForce GTX 1050 Ti, compute capability 6.1, VMM: yes, VRAM: 4095 MiB
2026-05-21 06:06:03 [DEBUG]
 srv    load_model: loading model 'C:\Users\aaa\.lmstudio\models\bartowski\sum-small-GGUF\sum-small-IQ1_S.gguf'
2026-05-21 06:06:05 [DEBUG]
 llama_model_load_from_file_impl: using device CUDA0 (NVIDIA GeForce GTX 1050 Ti) (0000:01:00.0) - 3353 MiB free
2026-05-21 06:06:05 [DEBUG]
 llama_model_loader: loaded meta data with 28 key-value pairs and 195 tensors from C:\Users\aaa\.lmstudio\models\bartowski\sum-small-GGUF\sum-small-IQ1_S.gguf (version GGUF V3 (latest))
llama_model_loader: Dumping metadata keys/values. Note: KV overrides do not apply in this output.
llama_model_loader: - kv   0:                       general.architecture str              = phi3
llama_model_loader: - kv   1:                               general.name str              = Phi3
llama_model_loader: - kv   2:                        phi3.context_length u32              = 4096
llama_model_loader: - kv   3:                      phi3.embedding_length u32              = 3072
llama_model_loader: - kv   4:                   phi3.feed_forward_length u32              = 8192
llama_model_loader: - kv   5:                           phi3.block_count u32              = 32
llama_model_loader: - kv   6:                  phi3.attention.head_count u32              = 32
llama_model_loader: - kv   7:               phi3.attention.head_count_kv u32              = 32
llama_model_loader: - kv   8:      phi3.attention.layer_norm_rms_epsilon f32              = 0.000010
llama_model_loader: - kv   9:                  phi3.rope.dimension_count u32              = 96
llama_model_loader: - kv  10:                          general.file_type u32              = 24
llama_model_loader: - kv  11:                       tokenizer.ggml.model str              = llama
llama_model_loader: - kv  12:                         tokenizer.ggml.pre str              = default
2026-05-21 06:06:05 [DEBUG]
 llama_model_loader: - kv  13:                      tokenizer.ggml.tokens arr[str,32064]   = ["<unk>", "<s>", "</s>", "<0x00>", "<...
2026-05-21 06:06:05 [DEBUG]
 llama_model_loader: - kv  14:                      tokenizer.ggml.scores arr[f32,32064]   = [0.000000, 0.000000, 0.000000, 0.0000...
2026-05-21 06:06:05 [DEBUG]
 llama_model_loader: - kv  15:                  tokenizer.ggml.token_type arr[i32,32064]   = [2, 3, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, ...
llama_model_loader: - kv  16:                tokenizer.ggml.bos_token_id u32              = 1
llama_model_loader: - kv  17:                tokenizer.ggml.eos_token_id u32              = 32000
llama_model_loader: - kv  18:            tokenizer.ggml.unknown_token_id u32              = 0
llama_model_loader: - kv  19:            tokenizer.ggml.padding_token_id u32              = 32000
llama_model_loader: - kv  20:               tokenizer.ggml.add_bos_token bool             = true
llama_model_loader: - kv  21:               tokenizer.ggml.add_eos_token bool             = false
llama_model_loader: - kv  22:                    tokenizer.chat_template str              = {{ bos_token }}{% for message in mess...
llama_model_loader: - kv  23:               general.quantization_version u32              = 2
llama_model_loader: - kv  24:                      quantize.imatrix.file str              = /models/sum-small-GGUF/sum-small.imatrix
llama_model_loader: - kv  25:                   quantize.imatrix.dataset str              = /training_data/groups_merged.txt
llama_model_loader: - kv  26:             quantize.imatrix.entries_count i32              = 128
llama_model_loader: - kv  27:              quantize.imatrix.chunks_count i32              = 108
llama_model_loader: - type  f32:   65 tensors
llama_model_loader: - type q2_K:    5 tensors
llama_model_loader: - type q5_K:    1 tensors
llama_model_loader: - type iq2_xxs:   32 tensors
llama_model_loader: - type iq1_s:   92 tensors
print_info: file format = GGUF V3 (latest)
print_info: file type   = IQ1_S - 1.5625 bpw
print_info: file size   = 801.92 MiB (1.76 BPW)
2026-05-21 06:06:05 [DEBUG]
 load: 0 unused tokens
2026-05-21 06:06:05 [DEBUG]
 load: special_eos_id is not in special_eog_ids - the tokenizer config may be incorrect
load: printing all EOG tokens:
load:   - 2 ('</s>')
load:   - 32000 ('[PAD32000]')
2026-05-21 06:06:05 [DEBUG]
 load: special tokens cache size = 67
load: token to piece cache size = 0.1690 MB
2026-05-21 06:06:05 [DEBUG]
 llama_model_load: error loading model: error loading model vocabulary: invalid unordered_map<K, T> key
llama_model_load_from_file_impl: failed to load model
common_init_from_params: failed to load model 'C:\Users\aaa\.lmstudio\models\bartowski\sum-small-GGUF\sum-small-IQ1_S.gguf'
srv    load_model: failed to load model, 'C:\Users\aaa\.lmstudio\models\bartowski\sum-small-GGUF\sum-small-IQ1_S.gguf': error loading model: error loading model vocabulary: invalid unordered_map<K, T> key
[LLMProcess] Failed to load model _0x392b90 [Error]: Failed to load model.
    at _0x4ea65f.loadModel (C:\Program Files\LM Studio\resources\app\.webpack\lib\llmworker.js:1:560010)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async _0x4ea65f.handleMessage (C:\Program Files\LM Studio\resources\app\.webpack\lib\llmworker.js:1:552166) {
  cause: 'Failed to load model',
  suggestion: undefined,
  errorData: undefined,
  data: undefined,
  displayData: undefined,
  title: 'Failed to load model.'
}

## Assistant

The model file `sum-small-IQ1_S.gguf` is broken under LM Studio's bundled llama.cpp build. Two things are wrong:

## The error

```
error loading model: error loading model vocabulary: invalid unordered_map<K, T> key
```

This is llama.cpp blowing up while parsing the GGUF tokenizer block. Two causes are common, both apply here:

1. **`IQ1_S` is a bleeding-edge 1.5-bit quant** (the log says `1.5625 bpw`). IQ1 quants have historically broken in older LM Studio builds because of how the vocab is packed.
2. **The model was likely quantized with a newer llama.cpp than your LM Studio ships with** — the vocab schema added fields that the older loader doesn't understand, so its `unordered_map` lookup fails.

So it's not your config — it's the model file vs. the runtime.

## What to do

Pick one (in order of effort):

| Option | Effort | Result |
|---|---|---|
| **Use a different quant of the same model** — grab `Q4_K_M` or `Q5_K_M` from `bartowski/sum-small-GGUF` instead of `IQ1_S` | tiny | almost certainly works, much better quality (Q4_K_M ≈ 4 bpw) |
| **Use a different model entirely** — your previous `.env` had `AI_CHAT_MODEL=Qwen3-4B-Q4_K_M.gguf` which was working. Revert and load that in LM Studio. | tiny | known-good baseline |
| **Update LM Studio** to the latest version (it bundles a newer llama.cpp build that fixes most IQ1/vocab edge cases) | small | might unblock IQ1_S — but Q4 is still a better tradeoff |

## My recommendation

Don't use `IQ1_S`. At 1.5 bpw the model will be noticeably worse than `Q4_K_M` (~4 bpw) for almost the same RAM footprint, and that quant is a regular source of vocab/loader bugs. Also `sum-small` is a 4B Phi-3 — for your English-tutor use case `Qwen3-4B-Q4_K_M.gguf` (your previous choice) or `Llama-3.1-8B-Instruct-Q4_K_M.gguf` will give clearly better replies and load reliably.

## Quick fix in your stack

1. In LM Studio, **Discover → Downloads**: grab `bartowski/sum-small-GGUF` at `Q4_K_M` (or just re-enable your existing Qwen3-4B-Q4_K_M).
2. Start it from LM Studio's **Developer** tab so it listens on `http://127.0.0.1:1234/v1`.
3. Update `backend/.env`:
   ```
   AI_CHAT_MODEL=<exact id LM Studio shows in /v1/models>
   AI_ANALYSIS_MODEL=<same>
   ```
   Verify with `curl http://127.0.0.1:1234/v1/models`.
4. Restart the backend.

That should get the tutor reply pipeline talking again. Once it's responding, you can experiment with smaller quants — just stay at Q3_K_M or higher; below that, "weird tokenizer errors" and "the model speaks gibberish" are the two most common outcomes.

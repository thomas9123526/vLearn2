# can you log out pcm bytes received on the terminal console?

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T09:51:03.759Z

## User

can you log out pcm bytes received on the terminal console?

## Assistant

Added. Each PCM chunk now prints its size and the running total to the terminal:

```
[AudioRecorder] PCM chunk: 3200 bytes (total: 3200)
[AudioRecorder] PCM chunk: 3200 bytes (total: 6400)
...
```

This will also confirm whether the stream is actually delivering data at all (which is relevant to the animation issue we just fixed).

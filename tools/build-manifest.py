#!/usr/bin/env python3
"""
Build manifest.json for a vLearn2 sherpa-onnx model bundle.

Usage:
    python tools/build-manifest.py <models-dir>

Walks the given directory, computes SHA-256 for every regular file (skipping
manifest.json itself), and emits a manifest.json next to the files.

Schema (kept tiny so an admin can hand-edit if needed):

    {
      "version": "2026.05.18",
      "stt": { "name": "whisper-tiny", "encoder": "stt/encoder.onnx", "decoder": "stt/decoder.onnx", "tokens": "stt/tokens.txt" },
      "tts": { "name": "vits-piper", "model": "tts/vits.onnx", "tokens": "tts/tokens.txt", "voices": ["maya-en", "leo-en", "sofia-en", "theo-en"] },
      "vad": { "name": "silero-vad", "model": "vad/silero.onnx" },
      "files": [
        { "path": "stt/encoder.onnx", "sha256": "...", "size": 12345 },
        ...
      ]
    }
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
from pathlib import Path

VERSION = "2026.05.18"


def sha256_of(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: build-manifest.py <models-dir>", file=sys.stderr)
        return 2
    root = Path(argv[1]).resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    files = []
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(root).as_posix()
        if rel == "manifest.json":
            continue
        files.append(
            {
                "path": rel,
                "sha256": sha256_of(p),
                "size": p.stat().st_size,
            }
        )

    manifest = {
        "version": VERSION,
        "stt": {
            "name": "whisper-tiny",
            "encoder": "stt/encoder.onnx",
            "decoder": "stt/decoder.onnx",
            "tokens": "stt/tokens.txt",
        },
        "tts": {
            "name": "vits-piper",
            "model": "tts/vits.onnx",
            "tokens": "tts/tokens.txt",
            "voices": ["maya-en", "leo-en", "sofia-en", "theo-en"],
        },
        "vad": {
            "name": "silero-vad",
            "model": "vad/silero.onnx",
        },
        "files": files,
    }

    out = root / "manifest.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out} with {len(files)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

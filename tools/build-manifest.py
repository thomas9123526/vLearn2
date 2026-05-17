#!/usr/bin/env python3
"""
Build manifest.json for a vLearn2 sherpa-onnx model bundle.

Usage:
    python tools/build-manifest.py --root <models-dir> [options]

By default writes <root>/manifest.json. Pass --stdout to print to stdout
without touching the directory (handy in CI / pipe-to-file scenarios).

Schema (kept tiny so an admin can hand-edit if needed):

    {
      "version": "2026.05.18-1",
      "stt": { "name": "zipformer-streaming-en" },
      "tts": { "name": "vits-piper-en", "voices": ["en_US-amy", "en_GB-jenny"] },
      "vad": { "name": "silero-v4" },
      "files": [
        { "path": "stt/encoder.onnx", "sha256": "...", "size": 12345678 },
        ...
      ]
    }

Files excluded by default: `manifest.json`, anything under `cache/`, and
hidden dotfiles. Override with --include-cache / --include-hidden if you
really need them.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import date
from pathlib import Path


def sha256_of(p: Path) -> str:
    """Stream-hash a single file in 1 MB chunks so giant ONNX models don't
    blow the heap."""
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def collect(root: Path, *, include_cache: bool, include_hidden: bool) -> list[dict]:
    """Walk the model root and SHA-256 every file we want in the manifest.

    Returns a sorted list of `{path, sha256, size}` dicts. `path` is always
    POSIX-style (forward slashes) regardless of the host OS — keeps Windows
    bundles consistent with the Android ones.
    """
    files: list[dict] = []
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(root).as_posix()
        if rel == "manifest.json":
            continue
        if not include_cache and (rel == "cache" or rel.startswith("cache/")):
            continue
        if not include_hidden and any(part.startswith(".") for part in rel.split("/")):
            continue
        files.append(
            {
                "path": rel,
                "sha256": sha256_of(p),
                "size": p.stat().st_size,
            }
        )
    return files


def build_manifest(args: argparse.Namespace, files: list[dict]) -> dict:
    return {
        "version": args.version,
        "stt": {"name": args.stt_name},
        "tts": {"name": args.tts_name, "voices": args.tts_voices},
        "vad": {"name": args.vad_name},
        "files": files,
    }


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Build manifest.json for vLearn2 sherpa-onnx bundle")
    p.add_argument("--root", required=True, type=Path, help="Path to the models directory")
    p.add_argument(
        "--version",
        default=f"{date.today().isoformat()}-1",
        help="Free-form version label (defaults to today's date)",
    )
    p.add_argument("--stt-name", default="zipformer-streaming-en")
    p.add_argument("--tts-name", default="vits-piper-en")
    p.add_argument(
        "--tts-voices",
        nargs="*",
        default=["en_US-amy"],
        help="Voice ids in the order the TTS model expects them (sid 0 first)",
    )
    p.add_argument("--vad-name", default="silero-v4")
    p.add_argument("--include-cache", action="store_true", help="Hash files under cache/ as well")
    p.add_argument("--include-hidden", action="store_true", help="Hash dotfiles")
    p.add_argument(
        "--stdout",
        action="store_true",
        help="Write manifest to stdout instead of <root>/manifest.json",
    )
    args = p.parse_args(argv[1:])

    root = args.root.resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    files = collect(root, include_cache=args.include_cache, include_hidden=args.include_hidden)
    manifest = build_manifest(args, files)
    serialized = json.dumps(manifest, indent=2) + "\n"

    if args.stdout:
        sys.stdout.write(serialized)
    else:
        out = root / "manifest.json"
        out.write_text(serialized, encoding="utf-8")
        print(f"wrote {out} with {len(files)} files", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

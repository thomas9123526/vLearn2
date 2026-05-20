#!/usr/bin/env node
// Extract a one-line summary of the latest user prompt from the transcript
// referenced by the Stop-hook stdin JSON. Used by auto-commit.sh to put a
// description of what was just done into the commit title — instead of the
// useless "auto: +N added, ~M modified" we had before.
//
// Reads:  hook input JSON on stdin
// Writes: a single line (<=72 chars) to stdout, or nothing if unavailable.

import { readFileSync, existsSync } from 'node:fs';
import process from 'node:process';

const HARNESS_TAGS = [
  'ide_opened_file',
  'ide_selection',
  'system-reminder',
  'command-message',
  'command-name',
  'command-args',
  'local-command-stdout',
  'local-command-stderr',
];

function stripTags(text) {
  let out = text;
  for (const tag of HARNESS_TAGS) {
    const re = new RegExp(`<${tag}\\b[^>]*>[\\s\\S]*?<\\/${tag}>`, 'gi');
    out = out.replace(re, '');
  }
  return out.trim();
}

function extractText(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  return content
    .filter((c) => c && c.type === 'text' && typeof c.text === 'string')
    .map((c) => c.text)
    .join('\n');
}

async function readStdin() {
  return new Promise((resolve) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => { data += c; });
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', () => resolve(data));
  });
}

const raw = await readStdin();
if (!raw.trim()) process.exit(0);

let hookInput;
try { hookInput = JSON.parse(raw); } catch { process.exit(0); }

const tp = hookInput.transcript_path;
if (!tp || !existsSync(tp)) process.exit(0);

const lines = readFileSync(tp, 'utf8').split(/\r?\n/).filter((l) => l.trim());

// Walk forward, remember the last real user prompt (skip tool_result-only
// entries that the harness writes back as type: 'user').
let latest = null;
for (const line of lines) {
  let entry;
  try { entry = JSON.parse(line); } catch { continue; }
  const msg = entry.message;
  if (!msg) continue;
  if (entry.type !== 'user' || msg.role !== 'user') continue;
  if (Array.isArray(msg.content) && msg.content.some((c) => c.type === 'tool_result')) continue;
  const text = stripTags(extractText(msg.content));
  if (text) latest = text;
}

if (!latest) process.exit(0);

const summary = latest
  .replace(/[\r\n]+/g, ' ')
  .replace(/\s+/g, ' ')
  .trim()
  .slice(0, 72);

process.stdout.write(summary);

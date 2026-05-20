#!/usr/bin/env node
// Stop hook: save the LATEST exchange (most recent user prompt +
// Claude's response to it) as markdown to
// todoList_report/question/<slug>.md. Slug derives from the latest
// user prompt, so each prompt becomes its own file.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import process from 'node:process';

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const OUT_DIR = join(PROJECT_DIR, 'todoList_report', 'question');

function readStdin() {
  return new Promise((resolveStdin) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => { data += chunk; });
    process.stdin.on('end', () => resolveStdin(data));
    process.stdin.on('error', () => resolveStdin(data));
  });
}

// Tags the harness wraps around context it injects into user turns.
// Strip these so they don't pollute the slug or the captured prompt.
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

function stripHarnessTags(text) {
  let out = text;
  for (const tag of HARNESS_TAGS) {
    const re = new RegExp(`<${tag}\\b[^>]*>[\\s\\S]*?<\\/${tag}>`, 'gi');
    out = out.replace(re, '');
  }
  return out.trim();
}

function extractText(content) {
  let raw;
  if (typeof content === 'string') raw = content;
  else if (Array.isArray(content)) {
    raw = content
      .filter((c) => c && c.type === 'text' && typeof c.text === 'string')
      .map((c) => c.text)
      .join('\n');
  } else return '';
  return stripHarnessTags(raw);
}

function slugify(text) {
  const words = text
    .toLowerCase()
    .replace(/[\r\n]+/g, ' ')
    .split(/\s+/)
    .filter((w) => /[a-z0-9]/i.test(w))
    .slice(0, 8);
  let slug = words.join('-').replace(/[^a-z0-9-]/g, '');
  slug = slug.replace(/-+/g, '-').replace(/^-+|-+$/g, '');
  return slug || 'untitled';
}

async function main() {
  let hookInput;
  try {
    const raw = await readStdin();
    if (!raw.trim()) return;
    hookInput = JSON.parse(raw);
  } catch {
    return;
  }

  const transcriptPath = hookInput.transcript_path;
  if (!transcriptPath || !existsSync(transcriptPath)) return;

  const lines = readFileSync(transcriptPath, 'utf8')
    .split(/\r?\n/)
    .filter((l) => l.trim().length > 0);

  const turns = [];
  for (const line of lines) {
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    const msg = entry.message;
    if (!msg) continue;

    if (entry.type === 'user' && msg.role === 'user') {
      // Skip tool_result-only user entries — those aren't real prompts
      if (Array.isArray(msg.content) && msg.content.some((c) => c.type === 'tool_result')) continue;
      const text = extractText(msg.content);
      if (text && text.trim()) turns.push({ role: 'user', text });
    } else if (entry.type === 'assistant' && msg.role === 'assistant') {
      const text = extractText(msg.content);
      if (text && text.trim()) turns.push({ role: 'assistant', text });
    }
  }
  if (turns.length === 0) return;

  // Walk back to the most recent user prompt; everything after it is the
  // assistant's response to that prompt (possibly multiple text blocks).
  let lastUserIdx = -1;
  for (let i = turns.length - 1; i >= 0; i--) {
    if (turns[i].role === 'user') { lastUserIdx = i; break; }
  }
  if (lastUserIdx === -1) return;

  const userPrompt = turns[lastUserIdx];
  const assistantParts = turns.slice(lastUserIdx + 1).filter((t) => t.role === 'assistant');

  const slug = slugify(userPrompt.text);
  const headerLine = userPrompt.text.replace(/[\r\n]+/g, ' ').trim().slice(0, 80);

  const md = [];
  md.push(`# ${headerLine}`);
  md.push('');
  md.push(`Session: \`${hookInput.session_id || 'unknown'}\``);
  md.push(`Saved: ${new Date().toISOString()}`);
  md.push('');
  md.push('## User');
  md.push('');
  md.push(userPrompt.text);
  md.push('');
  for (const a of assistantParts) {
    md.push('## Assistant');
    md.push('');
    md.push(a.text);
    md.push('');
  }

  if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });
  const outFile = join(OUT_DIR, `${slug}.md`);
  writeFileSync(outFile, md.join('\n'), 'utf8');
}

main().catch(() => {
  // Never block Claude on hook failure.
});

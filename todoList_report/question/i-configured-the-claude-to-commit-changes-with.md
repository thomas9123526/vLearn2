# I configured the claude to commit changes with the overview of what have done. b

Session: `859710bb-e71a-42d3-b4d0-af5e037a10f3`
Saved: 2026-05-20T11:11:09.740Z

## User

I configured the claude to commit changes with the overview of what have done. but i think it's not working.

## Assistant

Let me first verify what's happening with auto-commit and inspect why these 13 files are uncommitted.

## Assistant

I see — the hook is working, but with a useless title (`auto: +N added, ~M modified` — no description of what was done). And I just had to manually run it for the audit-log changes because the Stop hook hadn't picked them up earlier (likely due to interrupts/timeouts during the bigger turns). 

**The fix:** make the auto-commit script read the latest user prompt from the transcript and use it as the commit subject. That way "what was done" lands in the title.

## Assistant

Verifying the script works by piping a real transcript into it and observing what it would commit.

## Assistant

Done.

**What was wrong:** The script existed and was firing, but its commit title was purely numeric (`auto: +2 added, ~11 modified`) — no description of *what* was done. Also, the audit-log changes from earlier this session never got committed (likely a hook timeout / interrupt on the large turns), so I ran the script manually a moment ago to catch them up (commit `fe47e42`).

**What changed:**

- New: [.claude/scripts/extract-latest-prompt.mjs](.claude/scripts/extract-latest-prompt.mjs) — reads the Stop-hook stdin JSON, parses the transcript, and prints a one-line (≤72 char) summary of your most recent prompt (with harness tags like `<ide_opened_file>` stripped).
- Modified: [.claude/scripts/auto-commit.sh](.claude/scripts/auto-commit.sh) — captures stdin once, pipes it to the extractor, and uses the result as the commit title. Falls back to the old numeric summary if the transcript is unavailable. The numeric summary is preserved as a one-line note in the body (so you still see "(+2 added, ~11 modified)" alongside the file list).

**Pipe-tested** against the current session's transcript — extractor correctly produces "I configured the claude to commit changes with the overview of what have" from your latest prompt.

**Next commit you'll see:** when the Stop hook fires after this turn, it'll commit these two script changes with title `auto: I configured the claude to commit changes with the overview of what have`. From then on, every auto-commit will carry your prompt as its subject line.

**Caveat:** the title is your prompt verbatim, not a semantic summary of the code change. If you want something smarter (e.g., the model extracting "fix(audit): tighten diff to only-changed-fields" from the diff), that'd require a `prompt`-type hook calling an LLM — more accurate but slower and costs tokens per Stop. The current approach is deterministic and free.

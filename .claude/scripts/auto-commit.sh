#!/usr/bin/env bash
# Auto-commit hook script.
# Stages all changes and commits with a report describing what changed.
# Called from .claude/settings.local.json Stop hook.

set -e
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true

# Bail early if not a git repo
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Bail if nothing changed
status=$(git status --porcelain)
[ -z "$status" ] && exit 0

# Count each change type
added=$(echo "$status"   | grep -c '^??' || true)
modified=$(echo "$status" | grep -cE '^[ MAR]M|^M[ MD]' || true)
deleted=$(echo "$status"  | grep -cE '^[ M]D|^D ' || true)
renamed=$(echo "$status"  | grep -c '^R' || true)

# Build summary parts
parts=""
[ "$added"    -gt 0 ] && parts="${parts}+${added} added, "
[ "$modified" -gt 0 ] && parts="${parts}~${modified} modified, "
[ "$deleted"  -gt 0 ] && parts="${parts}-${deleted} deleted, "
[ "$renamed"  -gt 0 ] && parts="${parts}>${renamed} renamed, "
parts="${parts%, }"
[ -z "$parts" ] && parts="changes"

title="auto: ${parts}"

# Stage everything (respects .gitignore)
git add -A

# Build body: list of files with action prefix, then diffstat
body=$(git status --porcelain | awk '
{
  s=$1
  $1=""
  f=substr($0, 2)
  if (s == "??")       a="add"
  else if (s ~ /M/)    a="mod"
  else if (s ~ /D/)    a="del"
  else if (s ~ /^R/)   a="ren"
  else if (s ~ /^A/)   a="add"
  else                  a="chg"
  print "- " a ": " f
}' | head -40)

stat=$(git diff --cached --shortstat 2>/dev/null | sed 's/^ *//')

# Compose commit message
{
  echo "$title"
  echo
  echo "$body"
  [ -n "$stat" ] && echo && echo "$stat"
} > .claude/scripts/.commit-msg.tmp

git commit -F .claude/scripts/.commit-msg.tmp >/dev/null 2>&1 || true
rm -f .claude/scripts/.commit-msg.tmp

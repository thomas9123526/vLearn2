# what is git amend command?

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-21T08:34:13.665Z

## User

what is git amend command?

## Assistant

`git commit --amend` rewrites the most recent commit. Two common uses:

```
git commit --amend                       # edit the message of HEAD
git commit --amend --no-edit             # add staged changes to HEAD, keep message
git commit --amend -m "new message"      # replace message in one shot
```

Typical flow when you forgot a file:
```
git add forgotten_file.ts
git commit --amend --no-edit
```

## Important caveats

- **Amend rewrites history.** The amended commit has a new SHA. If the previous commit was already pushed, a normal `git push` will be rejected — you'd need `git push --force-with-lease`, which can stomp on teammates' work on a shared branch. Don't amend pushed commits unless you're sure no one else has based work on them.
- **Amend = new commit, old one is orphaned.** Reflog (`git reflog`) keeps it findable for a while if you need to recover.
- **Only amends HEAD.** To edit an older commit, use `git rebase -i <commit>^` and mark the target as `edit` or `reword`.

## When NOT to amend
- After hook failure during commit — the previous commit is still HEAD, so amending modifies *that* one. The convention in this repo (and most others) is to fix the issue, re-stage, and create a **new** commit instead.
- On already-pushed commits on a shared branch.

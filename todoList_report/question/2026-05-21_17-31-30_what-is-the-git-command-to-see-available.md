# what is the git command to see available branch

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-21T08:31:30.164Z

## User

what is the git command to see available branch

## Assistant

```
git branch          # local branches only — current one has a *
git branch -a       # local + remote-tracking
git branch -r       # remote-tracking only
git branch -vv      # local + upstream tracking + last commit
```

Most useful in practice: `git branch -vv` (you see which local branch tracks which remote and the latest commit on each).

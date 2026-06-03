# if the local and vmware has same base hash like 4c0a735ada3a2a16c035d61c4091a427

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T03:17:34.784Z

## User

if the local and vmware has same base hash like 4c0a735ada3a2a16c035d61c4091a42731da78a1.
and i work on local and push some commit.
After that how can i bundle single file and apply to vmware

## Assistant

Simple. Both are at `4c0a735...` — you work locally and add commits, then:

**On local** (create the bundle from that base hash forward):
```bash
git bundle create vlearn_update.bundle 4c0a735ada3a2a16c035d61c4091a42731da78a1..HEAD
```

**Copy to VMware** (shared folder, USB, whatever):
```bash
# example via scp if you know VMware's IP
scp vlearn_update.bundle user@192.168.x.x:~/
```

**On VMware** (apply it):
```bash
git pull vlearn_update.bundle HEAD
```

That's it. VMware will fast-forward to match your local HEAD.

---

### If you want to keep doing this repeatedly

Each time you do a new round of work, just re-run the bundle command. You can always use the **same base hash** `4c0a735...` — the bundle just grows to include all commits since that point:

```bash
# Local — re-bundle after more commits
git bundle create vlearn_update.bundle 4c0a735ada3a2a16c035d61c4091a42731da78a1..HEAD

# VMware — same command every time
git pull vlearn_update.bundle HEAD
```

Or use the **previous sync point** as the new base to keep the file small:
```bash
# After VMware is at e.g. abc1234, use that as the new base
git bundle create vlearn_update.bundle abc1234..HEAD
```

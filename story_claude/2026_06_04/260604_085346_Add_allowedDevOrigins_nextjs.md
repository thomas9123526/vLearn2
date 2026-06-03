# Conversation - Add allowedDevOrigins to Next.js config

| Field | Value |
|---|---|
| Saved | 2026-06-04 08:53:46 |
| Commit | Add allowedDevOrigins for VMware VM IP in next.config.mjs |
| Project | C:\project\vLearn2 |

---

## User

⚠ Cross origin request detected from 192.168.135.30 to /_next/* resource. In a future major version of Next.js, you will need to explicitly configure "allowedDevOrigins" in next.config to allow this.

## Assistant

Added llowedDevOrigins: ['192.168.135.30'] to admin_panel/next.config.mjs. The VMware VM (192.168.135.30) accesses the host's Next.js dev server, which Next.js flags as cross-origin. This silences the warning and future-proofs it against the upcoming breaking change.

---

## Prompt

⚠ Cross origin request detected from 192.168.135.30 to /_next/* resource.

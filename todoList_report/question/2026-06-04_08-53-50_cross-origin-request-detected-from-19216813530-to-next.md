# ⚠ Cross origin request detected from 192.168.135.30 to /_next/* resource. In a f

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T23:53:50.934Z

## User

⚠ Cross origin request detected from 192.168.135.30 to /_next/* resource. In a future major version of Next.js, you will need to explicitly configure "allowedDevOrigins" in next.config to allow this.
Read more: https://nextjs.org/docs/app/api-reference/config/next-config-js/allowedDevOrigins

## Assistant

That warning is from the Next.js dev server — the VMware VM (`192.168.135.30`) is accessing the host's Next.js app, and Next.js flags it as a cross-origin request. Let me find the config file and add the allowed origin.

## Assistant

Done. Added `allowedDevOrigins: ['192.168.135.30']` to [admin_panel/next.config.mjs](admin_panel/next.config.mjs) — this tells Next.js the VM's IP is an allowed dev origin for `/_next/*` hot-reload requests. Restart the Next.js dev server and the warning will be gone.

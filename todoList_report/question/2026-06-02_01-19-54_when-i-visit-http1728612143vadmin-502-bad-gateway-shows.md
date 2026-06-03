# when i visit http://172.86.121.43/vAdmin/, '502 Bad Gateway' shows, I upload sou

Session: `3fb0e8c5-c4b4-421d-97a4-d9e9c530c1a6`
Saved: 2026-06-01T16:19:54.263Z

## User

when i visit http://172.86.121.43/vAdmin/, '502 Bad Gateway' shows, I upload source to linux vps

## Assistant

Let me check if there are deployment configs in the project.

## Assistant

The nginx config is fine — `/vAdmin/` correctly proxies to `127.0.0.1:4100`. The 502 means the admin panel process is simply not running on the VPS yet.

Let me check the admin panel's Next.js config for the `basePath`:

## Assistant

The nginx config is correct. The 502 just means the admin panel PM2 process isn't running yet. Here are the commands to run on the VPS via SSH:

```bash
# 1. Install dependencies and build
cd /root/vfls/vLearn2/admin_panel
npm install
npm run build

# 2. Create .env (if it doesn't exist yet)
cat > .env << 'EOF'
NEXT_PUBLIC_API_BASE_URL=/vfls
BACKEND_BASE_URL=http://localhost:5100
EOF

# 3. Start with PM2 on port 4100
PORT=4100 pm2 start npm --name vfls-admin --cwd /root/vfls/vLearn2/admin_panel -- run start
pm2 save

# 4. Verify it's listening
pm2 logs vfls-admin --lines 30
```

Also make sure the backend is running too — the admin panel calls `/vfls/` which proxies to `:5100`:

```bash
# Check if backend is up
pm2 list
# If vfls-backend isn't running:
cd /root/vfls/vLearn2/backend
npm run build
pm2 start npm --name vfls-backend --cwd /root/vfls/vLearn2/backend -- run start:prod
pm2 save
```

And confirm the nginx `app.conf` on the server matches [cmds/server_files/etc_nginx/conf.d/app.conf](cmds/server_files/etc_nginx/conf.d/app.conf) — specifically that `/vAdmin/` is proxied to `127.0.0.1:4100`. If you replaced the file, reload nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

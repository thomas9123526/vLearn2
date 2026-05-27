# what is the host url for 127.0.0.1 in ldplayer

Session: `1eb40659-e5c9-4cd9-aa44-b57f47d3b5f7`
Saved: 2026-05-27T10:16:34.947Z

## User

what is the host url for 127.0.0.1 in ldplayer

## Assistant

In LDPlayer, the host machine's `127.0.0.1` is accessed from the emulator at:

**`10.0.2.2`**

Same as the standard Android emulator (AVD). So in your `app_config.json` on LDPlayer, use:

```json
"baseurl": "http://10.0.2.2:3000/vfls"
```

(adjust the port to whatever your backend listens on)

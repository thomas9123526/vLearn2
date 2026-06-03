# auth.signin] target=http://127.0.0.1:5101/api/auth/signin user=hlj0115 X — POST 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T07:07:52.465Z

## User

auth.signin] target=http://127.0.0.1:5101/api/auth/signin user=hlj0115
X — POST http://127.0.0.1:5101/api/auth/signin
[sign_in_screen] DioException [connection error]: No internet connection.
Error: ApiException(0): No internet connection.

## Assistant

The app is trying to reach the backend at `127.0.0.1:5101`, but on the VMware VM that's the VM's own loopback — not the host machine where the backend runs. The connection never leaves the VM.

You need to change the `baseurl` in `app_config.json` to the host machine's IP address.

**On the host machine**, run:
```powershell
ipconfig
```
Look for the VMware Network Adapter IP (usually `192.168.x.1` or `172.x.x.x`). That's the IP the VM can reach.

Then on the VMware machine, find `app_config.json` and update it:
```json
{ "baseurl": "http://192.168.x.x:5101/api", "reqTout": 100, "tSync": 120 }
```

Where is `app_config.json` stored on the device? Let me check so I can tell you the exact path:

## Assistant

On Windows, `app_config.json` is in the **same folder as the executable** — next to the `.exe` file.

On the VMware machine, find where the Flutter app `.exe` is (e.g., `C:\project\vLearn2\flutter_app\build\windows\x64\runner\Release\`) and edit `app_config.json` there:

```json
{"baseurl":"http://192.168.x.x:5101/api","reqTout":100,"tSync":120}
```

Replace `192.168.x.x` with the host machine's VMware adapter IP. A quick way to find it — run this **on the host machine**:

```powershell
ipconfig | Select-String "VMware|192.168|172." -A 1
```

The IP on the VMware Network Adapter line is what you need.

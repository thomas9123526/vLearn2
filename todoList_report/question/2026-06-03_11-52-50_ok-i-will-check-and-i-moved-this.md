# ok i will check and i moved this project to vmware and run with internet.  But t

Session: `cb14393c-1d33-4891-aee0-276d4c902efe`
Saved: 2026-06-03T02:52:50.982Z

## User

ok i will check and i moved this project to vmware and run with internet. 
But this message shows.

'ClientException with SocketException: Failed host lookup: 'pub.dev' (OS Error: No such host is known, errno = 11001), uri=https://pub.dev/api/packages/archive/advisories
Failed to update packages.'

when i build flutter build apk --debug

## Assistant

This is a VMware DNS issue — the VM can't resolve `pub.dev`. The quickest workaround while you fix networking:

```powershell
flutter build apk --debug --no-pub
```

`--no-pub` skips the package advisory check entirely. This works if you've already run `flutter pub get` before (packages are cached in `.dart_tool/`).

---

**To fix the networking properly in VMware:**

The issue is usually the network adapter type or DNS. Try these in order:

**1. Switch to Bridged networking** (most reliable):
- VMware → VM → Settings → Network Adapter → **Bridged** (instead of NAT)
- Restart the VM

**2. If Bridged doesn't work, set DNS manually inside the VM:**

Open PowerShell in the VM as admin:
```powershell
# Find your network adapter name
Get-NetAdapter

# Set Google DNS on it (replace "Ethernet0" with your adapter name)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses ("8.8.8.8", "8.8.4.4")

# Test it
Resolve-DnsName pub.dev
```

**3. If behind a corporate proxy:**
```powershell
$env:HTTPS_PROXY = "http://your-proxy:port"
flutter build apk --debug
```

---

Try `--no-pub` first to unblock your build immediately, then fix DNS so `flutter pub get` works normally.

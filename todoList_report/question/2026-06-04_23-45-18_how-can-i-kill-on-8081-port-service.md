# how can i kill on 8081 port service

Session: `40c2c32e-4bcc-4826-8449-440738f22ef6`
Saved: 2026-06-04T14:45:18.905Z

## User

how can i kill on 8081 port service

## Assistant

The process using port 8081 has PID **9736**. Kill it with:

```powershell
taskkill /PID 9736 /F
```

Or in one command without needing to look up the PID first:

```powershell
Get-Process -Id (Get-NetTCPConnection -LocalPort 8081).OwningProcess | Stop-Process -Force
```

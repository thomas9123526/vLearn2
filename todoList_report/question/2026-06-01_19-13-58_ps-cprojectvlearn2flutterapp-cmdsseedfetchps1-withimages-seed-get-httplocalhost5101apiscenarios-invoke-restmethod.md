# PS C:\project\vLearn2\flutter_app> ..\cmds\seed_fetch.ps1 -WithImages [seed] GET

Session: `90c5c6ba-f941-45bb-8889-37114ea77f9f`
Saved: 2026-06-01T10:13:58.344Z

## User

PS C:\project\vLearn2\flutter_app> ..\cmds\seed_fetch.ps1 -WithImages
[seed] GET http://localhost:5101/api/scenarios
Invoke-RestMethod: C:\project\vLearn2\cmds\seed_fetch.ps1:45:12                                                         
Line |
  45 |      return Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
     |             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     |  {   "message": "Unauthorized",   "statusCode": 401 }

## Assistant

The script doesn't pass any auth header. Let me check the backend auth endpoint quickly:

## Assistant

The backend uses `POST /api/auth/signin` with `{ cidUsername, password }` → returns `accessToken`. I'll add login support to the script:

## Assistant

Now add the login logic and wire the token into `Invoke-Api`. Let me read the current helpers section first:

## Assistant

Also pass the auth header for image downloads:

## Assistant

Now update the usage comment at the top:

## Assistant

Done. Usage now:

```powershell
# Prompts interactively for username + password
..\cmds\seed_fetch.ps1 -WithImages

# Pass username (password prompt appears securely)
..\cmds\seed_fetch.ps1 -CidUsername yourUser -WithImages

# Skip login entirely with a pre-obtained token
..\cmds\seed_fetch.ps1 -Token eyJhbGci... -WithImages
```

The `$Password` is typed as `SecureString` (suppresses linter warning and hides input at the prompt). It's converted to plaintext only at the moment of the signin POST, never stored as a string variable.

# PS C:\project\vLearn2\flutter_app>  "$env:LOCALAPPDATA\Android\Sdk\emulator\emul

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-25T01:16:21.199Z

## User

PS C:\project\vLearn2\flutter_app>  "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_XL
At line:1 char:56
+  "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_XL
+                                                        ~~~~
Unexpected token '-avd' in expression or statement.
At line:1 char:61
+  "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_XL
+                                                             ~~~~~~~~
Unexpected token 'Pixel_XL' in expression or statement.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : UnexpectedToken

## Assistant

PowerShell treats a quoted string at the start of a line as just a string expression — it won't run it as a command. You need the **call operator `&`** in front:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_XL
```

The `&` tells PowerShell "run this as a command, the args that follow are its arguments." Without it, `-avd` is parsed as an operator on a string and fails.

If you'd rather not type the path, add the SDK's `emulator` folder to PATH once and then just:

```powershell
emulator -avd Pixel_XL
```

Or to launch it detached so the terminal stays free:

```powershell
Start-Process -FilePath "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -ArgumentList '-avd','Pixel_XL'
```

; =============================================================================
; Virtual Foreign Language System — Inno Setup 6 installer script
;
; Compile with:
;   ISCC.exe installer.iss /DSourceDir=<path\to\Release> /DOutputDir=<out>
;
; Or run build.ps1 which passes these defines automatically.
; =============================================================================

#ifndef SourceDir
  #define SourceDir "..\..\flutter_app\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "output"
#endif
#ifndef DefaultServerUrl
  #define DefaultServerUrl "http://YOUR_SERVER_IP"
#endif

#define AppName    "Virtual Foreign Language System"
#define AppVersion "1.0.0"
#define AppPublisher "vLearn2"
#define AppExeName "flutter_app.exe"
#define AppId      "{{A3F2B8C1-4D7E-4F9A-B2C3-1234567890AB}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
OutputDir={#OutputDir}
OutputBaseFilename=vlfls-setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\{#AppExeName}

; Minimum Windows version: Windows 10
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
english.ServerUrlPageTitle=Server Connection
english.ServerUrlPageDesc=Enter the address of your Virtual Foreign Language server.
english.ServerUrlLabel=Server URL:
english.ServerUrlHint=Example: http://192.168.1.100  or  http://learn.example.com
english.TestingNote=You can change this later by editing app_config.json next to the application.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; All Flutter release output — exe, DLLs, data/
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}";         Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#AppName}";   Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; \
  Flags: nowait postinstall skipifsilent

; =============================================================================
; [Code] — custom wizard page to collect the server URL,
;           then write app_config.json next to the exe.
; =============================================================================
[Code]

var
  ServerUrlPage : TInputQueryWizardPage;
  ServerUrlValue: String;

procedure InitializeWizard;
begin
  // Create a custom input page after the "Ready to Install" page
  ServerUrlPage := CreateInputQueryPage(
    wpReady,
    CustomMessage('ServerUrlPageTitle'),
    CustomMessage('ServerUrlPageDesc'),
    ''
  );
  ServerUrlPage.Add(
    CustomMessage('ServerUrlLabel'),
    False  // not a password field
  );
  // Pre-fill with the default baked in at build time
  ServerUrlPage.Values[0] := '{#DefaultServerUrl}';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  url: String;
begin
  Result := True;
  if CurPageID = ServerUrlPage.ID then
  begin
    url := Trim(ServerUrlPage.Values[0]);
    if url = '' then
    begin
      MsgBox('Please enter the server URL before continuing.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    ServerUrlValue := url;
  end;
end;

// Write app_config.json after files are installed
procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigPath : String;
  ConfigJson : String;
  Lines      : TArrayOfString;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigPath := ExpandConstant('{app}\app_config.json');

    // Build a minimal JSON object
    // (Inno Setup has no JSON library; we compose the string directly.)
    ConfigJson :=
      '{' + #13#10 +
      '  "baseurl": "' + ServerUrlValue + '",' + #13#10 +
      '  "reqTout": 180,' + #13#10 +
      '  "tSync": 60,' + #13#10 +
      '  "dev": "prod",' + #13#10 +
      '  "model": ""' + #13#10 +
      '}';

    SetArrayLength(Lines, 1);
    Lines[0] := ConfigJson;
    SaveStringsToUTF8File(ConfigPath, Lines, False);
  end;
end;

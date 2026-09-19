; Inno Setup Script for LocalLoop (Windows Host)
; Packages LocalLoop.Service (Background) and LocalLoop.Bridge (Systray & QR)

#define MyAppName "LocalLoop"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "LocalLoop Authors"
#define MyAppURL "https://github.com/jhaabhijeet864/Ghost-Link"
#define MyAppExeName "LocalLoop.Bridge.exe"
#define MyServiceExeName "LocalLoop.Service.exe"

[Setup]
AppId={{6A99B87F-02D1-4D34-927A-9457E59EBF34}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=LocalLoopSetup
OutputDir=dist
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupentry"; Description: "Start LocalLoop Tray automatically at login"; GroupDescription: "Startup:"

[Files]
; Bridge files (Systray and UI)
Source: "publish\bridge\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Service files (Background worker)
Source: "publish\service\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; Tasks: startupentry

[Run]
; Launch background service
Filename: "{app}\service\{#MyServiceExeName}"; Description: "Start LocalLoop Background Service"; Flags: nowait postinstall runhidden
; Launch systray bridge UI
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

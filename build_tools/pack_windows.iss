; Inno Setup Script for Siga Automator Installer

[Setup]
AppName=Siga Automator
AppVersion=AppVersion
DefaultDirName={commonpf}\Siga Automator
DefaultGroupName=Siga Automator
OutputDir= "outputdirpath"
OutputBaseFilename=SigaAutomator-AppVersion_win_64
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{commondesktop}\Siga Automator"; Filename: "{app}\siga.exe"

[Run]
Filename: "{app}\siga.exe"; Description: "Launch Siga Automator"; Flags: nowait postinstall skipifsilent

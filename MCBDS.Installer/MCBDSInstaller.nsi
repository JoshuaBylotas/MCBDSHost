; MCBDS API Service Installer
; NSIS Installer Script for Windows Service with Configuration

;=============================================================================
; Includes
;=============================================================================
!include "MUI2.nsh"
!include "x64.nsh"
!include "logiclib.nsh"
!include "nsDialogs.nsh"

;=============================================================================
; Settings
;=============================================================================
Name "MCBDS API Service"
OutFile "..\MCBDS.API.Service.Installer.exe"
InstallDir "$PROGRAMFILES64\MCBDS API Service"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service" "InstallDir"

RequestExecutionLevel admin

VIProductVersion "1.0.2.0"
VIAddVersionKey "ProductName" "MCBDS API Service"
VIAddVersionKey "FileVersion" "1.0.2.0"
VIAddVersionKey "ProductVersion" "1.0.2.0"
VIAddVersionKey "CompanyName" "MCBDS"
VIAddVersionKey "FileDescription" "Minecraft Bedrock Dedicated Server API and Management Service"
VIAddVersionKey "LegalCopyright" "Copyright MCBDS"

;=============================================================================
; Variables
;=============================================================================
Var ServicePort
Var BackupFrequency
Var MaxBackups
Var CreateStartMenu

Var BinariesPath
Var LogsDir
Var LogFilePath
Var BackupsPath
Var BedrockExePath

Var BedrockDownloadConfirmed
Var hConfirmDownload

; Control handles for custom pages
Var hBinariesPath
Var hLogsDir
Var hBackupsPath
Var hPort
Var hFreq
Var hMax
Var hCreateStartMenu

; JSON-escaped variants
Var BedrockExePath_JSON
Var LogFilePath_JSON
Var BinariesPath_JSON
Var LogsDir_JSON
Var BackupsPath_JSON

;=============================================================================
; Pages
;=============================================================================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY

Page custom PathsPage PathsPageLeave
Page custom BackupSettingsPage BackupSettingsPageLeave
Page custom BedrockDownloadPage BedrockDownloadPageLeave

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

;=============================================================================
; Paths Page (Configuration Page 1)
;=============================================================================
Function PathsPage
  !insertmacro MUI_HEADER_TEXT "Storage Paths" "Configure where files will be stored"

  ; Ensure defaults before creating controls
  StrCmp $BinariesPath "" 0 +2
  StrCpy $BinariesPath "$INSTDIR\Binaries"

  StrCmp $LogsDir "" 0 +2
  StrCpy $LogsDir "$INSTDIR\logs"

  StrCmp $BackupsPath "" 0 +2
  StrCpy $BackupsPath "$INSTDIR\backups"

  nsDialogs::Create 1018
  Pop $0

  ${NSD_CreateLabel} 0 10 100% 10u "Bedrock Server Binaries Location:"
  Pop $1
  ${NSD_CreateText} 0 22u 100% 13u "$BinariesPath"
  Pop $hBinariesPath

  ${NSD_CreateLabel} 0 38u 100% 10u "Log File Directory:"
  Pop $1
  ${NSD_CreateText} 0 50u 100% 13u "$LogsDir"
  Pop $hLogsDir

  ${NSD_CreateLabel} 0 66u 100% 10u "Backups Location:"
  Pop $1
  ${NSD_CreateText} 0 78u 100% 13u "$BackupsPath"
  Pop $hBackupsPath

  nsDialogs::Show
FunctionEnd

Function PathsPageLeave
  ; Read user input from the stored handles
  ${NSD_GetText} $hBinariesPath $BinariesPath
  ${NSD_GetText} $hLogsDir     $LogsDir
  ${NSD_GetText} $hBackupsPath $BackupsPath

  ; Apply defaults if empty
  StrCmp $BinariesPath "" 0 +2
  StrCpy $BinariesPath "$INSTDIR\Binaries"

  StrCmp $LogsDir "" 0 +2
  StrCpy $LogsDir "$INSTDIR\logs"

  StrCmp $BackupsPath "" 0 +2
  StrCpy $BackupsPath "$INSTDIR\backups"

  ; Create the directories now
  CreateDirectory "$BinariesPath"
  CreateDirectory "$LogsDir"
  CreateDirectory "$BackupsPath"
FunctionEnd

;=============================================================================
; Backup Settings Page (Configuration Page 2)
;=============================================================================
Function BackupSettingsPage
  !insertmacro MUI_HEADER_TEXT "Service Configuration" "Configure the MCBDS API Service"

  nsDialogs::Create 1018
  Pop $0

  ${NSD_CreateLabel} 0 10 100% 10u "HTTP Port (default: 8080):"
  Pop $1
  ${NSD_CreateNumber} 0 22u 100% 13u "8080"
  Pop $hPort

  ${NSD_CreateLabel} 0 38u 100% 10u "Backup Frequency (minutes, default: 30):"
  Pop $1
  ${NSD_CreateNumber} 0 50u 100% 13u "30"
  Pop $hFreq

  ${NSD_CreateLabel} 0 66u 100% 10u "Maximum Backups to Keep (default: 30):"
  Pop $1
  ${NSD_CreateNumber} 0 78u 100% 13u "30"
  Pop $hMax

  ${NSD_CreateCheckbox} 0 94u 100% 12u "Create Start Menu Shortcuts"
  Pop $hCreateStartMenu
  ${NSD_SetState} $hCreateStartMenu 1

  nsDialogs::Show
FunctionEnd

Function BackupSettingsPageLeave
  ; Read values from stored handles
  ${NSD_GetText}  $hPort $ServicePort
  ${NSD_GetText}  $hFreq $BackupFrequency
  ${NSD_GetText}  $hMax  $MaxBackups
  ${NSD_GetState} $hCreateStartMenu $CreateStartMenu

  StrCmp $ServicePort "" 0 +2
  StrCpy $ServicePort "8080"

  StrCmp $BackupFrequency "" 0 +2
  StrCpy $BackupFrequency "30"

  StrCmp $MaxBackups "" 0 +2
  StrCpy $MaxBackups "30"
FunctionEnd

;=============================================================================
; Bedrock Download Confirmation Page
;=============================================================================
Function BedrockDownloadPage
  !insertmacro MUI_HEADER_TEXT "Bedrock Server Download" "Download and extract the Minecraft Bedrock server"

  ; Ensure a value is present even if user never changed it
  StrCmp $BinariesPath "" 0 +2
  StrCpy $BinariesPath "$INSTDIR\Binaries"

  nsDialogs::Create 1018
  Pop $0

  ${NSD_CreateLabel} 0 10 100% 10u "Extract Bedrock Server to this directory:"
  Pop $1

  ; Create text field and display the binaries path
  ${NSD_CreateText} 0 22u 100% 13u "$BinariesPath"
  Pop $2

  ${NSD_CreateLabel} 0 38u 100% 10u "Download the server from:"
  Pop $3

  ; Create button to open download URL
  ${NSD_CreateButton} 0 50u 100% 13u "Download Bedrock Server"
  Pop $4
  ${NSD_OnClick} $4 OpenBedrockDownloadLink

  ${NSD_CreateLabel} 0 66u 100% 24u "After downloading, extract all files to the directory shown above. The bedrock_server.exe must be directly in that directory, not in a subfolder."
  Pop $5

  ${NSD_CreateCheckbox} 0 94u 100% 12u "I have downloaded and extracted the Bedrock server to the above directory"
  Pop $hConfirmDownload

  nsDialogs::Show
FunctionEnd

Function OpenBedrockDownloadLink
  Pop $0  ; Pop the control HWND passed by OnClick
  DetailPrint "Opening Minecraft Bedrock download page..."
  ; Note: If this installer is elevated, ExecShell can fail to show a browser.
  ; For a robust, core-only elevated-safe approach, we can use PowerShell COM.
  ; For now, keep ExecShell as requested:
  ExecShell "open" "https://www.minecraft.net/en-us/download/server/bedrock"

  ; Elevated-safe alternative (uncomment to use):
  ; nsExec::ExecToStack /TIMEOUT=5000 `powershell -NoProfile -WindowStyle Hidden -Command "$s=New-Object -ComObject Shell.Application; $s.ShellExecute('https://www.minecraft.net/en-us/download/server/bedrock')"`
FunctionEnd

Function BedrockDownloadPageLeave
  ${NSD_GetState} $hConfirmDownload $BedrockDownloadConfirmed

  ${If} $BedrockDownloadConfirmed == 0
    MessageBox MB_ICONEXCLAMATION "Please confirm that you have downloaded and extracted the Bedrock server before proceeding."
    Abort
  ${EndIf}

  ; Log the path being used
  DetailPrint "Bedrock installation path: $BinariesPath"
  DetailPrint "Looking for: $BinariesPath\bedrock_server.exe"
FunctionEnd

;=============================================================================
; Installer Section
;=============================================================================
Section "Install MCBDS API Service"
SetOutPath "$INSTDIR"
SetRegView 64  ; Use native 64-bit registry view

; Normalize defaults
  ${If} $BinariesPath == ""
    StrCpy $BinariesPath "$INSTDIR\Binaries"
  ${EndIf}
  ${If} $LogsDir == ""
    StrCpy $LogsDir "$INSTDIR\logs"
  ${EndIf}
  ${If} $BackupsPath == ""
    StrCpy $BackupsPath "$INSTDIR\backups"
  ${EndIf}

  ; Compute real paths
  StrCpy $BedrockExePath "$BinariesPath\bedrock_server.exe"
  StrCpy $LogFilePath "$LogsDir\api.log"

  ; Verify bedrock_server.exe exists before proceeding
  DetailPrint "Verifying bedrock_server.exe at: $BedrockExePath"
  ${If} ${FileExists} "$BedrockExePath"
    DetailPrint "Success: bedrock_server.exe verified"
  ${Else}
    MessageBox MB_ICONEXCLAMATION "CRITICAL ERROR: bedrock_server.exe not found!$\r$\n$\r$\nExpected location:$\r$\n$BedrockExePath$\r$\n$\r$\nPlease:$\r$\n1. Cancel this installation$\r$\n2. Download Bedrock from minecraft.net$\r$\n3. Extract all files to: $BinariesPath$\r$\n4. Ensure bedrock_server.exe is directly in that folder$\r$\n5. Run installer again"
    Abort
  ${EndIf}

  DetailPrint "Extracting application files..."
  File /r "..\MCBDS.WindowsService\bin\Release\net10.0-windows\win-x64\publish\*.*"

  ; Ensure directories and log file
  CreateDirectory "$LogsDir"
  CreateDirectory "$BackupsPath"

  ${If} ${FileExists} "$LogFilePath"
    DetailPrint "Using existing log file: $LogFilePath"
  ${Else}
    DetailPrint "Creating log file: $LogFilePath"
    FileOpen $0 "$LogFilePath" w
    FileClose $0
  ${EndIf}

  DetailPrint "Creating configuration files..."

  ; Use PowerShell to intelligently merge existing config with new defaults
  DetailPrint "Merging configuration settings (preserving user customizations)..."
  
  ; Copy merge script to temp location
  SetOutPath "$TEMP"
  File "merge-appsettings.ps1"
  
  ; Execute PowerShell merge script
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TEMP\merge-appsettings.ps1" -InstallDir "$INSTDIR" -BedrockExePath "$BedrockExePath" -LogFilePath "$LogFilePath" -BackupsPath "$BackupsPath" -ServicePort $ServicePort -BackupFrequency $BackupFrequency -MaxBackups $MaxBackups'
  
  Pop $0
  ${If} $0 != 0
    DetailPrint "Warning: PowerShell merge failed (exit code: $0)"
    DetailPrint "Creating default configuration instead..."
    
    ; Fallback: Create basic config manually
    FileOpen $7 "$INSTDIR\appsettings.json" w
    FileWrite $7 "{$\r$\n"
    FileWrite $7 '  "Logging": {$\r$\n'
    FileWrite $7 '    "LogLevel": {$\r$\n'
    FileWrite $7 '      "Default": "Information",$\r$\n'
    FileWrite $7 '      "Microsoft.AspNetCore": "Warning"$\r$\n'
    FileWrite $7 '    }$\r$\n'
    FileWrite $7 '  },$\r$\n'
    FileWrite $7 '  "AllowedHosts": "*",$\r$\n'
    FileWrite $7 '  "Urls": "http://0.0.0.0:$ServicePort"$\r$\n'
    FileWrite $7 "}$\r$\n"
    FileClose $7
  ${Else}
    DetailPrint "Configuration merged successfully!"
  ${EndIf}
  
  ; Clean up temp merge script
  Delete "$TEMP\merge-appsettings.ps1"

  ; Uninstall registry
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service" "DisplayName" "MCBDS API Service"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service" "DisplayVersion" "1.0.1"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service" "Publisher" "MCBDS"

  WriteUninstaller "$INSTDIR\uninstall.exe"

  ${If} $CreateStartMenu == 1
    CreateDirectory "$SMPROGRAMS\MCBDS"
    CreateShortCut "$SMPROGRAMS\MCBDS\Service Management.lnk" "$WINDIR\System32\services.msc"
    CreateShortCut "$SMPROGRAMS\MCBDS\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  ${EndIf}

  DetailPrint "Installing Windows Service..."
  ExecWait '"$INSTDIR\MCBDS.WindowsService.exe" install'

  DetailPrint "Configuring Windows Firewall..."
  ExecWait 'netsh advfirewall firewall add rule name=$\"MCBDS API Service (HTTP)$\" dir=in action=allow protocol=tcp localport=$ServicePort program=$\"$INSTDIR\MCBDS.WindowsService.exe$\" enable=yes'

  DetailPrint "Starting MCBDS API Service..."
  Sleep 2000
  ExecWait 'net start MCBDSAPIService'

  DetailPrint "Installation completed successfully!"
  DetailPrint "Service Port: $ServicePort"
  DetailPrint "Backup Frequency: $BackupFrequency minutes"
  DetailPrint "Max Backups: $MaxBackups"
  DetailPrint "Binaries Location: $BinariesPath"
  DetailPrint "Logs Location: $LogFilePath"
  DetailPrint "Backups Location: $BackupsPath"
SectionEnd

;=============================================================================
; Uninstaller
;=============================================================================
Section "Uninstall"
  SetRegView 64  ; Use native 64-bit registry view

  DetailPrint "Stopping MCBDS API Service..."
  ExecWait 'net stop MCBDSAPIService'

  DetailPrint "Uninstalling Windows Service..."
  ExecWait '"$INSTDIR\MCBDS.WindowsService.exe" uninstall'

  DetailPrint "Removing firewall rules..."
  ExecWait 'netsh advfirewall firewall delete rule name=$\"MCBDS API Service (HTTP)$\"'

  DetailPrint "Removing registry entries..."
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service"

  DetailPrint "Removing application files..."
  Delete "$INSTDIR\MCBDS.WindowsService.exe"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\*.json"
  Delete "$INSTDIR\appsettings.user.json"
  Delete "$INSTDIR\appsettings.json"
  Delete "$INSTDIR\uninstall.exe"

  ; Remove logs directory
  RMDir /r "$INSTDIR\logs"

  ; Remove backups directory
  RMDir /r "$INSTDIR\backups"

  ; NOTE: Binaries directory is intentionally NOT deleted to preserve the Bedrock server
  ; Users can reinstall without re-downloading the large binary files

  ; Remove installation directory only if empty (it won't be if binaries folder exists)
  RMDir "$INSTDIR"

  DetailPrint "Uninstallation completed."
  DetailPrint "Note: The Bedrock server binaries were preserved at their configured location."
SectionEnd

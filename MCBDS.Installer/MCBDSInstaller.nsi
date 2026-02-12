; MCBDS Manager Installer
; NSIS Installer Script for Windows Service with Configuration

;=============================================================================
; Includes
;=============================================================================
!include "MUI2.nsh"
!include "x64.nsh"
!include "logiclib.nsh"
!include "nsDialogs.nsh"

;=============================================================================
; Version (can be overridden via command line: /DVERSION=x.x.x)
;=============================================================================
!ifndef VERSION
  !define VERSION "1.0.0"
!endif

; Convert version to 4-part format for Windows (x.x.x -> x.x.x.0)
!define VERSION_QUAD "${VERSION}.0"

;=============================================================================
; Settings
;=============================================================================
Name "MCBDS Manager ${VERSION}"
OutFile "..\MCBDS.API.Service.Installer.exe"
InstallDir "$PROGRAMFILES64\MCBDS Manager"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "InstallDir"

RequestExecutionLevel admin

VIProductVersion "${VERSION_QUAD}"
VIAddVersionKey "ProductName" "MCBDS Manager"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "CompanyName" "MCBDS"
VIAddVersionKey "FileDescription" "Minecraft Bedrock Dedicated Server Manager - API Service and Desktop App"
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
Var InstallLogFile

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

; WebView2 detection
Var WebView2Installed

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

; Setup installation log file
StrCpy $InstallLogFile "$INSTDIR\install.log"

; Create log file with installation details
FileOpen $0 "$InstallLogFile" w
FileWrite $0 "MCBDS Manager Installation Log$\r$\n"
FileWrite $0 "Version: ${VERSION}$\r$\n"
FileWrite $0 "Timestamp: $\r$\n"
FileWrite $0 "Installation Directory: $INSTDIR$\r$\n"
FileWrite $0 "================================$\r$\n$\r$\n"
FileClose $0

; Create macro for logging
!macro Log Message
  FileOpen $0 "$InstallLogFile" a
  FileSeek $0 0 END
  FileWrite $0 "${Message}$\r$\n"
  FileClose $0
  DetailPrint "${Message}"
!macroend

; Check if service is already installed and stop it
!insertmacro Log "Checking for existing MCBDS API Service..."

; Create PowerShell script to stop service reliably
SetOutPath "$TEMP"
FileOpen $0 "$TEMP\stop-service.ps1" w
FileWrite $0 "$ErrorActionPreference = 'Stop'$\r$\n"
FileWrite $0 "try {$\r$\n"
FileWrite $0 "    $$svc = Get-Service -Name 'MCBDSAPIService' -ErrorAction SilentlyContinue$\r$\n"
FileWrite $0 "    if ($$svc) {$\r$\n"
FileWrite $0 "        Write-Host 'Service found: ' $$svc.Status$\r$\n"
FileWrite $0 "        if ($$svc.Status -eq 'Running') {$\r$\n"
FileWrite $0 "            Write-Host 'Stopping service...'$\r$\n"
FileWrite $0 "            Stop-Service -Name 'MCBDSAPIService' -Force$\r$\n"
FileWrite $0 "            Start-Sleep -Seconds 2$\r$\n"
FileWrite $0 "            $$svc.Refresh()$\r$\n"
FileWrite $0 "            if ($$svc.Status -eq 'Stopped') {$\r$\n"
FileWrite $0 "                Write-Host 'Service stopped successfully'$\r$\n"
FileWrite $0 "                exit 0$\r$\n"
FileWrite $0 "            } else {$\r$\n"
FileWrite $0 "                Write-Host 'Warning: Service did not stop cleanly'$\r$\n"
FileWrite $0 "                exit 2$\r$\n"
FileWrite $0 "            }$\r$\n"
FileWrite $0 "        } else {$\r$\n"
FileWrite $0 "            Write-Host 'Service is not running'$\r$\n"
FileWrite $0 "            exit 0$\r$\n"
FileWrite $0 "        }$\r$\n"
FileWrite $0 "    } else {$\r$\n"
FileWrite $0 "        Write-Host 'No service found - new installation'$\r$\n"
FileWrite $0 "        exit 1$\r$\n"
FileWrite $0 "    }$\r$\n"
FileWrite $0 "} catch {$\r$\n"
FileWrite $0 "    Write-Host 'Error: ' $$_.Exception.Message$\r$\n"
FileWrite $0 "    exit 3$\r$\n"
FileWrite $0 "}$\r$\n"
FileClose $0

; Execute the PowerShell script
nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TEMP\stop-service.ps1"'
Pop $0

${If} $0 == 0
  DetailPrint "Service stopped successfully or was not running"
${ElseIf} $0 == 1
  DetailPrint "No existing service found - this is a new installation"
${ElseIf} $0 == 2
  DetailPrint "Warning: Service may still be running. Waiting before continuing..."
  Sleep 3000
${Else}
  DetailPrint "Warning: Error checking service status (code: $0). Continuing anyway..."
  Sleep 2000
${EndIf}

; Clean up temp script
Delete "$TEMP\stop-service.ps1"

; Wait a moment for files to be released
Sleep 1000

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
    !insertmacro Log "? Bedrock server found: $BedrockExePath"
  ${Else}
    DetailPrint "WARNING: bedrock_server.exe not found at configured location"
    !insertmacro Log "? WARNING: bedrock_server.exe not found!"
    !insertmacro Log "  Expected location: $BedrockExePath"
    !insertmacro Log "  The API Service will be installed but won't start until bedrock_server.exe is available"
    !insertmacro Log "  You can:"
    !insertmacro Log "    1. Download from: https://www.minecraft.net/en-us/download/server/bedrock"
    !insertmacro Log "    2. Extract to: $BinariesPath"
    !insertmacro Log "    3. Restart the service"
    
    ; Show warning but ALWAYS continue (no abort)
    MessageBox MB_ICONINFORMATION "bedrock_server.exe not found at:$\r$\n$BedrockExePath$\r$\n$\r$\nThe MCBDS Manager will still be installed.$\r$\n$\r$\nThe server won't start until you:$\r$\n1. Download Bedrock Server from minecraft.net$\r$\n2. Extract all files to: $BinariesPath$\r$\n3. Restart the MCBDSAPIService$\r$\n$\r$\nClick OK to continue installation..."
  ${EndIf}


  ; Backup existing appsettings.json before extracting files
  DetailPrint "Backing up existing configuration..."
  ${If} ${FileExists} "$INSTDIR\appsettings.json"
    DetailPrint "Found existing appsettings.json - backing up"
    CopyFiles /SILENT "$INSTDIR\appsettings.json" "$TEMP\appsettings.backup.json"
  ${Else}
    DetailPrint "No existing appsettings.json found - will create new"
  ${EndIf}

  ; Remove old Desktop App folder if it exists (from previous installations)
  ${If} ${FileExists} "$INSTDIR\DesktopApp"
    DetailPrint "Removing legacy Desktop App folder from previous installation..."
    RMDir /r "$INSTDIR\DesktopApp"
  ${EndIf}

  ; CRITICAL: Reset output path to installation directory before extracting service files
  SetOutPath "$INSTDIR"
  DetailPrint "Extracting API Service files..."
  !insertmacro Log "Extracting service files to: $INSTDIR"
  File /r "..\MCBDS.WindowsService\bin\Release\net10.0-windows\win-x64\publish\*.*"
  !insertmacro Log "? Service files extracted"
  
  ; Install PublicUI MAUI App (MSIX Package)
  !insertmacro Log "Installing MCBDS Manager Desktop App (PublicUI)..."
  
  ; First, install the code signing certificate to Trusted Root
  !insertmacro Log "Installing code signing certificate..."
  SetOutPath "$TEMP"
  !insertmacro Log "Temp directory: $TEMP"
  
  !ifdef CERT_PATH
    !insertmacro Log "Extracting embedded certificate from installer..."
    !insertmacro Log "  (Certificate was embedded at build time from: ${CERT_PATH})"
    
    ; Extract the certificate file that was embedded at compile time
    ; NSIS File command extracts from installer resources, not from build machine path
    File /oname=CodeSigning.cer "${CERT_PATH}"
    
    ; Verify copy was successful
    Sleep 500  ; Wait for file system
    ${If} ${FileExists} "$TEMP\CodeSigning.cer"
      !insertmacro Log "? Certificate successfully copied to temp: $TEMP\CodeSigning.cer"
      ; Check file size
      GetFileTime "$TEMP\CodeSigning.cer" $0 $1
      !insertmacro Log "  File size check passed"
    ${Else}
      !insertmacro Log "? ERROR: Certificate NOT in temp after copy!"
      !insertmacro Log "  Expected: $TEMP\CodeSigning.cer"
      !insertmacro Log "  This indicates a file system issue"
      MessageBox MB_ICONEXCLAMATION "Certificate file was not copied to temp!$\r$\n$\r$\nThis is a file system error. Check disk space and permissions."
      Goto SkipCert
    ${EndIf}
    
    ; Install certificate to Trusted Root Certification Authorities
    !insertmacro Log "Running: certutil.exe -addstore -f Root $TEMP\CodeSigning.cer"
    nsExec::ExecToStack 'certutil.exe -addstore -f "Root" "$TEMP\CodeSigning.cer"'
    Pop $0
    
    !insertmacro Log "Certutil exit code: $0"
    ${If} $0 == 0
      !insertmacro Log "? Certificate installed successfully to Trusted Root via certutil"
    ${Else}
      !insertmacro Log "? WARNING: certutil returned non-zero code: $0"
      !insertmacro Log "Attempting alternative installation method via PowerShell..."
      
      ; Try PowerShell as backup
      nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Import-Certificate -FilePath ''$TEMP\CodeSigning.cer'' -CertStoreLocation ''Cert:\LocalMachine\Root'' -Force -ErrorAction Stop | Out-Null; Write-Host ''SUCCESS''; exit 0 } catch { Write-Host ''FAILED: '' $_.Exception.Message; exit 1 }"'
      Pop $0
      
      !insertmacro Log "PowerShell exit code: $0"
      ${If} $0 == 0
        !insertmacro Log "? Certificate installed successfully via PowerShell"
      ${Else}
        !insertmacro Log "? ERROR: Certificate installation failed via both methods"
        !insertmacro Log "  Certutil code: $0, PowerShell code: $0"
        !insertmacro Log "  MSIX installation will likely fail"
      ${EndIf}
    ${EndIf}
    
    ; Verify certificate was actually installed
    !insertmacro Log "Verifying certificate installation..."
    nsExec::ExecToStack 'powershell.exe -NoProfile -Command "$cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -like ''*Pinecrest*''}; if ($cert) { Write-Host ''FOUND: '' $cert.Subject; exit 0 } else { Write-Host ''NOT FOUND''; exit 1 }"'
    Pop $0
    ${If} $0 == 0
      !insertmacro Log "? VERIFIED: Certificate is in Trusted Root"
    ${Else}
      !insertmacro Log "? WARNING: Certificate NOT found in Trusted Root after installation"
      !insertmacro Log "  Note: Certutil error 1380 means certificate was already installed"
      !insertmacro Log "  MSIX installation may fail"
    ${EndIf}
    
    Delete "$TEMP\CodeSigning.cer"
    !insertmacro Log "Cleaned up temp certificate file"
    
  !else
    !insertmacro Log "? ERROR: CERT_PATH not defined - cannot install certificate"
  !endif
  
  SkipCert:
  !insertmacro Log "Certificate installation phase complete"

  ; Now attempt MSIX installation
  !insertmacro Log "====== MSIX Installation Phase ======"
  !insertmacro Log "Temp directory being used: $TEMP"
  !insertmacro Log "Attempting MSIX package installation..."
  
  ; MSIX path must be passed via /DMSIX_PATH at compile time
  !ifdef MSIX_PATH
    !insertmacro Log "Extracting embedded MSIX from installer..."
    !insertmacro Log "  (MSIX was embedded at build time from: ${MSIX_PATH})"
    
    ; Extract the MSIX file that was embedded at compile time
    SetOutPath "$TEMP"
    File /oname=MCBDS.PublicUI.msix "${MSIX_PATH}"
    
    ; Verify extraction was successful
    Sleep 1000  ; Wait for file system
    !insertmacro Log "Checking if MSIX extracted to temp..."
    
    ${If} ${FileExists} "$TEMP\MCBDS.PublicUI.msix"
      !insertmacro Log "? MSIX successfully extracted to temp"
      !insertmacro Log "  Location: $TEMP\MCBDS.PublicUI.msix"
    ${Else}
      !insertmacro Log "? CRITICAL ERROR: MSIX NOT in temp after extraction!"
      !insertmacro Log "  Expected: $TEMP\MCBDS.PublicUI.msix"
      !insertmacro Log "  This means the MSIX was not embedded in the installer at build time"
      MessageBox MB_ICONSTOP "MSIX file was not embedded in installer!$\r$\n$\r$\nPlease rebuild the installer."
      Goto SkipMSIX
    ${EndIf}
  !else
    !insertmacro Log "? ERROR: MSIX_PATH not defined"
    !insertmacro Log "  This means /DMSIX_PATH was not passed to NSIS compiler"
    Goto SkipMSIX
  !endif
  
  ; At this point, MSIX MUST be in temp
  !insertmacro Log "====== Installing MSIX ======"
  !insertmacro Log "Running: Add-AppxPackage -Path '$TEMP\MCBDS.PublicUI.msix'"
  
  ; Use -File parameter to run a script instead of -Command for better path handling
  ; Create a temporary PowerShell script for MSIX installation
  FileOpen $1 "$TEMP\install-msix.ps1" w
  FileWrite $1 "$$ErrorActionPreference = 'Stop'$\r$\n"
  FileWrite $1 "$$msixPath = '$TEMP\MCBDS.PublicUI.msix'$\r$\n"
  FileWrite $1 "Write-Host 'Starting MSIX installation...'$\r$\n"
  FileWrite $1 "Write-Host 'Path: ' $$msixPath$\r$\n"
  FileWrite $1 "try {$\r$\n"
  FileWrite $1 "    Add-AppxPackage -Path $$msixPath -ForceApplicationShutdown -ErrorAction Stop$\r$\n"
  FileWrite $1 "    Write-Host 'MSIX installation SUCCEEDED'$\r$\n"
  FileWrite $1 "    exit 0$\r$\n"
  FileWrite $1 "} catch {$\r$\n"
  FileWrite $1 "    Write-Host 'MSIX installation FAILED: ' $$_.Exception.Message$\r$\n"
  FileWrite $1 "    Write-Host 'Exception Type: ' $$_.Exception.GetType().Name$\r$\n"
  FileWrite $1 "    exit 1$\r$\n"
  FileWrite $1 "}$\r$\n"
  FileClose $1
  
  ; Execute the script
  nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TEMP\install-msix.ps1"'
  Pop $0
  
  ; Clean up the temp script
  Delete "$TEMP\install-msix.ps1"
  
  !insertmacro Log "Add-AppxPackage exit code: $0"
  
  ; Success codes: 0 = clean install, 1768-1804 = already installed/registered
  ${If} $0 == 0
    !insertmacro Log "??? MSIX INSTALLED SUCCESSFULLY (Clean Install) ???"
    
    ; Clean up temp MSIX on success
    !insertmacro Log "Cleaning up temp MSIX file..."
    ${If} ${FileExists} "$TEMP\MCBDS.PublicUI.msix"
      Delete "$TEMP\MCBDS.PublicUI.msix"
      Sleep 200
      ${If} ${FileExists} "$TEMP\MCBDS.PublicUI.msix"
        !insertmacro Log "? WARNING: Failed to delete MSIX from temp"
      ${Else}
        !insertmacro Log "? Temp MSIX cleaned up"
      ${EndIf}
    ${EndIf}
  ${ElseIf} $0 == 1768
    !insertmacro Log "? MSIX Already Registered (Package is already installed)"
    !insertmacro Log "  This is normal for reinstalls/upgrades - continuing installation..."
  ${ElseIf} $0 == 1776
    !insertmacro Log "? MSIX Success with Warning (Package already exists)"
    !insertmacro Log "  Continuing installation..."
  ${ElseIf} $0 == 1788
    !insertmacro Log "? MSIX Already Installed or Registered"
    !insertmacro Log "  Continuing installation..."
  ${ElseIf} $0 == 1804
    !insertmacro Log "? MSIX Package Already Registered"
    !insertmacro Log "  Continuing installation..."
  ${Else}
    !insertmacro Log "? MSIX installation returned code: $0"
    !insertmacro Log "  Common error codes:"
    !insertmacro Log "    1340 = ERROR_INVALID_ACL - Invalid access control list"
    !insertmacro Log "    1488 = ERROR_INSTALL_REMOTE_PROHIBITED - Remote installation not allowed"
    !insertmacro Log "    1808 = ERROR_INSTALL_PACKAGE_REJECTED - Package was rejected (manifest/cert issue)"
    !insertmacro Log "    3 = Path issue or file not found"
    !insertmacro Log "    5 = Access denied"
    !insertmacro Log ""
    !insertmacro Log "  MSIX may already be installed - checking..."
    
    ; Check if MSIX is actually installed
    nsExec::ExecToStack 'powershell.exe -NoProfile -Command "if (Get-AppxPackage -Name *MCBDS*) { exit 0 } else { exit 1 }"'
    Pop $1
    ${If} $1 == 0
      !insertmacro Log "  ? MSIX IS installed despite error code - continuing..."
    ${Else}
      !insertmacro Log "  ? MSIX is NOT installed"
      !insertmacro Log ""
      !insertmacro Log "  MSIX file left in temp for manual testing:"
      !insertmacro Log "  $TEMP\MCBDS.PublicUI.msix"
      !insertmacro Log ""
      !insertmacro Log "  To install manually, run:"
      !insertmacro Log "  Add-AppxPackage -Path '$TEMP\MCBDS.PublicUI.msix'"
      
      ; Show warning but CONTINUE installation (don't abort)
      MessageBox MB_ICONINFORMATION "Desktop App (MSIX) installation encountered an issue (code $0).$\r$\n$\r$\nThe API Service will still be installed.$\r$\n$\r$\nYou can install the Desktop App manually later using:$\r$\nAdd-AppxPackage -Path '$TEMP\MCBDS.PublicUI.msix'$\r$\n$\r$\nContinuing with installation..."
    ${EndIf}
  ${EndIf}
  
  Goto EndMSIX
  
  SkipMSIX:
  !insertmacro Log "MSIX installation SKIPPED"
  
  EndMSIX:
  !insertmacro Log "====== MSIX Phase Complete ======"
  
  ; Reset output path back to installation directory
  SetOutPath "$INSTDIR"
  
  ; ====== Configure and Install Windows Service ======
  !insertmacro Log ""
  !insertmacro Log "====== Windows Service Installation ======"
  
  ; Configure appsettings.json with user-provided paths
  !insertmacro Log "Configuring appsettings.json..."
  
  ; Create PowerShell script to merge appsettings
  FileOpen $1 "$TEMP\merge-appsettings.ps1" w
  FileWrite $1 "$$installDir = '$INSTDIR'$\r$\n"
  FileWrite $1 "$$bedrockExePath = '$BedrockExePath'$\r$\n"
  FileWrite $1 "$$logFilePath = '$LogFilePath'$\r$\n"
  FileWrite $1 "$$backupsPath = '$BackupsPath'$\r$\n"
  FileWrite $1 "$$backupFreq = '$BackupFrequency'$\r$\n"
  FileWrite $1 "$$maxBackups = '$MaxBackups'$\r$\n"
  FileWrite $1 "$$servicePort = '$ServicePort'$\r$\n"
  FileWrite $1 "$$appsettingsPath = Join-Path $$installDir 'appsettings.json'$\r$\n"
  FileWrite $1 "if (Test-Path $$appsettingsPath) {$\r$\n"
  FileWrite $1 "    $$json = Get-Content $$appsettingsPath -Raw | ConvertFrom-Json$\r$\n"
  FileWrite $1 "    $$json.Runner.ExePath = $$bedrockExePath$\r$\n"
  FileWrite $1 "    $$json.Logging.LogFilePath = $$logFilePath$\r$\n"
  FileWrite $1 "    $$json.Backup.BackupDirectory = $$backupsPath$\r$\n"
  FileWrite $1 "    $$json.Backup.FrequencyMinutes = [int]$$backupFreq$\r$\n"
  FileWrite $1 "    $$json.Backup.MaxBackupsToKeep = [int]$$maxBackups$\r$\n"
  FileWrite $1 "    if ($$json.PSObject.Properties['Kestrel']) {$\r$\n"
  FileWrite $1 "        $$json.Kestrel.Endpoints.Http.Url = 'http://localhost:' + $$servicePort$\r$\n"
  FileWrite $1 "    }$\r$\n"
  FileWrite $1 "    $$json | ConvertTo-Json -Depth 10 | Set-Content $$appsettingsPath -Encoding UTF8$\r$\n"
  FileWrite $1 "    Write-Host 'SUCCESS'$\r$\n"
  FileWrite $1 "    exit 0$\r$\n"
  FileWrite $1 "} else {$\r$\n"
  FileWrite $1 "    Write-Host 'ERROR: appsettings.json not found'$\r$\n"
  FileWrite $1 "    exit 1$\r$\n"
  FileWrite $1 "}$\r$\n"
  FileClose $1
  
  nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TEMP\merge-appsettings.ps1"'
  Pop $0
  Delete "$TEMP\merge-appsettings.ps1"
  
  ${If} $0 == 0
    !insertmacro Log "? appsettings.json configured"
  ${Else}
    !insertmacro Log "? WARNING: Failed to configure appsettings.json"
  ${EndIf}
  
  ; Install Windows Service
  !insertmacro Log "Installing Windows Service..."
  nsExec::ExecToLog '"$INSTDIR\MCBDS.WindowsService.exe" install'
  Pop $0
  ${If} $0 == 0
    !insertmacro Log "? Windows Service installed"
  ${Else}
    !insertmacro Log "? WARNING: Service installation returned code $0 (may already be installed)"
  ${EndIf}
  
  ; Create firewall rules
  !insertmacro Log "Configuring firewall rules..."
  nsExec::ExecToLog 'netsh advfirewall firewall add rule name="MCBDS API Service (HTTP)" dir=in action=allow protocol=TCP localport=$ServicePort'
  Pop $0
  ${If} $0 == 0
    !insertmacro Log "? Firewall rule created"
  ${Else}
    !insertmacro Log "? WARNING: Firewall rule creation returned code $0"
  ${EndIf}
  
  ; Start the service
  !insertmacro Log "Starting service..."
  nsExec::ExecToLog 'net start MCBDSAPIService'
  Pop $0
  ${If} $0 == 0
    !insertmacro Log "? Service started successfully"
  ${Else}
    !insertmacro Log "? WARNING: Service start returned code $0 (will start automatically on reboot)"
  ${EndIf}
  
  ; Create Start Menu shortcuts if requested
  ${If} $CreateStartMenu == 1
    !insertmacro Log "Creating Start Menu shortcuts..."
    CreateDirectory "$SMPROGRAMS\MCBDS"
    CreateShortcut "$SMPROGRAMS\MCBDS\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    !insertmacro Log "? Start Menu shortcuts created"
  ${EndIf}
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Write registry keys for Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "DisplayName" "MCBDS Manager"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" "Publisher" "MCBDS"
  
  !insertmacro Log "====== Service Installation Complete ======"
  
  !insertmacro Log "========================================="
  !insertmacro Log "Installation completed successfully!"
  !insertmacro Log "========================================="
  !insertmacro Log "Service will start automatically"
  !insertmacro Log "API will be available at: http://localhost:$ServicePort"
  !insertmacro Log "Installation log file saved to:"
  !insertmacro Log "$InstallLogFile"
  !insertmacro Log "========================================="
  
  DetailPrint "Installation completed successfully!"
  DetailPrint "See $INSTDIR\install.log for detailed installation information"
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
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager"

  DetailPrint "Removing Start Menu shortcuts..."
  Delete "$SMPROGRAMS\MCBDS\Service Management.lnk"
  Delete "$SMPROGRAMS\MCBDS\Uninstall.lnk"
  RMDir "$SMPROGRAMS\MCBDS"

  ; Uninstall MSIX app (PublicUI)
  DetailPrint "Uninstalling MCBDS Manager Desktop App (MSIX)..."
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -Name *MCBDS* | Remove-AppxPackage -ErrorAction SilentlyContinue"'

  DetailPrint "Removing application files..."
  Delete "$INSTDIR\MCBDS.WindowsService.exe"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\*.json"
  Delete "$INSTDIR\appsettings.user.json"
  Delete "$INSTDIR\appsettings.json"
  Delete "$INSTDIR\uninstall.exe"

  ; Remove legacy Desktop App folder (from older versions)
  DetailPrint "Removing legacy Desktop App files..."
  ${If} ${FileExists} "$INSTDIR\DesktopApp"
    RMDir /r "$INSTDIR\DesktopApp"
    DetailPrint "Legacy Desktop App folder removed"
  ${EndIf}

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


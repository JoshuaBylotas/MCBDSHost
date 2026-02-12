# MCBDS Manager Installer - Troubleshooting Guide

## Overview
This guide helps diagnose and fix issues during MCBDS Manager installation. Most problems are logged in detail for easier troubleshooting.

## Installation Log Location

**After installation**, check the detailed log file:
```
C:\Program Files\MCBDS Manager\install.log
```

This file contains step-by-step information about:
- Version and installation directory
- Certificate installation status
- MSIX package installation results
- appsettings.json creation/merge status
- Service installation
- Configuration settings applied

## Common Issues & Solutions

### 1. Application Won't Start - JSON Parse Error

**Error Message:**
```
Failed to load configuration from file 'C:\Program Files\MCBDS Manager\appsettings.json'
'P' is an invalid escapable character within a JSON string
```

**Cause:** The `appsettings.json` file has unescaped backslashes in Windows paths.

**Solution:**
1. Stop the MCBDS API Service:
   ```powershell
   Stop-Service -Name MCBDSAPIService
   ```

2. Open `C:\Program Files\MCBDS Manager\appsettings.json` in a text editor

3. Look for lines with paths containing backslashes like:
   ```json
   "ExePath": "C:\Program Files\MCBDS Manager\Binaries\bedrock_server.exe"
   ```

4. Fix them by converting backslashes to forward slashes:
   ```json
   "ExePath": "C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe"
   ```

5. **OR** - For best results, delete appsettings.json and let installer regenerate it:
   ```powershell
   Remove-Item "C:\Program Files\MCBDS Manager\appsettings.json"
   # Run installer again and choose to merge/regenerate
   ```

6. Restart the service:
   ```powershell
   Start-Service -Name MCBDSAPIService
   ```

### 2. MSIX Installation Failed

**Error Message (in installer or log):**
```
MSIX installation returned code: (non-zero number)
The MSIX may be blocked due to missing certificate or unsigned content
```

**Check install.log for:**
```
Code signing certificate installed successfully to Trusted Root
```

**If certificate installation FAILED:**

**Solution Option A - Reinstall with Admin:**
1. Uninstall the current installation
2. Right-click installer and select **"Run as administrator"**
3. Verify UAC (User Account Control) prompt appears - if not, admin failed
4. Complete installation

**Solution Option B - Manual Certificate Installation:**
1. Locate the certificate file (usually in `C:\Program Files\MCBDS Manager\`)
2. Open **Certificates** (Windows):
   - Press `Win+R`, type `certmgr.msc`
   - Navigate to: `Trusted Root Certification Authorities` > `Certificates`
3. Right-click and select "Import Certificate"
4. Choose the `.cer` file from the installer directory
5. Click "Next" and select "Trusted Root Certification Authorities"
6. Uninstall and reinstall the MSIX manually

### 3. Certificate Not in Trusted Root Store

**Check if certificate is installed:**

```powershell
# Check Local Machine Trusted Root (requires admin)
Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}

# Check Current User Trusted Root
Get-ChildItem -Path "Cert:\CurrentUser\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
```

**If not found - Solution:**

1. **From install.log**, locate the line:
   ```
   Running: certutil.exe -addstore -f Root ...
   ```
   Note the return code

2. **If code is non-zero**, manually install with elevated PowerShell:
   ```powershell
   # Run as Administrator
   $CertPath = "C:\Program Files\MCBDS Manager\CodeSigning.cer"
   Import-Certificate -FilePath $CertPath -CertStoreLocation "Cert:\LocalMachine\Root"
   ```

3. **Verify installation:**
   ```powershell
   Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
   ```

### 4. Service Won't Start

**Check for issues:**

1. **Verify appsettings.json syntax:**
   ```powershell
   # From PowerShell
   $config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
   Write-Host "Config loaded successfully!"
   ```

2. **Check service logs:**
   ```powershell
   # View recent service errors
   Get-EventLog -LogName Application -Source MCBDSAPIService -Newest 10
   ```

3. **Check runner configuration:**
   - Verify Bedrock server path exists in appsettings.json
   - Confirm bedrock_server.exe is present at that path
   - Ensure path uses forward slashes (not backslashes)

### 5. Port Already in Use

**Error:** Service won't start because port 8080 is already in use

**Solution:**

1. **Check what's using the port:**
   ```powershell
   netstat -ano | findstr :8080
   ```

2. **Use a different port in appsettings.json:**
   ```json
   "Urls": "http://0.0.0.0:8081"
   ```

3. **Update Windows Firewall rule:**
   ```powershell
   netsh advfirewall firewall delete rule name="MCBDS API Service (HTTP)"
   netsh advfirewall firewall add rule name="MCBDS API Service (HTTP)" dir=in action=allow protocol=tcp localport=8081
   ```

4. **Restart service:**
   ```powershell
   Restart-Service -Name MCBDSAPIService
   ```

## Installer Logs in Detail

### What Gets Logged

The `install.log` file includes:
- ? Installation start time and version
- ? Installation directory
- ? Service detection and stopping
- ? File extraction status
- ? Certificate file copying
- ? Certificate installation method and result code
- ? MSIX package extraction and installation
- ? appsettings.json creation/merge status
- ? Service installation and startup
- ? Firewall rule configuration
- ? Installation completion status

### Reading the Log

1. **Search for "ERROR"** to find any failures:
   ```powershell
   Select-String "ERROR" "C:\Program Files\MCBDS Manager\install.log"
   ```

2. **Check certificate section** for installation status:
   ```powershell
   Select-String "certificate" "C:\Program Files\MCBDS Manager\install.log"
   ```

3. **Verify configuration merge:**
   ```powershell
   Select-String "Configuration" "C:\Program Files\MCBDS Manager\install.log"
   ```

## Administrative Requirements

The installer **MUST** be run as Administrator because:
- ? Installing certificates requires admin access
- ? Creating Windows services requires admin
- ? Opening Windows Firewall requires admin
- ? Writing to Program Files requires admin

**Verify you're running as admin:**
```powershell
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($admin) { "Running as Administrator" } else { "NOT running as Administrator" }
```

## Services and Ports

After successful installation:

**Windows Service:**
- Name: `MCBDSAPIService`
- Executable: `C:\Program Files\MCBDS Manager\MCBDS.WindowsService.exe`
- Startup Type: Automatic
- Check status: `Get-Service MCBDSAPIService`

**Network Port:**
- Default: `8080`
- Accessible at: `http://localhost:8080`
- Change in: `C:\Program Files\MCBDS Manager\appsettings.json` (Urls property)

## Getting Help

If you encounter issues not listed above:

1. **Collect diagnostic information:**
   ```powershell
   # Copy install log
   Copy-Item "C:\Program Files\MCBDS Manager\install.log" "$env:TEMP\mcbds-install.log"
   
   # Export service status
   Get-Service MCBDSAPIService | Format-List > "$env:TEMP\mcbds-service.txt"
   
   # Check appsettings.json
   Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" > "$env:TEMP\mcbds-appsettings.json"
   
   # Export certificate info
   Get-ChildItem "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"} | Format-List > "$env:TEMP\mcbds-cert.txt"
   
   Write-Host "Diagnostic files saved to $env:TEMP"
   ```

2. **Review the complete install.log** for detailed step-by-step information

3. **Check Windows Event Viewer** for system errors:
   ```powershell
   Get-EventLog -LogName System -Source "Service Control Manager" -Newest 20 | Where-Object {$_.Message -like "*MCBDSAPIService*"} | Format-List
   ```

## Prevention - Rebuilding the Installer

If the installer has issues, rebuild it:

```powershell
# Run from repository root as Administrator
.\MCBDS.Installer\build-installer.ps1 -IncrementVersion
```

This will:
- Create a fresh certificate
- Build a new MSIX package
- Generate a new installer with all fixes
- Provide detailed build output

The new installer will have:
- ? Proper JSON path escaping
- ? Detailed logging for every step
- ? Both certutil.exe and PowerShell certificate installation methods
- ? Complete error reporting

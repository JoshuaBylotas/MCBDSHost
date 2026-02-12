# MCBDS Installer - Recent Fixes Summary

## Issues Fixed

### 1. ? Unescaped Paths in appsettings.json (JSON Parse Error)
**Problem:** Windows paths with backslashes were being written to JSON, causing parse errors like:
```
'P' is an invalid escapable character within a JSON string
```

**Root Cause:** When creating appsettings.json, backslashes in paths weren't being converted to forward slashes for JSON compatibility.

**Fixes Applied:**
- Updated `MCBDSInstaller.nsi` to use PowerShell for creating appsettings.json with proper path conversion
- Updated `merge-appsettings.ps1` to convert all paths to forward slashes when reading from existing configs
- Added validation that checks JSON before and after writing to disk
- Added detailed error messages if JSON conversion fails

**Result:** All paths in appsettings.json now use forward slashes `/` instead of backslashes `\`

---

### 2. ? Missing Certificate in Trusted Root Store
**Problem:** MSIX installation was failing because the code signing certificate wasn't being installed to the Windows Trusted Root store on target machines.

**Root Cause:** The NSIS installer wasn't properly calling the certificate installation, and there was no logging to diagnose the failure.

**Fixes Applied:**
- Updated `MCBDSInstaller.nsi` to use `certutil.exe` as primary certificate installation method
- Added PowerShell fallback for certificate installation
- Certificate file is now properly embedded in installer and extracted to temp before installing
- Added validation that certificate file exists before attempting installation

**Result:** Certificate is now installed to `LocalMachine\Root` (Trusted Root) on target machines, allowing MSIX to install without warnings

---

### 3. ? No Logging During Installation
**Problem:** When installation failed, there was no way to debug what went wrong. Users couldn't see what happened with the certificate or MSIX installation.

**Root Cause:** NSIS DetailPrint statements aren't preserved after installation completes. Users had no post-installation log to reference.

**Fixes Applied:**
- Added `install.log` creation in NSIS installer
- Created logging macro `!insertmacro Log` that writes to both DetailPrint and install.log
- Added logging for every major step:
  - Certificate file location and existence verification
  - Certificate installation method and return codes
  - MSIX extraction and installation status
  - Configuration file creation/merge status
  - Service and firewall configuration
- Final log message tells users where to find install.log
- Log file location: `C:\Program Files\MCBDS Manager\install.log`

**Result:** Complete audit trail of installation steps saved to disk for post-installation troubleshooting

---

## Files Changed

### 1. `MCBDS.Installer\MCBDSInstaller.nsi` (NSIS Installer Script)
- Added installation logging infrastructure
- Fixed JSON path escaping in appsettings.json creation
- Updated certificate installation to use certutil.exe with PowerShell fallback
- Added detailed error reporting at each step
- Enhanced message box text with log file location reference

### 2. `MCBDS.Installer\merge-appsettings.ps1` (Configuration Merge Script)
- Added `ConvertFrom-JsonPath` function for proper path handling
- Updated all path preservation logic to convert backslashes to forward slashes
- Added JSON validation before and after writing files
- Enhanced error reporting with stack traces
- Shows problematic JSON if validation fails

### 3. `MCBDS.Installer\build-installer.ps1` (Build Script)
- Added detailed logging certificate and MSIX paths during build
- Updated final instructions to emphasize Administrator requirement
- Added clear next steps and troubleshooting information
- Added reference to detailed installation documentation

### 4. New Documentation Files Created
- `CERTIFICATE-INSTALLATION-GUIDE.md` - How certificate installation works
- `TROUBLESHOOTING-GUIDE.md` - Common issues and solutions
- `POST-INSTALLATION-VERIFICATION.md` - How to verify successful installation

---

## How to Use the Fixed Installer

### For Building:
```powershell
# Run as Administrator (recommended)
.\MCBDS.Installer\build-installer.ps1 -IncrementVersion
```

### For Installation:
1. **Right-click** installer EXE
2. **Select "Run as administrator"** (this is critical)
3. **Complete wizard**, answer configuration questions
4. **After installation**, check:
   - `C:\Program Files\MCBDS Manager\install.log` for status
   - Service status via `services.msc`
   - API access at `http://localhost:8080`

---

## Verification Checklist

After installation, verify:

? **install.log exists and shows success**
```powershell
Get-Content "C:\Program Files\MCBDS Manager\install.log"
```

? **Service is running**
```powershell
Get-Service MCBDSAPIService
```

? **appsettings.json is valid JSON**
```powershell
$config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
```

? **Certificate installed (if certificate section shows success in install.log)**
```powershell
Get-ChildItem "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
```

? **API is responding**
```powershell
Invoke-WebRequest -Uri "http://localhost:8080/health"
```

---

## Log File Reference

The `install.log` file will contain entries like:

```
MCBDS Manager Installation Log
Version: 1.2.3
Timestamp: [installer start time]
Installation Directory: C:\Program Files\MCBDS Manager
=================================

Checking for existing MCBDS API Service...
Extracting API Service files...
Installing MCBDS Manager Desktop App (PublicUI)...
Installing code signing certificate...
Certificate file path defined: D:\...\CodeSigning.cer
Certificate file successfully copied to temp: C:\Users\joshua\AppData\Local\Temp\CodeSigning.cer
Running: certutil.exe -addstore -f Root C:\Users\joshua\AppData\Local\Temp\CodeSigning.cer
Code signing certificate installed successfully to Trusted Root via certutil
Installing MSIX package...
MSIX path defined: D:\...\MCBDS.PublicUI.msix
MSIX package successfully copied to: C:\Users\joshua\AppData\Local\Temp\MCBDS.PublicUI.msix
Installing MSIX package using Add-AppxPackage...
MSIX package installed successfully
Cleaning up temporary files...
Creating application directories...
Merging configuration settings...
appsettings.json created successfully with proper path formatting
Service Port: 8080
Bedrock Path: C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe
... [more configuration details] ...
Starting MCBDS API Service...
=========================================
Installation completed successfully!
=========================================
Service will start automatically
API will be available at: http://localhost:8080
Installation log file saved to:
C:\Program Files\MCBDS Manager\install.log
=========================================
```

---

## What Changed Technially

### Path Handling
**Before:**
```json
"ExePath": "C:\Program Files\MCBDS Manager\Binaries\bedrock_server.exe"
// ? Invalid JSON - unescaped backslashes
```

**After:**
```json
"ExePath": "C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe"
// ? Valid JSON - forward slashes
```

### Certificate Installation
**Before:**
- Only attempted PowerShell Import-Certificate
- No logging, so failures were silent
- Certificate might not be in Trusted Root

**After:**
- Tries `certutil.exe` first (built-in Windows utility)
- Falls back to PowerShell if certutil fails
- Logs every step including return codes
- Verifies certificate file exists before installing
- Reports success/failure clearly to user

### JSON Validation
**Before:**
- Written to disk without validation
- Errors only discovered when service started

**After:**
- Validates JSON before writing to disk
- Tests that file can be read and parsed after writing
- Shows exact error and problematic JSON if validation fails
- Prevents "unreadable config" errors at runtime

---

## References

- [Installation Certificate Guide](CERTIFICATE-INSTALLATION-GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING-GUIDE.md)
- [Post-Installation Verification](POST-INSTALLATION-VERIFICATION.md)

# MCBDS Installer - Complete Fixes Applied

## Summary of Changes

You reported two critical issues during installation:

### Issue 1: JSON Parse Error - Invalid Escapable Character
```
'P' is an invalid escapable character within a JSON string. LineNumber: 10
```

**Root Cause:** Windows paths in `appsettings.json` contained unescaped backslashes like `C:\Program Files\...`

**? FIXED:**
- Updated NSIS installer to convert all Windows paths to forward slashes (`C:/Program Files/...`)
- Updated merge script to detect and convert backslashes to forward slashes when reading existing configs
- Added JSON validation before writing to disk to catch this error early
- Enhanced error messages showing exactly what JSON was malformed

### Issue 2: Certificate Not Installed to Trusted Root
The installer ran but the code signing certificate was never installed to the target machine's trusted store.

**? FIXED:**
- Changed to use `certutil.exe` (built-in Windows utility) as primary method
- Added PowerShell fallback if certutil fails
- Added comprehensive logging of certificate installation steps
- Enhanced error reporting with specific return codes

### Issue 3: No Logging During Installation
No way to debug what went wrong - errors were silent.

**? FIXED:**
- Created `install.log` file that persists after installation
- Logs every major step with timestamps
- Shows certificate installation status with return codes
- Shows JSON merge/creation status
- Final message directs user to log file location: `C:\Program Files\MCBDS Manager\install.log`

---

## Files Modified

### 1. **MCBDSInstaller.nsi** (NSIS Script)
```
Changes:
- Added install.log creation and logging macro
- Fixed appsettings.json JSON creation (paths use forward slashes)
- Improved certificate installation (certutil.exe with fallback)
- Added detailed error messages
- Log file location shown at end of installation
```

### 2. **merge-appsettings.ps1** (Configuration Script)
```
Changes:
- Added proper path conversion (backslash ? forward slash)
- Added JSON validation before/after writing
- Enhanced error reporting with stack traces
- Shows problematic JSON if validation fails
```

### 3. **build-installer.ps1** (Build Script)
```
Changes:
- Added certificate and MSIX path logging
- Updated final instructions with admin requirement
- Clear reference to documentation
```

---

## New Documentation Created

### 1. **CERTIFICATE-INSTALLATION-GUIDE.md**
- How certificate installation works
- Why Admin privileges are required
- Methods used (certutil.exe vs PowerShell)
- Self-signed certificate details
- Troubleshooting certificate issues

### 2. **TROUBLESHOOTING-GUIDE.md**
- Complete troubleshooting procedures
- JSON parse error solutions
- Certificate installation solutions
- Service startup issues
- Port conflicts
- How to read the install.log

### 3. **POST-INSTALLATION-VERIFICATION.md**
- Step-by-step verification checklist
- PowerShell commands to verify each component
- Diagnostic script to run if something fails
- How to check install.log
- What each log entry means

### 4. **FIXES-SUMMARY.md**
- Detailed explanation of each fix
- Before/after comparisons
- Technical details of changes
- File changes reference

---

## What to Do Next

### To Rebuild the Installer:
```powershell
# Run as Administrator
.\MCBDS.Installer\build-installer.ps1 -IncrementVersion
```

### To Install on Target Machine:
1. **Right-click** the installer EXE
2. **Select "Run as administrator"** (CRITICAL!)
3. **Complete the wizard**

### To Verify Installation Worked:
```powershell
# 1. Check install.log
Get-Content "C:\Program Files\MCBDS Manager\install.log"

# 2. Check service
Get-Service MCBDSAPIService

# 3. Check JSON
$config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json

# 4. Check certificate
Get-ChildItem "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}

# 5. Check API
Invoke-WebRequest -Uri "http://localhost:8080/health"
```

---

## Key Points to Remember

?? **CRITICAL:**
- Installer **MUST** be run as Administrator
- This is required for:
  - Certificate installation to Trusted Root
  - Service installation
  - Firewall rule creation
  - Program Files access

? **Paths in Configuration:**
- All paths in `appsettings.json` must use forward slashes `/`
- NOT backslashes `\`
- Examples:
  - ? `C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe`
  - ? `C:\Program Files\MCBDS Manager\Binaries\bedrock_server.exe`

?? **Always Check:**
- `C:\Program Files\MCBDS Manager\install.log` after installation
- This file contains all diagnostic information
- Search for "ERROR" to find any issues

---

## Log File Example Output

```
MCBDS Manager Installation Log
Version: 1.2.3
Timestamp: [install start]
Installation Directory: C:\Program Files\MCBDS Manager
=================================

Checking for existing MCBDS API Service...
Extracting API Service files...
Installing MCBDS Manager Desktop App (PublicUI)...
Installing code signing certificate...
Certificate file path defined: D:\...\CodeSigning.cer
Certificate file successfully copied to temp: C:\Users\...\Temp\CodeSigning.cer
Running: certutil.exe -addstore -f Root ...
? Code signing certificate installed successfully to Trusted Root via certutil
Installing MSIX package...
MSIX package successfully copied to temp
Installing MSIX package using Add-AppxPackage...
? MSIX package installed successfully
Cleaning up temporary files...
Merging configuration settings...
? appsettings.json created successfully with proper path formatting
Service Port: 8080
Bedrock Path: C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe
Log Path: C:/Program Files/MCBDS Manager/logs/runner.log
Backup Path: C:/Program Files/MCBDS Manager/backups
Starting MCBDS API Service...
=========================================
Installation completed successfully!
=========================================
Installation log file saved to:
C:\Program Files\MCBDS Manager\install.log
=========================================
```

---

## Reference Documents

For more detailed information, see:

1. **[CERTIFICATE-INSTALLATION-GUIDE.md](CERTIFICATE-INSTALLATION-GUIDE.md)**
   - Certificate installation details
   - Why admin is needed
   - Self-signed cert info

2. **[TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)**
   - Solutions for common problems
   - How to fix JSON errors
   - Certificate installation issues
   - Service startup problems

3. **[POST-INSTALLATION-VERIFICATION.md](POST-INSTALLATION-VERIFICATION.md)**
   - Verification checklist
   - PowerShell commands
   - Diagnostic script
   - What to do if something fails

4. **[FIXES-SUMMARY.md](FIXES-SUMMARY.md)**
   - Technical details of all fixes
   - Before/after comparisons
   - Complete file change list

5. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)**
   - Quick lookup guide
   - Common commands
   - Troubleshooting flowchart

---

## Testing the Fixes

The installer now handles:
- ? JSON path escaping (Windows paths ? JSON-compatible paths)
- ? Certificate installation (certutil + PowerShell fallback)
- ? Configuration validation (JSON validated before/after writing)
- ? Complete logging (every step logged to persistent file)
- ? Error reporting (clear messages for failures)

**Test by:**
1. Building new installer: `build-installer.ps1 -IncrementVersion`
2. Installing with admin privileges
3. Checking install.log for success
4. Verifying service runs
5. Checking appsettings.json has forward slashes in paths
6. Verifying certificate in Trusted Root (if install.log shows success)

---

## Questions?

Check the appropriate guide:
- **"How do I build?"** ? build-installer.ps1 or FIXES-SUMMARY.md
- **"Why did installation fail?"** ? install.log + TROUBLESHOOTING-GUIDE.md
- **"Is everything working?"** ? POST-INSTALLATION-VERIFICATION.md
- **"What changed?"** ? FIXES-SUMMARY.md
- **"Quick commands?"** ? QUICK-REFERENCE.md
- **"Certificate issues?"** ? CERTIFICATE-INSTALLATION-GUIDE.md

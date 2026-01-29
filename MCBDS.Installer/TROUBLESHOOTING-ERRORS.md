# ?? Troubleshooting Guide - Common Errors

## Common Installation/Build Errors

---

## Error: "Cannot find path"

### If you see:
```
Cannot find path 'MCBDS.WindowsService\bin\Release\net10.0-windows\win-x64\publish'
```

### Solution:
```powershell
# 1. Make sure you built the Windows Service project first
Build ? Build Solution (or right-click MCBDS.WindowsService ? Build)

# 2. Then build the installer
.\MCBDS.Installer\build-installer.ps1
```

---

## Error: "Access Denied"

### If you see:
```
Access to the path is denied
```

### Solution:
```powershell
# 1. Close Visual Studio completely
# 2. Run PowerShell as Administrator
# 3. Try again:
.\MCBDS.Installer\build-installer.ps1
```

---

## Error: NSIS Not Found

### If you see:
```
'makensis.exe' is not recognized as an internal or external command
```

### Solution:
```powershell
# NSIS needs to be installed
# Download from: https://nsis.sourceforge.io/

# Or check if it's installed:
where makensis.exe

# If not found, add to PATH:
# 1. Install NSIS from the link above
# 2. Add C:\Program Files (x86)\NSIS to your PATH
```

---

## Error: "Port Already in Use"

### If installer shows:
```
Service won't start on configured port
```

### Solution:
```powershell
# 1. Check what's using the port
netstat -ano | findstr :8080

# 2. Edit the configuration
notepad "C:\Program Files\MCBDS API Service\appsettings.user.json"

# 3. Change the port
# "Urls": "http://0.0.0.0:9000"

# 4. Restart the service
net stop MCBDSAPIService
net start MCBDSAPIService
```

---

## Error: "JSON Syntax Error"

### If service won't start:
```
JSON parse error in appsettings.user.json
```

### Solution:
```powershell
# 1. Check JSON syntax
Test-Json "C:\Program Files\MCBDS API Service\appsettings.user.json"

# 2. View the file
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json"

# 3. Make sure it has valid JSON structure
# Check for:
# - Missing commas
# - Mismatched braces
# - Special characters escaped properly
```

---

## Error: "WiX Project Won't Load"

### If you see:
```
MCBDS.Installer (unavailable)
```

### Solution:
This should be fixed by:
```powershell
# 1. Remove old WiX project from solution
#    (Right-click ? Remove)

# 2. Delete old files
Remove-Item "MCBDS.Installer\MCBDS.Installer.wixproj" -Force
Remove-Item "MCBDS.Installer\Product.wxs" -Force

# 3. Add new NSIS project
#    (Right-click Solution ? Add ? Existing Project)
#    (Select: MCBDS.Installer\MCBDS.Installer.csproj)

# 4. Reopen solution
```

---

## Error: "Service Installation Failed"

### If you see:
```
Failed to install service. Exit code: [number]
```

### Solution:
```powershell
# 1. Run as Administrator
# (PowerShell as Admin, not regular)

# 2. Check if service already exists
Get-Service MCBDSAPIService 2>$null

# 3. If it exists, uninstall first
net stop MCBDSAPIService 2>$null
"C:\Program Files\MCBDS API Service\MCBDS.WindowsService.exe" uninstall

# 4. Then install again
.\MCBDS.Installer\build-installer.ps1
```

---

## Error: "Firewall Rule Failed"

### If you see:
```
Error running netsh command
```

### Solution:
```powershell
# This requires Administrator privileges
# Make sure PowerShell is running as Admin

# Or manually add the firewall rule:
netsh advfirewall firewall add rule `
  name="MCBDS API Service (HTTP)" `
  dir=in `
  action=allow `
  protocol=tcp `
  localport=8080
```

---

## Error: "Build Script Fails"

### If you see:
```
build-installer.ps1 : File cannot be loaded
```

### Solution:
```powershell
# 1. Check execution policy
Get-ExecutionPolicy

# 2. If Restricted, allow scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Try again
.\MCBDS.Installer\build-installer.ps1
```

---

## Error: "Files Not Found During Build"

### If you see:
```
Cannot find MCBDS.WindowsService binaries
```

### Solution:
```powershell
# 1. Build the Windows Service project first
#    Visual Studio: Right-click MCBDS.WindowsService ? Build

# 2. Verify files exist
Test-Path "MCBDS.WindowsService\bin\Release\net10.0-windows\win-x64\publish"

# 3. Then build installer
.\MCBDS.Installer\build-installer.ps1
```

---

## Error: "Solution Won't Load"

### If you see:
```
One or more projects in the solution could not be loaded
```

### Solution:
```
This is usually the WiX project issue.

Follow: FIX-SOLUTION-LOAD.md
or: MANUAL-FIX-STEPS.md
```

---

## Quick Diagnostic Commands

### Check Everything
```powershell
# 1. Check if service exists
Get-Service MCBDSAPIService 2>$null | Format-Table

# 2. Check if running
Get-Service MCBDSAPIService | Select-Object Status

# 3. Check configuration file
Test-Path "C:\Program Files\MCBDS API Service\appsettings.user.json"

# 4. View configuration
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json

# 5. Check if port is listening
netstat -ano | findstr MCBDSAPIService | findstr LISTENING

# 6. Check firewall rule
netsh advfirewall firewall show rule name="MCBDS API Service*"

# 7. Test API
curl http://localhost:8080/health
```

---

## Detailed Error Info - How to Get Logs

### Service Logs
```powershell
# View event logs for the service
Get-EventLog -LogName Application -Source "MCBDS*" -Newest 20

# Or use Event Viewer:
# eventvwr.exe ? Windows Logs ? Application
```

### PowerShell Execution Log
```powershell
# View recent errors
Get-Error

# Run script with verbose output
.\MCBDS.Installer\build-installer.ps1 -Verbose
```

### Build Output
```powershell
# Save build output
.\MCBDS.Installer\build-installer.ps1 | Tee-Object -FilePath "build.log"
```

---

## Still Stuck?

### Provide This Information:
```
1. What error message did you see?
2. When did it occur? (During build, install, runtime?)
3. What command were you running?
4. What OS version? (Win 10, Win 11, Server 2019, etc.)
5. Are you running as Administrator?
6. Is .NET 10 SDK installed?
```

### Check Prerequisites
```powershell
# .NET SDK installed?
dotnet --version

# NSIS installed?
where makensis.exe

# PowerShell version?
$PSVersionTable.PSVersion

# Windows version?
[System.Environment]::OSVersion
```

---

## File Locations Reference

```
Installer Output: MCBDS.API.Service.Installer.exe
Installation Directory: C:\Program Files\MCBDS API Service
Configuration File: C:\Program Files\MCBDS API Service\appsettings.user.json
Logs: C:\Program Files\MCBDS API Service\logs
Build Scripts: D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer
```

---

## Support Resources

- **FIX-SOLUTION-LOAD.md** - If solution won't load
- **MANUAL-FIX-STEPS.md** - Manual fix steps
- **QUICK-REFERENCE.md** - Common commands
- **INSTALLER-CONFIGURATION-GUIDE.md** - Configuration help

---

**Ready to help! Let me know the specific error and I'll provide the exact fix!**

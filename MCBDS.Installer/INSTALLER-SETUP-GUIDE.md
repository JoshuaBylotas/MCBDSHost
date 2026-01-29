# NSIS Installer Setup Guide for MCBDS API Service

## Overview

This guide walks you through setting up and using the NSIS (Nullsoft Scriptable Install System) installer for the MCBDS API Windows Service. NSIS is a completely free, open-source installer that will replace the WiX Toolset.

## Table of Contents

1. [Installation Steps](#installation-steps)
2. [Building the Installer](#building-the-installer)
3. [Distributing the Installer](#distributing-the-installer)
4. [Advanced Configuration](#advanced-configuration)
5. [Troubleshooting](#troubleshooting)

---

## Installation Steps

### Step 1: Install NSIS

1. Download NSIS from: https://nsis.sourceforge.io/
2. Run the installer
3. Choose the default installation location: `C:\Program Files (x86)\NSIS\`
4. Complete the installation
5. **Restart your computer** (recommended)

### Step 2: Verify .NET 10 SDK

The .NET 10 SDK is required to publish the Windows Service executable.

```powershell
# Check if .NET 10 is installed
dotnet --version

# List all SDKs
dotnet --list-sdks
```

If .NET 10 is not installed, download from: https://dotnet.microsoft.com/download

### Step 3: Clone/Update Your Repository

```bash
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost
```

---

## Building the Installer

### Quick Build (Recommended)

1. **Open PowerShell as Administrator**
2. **Navigate to the solution directory**:
   ```powershell
   cd C:\path\to\MCBDSHost
   ```
3. **Run the build script**:
   ```powershell
   .\MCBDS.Installer\build-installer.ps1
   ```

The script will automatically:
- ? Publish the Windows Service
- ? Build the NSIS installer
- ? Create `MCBDS.API.Service.Installer.exe` in the project root

### Custom Build (If Default Path Different)

If NSIS is installed in a non-default location:

```powershell
.\MCBDS.Installer\build-installer.ps1 -NsisPath "C:\Custom\Path\makensis.exe"
```

### Manual Build (Advanced)

```powershell
# Step 1: Publish the Windows Service
dotnet publish MCBDS.WindowsService\MCBDS.WindowsService.csproj `
  -c Release `
  -r win-x64 `
  --self-contained

# Step 2: Build the NSIS installer
& "C:\Program Files (x86)\NSIS\makensis.exe" "MCBDS.Installer\MCBDSInstaller.nsi"
```

### Build Output

After successful build:
- **Installer**: `MCBDS.API.Service.Installer.exe`
- **Size**: ~80-120 MB (includes .NET 10 runtime)
- **Location**: Project root directory

---

## Distributing the Installer

### Package Contents

Your distribution should include:
```
MCBDS.API.Service.Installer.exe          (Main installer)
NSIS-README.md                             (User guide)
```

### Distribution Methods

#### Option 1: Direct Download
- Host on your website or GitHub Releases
- Users download and run the .exe file

#### Option 2: Embedded Installation
- Package into your application
- Automatically launch installer

#### Option 3: Network Share
- Place on a network share for internal deployment
- Users run from `\\server\share\MCBDS.API.Service.Installer.exe`

### Installer Size Optimization

The installer includes:
- Windows Service executable
- .NET 10 runtime (self-contained)
- Configuration files
- Directory structure

To reduce size, you can:
1. Exclude unnecessary dependencies from the publish step
2. Use `--no-self-contained` (requires .NET installed on target)
3. Split into separate packages

---

## Advanced Configuration

### Customizing the Installer

#### Change Installation Directory

Edit `MCBDS.Installer\MCBDSInstaller.nsi`:

```nsi
; Current (line ~28):
InstallDir "$PROGRAMFILES64\MCBDS API Service"

; Change to:
InstallDir "C:\MCBDS\API"
```

#### Add Custom Installation Steps

Add after the directory creation section:

```nsi
; Copy custom configuration file
File ".\custom-config.json"

; Run custom setup script
ExecWait "$INSTDIR\setup.bat"
```

#### Change Service Auto-Start Behavior

Edit `MCBDS.Installer\MCBDSInstaller.nsi`:

```nsi
; To NOT auto-start on install:
; Comment out this line:
ExecWait 'net start MCBDSAPIService'

; Or to delay start:
DetailPrint "Waiting 5 seconds before starting service..."
Sleep 5000
ExecWait 'net start MCBDSAPIService'
```

#### Add More Firewall Rules

Edit `MCBDS.Installer\MCBDSInstaller.nsi`:

```nsi
; Add rule for HTTPS (if needed):
DetailPrint "Configuring Windows Firewall for HTTPS..."
ExecWait 'netsh advfirewall firewall add rule name=$\"MCBDS API Service (HTTPS)$\" dir=in action=allow protocol=tcp localport=8443 program=$\"$INSTDIR\MCBDS.WindowsService.exe$\" enable=yes'
```

### Updating the Installer Version

1. **In `MCBDS.Installer\MCBDSInstaller.nsi`**:
   ```nsi
   VIProductVersion "1.0.2.0"
   VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "1.0.2.0"
   VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "1.0.2.0"
   ```

2. **In `MCBDS.WindowsService\MCBDS.WindowsService.csproj`**:
   ```xml
   <PropertyGroup>
       <Version>1.0.2</Version>
   </PropertyGroup>
   ```

3. **Rebuild the installer**:
   ```powershell
   .\MCBDS.Installer\build-installer.ps1
   ```

### Creating Silent Installation

Users can install without UI prompts:

```powershell
# Unattended installation
MCBDS.API.Service.Installer.exe /S /D=C:\MCBDS

# /S = Silent mode
# /D = Installation directory
```

For silent mode, edit `MCBDSInstaller.nsi`:

```nsi
; Change the UI section to:
; !insertmacro MUI_PAGE_WELCOME
; !insertmacro MUI_PAGE_DIRECTORY
; !insertmacro MUI_PAGE_INSTFILES
; !insertmacro MUI_PAGE_FINISH
; Replace with just INSTFILES for silent:
!insertmacro MUI_PAGE_INSTFILES
```

---

## Troubleshooting

### Build Issues

#### NSIS Not Found

**Error**: "NSIS not found at C:\Program Files (x86)\NSIS\makensis.exe"

**Solutions**:
1. Install NSIS from https://nsis.sourceforge.io/
2. Or specify custom path:
   ```powershell
   .\MCBDS.Installer\build-installer.ps1 -NsisPath "your\custom\path\makensis.exe"
   ```

#### .NET Publish Failed

**Error**: "Failed to publish Windows Service"

**Solutions**:
1. Check .NET SDK is installed:
   ```powershell
   dotnet --version
   ```
2. Ensure Windows development tools are installed
3. Try manual publish first:
   ```powershell
   dotnet publish MCBDS.WindowsService\MCBDS.WindowsService.csproj -c Release -r win-x64 --self-contained
   ```

#### NSIS Script Compilation Failed

**Error**: "NSIS build failed"

**Solutions**:
1. Verify the NSI script syntax:
   - Check for matching quotes
   - Ensure all File paths are correct
2. Manually test compilation:
   ```powershell
   & "C:\Program Files (x86)\NSIS\makensis.exe" "MCBDS.Installer\MCBDSInstaller.nsi" /V4
   ```
3. Review NSIS output for line number of error

### Installation Issues

#### Administrator Rights Required

**Error**: "Installation failed - administrator rights required"

**Solution**:
- Right-click installer ? "Run as administrator"
- Or use command line with admin privileges:
  ```powershell
  # Run PowerShell as admin, then:
  .\MCBDS.API.Service.Installer.exe
  ```

#### Port 8080 Already in Use

**Error**: Service starts but won't respond on port 8080

**Solution**:
1. Find what's using the port:
   ```powershell
   netstat -ano | findstr :8080
   ```
2. Change port in `appsettings.json`:
   ```json
   "Urls": "http://0.0.0.0:8081"
   ```
3. Restart service:
   ```powershell
   net stop MCBDSAPIService
   net start MCBDSAPIService
   ```

#### Firewall Rule Not Applied

**Error**: Cannot access service from network

**Solution**:
1. Manually add firewall rule:
   ```powershell
   netsh advfirewall firewall add rule `
     name="MCBDS API Service" `
     dir=in action=allow protocol=tcp localport=8080
   ```
2. Verify rule exists:
   ```powershell
   netsh advfirewall firewall show rule all | findstr MCBDS
   ```

#### Service Won't Start After Installation

**Solution**:
1. Check service status:
   ```powershell
   Get-Service MCBDSAPIService
   ```
2. Check Windows Event Viewer for errors:
   - Event Viewer ? Windows Logs ? Application
3. Restart the service:
   ```powershell
   net stop MCBDSAPIService
   net start MCBDSAPIService
   ```
4. Check logs in installation directory

---

## Next Steps

1. **Build the installer** using the quick build method
2. **Test the installation** on a test machine
3. **Distribute** to users with the README
4. **Collect feedback** and iterate

---

## File Reference

| File | Purpose |
|------|---------|
| `MCBDSInstaller.nsi` | Main NSIS installer script |
| `build-installer.ps1` | Automated build script |
| `NSIS-README.md` | User-facing documentation |
| `Program.cs` | Windows Service with install/uninstall support |
| `MCBDS.WindowsService.csproj` | Service project configuration |

---

## Support

For detailed NSIS documentation, visit: https://nsis.sourceforge.io/Docs/

For installer troubleshooting, check:
- Installation directory logs
- Windows Event Viewer
- NSIS installation with `/V4` flag for verbose output

# Fresh Windows Install Package - Quick Guide

## Version: 1.0.25.0 (Crash Fix Build)

This guide explains how to build and install the MCBDS Manager on a fresh Windows installation.

---

## What Was Changed

**Version Update:**
- Previous: 1.0.24.1
- Current: 1.0.25.0
- Changes: Added crash logging, improved error handling, new Diagnostics page

**Files Updated:**
1. `MCBDS.PublicUI.csproj` - ApplicationDisplayVersion: 1.0.1, ApplicationVersion: 2
2. `Package.appxmanifest` - Version: 1.0.25.0

---

## Quick Start: One Command Build

```powershell
# Navigate to project directory
cd "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.PublicUI"

# Build MSIX package for Windows
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true `
  -p:AppxPackageSigningEnabled=true

# Package will be created in:
# AppPackages\MCBDS.PublicUI_1.0.25.0_Test\
```

---

## Full Build Process

### Step 1: Clean Previous Builds

```powershell
# Clean solution
dotnet clean -c Release

# Remove old AppPackages folder
Remove-Item -Path "AppPackages" -Recurse -Force -ErrorAction SilentlyContinue
```

### Step 2: Restore Dependencies

```powershell
# Restore NuGet packages
dotnet restore
```

### Step 3: Build MSIX Package

```powershell
# Build for Windows with MSIX packaging
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true `
  -p:AppxPackageSigningEnabled=true `
  -p:AppxBundlePlatforms="x64" `
  -p:UapAppxPackageBuildMode=SideloadOnly
```

### Step 4: Locate the Package

```powershell
# Find the MSIX file
Get-ChildItem -Path "AppPackages" -Recurse -Filter "*.msix" | 
  Where-Object {$_.Name -notlike "*bundle*"} | 
  Select-Object FullName, Length

# Typical location:
# AppPackages\MCBDS.PublicUI_1.0.25.0_Test\MCBDS.PublicUI_1.0.25.0_x64.msix
```

---

## Installation on Fresh Windows

### Prerequisites

Fresh Windows 10/11 installation needs:
- [x] Windows 10 version 1809 (Build 17763) or later
- [x] Windows 11 (any version)
- [x] Internet connection (for certificate validation)

### Method 1: Double-Click Install (Easiest)

1. **Copy MSIX file** to the fresh Windows machine:
   ```
   MCBDS.PublicUI_1.0.25.0_x64.msix
   ```

2. **Double-click** the `.msix` file

3. Click **"Install"** button

4. App installs to:
   ```
   C:\Program Files\WindowsApps\50677PinecrestConsultants.MCBDSManager_1.0.25.0_x64__*
   ```

5. Find app in **Start Menu** > "MCBDS Manager"

### Method 2: PowerShell Install

```powershell
# On the fresh Windows machine
# Run PowerShell as Administrator

# Install the package
Add-AppxPackage -Path "C:\path\to\MCBDS.PublicUI_1.0.25.0_x64.msix"

# Verify installation
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}

# Launch the app
Start-Process "shell:AppsFolder\$(
  (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
)!App"
```

### Method 3: App Installer (Recommended for Multiple Machines)

1. Place MSIX on a network share:
   ```
   \\server\share\MCBDS.PublicUI_1.0.25.0_x64.msix
   ```

2. On each machine, run:
   ```powershell
   Add-AppxPackage -Path "\\server\share\MCBDS.PublicUI_1.0.25.0_x64.msix"
   ```

---

## Certificate Signing (For Enterprise Deployment)

If deploying to multiple machines, you may need to trust the certificate:

### Step 1: Export Certificate from MSIX

```powershell
# Extract certificate from MSIX
$cert = Get-AuthenticodeSignature "MCBDS.PublicUI_1.0.25.0_x64.msix"
$cert.SignerCertificate | Export-Certificate -FilePath "MCBDSManager.cer"
```

### Step 2: Install Certificate on Target Machine

```powershell
# Run as Administrator on fresh Windows machine
Import-Certificate -FilePath "MCBDSManager.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

---

## Troubleshooting

### Issue 1: "The app didn't start"

**Solution:**
1. Open **Event Viewer**
2. Navigate to **Windows Logs** > **Application**
3. Look for errors from "MCBDS.PublicUI"
4. Check crash log:
   ```powershell
   $pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
   $logPath = "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState\crash-log.txt"
   Get-Content $logPath
   ```

### Issue 2: Certificate Not Trusted

**Error:** "Install failed. Please contact your software vendor."

**Solution:**
```powershell
# Trust the certificate (as Administrator)
$cert = Get-AuthenticodeSignature "MCBDS.PublicUI_1.0.25.0_x64.msix"
$cert.SignerCertificate | Export-Certificate -FilePath "cert.cer"
Import-Certificate -FilePath "cert.cer" -CertStoreLocation Cert:\LocalMachine\Root
```

### Issue 3: "This app can't run on your PC"

**Causes:**
- Wrong architecture (x86 app on ARM device)
- Windows version too old

**Solution:**
```powershell
# Check Windows version
Get-ComputerInfo | Select-Object WindowsVersion, OsBuildNumber

# Minimum required: Build 17763 (Windows 10 1809)
```

### Issue 4: App Crashes on Launch

**Solution:**
1. Navigate to **Diagnostics** page in app (if it loads)
2. Or check crash log manually:
   ```powershell
   $pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
   notepad "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState\crash-log.txt"
   ```

---

## Testing the Installation

### Quick Test Checklist

After installation, verify:

```powershell
# 1. Check installation
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | 
  Select-Object Name, Version, InstallLocation

# 2. Launch app
Start-Process "shell:AppsFolder\$(
  (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
)!App"

# 3. Test pages (navigate in app):
# - Overview ?
# - Commands ?
# - Server ?
# - Backup ?
# - Diagnostics ? (NEW)

# 4. Check crash log
$pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
Get-Content "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState\crash-log.txt" -Tail 20
```

### Expected Results

? App launches without crashing  
? All pages load correctly  
? Crash log shows successful initialization  
? No errors in Event Viewer  
? Diagnostics page displays system info  

---

## Uninstall Instructions

### Method 1: Settings UI

1. **Settings** > **Apps** > **Installed apps**
2. Search for "MCBDS Manager"
3. Click **"..."** > **Uninstall**

### Method 2: PowerShell

```powershell
# Uninstall
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage

# Verify removal
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
# Should return nothing
```

---

## Distribution Options

### Option 1: USB Drive

1. Copy MSIX to USB drive
2. Include this guide (print or PDF)
3. Users double-click MSIX on their machines

### Option 2: Network Share

```powershell
# Set up share
New-SmbShare -Name "MCBDSInstaller" -Path "C:\Installers\MCBDS" -FullAccess "Everyone"

# Copy MSIX to share
Copy-Item "MCBDS.PublicUI_1.0.25.0_x64.msix" "C:\Installers\MCBDS\"

# Users install from network
Add-AppxPackage -Path "\\server\MCBDSInstaller\MCBDS.PublicUI_1.0.25.0_x64.msix"
```

### Option 3: Email Distribution

**Warning:** Email may block .msix files

**Workaround:**
1. Compress to ZIP:
   ```powershell
   Compress-Archive -Path "MCBDS.PublicUI_1.0.25.0_x64.msix" -DestinationPath "MCBDS_Installer.zip"
   ```
2. Email the ZIP file
3. Recipients extract and double-click MSIX

### Option 4: Microsoft Store (Recommended for Wide Distribution)

Submit to Store for automatic updates and easier installation:
- Users search "MCBDS Manager" in Microsoft Store
- Click Install
- Automatic updates

---

## Updating from Previous Version

If users have version 1.0.24.1 installed:

### Automatic Update (If Configured)

MSIX apps can auto-update if configured. The new version will replace the old one.

### Manual Update

```powershell
# Users simply install new version
Add-AppxPackage -Path "MCBDS.PublicUI_1.0.25.0_x64.msix"

# Old version is automatically replaced
# Settings and data are preserved
```

---

## What's New in 1.0.25.0

### Features Added
? **Crash Logger** - Diagnostic logging for troubleshooting  
? **Diagnostics Page** - View crash logs and system info  
? **Enhanced Error Handling** - Better handling of file system errors  
? **Improved Startup** - Graceful fallback if config files missing  

### Bug Fixes
?? Fixed crash on fresh Windows installations  
?? Fixed file permission errors in sandboxed environment  
?? Improved HttpClient configuration  

### Page Changes
?? New "Diagnostics" page in navigation menu

---

## Command Reference

### Build Commands

```powershell
# Full clean and build
dotnet clean -c Release
dotnet restore
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true

# Quick rebuild (no clean)
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX

# Check current version
Get-Content "MCBDS.PublicUI.csproj" | Select-String "ApplicationDisplayVersion"
Get-Content "Platforms\Windows\Package.appxmanifest" | Select-String "Version="
```

### Installation Commands

```powershell
# Install
Add-AppxPackage -Path "path\to\MCBDS.PublicUI_1.0.25.0_x64.msix"

# Check installed version
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | 
  Format-List Name, Version, PackageFullName, InstallLocation

# Launch
Start-Process "shell:AppsFolder\50677PinecrestConsultants.MCBDSManager_*!App"

# Uninstall
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage
```

### Diagnostic Commands

```powershell
# View crash log
$pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
Get-Content "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState\crash-log.txt"

# Check Event Viewer for crashes
Get-WinEvent -LogName Application -MaxEvents 50 | 
  Where-Object {$_.ProviderName -like "*MCBDS*" -or $_.Message -like "*MCBDS*"}

# View app data location
$pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
explorer "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState"
```

---

## Support Information

### Getting Help

1. **Crash Logs**: Check Diagnostics page in app or:
   ```
   %LOCALAPPDATA%\Packages\50677PinecrestConsultants.MCBDSManager_*\LocalState\crash-log.txt
   ```

2. **Event Viewer**: Windows Logs > Application

3. **GitHub Issues**: https://github.com/JoshuaBylotas/MCBDSHost/issues

4. **Email**: support@mc-bds.com

### Reporting Issues

Include:
- Windows version and build number
- MSIX package version
- Contents of crash-log.txt
- Steps to reproduce

---

## Next Steps

After successful installation:

1. ? **Test all pages** - Navigate through Overview, Commands, Server, Backup, Diagnostics
2. ? **Configure server connection** - Set API URL in Server Switcher
3. ? **Test Docker integration** - If Docker Desktop installed
4. ? **Check Diagnostics page** - Verify crash log shows successful startup
5. ? **Report any issues** - Submit to GitHub or email support

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.25.0 | 2025-01-08 | Crash fix: Added logging, error handling, Diagnostics page |
| 1.0.24.1 | Previous | Base version with Quick Commands feature |

---

## Files to Distribute

**Minimum:**
- `MCBDS.PublicUI_1.0.25.0_x64.msix` (the installer)

**Recommended:**
- This guide (FRESH_INSTALL_GUIDE.md)
- Certificate file (if deploying to multiple machines)

**Optional:**
- User manual
- Configuration examples
- Docker setup guide

---

## Technical Details

**Package Information:**
- Package Name: `50677PinecrestConsultants.MCBDSManager`
- Publisher: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
- Architecture: x64
- Minimum OS: Windows 10 Build 17763
- Framework: .NET 10.0

**Capabilities:**
- `runFullTrust` - Full system access
- `internetClient` - Internet connectivity
- `internetClientServer` - Server functionality
- `privateNetworkClientServer` - Local network access

---

## License

Refer to project license for terms of distribution and use.

---

**Last Updated:** January 8, 2025  
**Version:** 1.0.25.0  
**Build Type:** Release (signed)

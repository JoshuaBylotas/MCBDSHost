# ? Fix Installer Project - Complete Instructions

## Problem

The old **WiX Toolset project** (MCBDS.Installer.wixproj) is preventing the solution from loading because WiX isn't installed.

---

## Solution

**Remove the old WiX project** and use the new **NSIS-based installer** instead.

---

## Step-by-Step Fix

### Step 1: Remove WiX Project from Solution (Visual Studio)

1. **Open Visual Studio**
2. **Open MCBDSHost.slnx**
3. **In Solution Explorer**, right-click on **MCBDS.Installer** project
4. **Select "Remove"** (removes from solution, doesn't delete files)
5. **Save the solution** (Ctrl+S)

---

### Step 2: Backup Old WiX Files (Optional)

If you want to keep the old WiX files for reference:

```powershell
# Create backup folder
New-Item -ItemType Directory -Path "D:\source\repos\JoshuaBylotas\MCBDSHost\.archived\WiX-Original" -Force

# Copy old WiX files
Copy-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDS.Installer.wixproj" -Destination "D:\source\repos\JoshuaBylotas\MCBDSHost\.archived\WiX-Original\"
Copy-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\Product.wxs" -Destination "D:\source\repos\JoshuaBylotas\MCBDSHost\.archived\WiX-Original\"

Write-Host "Old WiX files backed up"
```

---

### Step 3: Delete Old WiX Files

```powershell
# Delete old WiX files from MCBDS.Installer folder
Remove-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDS.Installer.wixproj" -Force
Remove-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\Product.wxs" -Force

Write-Host "Old WiX files deleted"
```

---

### Step 4: Verify NSIS Files Are in Place

```powershell
# Check that new NSIS files exist
$files = @(
    "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDSInstaller.nsi",
    "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\build-installer.ps1",
    "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\00-START-HERE.md"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "? $([System.IO.Path]::GetFileName($file))"
    } else {
        Write-Host "? $([System.IO.Path]::GetFileName($file)) - MISSING!"
    }
}
```

---

### Step 5: Reload Solution

1. **Close MCBDSHost.slnx** in Visual Studio
2. **Reopen MCBDSHost.slnx**
3. **Solution should load without errors** ?

---

## Verify Solution Loads

```powershell
# In Visual Studio:
# 1. All projects should load in Solution Explorer
# 2. No error messages
# 3. Solution Explorer shows all projects without [Unload] status
```

---

## What You Now Have

### NSIS-Based Installer (No Project File Needed)
```
MCBDS.Installer\
??? MCBDSInstaller.nsi ................... Installer script
??? build-installer.ps1 ................. Build automation
??? 00-START-HERE.md ..................... Quick start
??? CONFIGURATION-QUICK-START.md ........ Configuration guide
??? ... (other documentation)
```

### To Build Installer

```powershell
# Just run the PowerShell script
.\MCBDS.Installer\build-installer.ps1

# That's it! No need for a Visual Studio project
```

---

## Before vs After

### Before ?
```
Solution tries to load MCBDS.Installer.wixproj
  ?? WiX Toolset not installed
     ?? Project fails to load
        ?? Solution won't load properly
```

### After ?
```
Solution loads all projects successfully
  ?? MCBDS.Installer is just a folder with scripts
     ?? No project file needed
        ?? Installer built via PowerShell script
```

---

## New Installer Workflow

### For Development
```powershell
# Build installer
.\MCBDS.Installer\build-installer.ps1

# Outputs: MCBDS.API.Service.Installer.exe
# No Visual Studio project file needed
```

### For Distribution
```powershell
# Just share the .exe file
# Include: NSIS-README.md (user guide)
```

---

## Complete Steps Summary

### Quick Fix (All Steps Combined)

```powershell
# 1. Remove old WiX project from solution (do this in Visual Studio)
#    - Right-click MCBDS.Installer in Solution Explorer
#    - Select "Remove"
#    - Save solution

# 2. Delete old WiX files
Remove-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDS.Installer.wixproj" -Force
Remove-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\Product.wxs" -Force

# 3. Verify NSIS files exist
Test-Path "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDSInstaller.nsi"
Test-Path "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\build-installer.ps1"

# 4. Close and reopen solution in Visual Studio
# 5. Solution now loads successfully! ?
```

---

## Commit to Git

```powershell
# Navigate to repo
cd "D:\source\repos\JoshuaBylotas\MCBDSHost"

# Remove old files from git tracking
git rm "MCBDS.Installer/MCBDS.Installer.wixproj"
git rm "MCBDS.Installer/Product.wxs"

# Commit the cleanup
git commit -m "Remove WiX project files, use NSIS installer instead"

# Push to remote
git push origin master
```

---

## Result

? **Solution loads without errors**  
? **Installer still works** (via PowerShell script)  
? **Clean repository** (no broken project files)  
? **Professional setup** (standard approach for tool scripts)  

---

## Summary

| Item | Before | After |
|------|--------|-------|
| **Solution Load** | ? Fails (WiX not installed) | ? Success |
| **Installer Project** | ? WiX .wixproj | ? Scripts only |
| **Build Method** | ? Visual Studio (broken) | ? PowerShell script |
| **Dependencies** | ? WiX Toolset required | ? No special tools |
| **Status** | ? Broken | ? Working |

---

## FAQ

**Q: Will the installer still work?**  
A: Yes! Better than before. Just run the PowerShell script instead of building through Visual Studio.

**Q: Do I need to uninstall WiX?**  
A: No, but you don't need it anymore either.

**Q: Can I build the installer from Visual Studio?**  
A: No, but you can from PowerShell: `.\MCBDS.Installer\build-installer.ps1`

**Q: Where do I find the generated installer?**  
A: `MCBDS.API.Service.Installer.exe` in the project root after running the build script.

---

**Status**: Ready to fix ?  
**Time to complete**: 5 minutes  
**Difficulty**: Easy ?  

?? **Your solution will load perfectly after these steps!**

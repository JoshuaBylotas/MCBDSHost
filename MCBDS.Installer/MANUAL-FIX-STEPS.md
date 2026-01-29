# ?? Fix Solution Load - Manual Steps

## The Problem

The **MCBDS.Installer.wixproj** project file is in your solution, but WiX Toolset isn't installed, so the solution won't load.

---

## The Solution

Remove the WiX project from the solution and delete the old WiX files. The NSIS-based installer doesn't need a project file.

---

## Manual Steps (Visual Studio)

### Step 1: Open the Solution
```
1. Open Visual Studio
2. Open: D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDSHost.slnx
3. Wait for solution to attempt loading
```

### Step 2: Unload the Broken Project (If Loaded Partially)
```
1. In Solution Explorer, look for projects
2. If you see "MCBDS.Installer (unavailable)" or similar:
   - Right-click it
   - Select "Unload Project"
```

### Step 3: Remove the WiX Project
```
1. In Solution Explorer, right-click the MCBDS.Installer project
2. Select "Remove"
   (This removes it from solution, doesn't delete files)
3. Click "Save All" (Ctrl+Shift+S) or File ? Save
```

### Step 4: Close Visual Studio
```
1. File ? Exit
   (Or just close the window)
```

### Step 5: Delete the WiX Files

**Open PowerShell** and run:

```powershell
# Navigate to the installer folder
cd "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer"

# Delete old WiX files
Remove-Item "MCBDS.Installer.wixproj" -Force
Remove-Item "Product.wxs" -Force

# Verify they're gone
dir *.wxs, *.wixproj 2>$null | Write-Host "Deleted successfully"
```

### Step 6: Reopen Visual Studio

```
1. Open Visual Studio
2. Open: MCBDSHost.slnx again
3. Solution should load without errors ?
```

---

## PowerShell One-Liner (Complete Fix)

If you want to do everything at once:

```powershell
# Stop Visual Studio first!

# Then run this:
cd "D:\source\repos\JoshuaBylotas\MCBDSHost"; `
Remove-Item "MCBDS.Installer\MCBDS.Installer.wixproj", "MCBDS.Installer\Product.wxs" -Force 2>$null; `
Write-Host "? Old WiX files removed. Solution should now load."; `
Write-Host "?? NSIS installer ready at: MCBDS.Installer\MCBDSInstaller.nsi"
```

---

## Verify It Worked

### In Visual Studio
```
? Solution Explorer shows all projects loading
? No error messages or warnings
? MCBDS.Installer folder exists but no project file
```

### In PowerShell
```powershell
# Check that NSIS files exist
ls "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDSInstaller.nsi"
ls "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\build-installer.ps1"

# Both should exist ?
```

---

## What's in MCBDS.Installer Now

```
MCBDS.Installer\
??? MCBDSInstaller.nsi ...................... Installer script (the important file!)
??? build-installer.ps1 ..................... Build automation script
?
??? Documentation:
??? 00-START-HERE.md ........................ Read this first
??? QUICK-REFERENCE.md ..................... Quick commands
??? CONFIGURATION-QUICK-START.md ........... Configuration guide
??? INSTALLER-CONFIGURATION-GUIDE.md ....... Full configuration docs
?
??? Metadata:
??? README.md .............................. Old WiX docs (can delete)
??? INSTALLER-OVERVIEW.md .................. Project overview
??? FILE-INVENTORY.md ...................... File listing
?
??? ... (other reference documentation)

? DELETED:
   ??? MCBDS.Installer.wixproj ............. (Old WiX project - removed)
   ??? Product.wxs ......................... (Old WiX configuration - removed)
```

---

## Build Your Installer

After fixing the solution load issue:

```powershell
# Build the installer
cd "D:\source\repos\JoshuaBylotas\MCBDSHost"
.\MCBDS.Installer\build-installer.ps1

# Output file created:
# MCBDS.API.Service.Installer.exe
```

---

## Common Issues & Fixes

### Issue: Visual Studio still shows "MCBDS.Installer (unavailable)"

**Fix:**
```
1. Close Visual Studio completely
2. Delete the old project files (if not done already)
3. Reopen Visual Studio
4. Open the solution again
```

### Issue: Files won't delete (permission denied)

**Fix:**
```powershell
# Close Visual Studio first!
# Then try again with admin PowerShell
Remove-Item "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer\MCBDS.Installer.wixproj" -Force
```

### Issue: Where do I check git status?

```powershell
cd "D:\source\repos\JoshuaBylotas\MCBDSHost"
git status

# You should see the deleted files ready to commit
```

---

## Commit the Changes (Optional)

If using git:

```powershell
cd "D:\source\repos\JoshuaBylotas\MCBDSHost"

# Remove from git
git rm "MCBDS.Installer/MCBDS.Installer.wixproj"
git rm "MCBDS.Installer/Product.wxs"

# Commit
git commit -m "Remove WiX project, use NSIS installer instead"

# Push (if you want)
git push origin master
```

---

## Summary

| Step | Action | Time |
|------|--------|------|
| 1 | Remove project from solution | 1 min |
| 2 | Delete WiX files | 1 min |
| 3 | Close and reopen Visual Studio | 2 min |
| **Total** | | **4 minutes** |

---

## Result

? **Solution loads without errors**  
? **All projects visible in Solution Explorer**  
? **Installer still functional** (via PowerShell script)  
? **Ready to build and deploy**  

---

## Next Steps

1. ? Follow the steps above
2. ? Verify solution loads
3. ? Run build script to create installer: `.\MCBDS.Installer\build-installer.ps1`
4. ? Test the installer
5. ? Commit changes to git

---

?? **Your solution will load successfully!**

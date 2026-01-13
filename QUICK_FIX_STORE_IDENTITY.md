# QUICK FIX: Store Package Identity Mismatch

## The Error

```
? Invalid package family name: 50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy 
   (expected: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w)

? Invalid package publisher name: CN=MC-BDS 
   (expected: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289)
```

## The Cause

You signed the package with your **development certificate** (`CN=MC-BDS`), but Microsoft Store expects it to be signed with the **Store certificate** (`CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`).

## The Fix (2 Minutes)

### Step 1: Increment Version
Open: `MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest`

Change:
```xml
Version="1.0.16.1"
```

To:
```xml
Version="1.0.17.0"
```

### Step 2: Create Store Package

1. Open **Visual Studio 2026**
2. Right-click **MCBDS.PublicUI** project
3. Select **Publish** ? **Create App Packages...**
4. Choose **Microsoft Store** (select "MCBDS Manager")
5. Sign in to Partner Center
6. Configure:
   - ? x64
   - ? x86  
   - ? ARM64
   - Generate app bundle: **Always**
7. Click **Create**
8. Wait for build (5-15 mins)

### Step 3: Upload to Partner Center

Find the file in:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.17.0_Test\
  ??? MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload
```

Upload this **`.msixupload`** file to Partner Center.

## Why This Works

? Visual Studio creates an **unsigned** or **test-signed** package  
? Microsoft **re-signs it** during certification with the Store certificate  
? The correct Package Family Name is generated: `..._n8ws8gp0q633w`  
? Package matches Partner Center expectations

## What NOT To Do

? Don't use `CreateMSIXWithWindowsSDK.ps1` for Store submission (that's for local testing)  
? Don't manually sign packages with `SignTool.exe` for Store  
? Don't upload individual `.msix` files (use `.msixupload` instead)  
? Don't resubmit the same version number (must increment)

## Two Package Types

| Development Package | Store Package |
|-------------------|--------------|
| For local testing | For Microsoft Store |
| Signed by **you** (`CN=MC-BDS`) | Signed by **Microsoft** |
| Creates `..._47q1101p6hvwy` | Creates `..._n8ws8gp0q633w` |
| Use `CreateMSIXWithWindowsSDK.ps1` | Use Visual Studio ? Create App Packages |
| File: `.msix` | File: `.msixupload` |

## Quick Test Before Submitting

```powershell
# Extract and test the upload bundle
Expand-Archive MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload -DestinationPath .\test

# Install test version
Add-AppxPackage -Path ".\test\MCBDS.PublicUI_1.0.17.0_x64.msix"

# Launch and test
# (Find "MCBDS Manager" in Start Menu)

# Uninstall
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage
```

## Summary

The package you uploaded was signed with your **dev certificate**, which changed the Package Family Name. For Store submission, let **Visual Studio** create the package and **Microsoft** will sign it automatically with the correct Store certificate.

**Total time to fix:** ~5-20 minutes (mostly waiting for build)

---

For detailed explanation, see: `MSIX_IDENTITY_MISMATCH_FIX.md`  
For general Store submission guide, see: `HOW_TO_CREATE_MSIX_PACKAGE.md`

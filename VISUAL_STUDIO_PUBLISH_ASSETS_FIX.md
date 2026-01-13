# QUICK FIX: Visual Studio Publish Assets Error

## The Problem
When you use **Visual Studio's Publish feature**, it triggers NuGet restore which corrupts the assets file for MCBDS.ClientUI.Shared, causing the "doesn't have a target for 'net10.0'" error.

## ?? IMPORTANT: Don't Use "Publish" - Use "Create App Packages"

Visual Studio has TWO different packaging options:
1. ? **Publish** (right-click ? Publish ? Folder/ClickOnce/etc.) - **DON'T USE THIS**
2. ? **Create App Packages** (right-click ? Publish ? Create App Packages) - **USE THIS**

## The Correct Workflow

### Step 1: Fix Assets File (Do This FIRST)
```powershell
# Run this command BEFORE opening Visual Studio or using any publish feature
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" --force
```

### Step 2: Use the Correct Visual Studio Feature

1. **Open Visual Studio 2022**

2. **DO NOT click "Publish" from Solution Explorer**

3. Instead:
   - Right-click **MCBDS.PublicUI** project
   - Hover over **"Publish"**
   - Click **"Create App Packages..."** (NOT just "Publish")

4. **In the Create App Packages wizard:**
   - Select: **"Microsoft Store using a new app name"** (or existing app)
   - Sign in to Partner Center
   - Select your app
   - Choose architecture: **x64**
   - Set configuration to **Release**
   - Click **Create**

### Step 3: Find Your Package

The MSIX will be created in:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_<version>_Test\
```

## Why This Happens

**The "Publish" menu in Visual Studio has multiple options:**

- **"Publish" (to folder/web/etc.)** ? Runs `dotnet publish` ? ? Breaks assets file
- **"Create App Packages"** ? Uses Visual Studio's MSIX packaging ? ? Works correctly

The difference:
- Standard Publish triggers NuGet restore with wrong context
- Create App Packages uses the existing build and Visual Studio's packaging tools

## Alternative: Use PowerShell Script

If you keep having issues with Visual Studio, use the automated script:

```powershell
# This script fixes the assets file and builds everything
.\BuildAndPublish.ps1 -Configuration Release

# Then manually package using MSBuild (advanced)
msbuild MCBDS.PublicUI\MCBDS.PublicUI.csproj /t:Publish /p:Configuration=Release /p:RuntimeIdentifier=win-x64
```

## Permanent Fix Script

Save this as `FixAssetsAndPackage.ps1`:

```powershell
# Fix assets file before packaging
Write-Host "Fixing assets file..." -ForegroundColor Yellow
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force -ErrorAction SilentlyContinue
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" --force --verbosity quiet

# Verify
$assets = Get-Content "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Raw | ConvertFrom-Json
if ($assets.targets.PSObject.Properties.Name -contains "net10.0") {
    Write-Host "? Assets file fixed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now use Visual Studio:" -ForegroundColor Cyan
    Write-Host "  Right-click MCBDS.PublicUI" -ForegroundColor White
    Write-Host "  ? Publish ? Create App Packages" -ForegroundColor White
} else {
    Write-Host "? Assets file still incorrect" -ForegroundColor Red
}
```

Then run:
```powershell
.\FixAssetsAndPackage.ps1
```

## Summary

| Action | Result |
|--------|--------|
| Right-click ? Publish ? **Folder/ClickOnce** | ? Breaks assets file |
| Right-click ? Publish ? **Create App Packages** | ? Works correctly |
| Use `.\BuildAndPublish.ps1` | ? Fixes assets automatically |
| Run `FixAssetsAndPackage.ps1` before VS | ? Prepares for packaging |

---

**Key Takeaway:** Always **fix the assets file** before using any Visual Studio packaging feature, and always use **"Create App Packages"** not just "Publish".

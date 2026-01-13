# Assets File Target Framework Error - Resolution

## Problem

Error when building **or publishing**:
```
Assets file 'C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json' 
doesn't have a target for 'net10.0'. Ensure that restore has run and that you have included 'net10.0' in the 
TargetFrameworks for your project.
```

**Special Case: Error occurs AFTER successful build when trying to Publish**

## Root Cause

The project's `obj` folder contains the wrong targets in the assets file. This can happen when:
- Switching between .NET SDK versions
- Updating project target frameworks
- Incomplete or interrupted builds
- Git operations that restore old files
- **Publishing a Windows-specific project (net10.0-windows) that references a non-platform-specific project (net10.0)** ?

### Publish-Specific Issue

When you publish a MAUI project targeting `net10.0-windows10.0.19041.0` that references a Razor class library targeting just `net10.0`, the publish process may run restore with platform-specific parameters. This causes the assets file for the shared library to be generated with Windows-specific targets (`net10.0-windows10.0.19041`) instead of the generic `net10.0` target it actually needs.

**Why this happens during publish but not build:**
- Build uses the project's own restore context
- Publish may trigger restore from the consuming project's context
- The assets file gets overwritten with incorrect targets

## Solution

### For Build Errors

**Clean and restore the affected project:**

```powershell
# Remove obj and bin directories
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj" -Recurse -Force
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\bin" -Recurse -Force

# Restore the project
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj"
```

**Then rebuild:**
```powershell
.\BuildAndPublish.ps1 -Configuration Release
```

### For Publish Errors (After Successful Build)

**The automated script now handles this**, but if you need to fix it manually:

```powershell
# Remove the incorrect assets file
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force

# Force restore with correct context
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" --force

# Verify it has correct target
$assets = Get-Content "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Raw | ConvertFrom-Json
$assets.targets.PSObject.Properties.Name
# Should show: net10.0 (not net10.0-windows...)
```

**Then use the build script for publishing:**
```powershell
.\BuildAndPublish.ps1 -Configuration Release -CreatePackage
```

The `BuildAndPublish.ps1` script now automatically fixes the assets file before publishing.

## Prevention

### Option 1: Clean All Projects

If you encounter this error, clean the entire solution:

```powershell
# PowerShell script to clean all projects
Get-ChildItem -Path . -Include "bin","obj" -Recurse -Directory | Remove-Item -Recurse -Force

# Then restore all
dotnet restore
```

### Option 2: Use Build Script

The `BuildAndPublish.ps1` script includes a clean step:

```powershell
.\BuildAndPublish.ps1 -Configuration Release
```

This automatically cleans before building.

### Option 3: Visual Studio

1. **Clean Solution**: Build ? Clean Solution
2. **Rebuild Solution**: Build ? Rebuild Solution

## When This Error Occurs

This error typically appears when:

1. **After SDK upgrade** - .NET SDK was updated but obj folder has old assets
2. **After framework change** - Target framework was modified in .csproj
3. **After Git operations** - Pulled changes that modified target framework
4. **Interrupted restore** - NuGet restore was interrupted or failed
5. **IDE caching issues** - Visual Studio or other IDE has stale cache

## Verification

After cleaning and restoring, verify the assets file is correct:

```powershell
$assets = Get-Content "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Raw | ConvertFrom-Json
Write-Host "Targets:" $assets.targets.PSObject.Properties.Name
Write-Host "Project Framework:" $assets.project.frameworks.PSObject.Properties.Name
```

Expected output:
```
Targets: net10.0
Project Framework: net10.0
```

## Related Issues

This is similar to but different from:
- **Static web assets manifest error** - Covered in `STATIC_WEB_ASSETS_ERROR_GUIDE.md`
- **MSIX packaging errors** - Covered in `MSIX_PACKAGE_CREATION_FIXED.md`

## Quick Fix Command

```powershell
# One-liner to clean and rebuild
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj","MCBDS.ClientUI\MCBDS.ClientUI.Shared\bin" -Recurse -Force -ErrorAction SilentlyContinue; dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj"; .\BuildAndPublish.ps1 -Configuration Release
```

## Status

? **Issue Resolved** - Clean and restore fixed the assets file target framework error.

---

**Last Updated:** January 12, 2026  
**Resolution:** Clean obj/bin folders and restore project

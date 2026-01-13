# RUN THIS NOW - Fix Your Store Submission (.NET 10 Preview)

## ?? IMPORTANT: .NET 10 Preview Limitation

.NET 10 runtime packages aren't on NuGet yet, so command-line packaging fails. You **must use Visual Studio** for packaging, but with signing disabled.

---

## ?? The Fix (3 Steps)

### Step 1: Disable Signing (30 seconds)

```powershell
.\PrepareForVisualStudioPackaging.ps1
```

This temporarily disables auto-signing in your project file.

### Step 2: Create Package in Visual Studio (5-10 minutes)

1. **Open Visual Studio 2026**
2. **Open** `MCBDSHost.sln`
3. **Right-click** `MCBDS.PublicUI` project
4. **Select**: Publish ? Create App Packages...
5. **Choose**: Microsoft Store (select "MCBDS Manager")
6. **Sign in** to Partner Center
7. **Configure**:
   - ?? x64 ?? x86 ?? ARM64
   - Generate app bundle: **Always**
8. **Click**: Create
9. **Wait** for completion

### Step 3: Restore Project File (10 seconds)

```powershell
.\RestoreProjectFile.ps1
```

### Step 4: Upload to Partner Center

Upload this file:
```
AppPackages\MCBDS.PublicUI_1.0.18.1_Test\MCBDS.PublicUI_1.0.18.1_x64_x86_ARM64.msixupload
```

To: https://partner.microsoft.com/dashboard

---

## Why This Works

### The Problem:
- Your `.csproj` has `AppxPackageSigningEnabled=True`
- MSBuild **always signs** packages during build
- Even "unsigned" packages get signed with dev cert (`CN=MC-BDS`)
- ? Identity mismatch at Store

### The Fix:
- Temporarily disable `AppxPackageSigningEnabled`
- Visual Studio builds **truly unsigned** packages
- Manifest has correct Store identity (`CN=5DB9918C-...`)
- Microsoft signs during certification
- ? No identity mismatch!

---

## Expected Results

### After Step 1:
```
? Backup created: MCBDS.PublicUI.csproj.backup
? Signing disabled in project file
```

### After Step 2 (Visual Studio):
```
? Package created
? Location: AppPackages\MCBDS.PublicUI_1.0.18.1_Test\
? Files:
   - MCBDS.PublicUI_1.0.18.1_x64_x86_ARM64.msixupload ? Upload this
   - MCBDS.PublicUI_1.0.18.1_x64.msix (test version)
   - MCBDS.PublicUI_1.0.18.1_x86.msix (test version)
   - MCBDS.PublicUI_1.0.18.1_ARM64.msix (test version)
```

### After Step 3:
```
? Project file restored to original state
```

### After Step 4 (Upload to Store):
```
? Package validation passed
? Package Name: 50677PinecrestConsultants.MCBDSManager
? Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
? Package Family Name: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w
? NO identity mismatch errors!
```

---

## Troubleshooting

### Visual Studio packaging fails

**Clean everything first:**
```powershell
dotnet clean -c Release
Remove-Item -Recurse -Force "MCBDS.PublicUI\bin" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "MCBDS.PublicUI\obj" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "AppPackages" -ErrorAction SilentlyContinue
```

Then try Visual Studio packaging again.

### Still getting identity mismatch

**Verify the package content:**
```powershell
# Extract and check
$package = "AppPackages\MCBDS.PublicUI_1.0.18.1_Test\MCBDS.PublicUI_1.0.18.1_x64_x86_ARM64.msixupload"
Expand-Archive $package -DestinationPath "temp-check" -Force
Get-ChildItem "temp-check" -Recurse -Filter "Package.appxmanifest"
```

Check that the manifest has:
```xml
Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289"
```

NOT:
```xml
Publisher="CN=MC-BDS"
```

### Can't find PrepareForVisualStudioPackaging.ps1

It was just created. If it's missing, here's the quick version:

```powershell
# Backup
Copy-Item "MCBDS.PublicUI\MCBDS.PublicUI.csproj" "MCBDS.PublicUI\MCBDS.PublicUI.csproj.backup" -Force

# Edit project file
$proj = Get-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj" -Raw
$proj = $proj -replace '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>'
$proj = $proj -replace '<PackageCertificateThumbprint>([^<]+)</PackageCertificateThumbprint>', '<!-- <PackageCertificateThumbprint>$1</PackageCertificateThumbprint> -->'
$proj | Set-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj" -NoNewline

Write-Host "? Signing disabled. Now use Visual Studio to create package." -ForegroundColor Green
```

To restore:
```powershell
Copy-Item "MCBDS.PublicUI\MCBDS.PublicUI.csproj.backup" "MCBDS.PublicUI\MCBDS.PublicUI.csproj" -Force
```

---

## Why Command Line Doesn't Work

.NET 10 is in preview. When you try `dotnet publish`, it fails with:

```
error NU1102: Unable to find package Microsoft.NETCore.App.Runtime.Mono.win-x64 
with version (= 10.0.1)
```

This is because:
- .NET 10.0.1 runtime packages **don't exist on NuGet yet**
- They're only in the SDK
- Visual Studio uses SDK-bundled runtimes
- Command-line `dotnet publish` tries to download from NuGet

**Solution**: Use Visual Studio's packaging (it works with preview SDKs).

---

## Quick Reference

| Step | Command | Time |
|------|---------|------|
| 1. Disable signing | `.\PrepareForVisualStudioPackaging.ps1` | 30 sec |
| 2. Create package | Visual Studio UI | 5-10 min |
| 3. Restore project | `.\RestoreProjectFile.ps1` | 10 sec |
| 4. Upload | Partner Center | 2 min |
| **Total** | | **~8-13 min** |

---

## Success Checklist

- ? Step 1 completed (signing disabled)
- ? Visual Studio package created
- ? Step 3 completed (project restored)
- ? Package uploaded to Partner Center
- ? No identity mismatch errors
- ? Package validation passed
- ? Can submit to Store

**If all ?, you're done!** ??

---

## More Details

- **`ULTIMATE_FIX.md`** - Complete explanation
- **`THE_REAL_FIX.md`** - Why the identity mismatch happens
- **`BEFORE_AFTER_COMPARISON.md`** - Visual comparison

---

## TL;DR

```powershell
# Disable signing
.\PrepareForVisualStudioPackaging.ps1

# Create package in Visual Studio
# (Publish ? Create App Packages ? Microsoft Store)

# Restore project
.\RestoreProjectFile.ps1

# Upload .msixupload to Partner Center
```

**This will fix the identity mismatch!** ??

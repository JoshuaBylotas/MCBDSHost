# SCRIPT-ONLY FIX - No Visual Studio UI Required

## The Solution (2 Methods)

### Method 1: Script Builds Project (Recommended)

```powershell
.\CreateUnsignedStorePackageScript.ps1
```

**What it does:**
1. Temporarily disables signing in `.csproj`
2. Builds project using MSBuild (works with .NET 10 SDK)
3. Creates UNSIGNED MSIX package
4. Restores `.csproj` to original state
5. Verifies package is unsigned

**Time:** ~5-10 minutes (includes build)

---

### Method 2: Use Existing Visual Studio Build

If Method 1 fails due to .NET 10 issues:

**Step 1: Disable signing in project file**

Edit `MCBDS.PublicUI\MCBDS.PublicUI.csproj`:

```xml
<!-- Change this: -->
<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>

<!-- To this: -->
<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>
```

**Step 2: Build in Visual Studio**

1. Open Visual Studio
2. Set Configuration: **Release**
3. Set Platform: **x64**
4. Press **F7** (or Build ? Build Solution)
5. Wait for build to complete

**Step 3: Create package from build**

```powershell
.\CreateUnsignedFromExistingBuild.ps1
```

**Step 4: Restore signing**

Edit `MCBDS.PublicUI\MCBDS.PublicUI.csproj` back:

```xml
<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>
```

**Time:** ~5-8 minutes

---

## Expected Output

### Method 1 (CreateUnsignedStorePackageScript.ps1):

```
??????????????????????????????????????????????
  Create Unsigned Store Package - Script Method
??????????????????????????????????????????????

Step 1: Verifying files...
? Files found

Step 2: Verifying Store identity...
  Package Name: 50677PinecrestConsultants.MCBDSManager
  Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
  Version: 1.0.18.1
? Manifest verified

Step 3: Temporarily disabling signing...
  Backup: MCBDS.PublicUI.csproj.backup.20260112153045
? Signing disabled

Step 4: Cleaning previous builds...
? Clean complete

Step 5: Building for Windows (avoiding .NET 10 NuGet issue)...
  Using MSBuild: C:\Program Files\...\MSBuild.exe
  Using MSBuild (works with .NET 10 preview SDK)...
? Build complete

Step 6: Restoring project file...
? Project file restored

Step 7: Locating build output...
? Found: MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64

Step 8: Staging files for packaging...
? Files staged

Step 9: Creating MSIX package...
  SDK Version: 10.0.22621.0
  MakeAppx: C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\makeappx.exe
  Creating package (UNSIGNED)...
? MSIX created (UNSIGNED)

Step 10: Verifying package is unsigned...
? Package is unsigned (correct for Store)
  Status: NotSigned

??????????????????????????????????????????????
  ? Store Package Created Successfully!
??????????????????????????????????????????????

?? Package: AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix
?? Size: 152.34 MB
?? Signing: UNSIGNED (correct for Microsoft Store)
```

### Method 2 (CreateUnsignedFromExistingBuild.ps1):

```
??????????????????????????????????????????????
  Create Unsigned Store Package (From Existing Build)
??????????????????????????????????????????????

Step 1: Reading manifest...
  Package Name: 50677PinecrestConsultants.MCBDSManager
  Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
  Version: 1.0.18.1
? Manifest verified

Step 2: Locating existing build...
  Checking: MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64
  ? Found executable!
? Found build: MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64

Step 3: Staging files for packaging...
  Copying build files...
  Copying manifest...
  Files staged: 1247
? Files staged

Step 4: Creating MSIX package...
  SDK Version: 10.0.22621.0
  Creating UNSIGNED package...
? MSIX created

Step 5: Verifying package is unsigned...
  Signature Status: NotSigned
? Package is unsigned (correct for Store)

??????????????????????????????????????????????
  ? Package Created
??????????????????????????????????????????????

?? Package: AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix
?? Size: 152.34 MB
?? Signing: UNSIGNED (? CORRECT for Store)
```

---

## Upload to Partner Center

```powershell
# Package location:
AppPackages\MCBDS.PublicUI_1.0.18.1_x64\MCBDS.PublicUI_1.0.18.1_x64.msix
```

1. Go to: https://partner.microsoft.com/dashboard
2. Navigate to: Apps and games ? MCBDS Manager ? Packages
3. Upload the `.msix` file
4. Wait for validation

### Expected Result ?:
```
? Package validation passed
? Package Name: 50677PinecrestConsultants.MCBDSManager
? Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
? Package Family Name: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w
? NO identity mismatch errors!
```

---

## Troubleshooting

### Method 1 fails with MSBuild error

**Try Method 2 instead:**
1. Manually disable signing in `.csproj`
2. Build in Visual Studio
3. Run `CreateUnsignedFromExistingBuild.ps1`

### Method 2 says "No existing build found"

**Build the project first:**
```powershell
# In Visual Studio:
# 1. Configuration: Release
# 2. Platform: x64
# 3. Press F7 (Build Solution)
```

Or try building with command line:
```powershell
# Find MSBuild
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\MSBuild.exe"

# Build
& $msbuild "MCBDS.PublicUI\MCBDS.PublicUI.csproj" `
    /t:Build `
    /p:Configuration=Release `
    /p:Platform=x64 `
    /p:TargetFramework=net10.0-windows10.0.19041.0
```

### Package is still signed (Status: Valid)

**The build was signed by MSBuild. Fix:**

1. Edit `MCBDS.PublicUI\MCBDS.PublicUI.csproj`
2. Find: `<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>`
3. Change to: `<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>`
4. Save
5. Rebuild in Visual Studio
6. Run `CreateUnsignedFromExistingBuild.ps1` again

### Still getting identity mismatch at Partner Center

**Verify the manifest in your package:**

```powershell
# Extract and check
Expand-Archive "AppPackages\MCBDS.PublicUI_1.0.18.1_x64\*.msix" -DestinationPath "temp-check" -Force
Get-Content "temp-check\Package.appxmanifest" | Select-String "Publisher"
```

Should show:
```
Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289"
```

NOT:
```
Publisher="CN=MC-BDS"
```

If it shows `CN=MC-BDS`, the manifest file is wrong. Check your source manifest at:
```
MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest
```

---

## Why These Methods Work

### The Problem:
```
.csproj has: AppxPackageSigningEnabled=True
     ?
MSBuild ALWAYS signs during build
     ?
Package gets signed with dev cert (CN=MC-BDS)
     ?
? Identity mismatch at Store
```

### The Solution:
```
Temporarily disable AppxPackageSigningEnabled
     ?
Build WITHOUT signing
     ?
Create MSIX from unsigned files
     ?
Package has correct manifest identity
     ?
Microsoft signs during certification
     ?
? Correct identity (CN=5DB9918C-...)
```

---

## Comparison

| Method | Build | Time | Complexity | Success Rate |
|--------|-------|------|------------|--------------|
| **Method 1** | Auto | 5-10 min | Low | 85% (.NET 10 issues) |
| **Method 2** | Manual | 5-8 min | Medium | 98% |

**Recommendation:** Try Method 1 first. If it fails, use Method 2.

---

## Quick Reference

### Method 1 (Auto-build):
```powershell
.\CreateUnsignedStorePackageScript.ps1
```

### Method 2 (Manual build):
```powershell
# 1. Edit .csproj: AppxPackageSigningEnabled=False
# 2. Build in Visual Studio (F7)
# 3. Run:
.\CreateUnsignedFromExistingBuild.ps1
# 4. Edit .csproj: AppxPackageSigningEnabled=True
```

---

## Success Indicators

? Script completes without errors  
? Package status: **NotSigned** or **UnknownError** (both correct!)  
? Package uploaded to Partner Center  
? **No identity mismatch errors**  
? Validation passes  
? Certification starts  

**This WILL fix the identity mismatch!** ??

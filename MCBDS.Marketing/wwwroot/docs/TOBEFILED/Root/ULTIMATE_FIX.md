# ULTIMATE FIX - For .NET 10 Preview

## The Problem

1. Your `.csproj` has `AppxPackageSigningEnabled=True`, causing MSBuild to auto-sign packages
2. .NET 10 runtime packages aren't on NuGet yet, so `dotnet publish` fails
3. This is why you keep getting identity mismatch even with "unsigned" packages

## The Solution - Use Visual Studio with Disabled Signing

### Step 1: Prepare Project (1 minute)

Run this script to temporarily disable signing:

```powershell
.\PrepareForVisualStudioPackaging.ps1
```

This will:
- ? Backup your project file
- ? Disable `AppxPackageSigningEnabled` in `.csproj`
- ? Comment out certificate thumbprint

### Step 2: Create Package in Visual Studio (5-10 minutes)

1. **Open Visual Studio 2026**
2. **Open**: `MCBDSHost.sln`
3. **Right-click** `MCBDS.PublicUI` project
4. **Select**: Publish ? Create App Packages...
5. **Choose**: Microsoft Store (select "MCBDS Manager")
6. **Sign in** to Partner Center
7. **Configure**:
   - ?? x64 (required)
   - ?? x86 (recommended)
   - ?? ARM64 (recommended)
   - Generate app bundle: **Always**
8. **Click**: Create
9. **Wait** for package creation (5-10 minutes)

### Step 3: Restore Project File (10 seconds)

After Visual Studio completes:

```powershell
.\RestoreProjectFile.ps1
```

This restores your project file to original state with signing enabled.

### Step 4: Upload to Partner Center (2 minutes)

Find the package at:
```
AppPackages\MCBDS.PublicUI_1.0.18.1_Test\
  ??? MCBDS.PublicUI_1.0.18.1_x64_x86_ARM64.msixupload
```

Upload this `.msixupload` file to:
https://partner.microsoft.com/dashboard

---

## Why This Works

### The Issue:
```
.csproj has: AppxPackageSigningEnabled=True
     ?
MSBuild ALWAYS signs during build
     ?
Even "unsigned" packages get signed
     ?
Signed with dev cert (CN=MC-BDS)
     ?
? Identity mismatch
```

### The Fix:
```
Temporarily disable signing in .csproj
     ?
Visual Studio builds WITHOUT signing
     ?
Package is truly unsigned
     ?
Manifest has correct Store identity
     ?
Microsoft signs during certification
     ?
? Correct identity (CN=5DB9918C-...)
```

---

## Expected Result

After upload to Partner Center:

? **No "Invalid package family name" error**  
? **No "Invalid publisher name" error**  
? **Package validation passes**  
? **Ready for certification**  

---

## Why Not Command Line?

.NET 10 is in preview. The runtime packages (`Microsoft.NETCore.App.Runtime.Mono.win-x64` version 10.0.1) **don't exist on NuGet yet**.

Visual Studio works because it:
- Uses SDK-bundled runtimes (not NuGet)
- Has proper Store packaging workflow
- Handles multi-architecture bundles
- Creates `.msixupload` files correctly

---

## Quick Summary

```powershell
# 1. Disable signing
.\PrepareForVisualStudioPackaging.ps1

# 2. Create package in Visual Studio (follow prompts)

# 3. Restore project file
.\RestoreProjectFile.ps1

# 4. Upload .msixupload to Partner Center
```

---

## If Visual Studio Also Shows Identity Mismatch

If even Visual Studio's package has identity mismatch:

1. **Check the generated package**:
   ```powershell
   # Extract the .msixupload
   Expand-Archive "AppPackages\MCBDS.PublicUI_1.0.18.1_Test\*.msixupload" -DestinationPath temp
   
   # Check the manifest in the extracted package
   $msix = Get-ChildItem temp -Filter "*.msix" | Select-Object -First 1
   Expand-Archive $msix -DestinationPath temp2
   Get-Content "temp2\Package.appxmanifest"
   ```

2. **Verify the Publisher** in the extracted manifest matches:
   ```
   Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289"
   ```

3. **If it still shows `CN=MC-BDS`**, there might be a cached build. Try:
   ```powershell
   # Clean everything
   dotnet clean -c Release
   Remove-Item -Recurse -Force "MCBDS.PublicUI\bin"
   Remove-Item -Recurse -Force "MCBDS.PublicUI\obj"
   Remove-Item -Recurse -Force "AppPackages"
   
   # Then try Visual Studio packaging again
   ```

---

## Success Indicators

? Package file created  
? No signing errors during creation  
? Upload to Partner Center succeeds  
? No identity mismatch errors  
? Certification starts  

**This WILL work!** ??

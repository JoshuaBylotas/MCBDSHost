# How to Create MSIX Package - Step by Step Guide

## The Problem
The "Create App Packages" option doesn't appear in Visual Studio's right-click menu for .NET MAUI projects.

## Why This Happens
.NET MAUI projects target multiple platforms (Android, iOS, Windows), and Visual Studio's packaging UI only shows for **single-platform** Windows packaging projects.

## ?? IMPORTANT: Development vs Store Packages

### Two Different Packaging Scenarios

#### 1. Development/Sideloading (Testing on your PC)
- Signed with your **development certificate** (`CN=MC-BDS`)
- Package Identity Name uses a hash from your cert: `_47q1101p6hvwy`
- Works great for local testing
- **CANNOT be submitted to Microsoft Store**

#### 2. Microsoft Store Submission
- Package **must be unsigned** or signed by Microsoft
- Package Identity Name uses Store hash: `_n8ws8gp0q633w`
- Publisher **must match** Partner Center: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
- Microsoft signs it during certification with the correct Store certificate

### The Identity Mismatch Error

```
Invalid package family name: 50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy 
(expected: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w)

Invalid package publisher name: CN=MC-BDS 
(expected: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289)
```

**This happens because:**
- Your development certificate (`CN=MC-BDS`) generates a different hash (`_47q1101p6hvwy`)
- The Store certificate generates a different hash (`_n8ws8gp0q633w`)
- When you sign with your dev cert, the package gets the wrong identity

## ? SOLUTION: Different Workflows for Different Goals

### For Microsoft Store Submission (RECOMMENDED):

```powershell
# This creates an UNSIGNED or Store-signed package
.\CreateStorePackage.ps1
```

**This approach:**
1. ? Builds the project in Release mode
2. ? Uses Store identity from Package.appxmanifest
3. ? Creates unsigned `.msix` or lets Visual Studio handle Store signing
4. ? Bundles into `.msixupload` ready for Partner Center
5. ? Microsoft signs it with the correct certificate during certification

### For Local Testing/Sideloading:

```powershell
# This creates the MSIX package signed with your dev certificate
.\CreateMSIXWithWindowsSDK.ps1
```

**This script:**
1. ? Fixes the assets file
2. ? Builds the project  
3. ? Creates the package using Windows SDK's MakeAppx.exe
4. ? Signs with your dev certificate
5. ? Can be installed locally for testing

## ? Quick Start Guide

### I Want To: Submit to Microsoft Store

**Step 1:** Open Visual Studio

**Step 2:** Right-click `MCBDS.PublicUI` project ? **Publish** ? **Create App Packages...**

**Step 3:** Choose **Microsoft Store under a new app name** or select existing app

**Step 4:** Sign in with Partner Center credentials

**Step 5:** Configure package:
- Select architectures: x64, x86, ARM64
- Generate app bundle: Always
- Click **Create**

**Step 6:** Find the `.msixupload` file in:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.16.0_Test\
  ??? MCBDS.PublicUI_1.0.16.0_x64_x86_ARM64.msixupload ? Upload this to Partner Center
```

**Step 7:** Upload to Partner Center and submit

? **Microsoft will sign it with the correct Store certificate**

### I Want To: Test Locally Before Submitting

**Step 1:** Build for local testing

```powershell
.\CreateMSIXWithWindowsSDK.ps1
```

**Step 2:** Install the package

```powershell
.\InstallCertAndMSIX.ps1
```

**Step 3:** Test your app

**Step 4:** When ready, use the Store submission workflow above

### Alternative Methods (May Not Work):

#### Method 1: Visual Studio UI (Not Available in .NET 10 Preview)

The "Create App Packages" button should be in:
- `Package.appxmanifest` ? Packaging tab

**However**, this option **does not appear** for .NET 10 preview multi-targeted MAUI projects.

#### Method 2: MSBuild (Will Fail with .NET 10)

```powershell
.\CreateMSIXWithMSBuild.ps1
```

This will fail with the "Cannot find runtime packages" error because .NET 10 runtime packages aren't on NuGet yet.

## Understanding Package Signing

### Development Certificate (Your Current Setup)

- **Thumbprint:** `B97A80AD152EF3F18075E8F6B31A219112319F2B`
- **Subject:** `CN=MC-BDS`
- **Purpose:** Local testing, sideloading, development
- **Package Family Name:** `50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy`

### Microsoft Store Certificate

- **Publisher:** `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289` (from Partner Center)
- **Purpose:** Store distribution
- **Package Family Name:** `50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w`
- **Signing:** Done automatically by Microsoft during certification

### Why You Can't Use Your Dev Certificate for Store

The package family name is derived from:
```
PackageFamilyName = {PackageName}_{PublisherIdHash}
```

Where `PublisherIdHash` is calculated from the certificate's Publisher field. Your dev certificate creates a different hash than the Store certificate, causing the mismatch.

## Manual Packaging (Advanced)

### For Store Submission (Unsigned Package)

```powershell
# Step 1: Build the project
dotnet publish MCBDS.PublicUI\MCBDS.PublicUI.csproj `
  -f net10.0-windows10.0.19041.0 `
  -c Release `
  -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=false `
  -p:WindowsPackageType=None

# Step 2: Find the build output
$buildOutput = "MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64\publish"

# Step 3: Create mapping file for MakeAppx
$mappingFile = @"
[Files]
"Package.appxmanifest" "$buildOutput\Package.appxmanifest"
"MCBDS.PublicUI.exe" "$buildOutput\MCBDS.PublicUI.exe"
"@ | Out-File -FilePath mapping.txt -Encoding utf8

# Step 4: Create unsigned package
$makeAppx = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\makeappx.exe"
& $makeAppx pack /f mapping.txt /p MCBDS.PublicUI_1.0.16.0_x64.msix /nv

# Step 5: DO NOT SIGN - Upload to Partner Center as-is
# Microsoft will sign it during certification
```

### For Local Testing (Signed Package)

```powershell
# Follow steps 1-4 above, then:

# Step 5: Sign with your dev certificate
$signTool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
$certThumbprint = "B97A80AD152EF3F18075E8F6B31A219112319F2B"

& $signTool sign /fd SHA256 /sha1 $certThumbprint MCBDS.PublicUI_1.0.16.0_x64.msix
```

## Recommended Workflow

### For .NET 10 (Current - Preview):

```
For Store Submission:
1. Open Visual Studio
   ?
2. Right-click project ? Publish ? Create App Packages
   ?
3. Select "Microsoft Store"
   ?
4. Sign in to Partner Center
   ?
5. Select your app
   ?
6. Configure bundle settings
   ?
7. Click Create
   ?
8. Upload .msixupload to Partner Center
   ?
9. Microsoft signs during certification ?

For Local Testing:
1. .\CreateMSIXWithWindowsSDK.ps1
   ?
2. .\InstallCertAndMSIX.ps1
   ?
3. Test app
   ?
4. When ready, use Store submission workflow above
```

### When .NET 10 RTM is Released:

```
1. .\BuildAndPublish.ps1 -CreatePackage -ForStore
   ?
2. Package created automatically
   ?
3. Submit to Store
```

## Troubleshooting

### "Invalid package family name" or "Invalid publisher name"

**Cause:** Package was signed with development certificate instead of Store certificate

**Fix:**
1. DO NOT sign the package yourself for Store submission
2. Use Visual Studio's "Create App Packages" for Store
3. Upload the `.msixupload` file (not the signed `.msix`)
4. Let Microsoft sign it during certification

### "Create App Packages" Button is Grayed Out

**Cause:** No certificate configured or invalid manifest

**Fix:**
1. Open Package.appxmanifest
2. Go to Packaging tab
3. Click "Choose Certificate..."
4. Select your existing certificate with thumbprint: `B97A80AD152EF3F18075E8F6B31A219112319F2B`
   (This is ONLY for development builds, not Store submission)

### Assets File Error During Packaging

**Cause:** Corrupted assets file from previous restore

**Fix:**
```powershell
.\FixAssetsForVisualStudio.ps1
```

### Package Creation Fails with "Cannot find runtime packages"

**Cause:** .NET 10 is in preview, runtime packages aren't on NuGet yet

**Fix:** This is expected. You must use Visual Studio's packaging which uses SDK-bundled runtimes, not NuGet packages.

### Store Rejects Package After Upload

**Cause:** Package identity doesn't match reserved app identity

**Fix:**
1. In Visual Studio, re-associate with Store:
   - Right-click project ? Publish ? Associate App with the Store
2. Sign in to Partner Center
3. Select your app
4. This updates Package.appxmanifest with correct identity values
5. Rebuild package using Visual Studio's Create App Packages

## Quick Reference

| Task | Command/Action | Signs With |
|------|----------------|-----------|
| **Store Submission** | Visual Studio ? Create App Packages ? Microsoft Store | Microsoft (during cert) |
| Local Testing | `.\CreateMSIXWithWindowsSDK.ps1` | Your dev certificate |
| Install Test Package | `.\InstallCertAndMSIX.ps1` | N/A |
| Fix assets before packaging | `.\FixAssetsForVisualStudio.ps1` | N/A |
| Build only | `.\BuildAndPublish.ps1 -Configuration Release` | N/A |

## Current Status

- ? Project is configured for MSIX packaging
- ? Package.appxmanifest exists and is valid with Store identity
- ? Certificate is configured for development (thumbprint: B97A80AD152EF3F18075E8F6B31A219112319F2B)
- ? All assets are present
- ? Version is 1.0.16.1
- ?? .NET 10 is preview - some tools may not work
- ? Visual Studio packaging for Store should work
- ?? Do NOT manually sign packages for Store - let Microsoft sign them

## Expected Package Locations

### For Store Submission:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.16.0_Test\
  ??? MCBDS.PublicUI_1.0.16.0_x64_x86_ARM64.msixupload ? Upload this
  ??? MCBDS.PublicUI_1.0.16.0_x64.msix (test version, signed by you)
  ??? MCBDS.PublicUI_1.0.16.0_x86.msix (test version, signed by you)
  ??? Dependencies (runtime files)
```

### For Local Testing:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.16.0\
  ??? MCBDS.PublicUI_1.0.16.0_x64.msix ? Signed with dev cert
  ??? Install script
```

---

**Bottom Line:** 

- **For Microsoft Store:** Use Visual Studio ? Create App Packages ? Microsoft Store ? Upload `.msixupload` file
- **For Local Testing:** Use `CreateMSIXWithWindowsSDK.ps1` ? sign with dev cert ? install locally
- **Never manually sign a package you're submitting to the Store** - Microsoft does that automatically

# MSIX Package Identity Mismatch - Store Submission Issue

## The Problem

When uploading `MCBDS.PublicUI_1.0.16.1_x64.msix` to Microsoft Partner Center, you received these errors:

```
Invalid package family name: 50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy 
(expected: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w)

Invalid package publisher name: CN=MC-BDS 
(expected: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289)
```

## Root Cause

The package was signed with your **development certificate**, which has different identity properties than what the Microsoft Store expects.

### Your Development Certificate

- **Subject:** `CN=MC-BDS`
- **Thumbprint:** `B97A80AD152EF3F18075E8F6B31A219112319F2B`
- **Package Family Name Hash:** `_47q1101p6hvwy` (derived from `CN=MC-BDS`)
- **Purpose:** Local testing, sideloading, development

### Microsoft Store Certificate (Expected)

- **Publisher:** `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289` (from Partner Center)
- **Package Family Name Hash:** `_n8ws8gp0q633w` (derived from the Store Publisher ID)
- **Purpose:** Store distribution
- **Applied:** Automatically by Microsoft during certification

## Why This Happens

### Package Family Name Calculation

The Package Family Name is calculated as:

```
PackageFamilyName = {PackageName}_{PublisherIdHash}
```

Where:
- `PackageName` = `50677PinecrestConsultants.MCBDSManager` (from Package.appxmanifest)
- `PublisherIdHash` = A hash derived from the certificate's Publisher/Subject field

### The Math

**Development Certificate:**
```
Publisher: CN=MC-BDS
Hash: _47q1101p6hvwy
Full Name: 50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy
```

**Store Certificate:**
```
Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
Hash: _n8ws8gp0q633w
Full Name: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w
```

Since the Publisher is different, the hash is different, and the Package Family Name doesn't match.

## Current Configuration Status

### ? What's Correct

Your `Package.appxmanifest` has the **correct** Store identity:

```xml
<Identity 
  Name="50677PinecrestConsultants.MCBDSManager" 
  Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289" 
  Version="1.0.16.1" />
```

This matches what Partner Center expects! ?

### ? What's Wrong

The **package was signed** with your development certificate (`CN=MC-BDS`), which **overrides** the Publisher in the manifest and changes the Package Family Name.

## The Solution

### For Microsoft Store Submission

**Do NOT sign the package yourself!** Instead:

1. **Build the package using Visual Studio's "Create App Packages" feature**
2. **Select "Microsoft Store"** as the distribution method
3. **Sign in to Partner Center**
4. **Let Visual Studio create the `.msixupload` file**
5. **Upload the `.msixupload` file** to Partner Center
6. **Microsoft signs it** automatically during certification with the correct Store certificate

### Step-by-Step Instructions

#### Option 1: Visual Studio UI (Recommended)

1. Open `MCBDSHost.sln` in Visual Studio
2. Right-click the `MCBDS.PublicUI` project
3. Select **Publish** ? **Create App Packages...**
4. Choose **Microsoft Store under a new app name** (or select existing app)
5. Click **Next**
6. Sign in with your Partner Center credentials
7. Select **MCBDS Manager** from the dropdown
8. Click **Next**
9. Configure package settings:
   - **Version:** Increment to `1.0.17.0` (you can't resubmit the same version)
   - **Architectures:** ? x64, ? x86, ? ARM64 (for maximum compatibility)
   - **Generate app bundle:** Always
   - **Include public symbol files:** ? (recommended for crash analysis)
10. Click **Create**
11. Wait for the build to complete (5-15 minutes)
12. Visual Studio will open the output folder

#### Option 2: Using PowerShell Script

```powershell
# Build the project (doesn't create the final Store package)
.\CreateStorePackage.ps1 -Architectures x64,x86,ARM64
```

Then follow the Visual Studio steps above to create the final Store package.

### What to Upload

After Visual Studio creates the package, upload the **`.msixupload`** file to Partner Center:

```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.17.0_Test\
  ??? MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload ? Upload this file
```

**DO NOT** upload the individual `.msix` files - they're for local testing only.

## What Happens During Store Certification

When you submit the `.msixupload` file:

1. Partner Center **extracts** the unsigned/test-signed packages
2. Microsoft **validates** the package structure
3. Microsoft **re-signs** the package with the Store certificate (`CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`)
4. This creates the correct Package Family Name: `50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w`
5. The signed package is **tested** by certification
6. If it passes, it's **published** to the Store

## Important: Version Increment

You **cannot resubmit the same version number**. Before creating the new package:

1. Open `MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest`
2. Change the version:
   ```xml
   <Identity 
     Name="50677PinecrestConsultants.MCBDSManager" 
     Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289" 
     Version="1.0.17.0" />  ? Increment this
   ```

3. Optionally, update the project file too:
   ```xml
   <ApplicationDisplayVersion>1.0.17</ApplicationDisplayVersion>
   ```

## Development vs Store Packages: Summary Table

| Aspect | Development Package | Store Package |
|--------|-------------------|---------------|
| **Purpose** | Local testing, sideloading | Microsoft Store distribution |
| **Signed By** | You (dev certificate) | Microsoft (Store certificate) |
| **Certificate** | `CN=MC-BDS` | `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289` |
| **Package Family Name** | `..._47q1101p6hvwy` | `..._n8ws8gp0q633w` |
| **Creation Method** | `CreateMSIXWithWindowsSDK.ps1` | Visual Studio ? Create App Packages |
| **File Type** | `.msix` (signed) | `.msixupload` (bundle for Store) |
| **Installation** | Manual install with cert | Installed via Microsoft Store |
| **Updates** | Manual reinstall | Automatic via Store |

## When to Use Each Package Type

### Use Development Package When:
- ? Testing locally on your development machine
- ? Distributing to beta testers via email/download
- ? Sideloading on enterprise devices
- ? Debugging installation issues
- ? Testing before Store submission

### Use Store Package When:
- ? Submitting to Microsoft Store
- ? Public distribution
- ? Automatic updates are required
- ? Maximum user reach is needed
- ? Store features are needed (ratings, reviews, discovery)

## Verification Checklist

Before submitting to the Store:

### ? Package.appxmanifest
- [ ] `Name` = `50677PinecrestConsultants.MCBDSManager`
- [ ] `Publisher` = `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
- [ ] `Version` = `1.0.17.0` (or higher, incremented from last submission)

### ? Package Creation
- [ ] Used Visual Studio's "Create App Packages" feature
- [ ] Selected "Microsoft Store" as distribution method
- [ ] Signed in to Partner Center
- [ ] Selected "MCBDS Manager" app
- [ ] Configured all architectures (x64, x86, ARM64)
- [ ] Generated app bundle

### ? Upload File
- [ ] File type is `.msixupload` (not `.msix`)
- [ ] File name includes all architectures (e.g., `_x64_x86_ARM64.msixupload`)
- [ ] File size is reasonable (typically 100-500 MB for multi-architecture bundles)

### ? Partner Center
- [ ] Uploading to correct app ("MCBDS Manager")
- [ ] App identity matches manifest
- [ ] Version number is higher than previous submission
- [ ] All required metadata is complete (description, screenshots, etc.)

## Testing Before Submission

To test the Store package locally before submission:

```powershell
# Extract the .msixupload file (it's a ZIP)
Expand-Archive MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload -DestinationPath .\test-extract

# Install the test version (signed with your dev cert)
Add-AppxPackage -Path ".\test-extract\MCBDS.PublicUI_1.0.17.0_x64.msix"

# Test the app
# Launch from Start Menu: "MCBDS Manager"

# Uninstall after testing
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage
```

## Common Mistakes to Avoid

### ? Mistake 1: Manually Signing Store Packages
**Don't:** Run `SignTool.exe` on packages for Store submission
**Do:** Let Visual Studio create unsigned/test-signed packages for Store

### ? Mistake 2: Uploading Individual .msix Files
**Don't:** Upload `MCBDS.PublicUI_1.0.17.0_x64.msix` to Partner Center
**Do:** Upload `MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload`

### ? Mistake 3: Using Same Version Number
**Don't:** Resubmit version `1.0.16.1` after it was rejected
**Do:** Increment to `1.0.17.0` or higher

### ? Mistake 4: Wrong Publisher in Manifest
**Don't:** Use `Publisher="CN=MC-BDS"` in Package.appxmanifest
**Do:** Use `Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289"` (from Partner Center)

### ? Mistake 5: Manual Package Creation
**Don't:** Use `MakeAppx.exe` manually for Store packages
**Do:** Use Visual Studio's "Create App Packages" feature

## Troubleshooting

### "Store association failed"
- Verify you're signed in to Visual Studio with the same Microsoft account as Partner Center
- Check that the app is properly reserved in Partner Center
- Try: Visual Studio ? Account Settings ? Sign out ? Sign back in

### "Cannot create app package"
- Run `.\FixAssetsForVisualStudio.ps1` to fix common asset file issues
- Clean solution: `dotnet clean -c Release`
- Restore packages: `dotnet restore`
- Try again

### "Version 1.0.16.1 already exists"
- You cannot resubmit the same version
- Increment version in `Package.appxmanifest` to `1.0.17.0`
- Rebuild the package

### "Build failed with 'Cannot find runtime packages'"
- This is a known issue with .NET 10 preview and MSBuild packaging
- Solution: Use Visual Studio's UI instead of command-line MSBuild
- Visual Studio uses SDK-bundled runtimes, not NuGet packages

## Resources

- **Partner Center:** https://partner.microsoft.com/dashboard
- **App Identity:** Partner Center ? Your App ? Product management ? Product identity
- **MSIX Packaging:** https://learn.microsoft.com/windows/msix/
- **Store Policies:** https://learn.microsoft.com/windows/apps/publish/store-policies

## Quick Reference

```powershell
# Build project (preparation)
.\CreateStorePackage.ps1 -Architectures x64,x86,ARM64

# Then use Visual Studio to create Store package:
# Right-click project ? Publish ? Create App Packages ? Microsoft Store

# Upload to Partner Center:
# https://partner.microsoft.com/dashboard
# ? MCBDS Manager ? Packages ? Upload new package
```

---

**Key Takeaway:** The identity mismatch happens because the package was signed with your development certificate (`CN=MC-BDS`) instead of letting Microsoft sign it with the Store certificate (`CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`). Always use Visual Studio's "Create App Packages" feature for Store submissions, and upload the `.msixupload` file.

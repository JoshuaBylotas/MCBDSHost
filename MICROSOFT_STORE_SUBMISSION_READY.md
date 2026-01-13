# MCBDS.PublicUI - Microsoft Store Submission Summary

## ? Issue Resolved

**Problem:** `Manifest file at 'obj\Release\net10.0\staticwebassets.build.json' not found.`

**Root Cause:** Referenced Razor class library (MCBDS.ClientUI.Shared) wasn't built before publishing.

**Solution Implemented:** 
1. Created automated build script (`BuildAndPublish.ps1`)
2. Updated project references to ensure proper build order
3. Created verification scripts

---

## ?? Project Structure

```
MCBDSHost/
??? MCBDS.ClientUI/
?   ??? MCBDS.ClientUI.Shared/          # Razor class library with static web assets
?       ??? obj/Release/net10.0/
?           ??? staticwebassets.build.json  # Generated during build
?
??? MCBDS.PublicUI/                      # .NET MAUI Blazor app
    ??? Platforms/Windows/Assets/        # Store assets
    ?   ??? Square44x44Logo.transparent.png
    ?   ??? Square71x71Logo.transparent.png
    ?   ??? Square150x150Logo.transparent.png
    ?   ??? Square310x310Logo.transparent.png
    ?   ??? Wide310x150Logo.transparent.png
    ?   ??? StoreLogo.transparent.png
    ?   ??? SplashScreen.transparent.png (+ scale variants)
    ??? Platforms/Windows/Package.appxmanifest
```

---

## ?? Build & Publish Workflow

### Option 1: Using Automated Script (Recommended)

```powershell
# Step 1: Verify readiness
.\PrePublishCheck.ps1 -Configuration Release

# Step 2: Build and create MSIX package
.\BuildAndPublish.ps1 -Configuration Release -CreatePackage

# Step 3: Package will be created in:
# MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64\*.msix
```

### Option 2: Using Visual Studio

1. **Build ? Rebuild Solution** (Ctrl+Shift+B)
2. Right-click **MCBDS.PublicUI**
3. Select **Publish ? Create App Packages**
4. Follow the wizard

### Option 3: Manual CLI

```powershell
# 1. Build shared library first
dotnet build MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj -c Release

# 2. Build main project
dotnet build MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release -f net10.0-windows10.0.19041.0

# 3. Publish
dotnet publish MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release -f net10.0-windows10.0.19041.0 -r win-x64 -p:WindowsPackageType=MSIX
```

---

## ?? Available Scripts

| Script | Purpose |
|--------|---------|
| `BuildAndPublish.ps1` | Automated build and package creation |
| `PrePublishCheck.ps1` | Verify all requirements before publishing |
| `VerifyStoreReadiness.ps1` | Complete readiness check for Store submission |
| `CreateMissingStoreAssets.ps1` | Generate missing Windows Store assets |

---

## ? Current Status

### Build Configuration
- ? Static web assets manifest: **Created**
- ? Shared library: **Built (Release)**
- ? Main project: **Built (Release)**
- ? Windows Store assets: **All present**
- ? Package manifest: **Updated**

### Package Information
- **App Name:** MCBDS Manager
- **Publisher:** Pinecrest Consultants
- **Package ID:** 50677PinecrestConsultants.MCBDSManager
- **Version:** 1.0.6.0
- **Certificate:** Configured (Thumbprint: B97A80AD152EF3F18075E8F6B31A219112319F2B)

---

## ?? Creating Store Package

### For x64 Architecture (Most Common)
```powershell
.\BuildAndPublish.ps1 -Configuration Release -RuntimeIdentifier win-x64 -CreatePackage
```

### For x86 Architecture (32-bit)
```powershell
.\BuildAndPublish.ps1 -Configuration Release -RuntimeIdentifier win-x86 -CreatePackage
```

### For ARM64 Architecture
```powershell
.\BuildAndPublish.ps1 -Configuration Release -RuntimeIdentifier win-arm64 -CreatePackage
```

---

## ?? Testing MSIX Package Locally

```powershell
# 1. Find your package
$package = Get-ChildItem "MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64\*.msix" | Select-Object -First 1

# 2. Install
Add-AppxPackage -Path $package.FullName

# 3. Launch from Start Menu
# Search for "MCBDS Manager"

# 4. Uninstall after testing
Get-AppxPackage *MCBDSManager* | Remove-AppxPackage
```

---

## ?? Microsoft Store Submission Checklist

### Technical Requirements
- ? MSIX package created
- ? Package signed with certificate
- ? All required assets included
- ? Manifest properly configured
- ? Package tested locally

### Store Listing Requirements
You'll also need to prepare:

1. **App Metadata**
   - App description (200-10,000 characters)
   - Release notes
   - Keywords

2. **Visual Assets for Store**
   - Screenshots (at least 1, recommended 4-5)
     - Size: 1366×768 or larger
   - Store logo (300×300)
   - Promotional images (optional)

3. **Legal Information**
   - Privacy policy URL (if app collects data)
   - Terms of service (optional)
   - Age rating
   - Support contact information

4. **Pricing & Availability**
   - Free or paid
   - Markets/regions
   - Release date

---

## ?? Troubleshooting

### Problem: "Manifest file not found" error

**Solution:**
```powershell
# Run the build script which ensures correct build order
.\BuildAndPublish.ps1 -Configuration Release
```

### Problem: Missing assets error

**Solution:**
```powershell
# Regenerate missing assets
.\CreateMissingStoreAssets.ps1
```

### Problem: Certificate error

**Solution:**
- Ensure certificate is installed in Windows Certificate Store
- Verify thumbprint in MCBDS.PublicUI.csproj matches installed certificate

---

## ?? Documentation Reference

| Document | Purpose |
|----------|---------|
| [MICROSOFT_STORE_ASSETS_SETUP.md](MICROSOFT_STORE_ASSETS_SETUP.md) | Complete assets setup guide |
| [STATIC_WEB_ASSETS_ERROR_GUIDE.md](STATIC_WEB_ASSETS_ERROR_GUIDE.md) | Detailed error resolution |
| This file | Quick reference and current status |

---

## ?? Next Steps

1. **Create the MSIX package:**
   ```powershell
   .\BuildAndPublish.ps1 -Configuration Release -CreatePackage
   ```

2. **Test locally:**
   - Install the MSIX package
   - Verify all features work
   - Test on different screen DPIs
   - Verify all assets display correctly

3. **Prepare store listing:**
   - Take screenshots
   - Write app description
   - Prepare privacy policy

4. **Submit to Microsoft Partner Center:**
   - Upload MSIX package
   - Complete store listing
   - Submit for certification

---

## ? Success Criteria

Your app is ready for store submission when:

- ? `PrePublishCheck.ps1` shows all checks passed
- ? MSIX package created successfully
- ? Package installs and runs locally without errors
- ? All assets display correctly in Windows Start Menu
- ? App functions as expected
- ? Store listing materials prepared

---

## ?? Support

For issues:
1. Run `PrePublishCheck.ps1` to diagnose problems
2. Check error messages in build output
3. Review [STATIC_WEB_ASSETS_ERROR_GUIDE.md](STATIC_WEB_ASSETS_ERROR_GUIDE.md)
4. Ensure all dependencies are built in same configuration

---

**Last Updated:** January 12, 2026  
**Status:** ? Ready for Microsoft Store Submission

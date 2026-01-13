# MSIX Package Creation for Microsoft Store - FIXED

## ? Issue Resolution

**Problem:** Assets were not being included in MSIX package, causing Partner Center validation error:
```
Package acceptance validation error: The following image(s) specified in the appxManifest.xml were not found: 
Assets\StoreLogo.transparent.png, Assets\Square44x44Logo.transparent.png, ...
```

**Root Cause:** Content items weren't configured with proper `<Link>` metadata for MSIX packaging.

**Solution Applied:** Updated `MCBDS.PublicUI.csproj` to:
1. Remove auto-included transparent PNG files
2. Explicitly re-add them with `<Link>` metadata pointing to `Assets\` directory

**Verification:** Run `.\VerifyMSIXAssets.ps1` - All assets now present ?

---

## ?? Creating MSIX Package for Microsoft Store

### Option 1: Visual Studio (Recommended for .NET 10)

1. **Open Solution** in Visual Studio 2022

2. **Build Solution** in Release mode:
   - Build ? Configuration Manager
   - Set Active solution configuration to **Release**
   - Build ? Rebuild Solution (Ctrl+Shift+B)

3. **Create App Package**:
   - Right-click **MCBDS.PublicUI** project
   - Select **Publish** ? **Create App Packages...**
   
4. **Package Wizard**:
   - Select **Microsoft Store using a new app name**
   - Sign in to Partner Center account
   - Select your app: **MCBDS Manager**
   - Click **Next**

5. **Package Configuration**:
   - **Architecture**: Select x64, x86, or ARM64 (or all)
   - **Configuration**: Release
   - **Include public symbol files**: Uncheck (unless needed)
   - **Version**: Will auto-increment
   - Click **Create**

6. **Package Location**:
   - Packages will be created in:
     ```
     MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_<version>_Test\
     ```

### Option 2: Manual Build (For Verification)

Since `dotnet publish` has package dependency issues with .NET 10, use this to build:

```powershell
# 1. Clean
dotnet clean MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release

# 2. Build (this creates assets in output)
dotnet build MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release -f net10.0-windows10.0.19041.0

# 3. Verify assets are included
.\VerifyMSIXAssets.ps1 -Configuration Release -RuntimeIdentifier win-x64

# 4. Use Visual Studio to create MSIX from the build
```

---

## ?? Verify Package Before Upload

### Extract and Inspect MSIX

```powershell
# Find the MSIX package
$package = Get-ChildItem "MCBDS.PublicUI\AppPackages" -Recurse -Filter "*.msix" | Select-Object -First 1

# Extract to temp folder
$extractPath = "C:\Temp\MSIXExtract"
New-Item -ItemType Directory -Path $extractPath -Force
Expand-Archive -Path "$($package.FullName -replace '\.msix$', '.zip')" -DestinationPath $extractPath

# Check Assets folder
Get-ChildItem "$extractPath\Assets\*.png"
```

### Verify Assets in Package

```powershell
# Run verification on extracted package
$assetsInPackage = Get-ChildItem "$extractPath\Assets" -Filter "*.transparent.png"

Write-Host "Assets in MSIX package:" -ForegroundColor Cyan
foreach ($asset in $assetsInPackage) {
    Write-Host "  ? $($asset.Name)" -ForegroundColor Green
}
```

---

## ? Pre-Upload Checklist

Before uploading to Partner Center:

- [ ] All builds completed successfully
- [ ] `.\VerifyMSIXAssets.ps1` shows all assets present
- [ ] MSIX package created via Visual Studio
- [ ] Package tested locally (install and run)
- [ ] All app tiles display correctly in Start Menu
- [ ] Version number incremented from previous submission
- [ ] Package signed with valid certificate

---

## ?? Upload to Microsoft Partner Center

1. **Go to Partner Center**:
   - Navigate to https://partner.microsoft.com/dashboard
   - Go to your app: **MCBDS Manager**

2. **Start New Submission**:
   - Click "Start update" or "Create new submission"

3. **Upload Packages**:
   - Go to **Packages** section
   - Drag and drop your MSIX file(s)
   - Wait for validation (should pass now with assets included)

4. **Review Validation**:
   - ? Should see: "Package acceptance validation passed"
   - ? Warning about `runFullTrust` capability is expected (approval needed)

5. **Complete Store Listing**:
   - Fill in any required store listing information
   - Add screenshots if needed
   - Update release notes

6. **Submit for Certification**:
   - Review all sections
   - Click "Submit to the Store"

---

## ?? Troubleshooting

### Issue: Assets still not found after rebuild

**Solution:**
```powershell
# 1. Clean everything
Remove-Item "MCBDS.PublicUI\bin" -Recurse -Force
Remove-Item "MCBDS.PublicUI\obj" -Recurse -Force

# 2. Rebuild with Visual Studio
# (Build ? Rebuild Solution)

# 3. Verify
.\VerifyMSIXAssets.ps1
```

### Issue: Package validation fails with different error

Check build output logs:
```powershell
# Check for warnings during build
Get-Content "MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64\*.log"
```

### Issue: runFullTrust capability warning

This is **expected** for .NET MAUI apps. It requires special approval from Microsoft:

1. On Partner Center, submit the package
2. Microsoft will review the `runFullTrust` capability
3. Provide business justification if requested
4. Approval usually granted for legitimate desktop apps

---

## ?? Current Status

### Build Output Verification (Latest)

```
? All required assets present in build output:
   - StoreLogo.transparent.png (20.2 KB)
   - Square44x44Logo.transparent.png (4.5 KB)
   - Square71x71Logo.transparent.png (5.1 KB)
   - Square150x150Logo.transparent.png (15.5 KB)
   - Square310x310Logo.transparent.png (35.9 KB)
   - Wide310x150Logo.transparent.png (22.2 KB)
   - SplashScreen.transparent.png (52.5 KB)
   + 4 splash screen scale variants

? Assets properly referenced in AppxManifest.xml
? All files present in build output Assets\ directory
```

### Project Configuration

**File**: `MCBDS.PublicUI\MCBDS.PublicUI.csproj`

**Key Changes:**
- Removed auto-included Content items for transparent PNGs
- Explicitly added them with `<Link>Assets\[filename]</Link>` metadata
- This ensures they're placed in `Assets\` directory in MSIX package

---

## ?? Notes

- **Visual Studio is required** for packaging due to .NET 10 SDK limitations
- **Assets must have Link metadata** to be included in MSIX at correct path
- **Verification script** confirms assets before packaging
- **runFullTrust capability** is normal for .NET MAUI Windows apps

---

## ? Success Indicators

Your package is ready when:

1. ? `.\VerifyMSIXAssets.ps1` shows all checks passed
2. ? MSIX package created successfully
3. ? Package installs locally without errors
4. ? App launches and all tiles display correctly
5. ? Partner Center validation passes (no asset errors)

---

**Last Updated:** January 12, 2026  
**Status:** ? Assets fixed and verified in build output  
**Next Step:** Create MSIX package using Visual Studio

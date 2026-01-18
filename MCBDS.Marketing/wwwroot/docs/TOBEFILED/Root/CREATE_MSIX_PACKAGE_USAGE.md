# CreateMSIXPackage.ps1 - Usage Guide

## Quick Reference

### For Microsoft Store Submission (UNSIGNED)

```powershell
.\CreateMSIXPackage.ps1 -ForStore
```

Creates an **unsigned** MSIX package ready for Microsoft Store upload. This is the **recommended** approach for Store submission.

**Output:**
- `AppPackages\MCBDS.PublicUI_{version}_x64.msix` (unsigned)
- Ready to upload to Partner Center
- Microsoft will sign it during certification

---

### For Local Testing (SIGNED)

```powershell
.\CreateMSIXPackage.ps1 -Sign
```

Creates a **signed** MSIX package for local installation and testing.

**Output:**
- `AppPackages\MCBDS.PublicUI_{version}_x64.msix` (signed with dev cert)
- Can be installed with `Add-AppxPackage`
- Uses development certificate (`CN=MC-BDS`)

---

### For Local Testing (UNSIGNED)

```powershell
.\CreateMSIXPackage.ps1
```

Creates an **unsigned** MSIX package. You'll need to install the certificate separately.

**Output:**
- `AppPackages\MCBDS.PublicUI_{version}_x64.msix` (unsigned)
- Requires certificate installation before use

---

## All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Configuration` | String | `Release` | Build configuration (Debug or Release) |
| `-Architecture` | String | `x64` | Target architecture (x86, x64, ARM64) |
| `-ForStore` | Switch | Off | Create unsigned package for Microsoft Store |
| `-Sign` | Switch | Off | Sign package with development certificate |
| `-SkipVersionIncrement` | Switch | Off | Keep current version (don't auto-increment) |

---

## Common Scenarios

### Scenario 1: First-time Store Submission

```powershell
# Create unsigned package for Store
.\CreateMSIXPackage.ps1 -ForStore

# Upload to Partner Center:
# https://partner.microsoft.com/dashboard
```

### Scenario 2: Local Testing Before Store Submission

```powershell
# Create signed package for local testing
.\CreateMSIXPackage.ps1 -Sign

# Install and test
Add-AppxPackage -Path "AppPackages\MCBDS.PublicUI_1.0.17.0_x64.msix"

# When ready, create Store package
.\CreateMSIXPackage.ps1 -ForStore -SkipVersionIncrement
```

### Scenario 3: Multi-Architecture Build

```powershell
# Build for x64
.\CreateMSIXPackage.ps1 -ForStore -Architecture x64

# Build for x86 (without incrementing version)
.\CreateMSIXPackage.ps1 -ForStore -Architecture x86 -SkipVersionIncrement

# Build for ARM64 (without incrementing version)
.\CreateMSIXPackage.ps1 -ForStore -Architecture ARM64 -SkipVersionIncrement
```

### Scenario 4: Debug Build for Testing

```powershell
# Create signed debug build
.\CreateMSIXPackage.ps1 -Configuration Debug -Sign
```

---

## Important Notes

### ?? ForStore vs Sign

**You cannot use both `-ForStore` and `-Sign` together.** The script will show an error:

```
ERROR: Cannot use -ForStore and -Sign together
Store packages should NOT be signed manually.
Microsoft will sign them during certification.
```

**Why?**
- **Store packages** should be **unsigned** so Microsoft can sign them with the Store certificate
- **Local packages** should be **signed** with your dev certificate so you can install them

### ? Store Identity Verification

When using `-ForStore`, the script checks if your `Package.appxmanifest` has the correct Store identity:

```xml
<Identity 
  Name="50677PinecrestConsultants.MCBDSManager" 
  Publisher="CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289" 
  Version="1.0.17.0" />
```

If the Publisher doesn't match the expected Store format, you'll get a warning with instructions to fix it.

### ?? Version Auto-Increment

By default, the script **automatically increments** the last digit of the version:

- Current: `1.0.17.0`
- After script: `1.0.17.1`

Use `-SkipVersionIncrement` to keep the current version (useful for multi-architecture builds).

---

## What the Script Does

### Step-by-Step Process

1. **Validates parameters** - Ensures -ForStore and -Sign aren't used together
2. **Finds Windows SDK** - Locates MakeAppx.exe and SignTool.exe
3. **Builds project** - Runs `BuildAndPublish.ps1` to compile
4. **Finds build output** - Locates compiled files
5. **Updates version** - Increments version (unless -SkipVersionIncrement)
6. **Verifies Store identity** - Checks manifest (if -ForStore)
7. **Stages files** - Copies files to staging directory
8. **Creates MSIX** - Uses MakeAppx.exe to create package
9. **Signs package** - Uses SignTool.exe (if -Sign)
10. **Shows summary** - Displays next steps

---

## Comparison: Command-Line vs Visual Studio

| Feature | CreateMSIXPackage.ps1 | Visual Studio UI |
|---------|---------------------|------------------|
| **Single architecture** | ? Yes | ? Yes |
| **Multi-architecture bundle** | ? No (manual) | ? Yes (automatic) |
| **Creates .msixupload** | ? No | ? Yes |
| **Store signing** | ? Unsigned | ? Proper Store signing |
| **Speed** | ? Fast | ?? Slower |
| **Flexibility** | ? High | ?? Limited |
| **Best for** | Testing, single arch | Store submission |

### Recommendation

- **For Store submission:** Use **Visual Studio** ? Create App Packages ? Microsoft Store
  - Creates proper `.msixupload` bundle
  - Handles multi-architecture automatically
  - Proper Store signing workflow

- **For local testing:** Use **CreateMSIXPackage.ps1 -Sign**
  - Faster than Visual Studio
  - Good for quick iterations
  - Can test specific architectures

---

## Output Files

After running the script, you'll find:

```
AppPackages\
??? MCBDS.PublicUI_1.0.17.0\
    ??? MCBDS.PublicUI_1.0.17.0_x64.msix  ? Your package
```

### File Details

- **Unsigned (ForStore):** ~50-200 MB
- **Signed:** ~50-200 MB (same size, just signed)

---

## Troubleshooting

### Error: "Windows SDK not found"

**Solution:** Install Windows SDK
```
https://developer.microsoft.com/windows/downloads/windows-sdk/
```

### Error: "Build output not found"

**Solution:** Check build logs, ensure project compiles
```powershell
.\BuildAndPublish.ps1 -Configuration Release
```

### Error: "Certificate not found" (when using -Sign)

**Solution:** Install or create development certificate
```powershell
# Check if certificate exists
Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq "B97A80AD152EF3F18075E8F6B31A219112319F2B" }

# If not found, create in Visual Studio:
# Right-click project ? Properties ? Package ? Choose Certificate ? Create Test Certificate
```

### Warning: "Publisher doesn't look like a Store identity"

**Solution:** Associate app with Store in Visual Studio
1. Right-click project ? Publish ? Associate App with the Store
2. Sign in to Partner Center
3. Select "MCBDS Manager"

---

## Related Scripts

| Script | Purpose |
|--------|---------|
| `CreateMSIXPackage.ps1` | Create MSIX (this script) |
| `CreateStorePackage.ps1` | Build preparation for Store |
| `IncrementPackageVersion.ps1` | Update version manually |
| `InstallCertAndMSIX.ps1` | Install certificate and package |
| `BuildAndPublish.ps1` | Build project only |

---

## Examples

### Example 1: Simple Store Package

```powershell
PS> .\CreateMSIXPackage.ps1 -ForStore

????????????????????????????????????????????????????
  Create MSIX Package - FOR MICROSOFT STORE
????????????????????????????????????????????????????

?? Package Type: Microsoft Store Submission (UNSIGNED)
   Microsoft will sign this during certification

? Windows SDK: 10.0.22621.0

Step 1: Building project...
? Build complete

Step 2: Found build output
  MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64

Step 3: Updating version...
  Old: 1.0.17.0
  New: 1.0.17.1
? Version: 1.0.17.1

Step 4: Verifying Store identity...
  Package Name: 50677PinecrestConsultants.MCBDSManager
  Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
? Store identity looks correct

Step 5: Staging files...
? Files staged

Step 6: Creating MSIX...
  Creating UNSIGNED package (for Store submission)...
? MSIX created

Step 6: Skipping signing (Store packages should be unsigned)
  ??  Microsoft will sign this package during certification

????????????????????????????????????????????????????
  ? Package Created Successfully!
????????????????????????????????????????????????????

?? Package: AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix
?? Size: 152.34 MB
```

### Example 2: Signed Testing Package

```powershell
PS> .\CreateMSIXPackage.ps1 -Sign

????????????????????????????????????????????????????
  Create MSIX Package - FOR LOCAL TESTING
????????????????????????????????????????????????????

?? Package Type: Local Testing (SIGNED)
   Will be signed with development certificate

# ... build steps ...

Step 7: Signing...
  Certificate found: CN=MC-BDS
  Thumbprint: B97A80AD152EF3F18075E8F6B31A219112319F2B
? Package signed successfully

????????????????????????????????????????????????????
  NEXT STEPS: Install and Test
????????????????????????????????????????????????????

To install:
  Add-AppxPackage -Path 'AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix'
```

---

## Summary

| Use Case | Command | Output |
|----------|---------|--------|
| **Store submission** | `.\CreateMSIXPackage.ps1 -ForStore` | Unsigned .msix |
| **Local testing** | `.\CreateMSIXPackage.ps1 -Sign` | Signed .msix |
| **Multi-arch for Store** | Visual Studio UI | .msixupload bundle |

**Key Point:** For Store submission, the script creates an **unsigned** package. Microsoft signs it during certification with the correct Store certificate, which ensures the Package Family Name matches what they expect.

# SOLUTION: CreateMSIXPackage.ps1 Updated for Store Submission

## What Changed

I've updated `CreateMSIXPackage.ps1` to support **unsigned packages** for Microsoft Store submission, solving your identity mismatch issue.

---

## Key Changes

### ? New Parameter: `-ForStore`

Creates an **unsigned** MSIX package suitable for Microsoft Store submission.

```powershell
.\CreateMSIXPackage.ps1 -ForStore
```

**What it does:**
- Builds the project
- Creates MSIX package
- **Does NOT sign** the package
- Verifies Store identity in manifest
- Auto-increments version
- Shows Store-specific next steps

### ? New Parameter: `-Sign`

Creates a **signed** MSIX package for local testing.

```powershell
.\CreateMSIXPackage.ps1 -Sign
```

**What it does:**
- Builds the project
- Creates MSIX package
- **Signs with development certificate** (`CN=MC-BDS`)
- Auto-increments version
- Shows installation instructions

### ? Safety Check

The script prevents you from accidentally signing Store packages:

```powershell
.\CreateMSIXPackage.ps1 -ForStore -Sign
# ERROR: Cannot use -ForStore and -Sign together
```

### ? Store Identity Verification

When using `-ForStore`, the script checks your manifest:

```
Step 4: Verifying Store identity...
  Package Name: 50677PinecrestConsultants.MCBDSManager
  Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
? Store identity looks correct
```

If the Publisher doesn't match Store format, it warns you with fix instructions.

---

## Usage Examples

### For Microsoft Store Submission

```powershell
# Create unsigned package for Store
.\CreateMSIXPackage.ps1 -ForStore

# Output: AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix (UNSIGNED)
# Upload to: https://partner.microsoft.com/dashboard
```

### For Local Testing

```powershell
# Create signed package for testing
.\CreateMSIXPackage.ps1 -Sign

# Install:
Add-AppxPackage -Path "AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix"
```

### Skip Version Increment (Multi-Architecture)

```powershell
# Build x64
.\CreateMSIXPackage.ps1 -ForStore -Architecture x64

# Build x86 (same version)
.\CreateMSIXPackage.ps1 -ForStore -Architecture x86 -SkipVersionIncrement

# Build ARM64 (same version)
.\CreateMSIXPackage.ps1 -ForStore -Architecture ARM64 -SkipVersionIncrement
```

---

## What This Solves

### The Problem
Your original MSIX package was **signed with development certificate** (`CN=MC-BDS`), which created the wrong Package Family Name (`_47q1101p6hvwy`) instead of the Store's expected name (`_n8ws8gp0q633w`).

### The Solution
Using `-ForStore` creates an **unsigned** package. When you upload to Partner Center, **Microsoft signs it** during certification with the correct Store certificate, creating the right Package Family Name.

---

## Comparison: Before vs After

| Aspect | Before (Old Script) | After (New Script) |
|--------|-------------------|-------------------|
| **Default behavior** | Always signs | No signing by default |
| **Store packages** | Signed (wrong) | Unsigned (correct) |
| **Local testing** | Signed | Optional with `-Sign` |
| **Identity check** | None | Verifies Store identity |
| **Safety** | Could sign Store packages | Prevents `-ForStore -Sign` |
| **Guidance** | Generic | Context-specific |

---

## Parameters Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Configuration` | String | `Release` | Build configuration |
| `-Architecture` | String | `x64` | Target architecture (x86, x64, ARM64) |
| **`-ForStore`** | Switch | Off | **Create unsigned package for Store** |
| **`-Sign`** | Switch | Off | **Sign package with dev certificate** |
| `-SkipVersionIncrement` | Switch | Off | Keep current version |

---

## Workflow: Command-Line Store Submission

### Step 1: Increment Version (if needed)

```powershell
.\IncrementPackageVersion.ps1
```

### Step 2: Create Store Package

```powershell
.\CreateMSIXPackage.ps1 -ForStore
```

### Step 3: Upload to Partner Center

1. Go to https://partner.microsoft.com/dashboard
2. Navigate to MCBDS Manager
3. Go to Packages section
4. Upload: `AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix`

### Step 4: Complete Submission

- Verify identity (should match now!)
- Complete all submission sections
- Submit for certification

---

## When to Use Each Method

### Use `CreateMSIXPackage.ps1 -ForStore` When:
- ? You want command-line workflow
- ? Building single architecture
- ? Quick iteration for Store testing
- ? Scripting/automation

### Use Visual Studio UI When:
- ? Need multi-architecture bundle (.msixupload)
- ? First-time Store submission
- ? Want automatic Store association
- ? Prefer GUI over command-line

---

## File Structure

After running the script:

```
MCBDSHost\
??? CreateMSIXPackage.ps1          ? Updated script
??? CREATE_MSIX_PACKAGE_USAGE.md   ? Detailed usage guide
??? AppPackages\
    ??? MCBDS.PublicUI_1.0.17.1\
        ??? MCBDS.PublicUI_1.0.17.1_x64.msix  ? Your package
```

---

## Related Documentation

| File | Purpose |
|------|---------|
| `CREATE_MSIX_PACKAGE_USAGE.md` | Detailed usage guide for this script |
| `QUICK_FIX_STORE_IDENTITY.md` | 2-minute quick fix summary |
| `STORE_SUBMISSION_CHECKLIST.md` | Complete submission checklist |
| `MSIX_IDENTITY_MISMATCH_FIX.md` | Technical explanation of the issue |
| `PACKAGE_IDENTITY_VISUAL_GUIDE.md` | Visual diagrams and comparisons |
| `HOW_TO_CREATE_MSIX_PACKAGE.md` | General MSIX creation guide |

---

## Quick Test

Test the updated script:

```powershell
# Test Store package creation (unsigned)
.\CreateMSIXPackage.ps1 -ForStore -SkipVersionIncrement

# Check it's unsigned
$package = Get-AppxPackageManifest -Path "AppPackages\MCBDS.PublicUI_1.0.17.0\MCBDS.PublicUI_1.0.17.0_x64.msix"
# Should succeed (package is valid but unsigned)
```

---

## Summary

? **Script updated** to support unsigned packages  
? **`-ForStore` parameter** creates Store-ready packages  
? **`-Sign` parameter** creates test packages  
? **Safety checks** prevent signing Store packages  
? **Identity verification** warns if manifest is wrong  
? **Context-specific guidance** shows next steps  

**Result:** You can now create proper unsigned MSIX packages for Store submission directly from the command line, avoiding the identity mismatch issue!

---

## Next Steps

1. **Test the script:**
   ```powershell
   .\CreateMSIXPackage.ps1 -ForStore
   ```

2. **Upload to Partner Center:**
   - Go to https://partner.microsoft.com/dashboard
   - Upload the unsigned package

3. **Submit for certification:**
   - Microsoft will sign it with Store certificate
   - Package Family Name will be correct
   - Certification should pass ?

**The identity mismatch is now fixed!** ??

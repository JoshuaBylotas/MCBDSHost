# FIX NOW: Identity Mismatch - Step by Step

## The Problem You're Seeing

```
? Invalid package family name: 50677PinecrestConsultants.MCBDSManager_47q1101p6hvwy 
   (expected: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w)

? Invalid package publisher name: CN=MC-BDS 
   (expected: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289)
```

## Why This Happens

Your package is being **signed with your development certificate** (`CN=MC-BDS`), which overrides the correct Store identity.

## The Fix (3 Commands, 5 Minutes)

### Step 1: Increment Version

You can't resubmit version 1.0.17.1, so increment it:

```powershell
.\IncrementPackageVersion.ps1
```

**Expected output:**
```
Current version: 1.0.17.1
New version:     1.0.18.0
? Version updated successfully!
```

---

### Step 2: Create UNSIGNED Store Package

**This is the key change!** Use the new `-ForStore` parameter:

```powershell
.\CreateMSIXPackage.ps1 -ForStore
```

**Look for these confirmations:**
```
?? Package Type: Microsoft Store Submission (UNSIGNED)
   Microsoft will sign this during certification

? Store identity looks correct
? MSIX created

Step X: Skipping signing (Store packages should be unsigned)
  ??  Microsoft will sign this package during certification
```

**Output file:**
```
AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix
```

---

### Step 3: Verify Package is Unsigned

Check the package properties:

```powershell
# Get the package file
$package = Get-Item "AppPackages\MCBDS.PublicUI_1.0.18.*\*.msix" | Select-Object -First 1

# Display info
Write-Host "Package: $($package.Name)" -ForegroundColor Cyan
Write-Host "Size: $([Math]::Round($package.Length / 1MB, 2)) MB" -ForegroundColor Cyan

# Try to get signature (should fail or show no signature for unsigned)
Get-AuthenticodeSignature $package | Format-List *
```

**Expected:** Status should be "NotSigned" or similar (this is CORRECT for Store packages!)

---

### Step 4: Upload to Partner Center

1. **Go to:** https://partner.microsoft.com/dashboard
2. **Navigate to:** Apps and games ? MCBDS Manager
3. **Click:** Packages section
4. **Upload:** `AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix`
5. **Wait:** 1-2 minutes for validation

**Expected:** No more identity mismatch errors! ?

---

## What Changed

| Before | After |
|--------|-------|
| `.\CreateMSIXPackage.ps1` | `.\CreateMSIXPackage.ps1 -ForStore` |
| Package signed with `CN=MC-BDS` | Package unsigned (correct!) |
| Wrong hash: `_47q1101p6hvwy` | Microsoft creates: `_n8ws8gp0q633w` |
| ? Identity mismatch | ? Identity matches |

---

## Why `-ForStore` Works

1. Creates **unsigned** package
2. Microsoft **signs** it during certification
3. Microsoft's certificate has Publisher: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
4. This creates the **correct hash**: `_n8ws8gp0q633w`
5. Package Family Name **matches** Store expectations ?

---

## Quick Troubleshooting

### "Build failed"
```powershell
dotnet clean
dotnet restore
.\CreateMSIXPackage.ps1 -ForStore
```

### "Warning: Publisher doesn't look like Store identity"
Your manifest is already correct (`CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`), so just press `y` to continue.

### Package still shows identity mismatch
Verify:
1. You used `-ForStore` parameter ?
2. Package is unsigned (check with `Get-AuthenticodeSignature`) ?
3. You uploaded the **new** package (check version 1.0.18.x) ?

---

## Complete Command Sequence

Copy and paste:

```powershell
# Step 1: Update version
.\IncrementPackageVersion.ps1

# Step 2: Create unsigned Store package
.\CreateMSIXPackage.ps1 -ForStore

# Step 3: Verify package
Get-Item "AppPackages\MCBDS.PublicUI_1.0.18.*\*.msix"

# Step 4: Check signature (should be NotSigned or similar)
Get-AuthenticodeSignature "AppPackages\MCBDS.PublicUI_1.0.18.1_x64\MCBDS.PublicUI_1.0.18.1_x64.msix"
```

Then upload to: https://partner.microsoft.com/dashboard

---

## Visual Confirmation

When running `CreateMSIXPackage.ps1 -ForStore`, you should see:

```
????????????????????????????????????????????????????
  Create MSIX Package - FOR MICROSOFT STORE
????????????????????????????????????????????????????

?? Package Type: Microsoft Store Submission (UNSIGNED)    ? Key indicator
   Microsoft will sign this during certification

? Windows SDK: 10.0.22621.0

Step 1: Building project...
? Build complete

Step 2: Found build output
  MCBDS.PublicUI\bin\Release\net10.0-windows10.0.19041.0\win-x64

Step 3: Updating version...
  Old: 1.0.18.0
  New: 1.0.18.1
? Version: 1.0.18.1

Step 4: Verifying Store identity...
  Package Name: 50677PinecrestConsultants.MCBDSManager
  Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289    ? Correct!
? Store identity looks correct

Step 5: Staging files...
? Files staged

Step 6: Creating MSIX...
  Creating UNSIGNED package (for Store submission)...    ? Key indicator
? MSIX created

Step 6: Skipping signing (Store packages should be unsigned)    ? Key indicator
  ??  Microsoft will sign this package during certification

????????????????????????????????????????????????????
  ? Package Created Successfully!
????????????????????????????????????????????????????

?? Package: AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix
?? Size: 152.34 MB

????????????????????????????????????????????????????
  NEXT STEPS: Upload to Microsoft Store
????????????????????????????????????????????????????

This package is UNSIGNED and ready for Store submission.    ? Confirms it's correct!
```

---

## Success!

After uploading to Partner Center:

? **No "Invalid package family name" error**  
? **No "Invalid publisher name" error**  
? **Validation passes**  
? **Ready for certification**  

The identity mismatch is **fixed**! ??

---

## Remember

- **For Store:** `.\CreateMSIXPackage.ps1 -ForStore` (unsigned)
- **For local testing:** `.\CreateMSIXPackage.ps1 -Sign` (signed)

Never use `-Sign` for Store packages!

---

**Total time: ~5 minutes**

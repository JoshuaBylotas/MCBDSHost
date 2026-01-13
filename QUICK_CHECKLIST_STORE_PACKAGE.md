# Quick Checklist: Create Store Package with CreateMSIXPackage.ps1

## ? Fast Track (5 minutes)

Follow these steps to create and submit your Store package:

---

### ? Step 1: Update Version (30 seconds)

```powershell
.\IncrementPackageVersion.ps1
```

**Expected output:**
```
Current version: 1.0.16.1
New version:     1.0.17.0
? Version updated successfully!
```

---

### ? Step 2: Create Store Package (2-5 minutes)

```powershell
.\CreateMSIXPackage.ps1 -ForStore
```

**What to look for:**
```
? Windows SDK: 10.0.22621.0
? Build complete
? Version: 1.0.17.1
? Store identity looks correct
? Files staged
? MSIX created
```

**Output file:**
```
AppPackages\MCBDS.PublicUI_1.0.17.1_x64.msix
```

---

### ? Step 3: Verify Package (30 seconds)

Check the file was created:

```powershell
Get-Item "AppPackages\MCBDS.PublicUI_1.0.17.*\*.msix"
```

**Expected:**
```
Directory: C:\...\AppPackages\MCBDS.PublicUI_1.0.17.1

Mode     Length          Name
----     ------          ----
-a----   150-200 MB      MCBDS.PublicUI_1.0.17.1_x64.msix
```

---

### ? Step 4: Upload to Partner Center (2 minutes)

1. Go to: https://partner.microsoft.com/dashboard
2. Click **Apps and games**
3. Click **MCBDS Manager**
4. Click **Packages** section
5. Click **Upload packages**
6. Drag and drop: `MCBDS.PublicUI_1.0.17.1_x64.msix`
7. Wait for validation (1-2 minutes)

---

### ? Step 5: Verify Upload (30 seconds)

Check Partner Center shows:

```
? Package name: 50677PinecrestConsultants.MCBDSManager
? Publisher: CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289
? Version: 1.0.17.1
? Device family: Desktop
? Architecture: x64
```

---

### ? Step 6: Complete Submission (1-2 minutes)

1. Review all sections have ? green checkmarks
2. Update **Store listing** > What's new:
   ```
   Bug fixes and performance improvements
   ```
3. Add **Notes for certification**:
   ```
   Resubmission with corrected package identity.
   Package is properly prepared for Store distribution.
   ```
4. Click **Submit to the Store**

---

### ? Step 7: Monitor Certification (24-72 hours)

You'll receive emails for:
- Certification started
- Certification passed ?
- App published

Check status at: https://partner.microsoft.com/dashboard

---

## ? Success Criteria

You'll know it worked when:

? Package uploads without "Invalid package family name" error  
? Package uploads without "Invalid publisher name" error  
? Partner Center validation passes  
? Certification starts automatically  
? Within 24-72 hours, certification passes  
? App is published to Microsoft Store  

---

## ?? Troubleshooting

### Issue: Build fails

```powershell
# Try cleaning first
dotnet clean
dotnet restore
.\CreateMSIXPackage.ps1 -ForStore
```

### Issue: "Certificate not found" error

**Expected!** When using `-ForStore`, the package should be unsigned. This is correct.

### Issue: "Publisher doesn't look like Store identity"

```powershell
# Fix in Visual Studio:
# 1. Right-click project ? Publish ? Associate App with the Store
# 2. Sign in to Partner Center
# 3. Select "MCBDS Manager"
```

### Issue: Upload validation fails with identity mismatch

**Should NOT happen** with this script. If it does:
1. Check Package.appxmanifest has correct Store identity
2. Verify you used `-ForStore` parameter
3. Ensure package is unsigned (no "Signed" in properties)

---

## ?? Alternative: Visual Studio (Multi-Architecture)

For multi-architecture bundle:

1. Open Visual Studio
2. Right-click **MCBDS.PublicUI** project
3. **Publish** ? **Create App Packages...**
4. Choose **Microsoft Store**
5. Select **MCBDS Manager**
6. Configure: ? x64, ? x86, ? ARM64
7. Generate app bundle: **Always**
8. Click **Create**
9. Upload `.msixupload` file to Partner Center

---

## ?? Comparison

| Method | Time | Architectures | File Type | Best For |
|--------|------|---------------|-----------|----------|
| **CreateMSIXPackage.ps1** | 5 min | Single | .msix | Quick iterations |
| **Visual Studio UI** | 15 min | Multiple | .msixupload | Final submission |

---

## ?? Total Time Estimate

- Step 1: 30 seconds
- Step 2: 2-5 minutes
- Step 3: 30 seconds
- Step 4: 2 minutes
- Step 5: 30 seconds
- Step 6: 1-2 minutes
- **Total Active Time: ~7-11 minutes**
- Step 7: 24-72 hours (waiting)

---

## ?? Notes

- **Package is UNSIGNED** - This is correct! Microsoft signs it during certification.
- **Single architecture (x64)** - Fine for most users. Use Visual Studio for multi-arch.
- **Version auto-increments** - Script bumps last digit automatically.
- **Store identity verified** - Script checks manifest matches Partner Center.

---

## ? That's It!

You're now ready to submit to Microsoft Store using the command line. The identity mismatch issue is resolved because the package is properly unsigned, allowing Microsoft to sign it with the correct Store certificate during certification.

**Good luck! ??**

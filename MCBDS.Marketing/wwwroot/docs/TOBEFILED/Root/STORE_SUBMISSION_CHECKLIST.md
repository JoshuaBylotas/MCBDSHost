# Store Submission Checklist - Fix Identity Mismatch

## ? Complete This Checklist

Follow these steps in order to fix the package identity mismatch and successfully submit to Microsoft Store.

---

### Step 1: Increment Package Version ?? 30 seconds

**Why:** You cannot resubmit version `1.0.16.1` - it was already rejected.

**Action:** Run this PowerShell script:

```powershell
.\IncrementPackageVersion.ps1
```

**Expected Output:**
```
Current version: 1.0.16.1
New version:     1.0.17.0
? Version updated successfully!
```

**Manual Alternative:**
1. Open: `MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest`
2. Find: `Version="1.0.16.1"`
3. Change to: `Version="1.0.17.0"`
4. Save the file

- [ ] **DONE:** Version incremented to 1.0.17.0

---

### Step 2: Open Visual Studio ?? 1 minute

**Action:**
1. Launch **Visual Studio 2026**
2. Open: `MCBDSHost.sln`
3. Wait for solution to load
4. In Solution Explorer, locate the **MCBDS.PublicUI** project

- [ ] **DONE:** Solution open in Visual Studio

---

### Step 3: Create Store Package ?? 5-15 minutes

**Action:**

1. **Right-click** the `MCBDS.PublicUI` project in Solution Explorer

2. Select **Publish** ? **Create App Packages...**

3. In the wizard, choose:
   - ?? **Microsoft Store under a new app name**
   - OR select existing: **MCBDS Manager**

4. Click **Next**

5. **Sign in** with your Microsoft Partner Center account
   - Email: [Your Partner Center email]
   - Password: [Your Partner Center password]

6. Select your app from the dropdown:
   - **MCBDS Manager** (50677PinecrestConsultants.MCBDSManager)

7. Click **Next**

8. Configure package settings:

   **Version Information:**
   - Version: Should show `1.0.17.0` ?
   - If not, go back and verify Step 1

   **Select and Configure Packages:**
   - ?? **x64** (64-bit Windows - Required)
   - ?? **x86** (32-bit Windows - Recommended)
   - ?? **ARM64** (ARM devices - Recommended)

   **Bundle Options:**
   - Generate app bundle: **Always** ??
   - Include public symbol files: **Checked** ?? (helps with crash diagnostics)

9. Click **Create**

10. **Wait** for the build to complete (5-15 minutes)
    - Visual Studio will show build progress
    - Don't close Visual Studio during this time
    - You can continue working on other things

11. When complete, Visual Studio will show a success message and open the output folder

- [ ] **DONE:** Store package created successfully

---

### Step 4: Locate the Upload File ?? 30 seconds

**Action:**

The package will be in:
```
MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.17.0_Test\
```

**Look for this specific file:**
```
MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload
```

**File Details:**
- ? Extension: `.msixupload` (NOT `.msix`)
- ? Size: Typically 100-500 MB (multi-architecture bundle)
- ? Name includes all architectures: `_x64_x86_ARM64`

**What NOT to upload:**
- ? `MCBDS.PublicUI_1.0.17.0_x64.msix` (individual architecture - for testing only)
- ? `MCBDS.PublicUI_1.0.17.0_x86.msix` (individual architecture - for testing only)
- ? `MCBDS.PublicUI_1.0.17.0_ARM64.msix` (individual architecture - for testing only)

- [ ] **DONE:** Found the `.msixupload` file

---

### Step 5: Test Package Locally (Optional) ?? 5 minutes

**Why:** Verify the package works before submitting to Store.

**Action:**

```powershell
# Extract the upload bundle
Expand-Archive "MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.17.0_Test\MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload" -DestinationPath ".\test-package"

# Install the test version (x64)
Add-AppxPackage -Path ".\test-package\MCBDS.PublicUI_1.0.17.0_x64.msix"

# Launch the app from Start Menu
# Search for: "MCBDS Manager"
# Test basic functionality

# Uninstall after testing
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage

# Clean up
Remove-Item ".\test-package" -Recurse -Force
```

**Note:** The test version is signed with your dev certificate, which is fine for local testing. Microsoft will re-sign it with the Store certificate during certification.

- [ ] **DONE (Optional):** Package tested locally

---

### Step 6: Upload to Partner Center ?? 2-5 minutes

**Action:**

1. Go to: **https://partner.microsoft.com/dashboard**

2. Sign in with your Partner Center account

3. Navigate to **Apps and games**

4. Click on **MCBDS Manager**

5. Click **Start your submission** (or **Update** if this is an update)

6. Go to the **Packages** section

7. Click **Upload packages**

8. **Drag and drop** or browse to:
   ```
   MCBDS.PublicUI_1.0.17.0_x64_x86_ARM64.msixupload
   ```

9. Wait for **validation** (2-5 minutes)
   - Partner Center will analyze the package
   - Check for errors
   - Verify identity matches

10. **Verify** the upload:
    - ? Package name: `50677PinecrestConsultants.MCBDSManager`
    - ? Publisher: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
    - ? Version: `1.0.17.0`
    - ? Device family: Desktop
    - ? Architectures: x64, x86, ARM64

- [ ] **DONE:** Package uploaded and validated successfully

---

### Step 7: Complete Submission ?? 5-10 minutes

**Action:**

1. Review all submission sections (ensure green checkmarks):
   - ? Pricing and availability
   - ? Properties
   - ? Age ratings
   - ? **Packages** (just uploaded)
   - ? Store listings
   - ? Submission options

2. Update **Store listing** if needed:
   - What's new in this version:
     ```
     Bug fixes and performance improvements
     ```

3. Add **Notes for certification** (optional but helpful):
   ```
   This is a resubmission to fix package identity issues.
   Package is now correctly prepared for Store distribution.
   All functionality remains the same as previous submission.
   ```

4. Click **Review and submit**

5. Review the summary

6. Click **Submit to the Store**

7. **Confirmation:**
   - You'll see a "Submission in progress" message
   - You'll receive an email confirmation

- [ ] **DONE:** Submission completed

---

### Step 8: Monitor Certification ?? 24-72 hours

**Action:**

1. Go to Partner Center ? MCBDS Manager

2. Check **Submission progress**:
   - ?? **In progress** - Being reviewed
   - ?? **In the Store** - Published ?
   - ?? **Failed** - Issues found

3. **You'll receive emails for:**
   - Certification started
   - Certification passed
   - Certification failed (with details)
   - App published

**Typical Timeline:**
- Pre-processing: 15 mins - 1 hour
- Security tests: 1-4 hours
- Technical compliance: 2-6 hours
- Content compliance: 4-24 hours
- Release: 1-3 hours
- **Total: 24-72 hours**

**If certification fails:**
1. Check the certification report in Partner Center
2. Review the failure reasons
3. Fix the issues
4. Increment version again (to 1.0.18.0)
5. Resubmit

- [ ] **DONE:** Monitoring certification progress

---

## What Changed in This Fix

| Before (Incorrect) | After (Correct) |
|-------------------|----------------|
| Signed with dev cert (`CN=MC-BDS`) | Let Microsoft sign during certification |
| Package Family Name: `..._47q1101p6hvwy` | Package Family Name: `..._n8ws8gp0q633w` |
| Publisher: `CN=MC-BDS` | Publisher: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289` |
| File: Individual `.msix` | File: Bundle `.msixupload` |
| Manual signing with `SignTool.exe` | Unsigned or test-signed by Visual Studio |

## Why This Works

? **Visual Studio** creates the package properly for Store submission  
? **Partner Center** validates the package structure  
? **Microsoft** re-signs the package with the Store certificate during certification  
? **Package Family Name** is correctly generated from the Store certificate  
? **Identity** matches what Partner Center expects  

## Key Principles

1. **For Store submission:** Always use Visual Studio's "Create App Packages" feature
2. **For local testing:** Use `CreateMSIXWithWindowsSDK.ps1` or similar
3. **Never manually sign** packages intended for Store submission
4. **Always increment version** when resubmitting
5. **Upload `.msixupload`** files, not individual `.msix` files

## Troubleshooting

### Issue: "Create App Packages" option not available

**Solution:**
- Make sure Package.appxmanifest exists
- Verify project targets Windows: `net10.0-windows10.0.19041.0`
- Check that Visual Studio recognizes it as a Windows project
- Try: Clean solution ? Rebuild

### Issue: "Cannot sign in to Partner Center"

**Solution:**
- Verify account credentials
- Check you're using the correct Microsoft account
- Try: Visual Studio ? Account Settings ? Sign out ? Sign in again
- Ensure your Partner Center account is active and verified

### Issue: Build fails with "Cannot find runtime packages"

**Solution:**
- This is a known issue with .NET 10 preview and command-line builds
- Use Visual Studio UI instead (which uses SDK-bundled runtimes)
- Don't use MSBuild directly for .NET 10 preview

### Issue: "Version 1.0.17.0 already exists"

**Solution:**
- You already submitted this version
- Increment again: `Version="1.0.18.0"`
- Re-run the process

### Issue: Upload validation fails

**Solution:**
- Check that Package.appxmanifest has correct Store identity
- Verify Publisher: `CN=5DB9918C-386B-4DCF-98CB-FF6BA76EA289`
- Ensure all required assets exist
- Try re-associating with Store in Visual Studio

## Success Criteria

You'll know it's successful when:

? Package uploads to Partner Center without errors  
? Validation shows correct identity information  
? No "Invalid package family name" errors  
? No "Invalid publisher name" errors  
? Certification starts automatically  
? Within 24-72 hours, certification passes  
? App is published to Microsoft Store  

## Resources

- **This Checklist:** `STORE_SUBMISSION_CHECKLIST.md`
- **Quick Fix Summary:** `QUICK_FIX_STORE_IDENTITY.md`
- **Detailed Explanation:** `MSIX_IDENTITY_MISMATCH_FIX.md`
- **General Guide:** `HOW_TO_CREATE_MSIX_PACKAGE.md`
- **Partner Center:** https://partner.microsoft.com/dashboard
- **App Identity Details:** Partner Center ? MCBDS Manager ? Product identity

## Estimated Total Time

- Step 1: 30 seconds
- Step 2: 1 minute  
- Step 3: 5-15 minutes (build time)
- Step 4: 30 seconds
- Step 5: 5 minutes (optional testing)
- Step 6: 2-5 minutes (upload)
- Step 7: 5-10 minutes (submission)
- Step 8: 24-72 hours (certification)

**Active time:** ~15-30 minutes  
**Wait time:** 24-72 hours  

---

**Good luck with your Store submission!** ??

Check off each box as you complete the steps. If you encounter any issues, refer to the Troubleshooting section or the detailed documentation.

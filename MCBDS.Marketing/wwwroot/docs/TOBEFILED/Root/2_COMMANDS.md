# STORE PACKAGE - 2 COMMANDS

## Fix Identity Mismatch Now

```powershell
.\IncrementPackageVersion.ps1
.\CreateMSIXPackage.ps1 -ForStore
```

## What to Look For

? **"Microsoft Store Submission (UNSIGNED)"**  
? **"Skipping signing"**  
? **"UNSIGNED and ready for Store submission"**

? "Signed" or "Valid" = WRONG (forgot `-ForStore`)

## Upload

https://partner.microsoft.com/dashboard

Upload: `AppPackages\MCBDS.PublicUI_1.0.18.1_x64\MCBDS.PublicUI_1.0.18.1_x64.msix`

## Result

? No "Invalid package family name" error  
? No "Invalid publisher name" error  
? Identity mismatch **FIXED**

---

**That's it!** ??

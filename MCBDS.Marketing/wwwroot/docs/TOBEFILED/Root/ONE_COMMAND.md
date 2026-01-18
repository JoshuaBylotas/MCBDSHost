# SCRIPT-ONLY - 1 Command

## Try This First

```powershell
.\CreateUnsignedStorePackageScript.ps1
```

Uses MSBuild to build and package (works with .NET 10 SDK).

---

## If That Fails

### Quick Fix:

```powershell
# 1. Disable signing
(Get-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj" -Raw) -replace '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>' | Set-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj"

# 2. Build in Visual Studio (F7)

# 3. Create package
.\CreateUnsignedFromExistingBuild.ps1

# 4. Restore signing
(Get-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj" -Raw) -replace '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>' | Set-Content "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
```

---

## Result

? Unsigned package  
? No identity mismatch  
? Ready for Partner Center  

?? Upload: `AppPackages\MCBDS.PublicUI_1.0.18.1_x64\MCBDS.PublicUI_1.0.18.1_x64.msix`

---

**See `SCRIPT_ONLY_FIX.md` for details**

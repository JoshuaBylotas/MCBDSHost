# ?? Quick Build & Install - Version 1.0.25.0

## ONE COMMAND TO BUILD

```powershell
cd "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.PublicUI"

dotnet publish -f net10.0-windows10.0.19041.0 -c Release -p:WindowsPackageType=MSIX -p:GenerateAppxPackageOnBuild=true
```

**Output:**
```
AppPackages\MCBDS.PublicUI_1.0.25.0_Test\MCBDS.PublicUI_1.0.25.0_x64.msix
```

---

## INSTALL ON FRESH WINDOWS

### Option 1: Double-Click
1. Copy `.msix` file to target machine
2. Double-click
3. Click "Install"
4. Done!

### Option 2: PowerShell
```powershell
Add-AppxPackage -Path "MCBDS.PublicUI_1.0.25.0_x64.msix"
```

---

## VERIFY INSTALLATION

```powershell
# Check installed
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}

# Launch app
Start-Process "shell:AppsFolder\$(
  (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
)!App"

# Check crash log
$pkg = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
notepad "$env:LOCALAPPDATA\Packages\$($pkg.PackageFamilyName)\LocalState\crash-log.txt"
```

---

## WHAT'S NEW

? Crash logging for diagnostics  
? New Diagnostics page  
? Fixed launch crashes  
? Better error handling  

---

## TROUBLESHOOTING

**App won't install?**
```powershell
# Trust certificate
$cert = Get-AuthenticodeSignature "MCBDS.PublicUI_1.0.25.0_x64.msix"
$cert.SignerCertificate | Export-Certificate -FilePath "cert.cer"
Import-Certificate -FilePath "cert.cer" -CertStoreLocation Cert:\LocalMachine\Root
```

**App crashes?**
1. Open app
2. Go to Diagnostics page
3. View crash log

---

## VERSION INFO

- **Version:** 1.0.25.0
- **Build:** 2
- **Date:** 2025-01-08
- **Changes:** Store crash fix

---

## FILES UPDATED

- `MCBDS.PublicUI.csproj` ? Version 1.0.1 / Build 2
- `Package.appxmanifest` ? Version 1.0.25.0

---

**Full Guide:** See `FRESH_INSTALL_GUIDE.md`

# ? Update Complete: Registry Settings Removed

## What Changed

The NSIS installer **no longer writes configuration settings to the Windows Registry**.

**Configuration is stored ONLY in the JSON file.**

---

## Registry Status

### What Was Removed ?
```
HKLM\Software\MCBDS\API Service
  ?? ServicePort
  ?? BackupFrequency
  ?? MaxBackups
```

### What Still Exists ?
```
HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service
  ?? DisplayName         (Windows standard)
  ?? UninstallString     (Windows standard)
  ?? DisplayVersion      (Windows standard)
  ?? Publisher           (Windows standard)
```

---

## Single Source of Truth: JSON File

**All configuration now in one place**:
```
C:\Program Files\MCBDS API Service\appsettings.user.json
```

```json
{
  "Urls": "http://0.0.0.0:9000",
  "Backup": {
    "FrequencyMinutes": 60,
    "MaxBackupsToKeep": 20
  }
}
```

---

## Benefits

? **Cleaner Registry** - No application-specific entries  
? **Standard Format** - JSON is portable and readable  
? **Single Source** - All config in one file  
? **Best Practices** - Follows Windows guidelines  
? **Easy Backup** - Just copy the JSON file  

---

## How Users Check Configuration

### Before (Registry)
```powershell
Get-ItemProperty "HKLM:\Software\MCBDS\API Service"
```

### After (JSON File) ?
```powershell
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
```

---

## Files Updated

| File | Status |
|------|--------|
| MCBDSInstaller.nsi | ? Updated |
| INSTALLER-CONFIGURATION-GUIDE.md | ? Updated |
| REGISTRY-REMOVAL-UPDATE.md | ? New |

---

## Build & Test

```powershell
# Rebuild installer
.\MCBDS.Installer\build-installer.ps1

# Test installation
.\MCBDS.API.Service.Installer.exe

# Verify configuration in JSON only
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json

# Verify NO config in registry (should error)
Get-ItemProperty "HKLM:\Software\MCBDS\API Service" 2>&1  # Not found (expected)
```

---

## Summary

**Registry**: Only Windows standard Uninstall entry  
**Configuration**: JSON file only (no registry pollution)  
**Benefits**: Professional, clean installation  

?? **Clean and professional!**

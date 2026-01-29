# Configuration - Registry Removal Update

## Change Made

The installer **no longer writes configuration settings to the Windows Registry**. Configuration is stored **only in the JSON file**.

---

## What Changed

### Before
```nsi
WriteRegStr HKLM "Software\MCBDS\API Service" "ServicePort" "$ServicePort"
WriteRegStr HKLM "Software\MCBDS\API Service" "BackupFrequency" "$BackupFrequency"
WriteRegStr HKLM "Software\MCBDS\API Service" "MaxBackups" "$MaxBackups"
```

### After
? **Removed** - Configuration no longer written to registry

---

## Registry Behavior

### What IS Still Written (Windows Standard)
```nsi
; Only the standard Uninstall entry (required by Windows)
HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service
  ?? DisplayName
  ?? UninstallString
  ?? DisplayVersion
  ?? Publisher
```

### What is NOT Written (Configuration)
```
HKLM\Software\MCBDS\API Service    ? Deleted (no longer written)
```

---

## Configuration Storage

### Single Source of Truth: JSON File
```
C:\Program Files\MCBDS API Service\appsettings.user.json
```

**File contains everything**:
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

? **Cleaner Registry** - No application-specific registry entries  
? **Single Source of Truth** - All config in one JSON file  
? **Portable Config** - Easy to copy/backup JSON file  
? **Standard Format** - JSON is portable and readable  
? **No Registry Pollution** - Follows Windows best practices  

---

## Uninstallation

When uninstalling:
- ? Removes Uninstall registry entry (Windows requirement)
- ? Removes all installation files
- ? Removes `appsettings.user.json` (as part of directory removal)
- ? No configuration registry entries to clean up

---

## Modifying Configuration

### Only Method Now
```powershell
# 1. Edit the JSON file
notepad "C:\Program Files\MCBDS API Service\appsettings.user.json"

# 2. Restart service to apply
net stop MCBDSAPIService
net start MCBDSAPIService
```

### No Registry Check Needed
Previously: Users might check registry to verify settings
Now: Settings only in JSON file (standard configuration file)

---

## For Developers

### Finding Configuration Settings
```powershell
# Look here:
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json

# Don't look at registry anymore:
Get-ItemProperty "HKLM:\Software\MCBDS\API Service"  # Won't exist
```

### Verifying After Install
```powershell
# Just check the JSON file
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertTo-Json
```

---

## For System Admins

### Configuration Backup
```powershell
# Backup configuration
Copy-Item "C:\Program Files\MCBDS API Service\appsettings.user.json" "backup-config.json"

# Restore configuration
Copy-Item "backup-config.json" "C:\Program Files\MCBDS API Service\appsettings.user.json"
```

### Configuration Audit
```powershell
# Check what's configured
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" -Raw
```

---

## Installation Summary

**Registry entries created**:
- ? Add/Remove Programs entry (Windows standard)

**Registry entries NOT created**:
- ? Application configuration settings (now JSON only)

**Configuration storage**:
- ? `appsettings.user.json` (complete configuration)

---

## Files Updated

| File | Change |
|------|--------|
| MCBDSInstaller.nsi | ? Registry writes removed |
| build-installer.ps1 | No change needed |
| Program.cs | No change needed |
| appsettings.json | No change needed |

---

## Backwards Compatibility

### Fresh Installs
? Works perfectly - JSON file created during installation

### Upgrades (If Any)
?? If upgrading from version with registry entries:
```powershell
# Manually clean old registry (if needed)
Remove-Item "HKLM:\Software\MCBDS" -Recurse -Force
```

---

## Build & Test

```powershell
# Rebuild installer
.\MCBDS.Installer\build-installer.ps1

# Install and test
.\MCBDS.API.Service.Installer.exe

# Verify configuration in JSON only
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json"

# Verify registry has NO configuration entries
Get-ItemProperty "HKLM:\Software\MCBDS\API Service" 2>&1  # Should show error (not found)
```

---

## Documentation Updates

Updated files:
- ? MCBDSInstaller.nsi
- ? Need to update documentation to mention "JSON only" configuration

---

## Summary

**Changed**: Configuration is now stored **ONLY in JSON file**, not in Windows Registry

**Benefits**:
- Cleaner registry
- Standard configuration format
- Single source of truth
- No registry pollution
- Better portability

**Result**: Professional, clean installation that follows Windows best practices

---

**Status**: ? Implementation Complete  
**Next**: Rebuild installer and test

# Smart Configuration Merging for Upgrades

## ?? Overview

The MCBDS installer now **intelligently preserves** your custom settings during upgrades, preventing the need for reconfiguration.

---

## ? What Gets Preserved

When upgrading, the installer automatically keeps:

| Setting | Example | Preserved? |
|---------|---------|-----------|
| **Custom Port** | `"Urls": "http://0.0.0.0:9000"` | ? YES |
| **Bedrock Server Path** | `"ExePath": "D:\\Games\\bedrock_server.exe"` | ? YES |
| **Log File Path** | `"LogFilePath": "C:\\Logs\\api.log"` | ? YES |
| **Backup Directory** | `"BackupDirectory": "E:\\Backups"` | ? YES |
| **Backup Frequency** | `"FrequencyMinutes": 60` | ? YES |
| **Max Backups** | `"MaxBackupsToKeep": 100` | ? YES |
| **Xbox Live API Key** | `"ApiKey": "your-key-here"` | ? YES |
| **Custom Sections** | `"MyCustomConfig": { ... }` | ? YES |

---

## ?? How It Works

### **During Installation:**

```
1. Installer extracts PowerShell merge script
2. Script checks for existing appsettings.json
3. If found:
   ? Creates backup: appsettings.backup.json
   ? Reads your custom settings
   ? Merges with new installer defaults
   ? Writes merged configuration
4. If not found:
   ? Creates new default configuration
```

### **Merge Priority:**

```
Your existing settings > Installer defaults
```

Your customizations always win!

---

## ?? Example Upgrade Scenario

### **Before Upgrade:**

Your custom `appsettings.json`:
```json
{
  "Urls": "http://0.0.0.0:9000",
  "Runner": {
    "ExePath": "D:\\Games\\bedrock_server.exe"
  },
  "Backup": {
    "FrequencyMinutes": 60
  },
  "XboxLive": {
    "ApiKey": "7295a573-6903-49f7-99e0-3cfb243ef335"
  }
}
```

### **After Upgrade:**

Merged `appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Urls": "http://0.0.0.0:9000",           ? YOUR CUSTOM PORT
  "Runner": {
    "ExePath": "D:/Games/bedrock_server.exe", ? YOUR CUSTOM PATH
    "LogFilePath": "C:/Program Files/MCBDS API Service/logs/api.log"
  },
  "Backup": {
    "FrequencyMinutes": 60,                ? YOUR CUSTOM FREQUENCY
    "BackupDirectory": "C:/Program Files/MCBDS API Service/backups",
    "MaxBackupsToKeep": 30
  },
  "XboxLive": {
    "ApiKey": "7295a573-6903-49f7-99e0-3cfb243ef335", ? YOUR KEY PRESERVED!
    "ApiBaseUrl": "https://xbl.io/api/v2",
    "EnableCaching": true,
    "CacheExpirationMinutes": 1440
  }
}
```

**Result:** Your custom settings preserved + New features added! ??

---

## ??? Safety Features

### **1. Automatic Backup**
Every upgrade creates `appsettings.backup.json`:
```
C:\Program Files\MCBDS API Service\
??? appsettings.json          ? Merged configuration
??? appsettings.backup.json   ? Your old config (backup)
??? appsettings.user.json     ? Copy of merged config
```

### **2. Fallback Protection**
If PowerShell merge fails:
- ? Creates basic default config
- ? Keeps your backup file safe
- ? Shows warning in installer log

### **3. Manual Merge Option**
If automatic merge fails, you can manually merge using the backup:
```powershell
# Compare files
code "C:\Program Files\MCBDS API Service\appsettings.json" `
     "C:\Program Files\MCBDS API Service\appsettings.backup.json"

# Or restore backup
Copy-Item appsettings.backup.json appsettings.json
```

---

## ?? Installer Output

### **Fresh Install:**
```
Creating configuration files...
No existing config found - creating new appsettings.json
? Wrote appsettings.json successfully
? Wrote appsettings.user.json successfully
Configuration complete!
```

### **Upgrade (Preserving Settings):**
```
Creating configuration files...
Merging configuration settings (preserving user customizations)...
Found existing appsettings.json - preserving user settings
Created backup: appsettings.backup.json
  ? Preserved custom port: http://0.0.0.0:9000
  ? Preserved custom Bedrock path: D:/Games/bedrock_server.exe
  ? Preserved backup frequency: 60 minutes
  ? Preserved Xbox Live API key
Configuration merge successful!
? Wrote appsettings.json successfully
? Wrote appsettings.user.json successfully
Configuration complete!
```

---

## ?? Technical Details

### **Merge Script Location:**
```
MCBDS.Installer\merge-appsettings.ps1
```

### **Execution:**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "merge-appsettings.ps1" `
  -InstallDir "C:\Program Files\MCBDS API Service" `
  -BedrockExePath "C:\Binaries\bedrock_server.exe" `
  -LogFilePath "C:\Logs\api.log" `
  -BackupsPath "C:\Backups" `
  -ServicePort 8080 `
  -BackupFrequency 30 `
  -MaxBackups 30
```

### **Merge Logic:**
```
For each setting:
  If exists in old config AND differs from default:
    ? Keep user's value
  Else:
    ? Use installer default
    
For custom sections:
  ? Always preserve
```

---

## ?? Benefits

| Before | After |
|--------|-------|
| ? Lost settings on upgrade | ? Settings preserved |
| ? Manual reconfiguration | ? Automatic merge |
| ? Lost API keys | ? Keys preserved |
| ? Reset custom paths | ? Paths preserved |
| ? No backup | ? Automatic backup |

---

## ?? Edge Cases

### **Corrupted Config:**
```
Warning: Could not parse existing config, using new defaults
Your old config is saved as: appsettings.backup.json
```
**Action:** Manually check and merge backup file.

### **PowerShell Disabled:**
```
Warning: PowerShell merge failed (exit code: 1)
Creating default configuration instead...
```
**Action:** Enable PowerShell or manually merge from backup.

### **Permission Issues:**
```
ERROR: Failed to write configuration files!
Access to the path is denied.
```
**Action:** Run installer as Administrator.

---

## ?? Version History

| Version | Change |
|---------|--------|
| **1.0** | Manual JSON creation (overwrites) |
| **1.1** | Smart merge with preservation |

---

## ?? For Developers

### **Modifying Merge Logic:**

Edit `MCBDS.Installer\merge-appsettings.ps1`:

```powershell
# Add new setting preservation
if ($existingConfig.MyNewSection) {
    $newConfig.MyNewSection = $existingConfig.MyNewSection
    Write-Host "  ? Preserved custom setting" -ForegroundColor Green
}
```

### **Testing:**

```powershell
# Test merge script manually
.\merge-appsettings.ps1 `
  -InstallDir "C:\Temp\Test" `
  -BedrockExePath "C:\bedrock_server.exe" `
  -LogFilePath "C:\api.log" `
  -BackupsPath "C:\backups" `
  -ServicePort 8080 `
  -BackupFrequency 30 `
  -MaxBackups 30
```

---

## ? Summary

Your settings are now **upgrade-safe**! The installer will:
- ? Preserve all custom configurations
- ? Add new features automatically
- ? Create safety backups
- ? Prevent reconfiguration headaches

**Upgrade confidently!** ??

---

**Status:** ? Implemented  
**Version:** 1.1+  
**Last Updated:** 2024

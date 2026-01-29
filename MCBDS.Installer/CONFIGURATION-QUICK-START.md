# Configuration Setup - Quick Start

## What's New? ??

The NSIS installer now has an **interactive configuration page** during installation that asks users for:

1. **Service Port** (default: 8080)
2. **Backup Frequency** (default: 30 minutes)
3. **Max Backups** (default: 30)
4. **Start Menu Shortcuts** (default: Yes)

---

## Installation Experience

### Before (No Configuration)
```
Welcome
  ?
Choose Folder
  ?
Install
  ?
Done
```

### After (With Configuration) ?
```
Welcome
  ?
Choose Folder
  ?
?? CONFIGURE SETTINGS  ? Users fill this in!
  ?
Install
  ?
Done
```

---

## What Gets Stored

### Configuration File
**Location**: `C:\Program Files\MCBDS API Service\appsettings.user.json`

```json
{
  "Urls": "http://0.0.0.0:9000",  ? Custom port from setup
  "Backup": {
    "FrequencyMinutes": 60,         ? Custom frequency from setup
    "MaxBackupsToKeep": 20          ? Custom limit from setup
  }
}
```

### Windows Registry
**Location**: `HKLM\Software\MCBDS\API Service`

```
ServicePort    = "9000"
BackupFrequency= "60"
MaxBackups     = "20"
```

---

## User Installation Steps

1. **Run installer** ? "MCBDS.API.Service.Installer.exe"

2. **Configure** ? Enter your settings:
   ```
   HTTP Port: [9000          ]
   Backup Frequency: [60    ]
   Max Backups: [20         ]
   ? Create Start Menu Shortcuts
   ```

3. **Install** ? Installer creates config and starts service

4. **Done!** ? Service runs with custom settings

---

## Modifying Configuration Later

### Option 1: Edit JSON File
```powershell
# Edit the file
notepad "C:\Program Files\MCBDS API Service\appsettings.user.json"

# Restart service
net stop MCBDSAPIService
net start MCBDSAPIService
```

### Option 2: PowerShell
```powershell
# Stop service
net stop MCBDSAPIService

# Modify config
$config = Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
$config.Backup.FrequencyMinutes = 45
$config | ConvertTo-Json | Set-Content "C:\Program Files\MCBDS API Service\appsettings.user.json"

# Restart
net start MCBDSAPIService
```

---

## Default Values

| Setting | Default | Min | Max | Recommended |
|---------|---------|-----|-----|-------------|
| Port | 8080 | 1 | 65535 | 8080-9000 |
| Backup Frequency | 30 min | 1 | ? | 15-60 min |
| Max Backups | 30 | 1 | ? | 10-50 |

---

## Build & Test

```powershell
# Build installer with new configuration feature
.\MCBDS.Installer\build-installer.ps1

# Run installer
.\MCBDS.API.Service.Installer.exe

# Test service with custom settings
Get-Service MCBDSAPIService
curl http://localhost:8080/health  # Adjust port if changed!
```

---

## Technical Details

### How It Works

1. **Installation**: NSIS shows configuration dialog
2. **User Input**: User enters custom values (or accepts defaults)
3. **File Creation**: Installer creates `appsettings.user.json` with values
4. **Registry**: Settings stored in registry for reference
5. **Service Startup**: Service reads config and applies settings
6. **Firewall**: Rule created for configured port

### Configuration Loading Order

```csharp
// Service reads configuration in this order:
1. appsettings.json (defaults)
2. appsettings.user.json (overrides)  ? Installer-created file
3. Environment variables (highest priority)
```

---

## Files Modified

| File | Change |
|------|--------|
| MCBDSInstaller.nsi | ? Added configuration page with nsDialogs |
| build-installer.ps1 | No change (still works) |
| Program.cs | No change needed |
| appsettings.json | No change (defaults) |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Configuration page doesn't show | Ensure nsDialogs is included in NSIS |
| Port not accessible | Check firewall rule: `netsh advfirewall firewall show rule all \| findstr MCBDS` |
| Service won't start | Verify JSON syntax: `Test-Json -Path appsettings.user.json` |
| Settings ignored | Check service is reading correct file: Check logs |

---

## Example Configurations

### Lightweight Setup
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Backup": {
    "FrequencyMinutes": 120,
    "MaxBackupsToKeep": 5
  }
}
```

### Standard Setup
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Backup": {
    "FrequencyMinutes": 30,
    "MaxBackupsToKeep": 30
  }
}
```

### High-Performance Setup
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Backup": {
    "FrequencyMinutes": 15,
    "MaxBackupsToKeep": 50
  }
}
```

---

## Firewall Rules Created

For each configured port, NSIS adds:
```
Rule Name: MCBDS API Service (HTTP)
Direction: Inbound
Port: <configured port>
Protocol: TCP
Action: Allow
Program: MCBDS.WindowsService.exe
```

---

## Next: Full Documentation

? See: **INSTALLER-CONFIGURATION-GUIDE.md** for complete details

---

**Status**: ? Interactive configuration implemented  
**Ready**: Yes, build and test now!

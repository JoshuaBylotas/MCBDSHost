# Interactive Configuration Setup - NSIS Installer

## Overview

The NSIS installer now includes an **interactive configuration page** that prompts users for important settings during installation instead of using hardcoded defaults.

---

## What Gets Configured

### 1. **HTTP Service Port** (Default: 8080)
- Allows users to choose a different port if 8080 is already in use
- Firewall rule is automatically created for the chosen port
- Validation: Must be a valid port number (1-65535)

### 2. **Backup Frequency** (Default: 30 minutes)
- How often the service backs up the Minecraft world data
- Users can set to any value in minutes
- Lower values = more frequent backups (higher disk usage)
- Higher values = less frequent backups (more work to recover)

### 3. **Maximum Backups to Keep** (Default: 30)
- How many backup copies to retain
- Older backups are automatically deleted
- Prevents unlimited disk space usage
- Example: 30 backups at 1GB each = ~30GB max space for backups

### 4. **Start Menu Shortcuts** (Default: Enabled)
- Option to create Windows Start Menu shortcuts
- Shortcut to Windows Services management console
- Shortcut to Uninstaller

---

## Installation Flow

```
1. Welcome Page
   ?
2. Choose Installation Directory
   ?
3. ?? CONFIGURE SETTINGS (Interactive Page)
   ?? Enter HTTP Port
   ?? Enter Backup Frequency
   ?? Enter Max Backups
   ?? Choose Start Menu Option
   ?
4. Installation Progress
   ?? Extract Files
   ?? Create Configuration File
   ?? Register Service
   ?? Add Firewall Rule
   ?? Start Service
   ?
5. Completion Page
   ?? Show Settings Summary
```

---

## Configuration File Location

**File**: `C:\Program Files\MCBDS API Service\appsettings.user.json`

**Contents** (example with custom settings):
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Urls": "http://0.0.0.0:9000",
  "Runner": {
    "ExePath": "Binaries\bedrock_server.exe",
    "LogFilePath": "logs\runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 60,
    "BackupDirectory": "backups",
    "MaxBackupsToKeep": 20
  }
}
```

---

## Registry Storage

**Configuration settings are NOT stored in the Windows Registry.**

Configuration is stored **only in the JSON file** for cleaner registry management and standard configuration practices.

Registry entries created (Windows standard only):
```
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service
  ?? DisplayName
  ?? UninstallString
  ?? DisplayVersion
  ?? Publisher
```

To view installation details, check the JSON file:
```powershell
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
```

---

## How the Service Uses Configuration

### At Startup

The Windows Service reads `appsettings.user.json` on startup:

```csharp
// In Program.cs - ConfigureApiServices method
builder.Configuration
  .AddJsonFile("appsettings.user.json", optional: true, reloadOnChange: true)
  .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
```

### Applying Settings

1. **Port Configuration**: Kestrel binds to the configured port
   ```csharp
   builder.WebHost.ConfigureKestrel(serverOptions =>
   {
       serverOptions.ListenAnyIP(int.Parse(settings["Port"]));
   });
   ```

2. **Backup Configuration**: BackupHostedService uses the settings
   ```csharp
   builder.Services.Configure<BackupConfiguration>(
       builder.Configuration.GetSection("Backup"));
   ```

3. **Server Configuration**: RunnerHostedService uses paths
   ```csharp
   builder.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
   {
       ["Runner:ExePath"] = Path.Combine(serviceDirectory, "Binaries", "bedrock_server.exe"),
       ["Backup:FrequencyMinutes"] = settings["Backup:FrequencyMinutes"]
   });
   ```

---

## User Installation Experience

### Step 1: Welcome
```
MCBDS API Service Setup Wizard
?????????????????????????????

Welcome to MCBDS API Service

This will install the MCBDS API Service on your computer.

[Next >]
```

### Step 2: Choose Installation Folder
```
Choose Install Location
?????????????????????????????

Destination Folder:
C:\Program Files\MCBDS API Service

[Browse...] [Next >]
```

### Step 3: Configure Settings ? NEW!
```
Service Configuration
?????????????????????????????

HTTP Port (default: 8080)
[8080                          ]

Backup Frequency (minutes, default: 30)
[30                            ]

Maximum Backups to Keep (default: 30)
[30                            ]

? Create Start Menu Shortcuts

[< Back] [Next >]
```

### Step 4: Installation Progress
```
Installation Progress
?????????????????????????????

Installing Windows Service... ?
Creating configuration file... ?
Registering Service... ?
Configuring Windows Firewall... ?
Starting Service... ?

Installation completed successfully!
Service Port: 9000
Backup Frequency: 60 minutes
Max Backups: 20

[Close]
```

---

## Validation Rules

### Port Number
- **Type**: Integer
- **Range**: 1-65535
- **Default**: 8080
- **Validation**: Must not be already in use
- **Firewall**: Rule automatically created for chosen port

### Backup Frequency
- **Type**: Integer (minutes)
- **Minimum**: 1 minute
- **Recommended**: 10-60 minutes
- **Default**: 30 minutes
- **Note**: Lower values = more backups, more disk I/O

### Max Backups
- **Type**: Integer
- **Minimum**: 1
- **Recommended**: 10-50
- **Default**: 30
- **Impact**: More backups = more disk space needed

---

## Customizing Configuration Page

### Add More Options

Edit `MCBDSInstaller.nsi` in the `ConfigurationPage` function:

```nsi
; Add a new configuration option
${NSD_CreateLabel} 0 $3 100% 12u "New Setting Name"
Pop $1
IntOp $3 $3 + 12
${NSD_CreateTextBox} 0 $3 100% 12u "default_value"
Pop $7
IntOp $3 $3 + 12

; Store the value
${NSD_GetText} $7 $NewSettingVariable
```

### Modify Configuration File

Edit the configuration file creation section in the installation:

```nsi
FileWrite $7 '  "NewSection": {$\r$\n'
FileWrite $7 '    "Setting": "$NewSettingVariable"$\r$\n'
FileWrite $7 '  },$\r$\n'
```

---

## Modifying Configuration After Installation

### Method 1: Edit JSON File Directly

1. Open: `C:\Program Files\MCBDS API Service\appsettings.user.json`
2. Edit the values
3. Restart the service:
   ```powershell
   net stop MCBDSAPIService
   net start MCBDSAPIService
   ```

### Method 2: Command Line

```powershell
# Stop service
net stop MCBDSAPIService

# Use PowerShell to modify JSON
$config = Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
$config.Backup.FrequencyMinutes = 60
$config | ConvertTo-Json | Set-Content "C:\Program Files\MCBDS API Service\appsettings.user.json"

# Start service
net start MCBDSAPIService
```

### Method 3: Check Service Configuration

Configuration is stored in JSON file only (no registry entries):

```powershell
# View current configuration
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json

# Only Windows uninstall entry in registry:
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service"
```

---

## Troubleshooting Configuration

### Service Won't Start After Installation

**Check the configuration file**:
```powershell
# Verify JSON syntax and content
$json = Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
Write-Host "Config loaded successfully"

# View content
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | Out-Host

# Check for JSON syntax errors:
Test-Json -Path "C:\Program Files\MCBDS API Service\appsettings.user.json"
```

### Port Already in Use

**Error**: Service won't listen on configured port

**Solution**:
```powershell
# Find what's using the port
netstat -ano | findstr :9000

# Change to different port
# Edit appsettings.user.json
# Change "Urls": "http://0.0.0.0:9000" to different port
# Restart service
```

### Firewall Rule Not Applied

**Error**: Can't access service from network

**Solution**:
```powershell
# Re-add firewall rule manually
netsh advfirewall firewall add rule `
  name="MCBDS API Service (HTTP)" `
  dir=in `
  action=allow `
  protocol=tcp `
  localport=9000

# Restart service
net stop MCBDSAPIService
net start MCBDSAPIService
```

---

## Advanced: Silent Installation with Custom Config

For deployment teams, you can provide a silent installation with pre-configured settings:

```powershell
# Create custom config file first
$config = @{
    Urls = "http://0.0.0.0:9000"
    Backup = @{
        FrequencyMinutes = 60
        MaxBackupsToKeep = 20
    }
}

# Save to temporary location
$config | ConvertTo-Json | Out-File "temp-config.json"

# Install silently
MCBDS.API.Service.Installer.exe /S /D="C:\MCBDS"

# Replace config after installation
Copy-Item "temp-config.json" "C:\MCBDS\appsettings.user.json"

# Restart service
net stop MCBDSAPIService
net start MCBDSAPIService
```

---

## Configuration Best Practices

### Port Selection
- ? Use 8080 or higher for non-admin ports
- ? Avoid common ports (80, 443, 3306, 5432)
- ? Check if port is available before installation
- ? Don't use ports below 1024 (requires special permissions)

### Backup Settings
- ? Balance frequency with disk I/O
- ? Consider disk space for backups
- ? Keep at least 3-5 backups for recovery
- ? Monitor backup directory size
- ? Don't set frequency too low (causes disk thrashing)
- ? Don't keep too many backups (wastes space)

### Recommended Configurations

**Small/Test Server**:
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Backup": {
    "FrequencyMinutes": 60,
    "MaxBackupsToKeep": 10
  }
}
```

**Production Server**:
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Backup": {
    "FrequencyMinutes": 30,
    "MaxBackupsToKeep": 30
  }
}
```

**High-Traffic Server**:
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

## Configuration Files Summary

| File | Purpose | Editable |
|------|---------|----------|
| `appsettings.user.json` | User configuration | ? Yes |
| `appsettings.json` | Default settings | ? Yes |
| Registry entries | Reference/metadata | ? Yes |

---

## Next Steps

1. **Build the updated installer**: `.\MCBDS.Installer\build-installer.ps1`
2. **Test the configuration page**: Run the installer and verify all options
3. **Try different settings**: Install with custom port/backup settings
4. **Verify configuration**: Check both JSON file and registry
5. **Test service behavior**: Ensure service respects custom settings

---

**Status**: ? Configuration feature implemented and ready  
**Updated**: 2024  
**Documentation**: Complete

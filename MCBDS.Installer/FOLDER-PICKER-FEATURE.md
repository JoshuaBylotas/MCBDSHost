# ?? Folder Picker Feature Added - Installation Complete!

## What's New

The installer now includes a **folder picker page** where users can customize the storage locations for:
- **Binaries** - Where bedrock_server.exe is located
- **Logs** - Where runner.log files are stored
- **Backups** - Where server backups are saved

---

## Installation Flow (Updated)

```
Welcome
  ?
Choose Installation Directory
  ?
?? Data Storage Locations (New Folder Picker Page!)
  ?? Browse button for Binaries folder
  ?? Browse button for Logs folder
  ?? Browse button for Backups folder
  ?
Service Configuration
  ?? HTTP Port
  ?? Backup Frequency
  ?? Max Backups to Keep
  ?? Start Menu Shortcuts
  ?
Installation Progress
  ?
Completion Summary (Now includes all paths)
```

---

## Folder Picker Page Features

### ? Binaries Path
- **Default**: `C:\Program Files\MCBDS API Service\Binaries`
- **Purpose**: Where the bedrock_server.exe executable is located
- **Configurable**: Yes - users can browse and select any location
- **Used in config**: `"ExePath": "<selected_path>\bedrock_server.exe"`

### ? Logs Path
- **Default**: `C:\Program Files\MCBDS API Service\logs`
- **Purpose**: Where server logs (runner.log) are stored
- **Configurable**: Yes - users can browse and select any location
- **Used in config**: `"LogFilePath": "<selected_path>\runner.log"`

### ? Backups Path
- **Default**: `C:\Program Files\MCBDS API Service\backups`
- **Purpose**: Where server backups are stored
- **Configurable**: Yes - users can browse and select any location
- **Used in config**: `"BackupDirectory": "<selected_path>"`

---

## How It Works

### Example Installation

1. User installs and gets to "Data Storage Locations" page:
   ```
   Bedrock Server Binaries Location:
   [C:\Program Files\MCBDS API Service\Binaries] [Browse...]
   
   Logs Storage Location:
   [C:\Program Files\MCBDS API Service\logs] [Browse...]
   
   Backups Storage Location:
   [C:\Program Files\MCBDS API Service\backups] [Browse...]
   ```

2. User clicks "Browse..." next to Binaries:
   ```
   Folder Browser Dialog Opens
   ?
   User selects: D:\GameData\Binaries
   ?
   Field updates to: D:\GameData\Binaries
   ```

3. User configures Logs path:
   ```
   Select: E:\Logs
   ```

4. User configures Backups path:
   ```
   Select: F:\Backups
   ```

5. Installer creates configuration:
   ```json
   {
     "Runner": {
       "ExePath": "D:\\GameData\\Binaries\\bedrock_server.exe",
       "LogFilePath": "E:\\Logs\\runner.log"
     },
     "Backup": {
       "BackupDirectory": "F:\\Backups"
     }
   }
   ```

---

## Generated Configuration

After installation with custom paths, `appsettings.user.json` contains:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Urls": "http://0.0.0.0:8080",
  "Runner": {
    "ExePath": "D:\\GameData\\Binaries\\bedrock_server.exe",
    "LogFilePath": "E:\\Logs\\runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "F:\\Backups",
    "MaxBackupsToKeep": 30
  }
}
```

---

## Benefits

? **Flexible Storage** - Users can store data on different drives
? **Performance** - Can place backups on faster drives
? **Space Management** - Can use multiple disks for large backups
? **User Choice** - Not forced to single location
? **Easy Browsing** - Native folder picker dialog
? **Default Values** - Sensible defaults provided
? **Validation** - Empty paths automatically fallback to defaults

---

## Installation Summary Output

After installation, the completion screen shows:

```
Installation completed successfully!
Service Port: 8080
Backup Frequency: 30 minutes
Max Backups: 30
Binaries Location: D:\GameData\Binaries
Logs Location: E:\Logs
Backups Location: F:\Backups
```

---

## Use Cases

### Case 1: Everything in One Location
```
User accepts all defaults
? All data stored in: C:\Program Files\MCBDS API Service\
```

### Case 2: Distributed Storage
```
User selects:
- Binaries: C:\Games\Bedrock\
- Logs: D:\Logs\
- Backups: E:\Backups\
? Data spread across 3 drives for performance
```

### Case 3: Network Storage
```
User selects:
- Binaries: C:\Local\Binaries\
- Logs: \\NAS\logs\
- Backups: \\NAS\backups\
? Centralized backup and logs on network storage
```

---

## Features Implemented

? **Browse Button** - Native Windows folder picker for each path
? **Default Values** - Sensible defaults based on installation directory
? **Empty String Handling** - Falls back to defaults if left empty
? **Validation** - Ensures paths are valid
? **Configuration Generation** - Creates JSON with selected paths
? **Summary Display** - Shows all paths at completion

---

## Technical Implementation

### NSIS Changes
- Added `FolderPickerPage()` function with:
  - 3 text input fields with browse buttons
  - `nsDialogs::SelectFolderDialog` for folder selection
  - Validation in `FolderPickerPageLeave()`

### Variables Added
```nsi
Var BinariesPath   ; User-selected binaries location
Var LogsPath       ; User-selected logs location
Var BackupsPath    ; User-selected backups location
```

### Configuration Updates
- JSON file now uses selected paths instead of hardcoded defaults
- All paths properly escaped for Windows (`\\`)

---

## Testing

To test the folder picker feature:

```powershell
# Run the installer
.\MCBDS.API.Service.Installer.exe

# Step through the wizard:
# 1. Welcome
# 2. Install Location
# 3. DATA STORAGE LOCATIONS (NEW!)
#    - Try clicking Browse buttons
#    - Try selecting different paths
# 4. Service Configuration
# 5. Complete

# Verify configuration created with custom paths:
Get-Content "C:\Program Files\MCBDS API Service\appsettings.user.json" | ConvertFrom-Json
```

---

## What's Next

The installer now provides:
- ? Interactive port configuration
- ? Backup frequency customization
- ? Max backups retention policy
- ? **?? Flexible folder locations**
- ? Start Menu shortcuts option
- ? Automatic firewall rules
- ? Windows Service registration

---

## Summary

| Feature | Status |
|---------|--------|
| **Binaries Path Picker** | ? Implemented |
| **Logs Path Picker** | ? Implemented |
| **Backups Path Picker** | ? Implemented |
| **Browse Buttons** | ? Implemented |
| **Configuration Generation** | ? Implemented |
| **Validation** | ? Implemented |
| **Summary Display** | ? Implemented |

---

?? **Installer now has complete folder customization!**

Users can now:
- Keep data in default locations
- Spread data across multiple drives
- Use network storage
- Optimize performance by choosing drives strategically

**Ready to use!** ?

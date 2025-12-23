# Backup Settings Feature

## Overview

A new **Backup Settings** tab has been added to the PublicUI that allows users to configure automatic backup settings for the Minecraft Bedrock Dedicated Server.

## Features

### Settings Configuration
- **Backup Frequency**: Set how often backups should run (1-1440 minutes)
- **Output Directory**: Specify where backup files will be stored
- **Browse Button**: Select a directory using the system folder picker

### Data Storage
Settings are stored locally in a JSON file:
- **Location**: `{AppDataDirectory}/backup-settings.json`
- **Format**: JSON with indentation for readability
- **Persistence**: Settings are loaded automatically when the page opens

### User Interface
- Clean, card-based layout
- Real-time validation
- Status messages for save operations
- Current settings display
- Information section with helpful tips

## Navigation Structure

```
?? Overview (/)
?? Commands (/commands)
?? Backup Settings (/backup-settings) ? NEW
```

## Files Added/Modified

### New Files Created:

1. **`MCBDS.ClientUI.Shared\Models\BackupSettings.cs`**
   - Model class for backup settings
   - Properties: `FrequencyMinutes`, `OutputDirectory`

2. **`MCBDS.ClientUI.Shared\Services\BackupSettingsService.cs`**
   - Service for loading and saving settings
   - JSON serialization/deserialization
   - File system operations

3. **`MCBDS.PublicUI\Components\Pages\BackupSettings.razor`**
   - Blazor page component
   - Form with validation
   - Folder picker integration
   - Status feedback

### Modified Files:

1. **`MCBDS.PublicUI\Components\Layout\NavMenu.razor`**
   - Added "Backup Settings" navigation item with archive icon

2. **`MCBDS.PublicUI\MauiProgram.cs`**
   - Registered `BackupSettingsService` as singleton
   - Configured with MAUI `AppDataDirectory`

3. **`MCBDS.PublicUI\Components\Pages\Home.razor`**
   - Added Backup Settings reference to feature list

## Usage

### For End Users:

1. Open the PublicUI app
2. Navigate to **Backup Settings** tab
3. Set the **Backup Frequency** (in minutes)
4. Click **Browse** to select an **Output Directory**, or type it manually
5. Click **Save Settings**

### Settings JSON Example:

```json
{
  "FrequencyMinutes": 30,
  "OutputDirectory": "C:\\Backups\\Minecraft"
}
```

### Settings File Location:

The settings file is stored at:
- **Windows**: `C:\Users\{Username}\AppData\Local\Packages\{AppId}\LocalState\backup-settings.json`
- **Android**: `/data/user/0/{package.name}/files/backup-settings.json`
- **iOS**: App's Documents directory
- **macOS**: Application Support directory

## Validation

- Frequency must be between **1** and **1440** minutes (24 hours)
- Output Directory is required and cannot be empty
- Real-time feedback on save success/failure

## Future Enhancements

This feature provides the UI and settings storage. Future work could include:

1. **Backend Integration**: 
   - Add API endpoints to manage backups
   - Implement actual backup logic in the API

2. **Backup Management**:
   - List existing backups
   - Restore from backup
   - Delete old backups

3. **Scheduled Backups**:
   - Use the frequency setting to trigger automatic backups
   - Background service for backup execution

4. **Backup Status**:
   - Show last backup time
   - Display backup history
   - Backup size and duration metrics

## Technical Details

### Service Registration
```csharp
builder.Services.AddSingleton<BackupSettingsService>(sp => 
    new BackupSettingsService(FileSystem.Current.AppDataDirectory));
```

### MAUI Folder Picker
```csharp
var result = await FolderPicker.Default.PickAsync(default);
if (result.IsSuccessful && result.Folder != null)
{
    settings.OutputDirectory = result.Folder.Path;
}
```

### JSON Serialization
```csharp
var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions
{
    WriteIndented = true
});
await File.WriteAllTextAsync(_settingsFilePath, json);
```

## Testing

To test the feature:

1. Run the PublicUI app
2. Navigate to Backup Settings
3. Enter test values (e.g., 15 minutes, C:\Temp)
4. Click Save
5. Close and restart the app
6. Verify settings are loaded correctly
7. Check the JSON file at the displayed path

## Notes

- Settings are device-specific (not synced between devices)
- The output directory must have write permissions
- Directory validation happens only when attempting to write
- The folder picker may not be available on all platforms (Web)

# Build Fix for Backup Settings Feature

## Problem
The build was failing with multiple errors related to the `BackupSettings` class name conflict and missing `FolderPicker` API.

## Root Causes

### 1. Class Name Conflict
The Razor component file `BackupSettings.razor` generated a class named `BackupSettings` which conflicted with the model class `MCBDS.ClientUI.Shared.Models.BackupSettings`.

### 2. FolderPicker API Not Available
The `FolderPicker` API is MAUI-specific and not accessible in Blazor Hybrid context without additional setup.

## Solutions Applied

### 1. Renamed Page File
- **Old**: `BackupSettings.razor`
- **New**: `BackupConfig.razor`
- This prevents the class name conflict

### 2. Fully Qualified Model Type
Changed the settings variable declaration from:
```csharp
private BackupSettings settings = new BackupSettings();
```

To:
```csharp
private MCBDS.ClientUI.Shared.Models.BackupSettings settings = new MCBDS.ClientUI.Shared.Models.BackupSettings();
```

### 3. Removed Folder Picker
Removed the Browse button and `FolderPicker` functionality. Users now manually type the directory path.

**Before:**
```razor
<button class="btn btn-outline-secondary" 
        type="button" 
        @onclick="BrowseDirectory"
        disabled="@isSaving">
    Browse
</button>
```

**After:**
Simple text input without browse button.

## Current Status

? **Build Successful**

The page is now working with:
- Text input for frequency (1-1440 minutes)
- Manual text input for output directory
- Save/Load functionality
- Settings stored in JSON format

## Files Changed

1. **Created**: `MCBDS.PublicUI\Components\Pages\BackupConfig.razor` (new name)
2. **Deleted**: `MCBDS.PublicUI\Components\Pages\BackupSettings.razor` (old name)

## Notes

- The route remains `/backup-settings` (unchanged)
- Navigation menu still shows "Backup Settings"
- Users can still configure all settings, just without the folder picker
- For future enhancement, a proper folder picker could be implemented using platform-specific services injected via dependency injection

## Testing

To test:
1. Run PublicUI
2. Navigate to Backup Settings tab
3. Enter frequency and directory path manually
4. Save settings
5. Restart app and verify settings persist

# MCBDS.PublicUI.Android Setup Guide

## ?? Important: Setup Required Before Building

This project requires shared components from MCBDS.PublicUI. You have three options to set them up:

## Quick Start

### Option 1: Use PowerShell Script (Recommended for most users)

**Windows PowerShell (Run as Administrator):**

```powershell
# From the solution root directory (MCBDSHost)
cd C:\path\to\MCBDSHost

# Run with Administrator privileges
Start-Process powershell -ArgumentList "-NoExit -File '.\MCBDS.PublicUI.Android\setup-links.ps1'" -Verb RunAs
```

Or:

```powershell
# If you already have admin PowerShell open
.\MCBDS.PublicUI.Android\setup-links.ps1
```

### Option 2: Use Python Script (Cross-platform)

**Python 3.6+ (recommended for macOS/Linux):**

```bash
cd /path/to/MCBDSHost
python MCBDS.PublicUI.Android/setup-links.py
```

### Option 3: Use Batch Script (Windows)

**Windows Command Prompt (Run as Administrator):**

```cmd
cd C:\path\to\MCBDSHost
MCBDS.PublicUI.Android\setup-links.bat
```

### Option 4: Manual Setup (Command Line)

```powershell
# Run as Administrator
cd MCBDS.PublicUI.Android

# Create symbolic links
mklink /D Components ..\MCBDS.PublicUI\Components
mklink /D wwwroot\lib ..\MCBDS.PublicUI\wwwroot\lib
```

### Option 5: Manual Copy (For non-Admin users)

If you can't run setup scripts, manually copy directories:

1. Open File Explorer
2. Navigate to `MCBDS.PublicUI\Components`
3. Copy the `Layout` folder to `MCBDS.PublicUI.Android\Components\Layout`
4. Copy the `Pages` folder to `MCBDS.PublicUI.Android\Components\Pages`
5. Copy `ServerSwitcher.razor` and `ServerSwitcher.razor.css` to `MCBDS.PublicUI.Android\Components\`
6. Navigate to `MCBDS.PublicUI\wwwroot`
7. Copy the `lib` folder to `MCBDS.PublicUI.Android\wwwroot\lib`

## Building the Android App

After setup is complete:

```bash
# Debug build
dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android

# Release build
dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android -c Release

# Publish as APK
dotnet publish MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android -c Release
```

## Project Structure

```
MCBDSHost/                           (Solution Root)
??? MCBDS.PublicUI/                 (Main UI project)
?   ??? Components/
?   ?   ??? Layout/
?   ?   ??? Pages/
?   ?   ??? ServerSwitcher.razor
?   ??? wwwroot/
?       ??? lib/
?
??? MCBDS.PublicUI.Android/         (Android project)
    ??? App.xaml                    # MAUI Application root
    ??? App.xaml.cs                 # Application logic
    ??? MainPage.xaml               # Main XAML page (hosts BlazorWebView)
    ??? MainPage.xaml.cs
    ?
    ??? MauiProgram.cs              # MAUI/DI Configuration
    ??? MCBDS.PublicUI.Android.csproj # Project file
    ?
    ??? Components/                 # Blazor Components (copied/linked from PublicUI)
    ?   ??? _Imports.razor          # Blazor using statements
    ?   ??? Routes.razor            # Blazor routing configuration
    ?   ??? Layout/                 # ? Copy from MCBDS.PublicUI
    ?   ??? Pages/                  # ? Copy from MCBDS.PublicUI
    ?   ??? ServerSwitcher.razor    # ? Copy from MCBDS.PublicUI
    ?
    ??? Platforms/
    ?   ??? Android/
    ?       ??? MainActivity.cs     # Android entry point
    ?       ??? AndroidManifest.xml # Android configuration
    ?
    ??? wwwroot/
    ?   ??? index.html              # Blazor host HTML
    ?   ??? app.css                 # Global styles
    ?   ??? lib/                    # ? Copy from MCBDS.PublicUI
    ?
    ??? Documentation
        ??? README.md
        ??? SETUP.md                # This file
        ??? setup-links.bat
        ??? setup-links.ps1
        ??? setup-links.py
        ??? .gitignore
```

## Shared Components

The Android app reuses the following from MCBDS.PublicUI:

- **Layout Components**: MainLayout, NavMenu, ServerSwitcher
- **Pages**: Home, Commands, ServerProperties, BackupConfig
- **Styles**: Bootstrap, Bootstrap Icons, app.css
- **Resources**: App icons, fonts, images

## Configuration

### AppSettings
Configuration is managed through `MauiProgram.cs`:

```csharp
// HttpClient for API communication
builder.Services.AddSingleton(httpClient);

// Server configuration service
builder.Services.AddSingleton<ServerConfigService>(sp => 
{
    var client = sp.GetRequiredService<HttpClient>();
    return new ServerConfigService(client, FileSystem.Current.AppDataDirectory);
});

// API communication service
builder.Services.AddSingleton<BedrockApiService>(sp =>
{
    var client = sp.GetRequiredService<HttpClient>();
    var serverConfig = sp.GetRequiredService<ServerConfigService>();
    return new BedrockApiService(client, serverConfig);
});
```

### Android Manifest
Default permissions in `Platforms/Android/AndroidManifest.xml`:
- `android.permission.INTERNET` - Required for API calls
- `android.permission.ACCESS_NETWORK_STATE` - Required for network status

## Building and Testing

### Debug Build (Fast Iteration)
```bash
dotnet build MCBDS.PublicUI.Android -f net10.0-android
```

### Deploy to Emulator
```bash
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### Deploy to Physical Device
```bash
dotnet run MCBDS.PublicUI.Android -f net10.0-android -d [device-id]
```

### Release Build
```bash
dotton publish MCBDS.PublicUI.Android -f net10.0-android -c Release
```

The APK will be located at:
```
MCBDS.PublicUI.Android/bin/Release/net10.0-android/publish/
```

## Troubleshooting

### Components Not Found / Build Fails

**Error**: "Cannot find Components/Layout", "Cannot find Components/Pages", or BLAZOR102 errors

**Solution**:
1. Verify the setup script completed successfully
2. Check that directories exist in MCBDS.PublicUI.Android:
   - `Components\Layout\`
   - `Components\Pages\`
   - `Components\ServerSwitcher.razor`
   - `wwwroot\lib\`
3. If symbolic links failed, manually copy the directories
4. Delete `bin/` and `obj/` folders
5. Rebuild: `dotnet build MCBDS.PublicUI.Android -f net10.0-android`

### Permission Denied / Access Denied

**Solution**:
1. Close any file explorer or IDE windows accessing the directories
2. Run setup script as Administrator
3. Or use the Python script which has better error handling

### Admin Privileges Required

If you can't get admin access:
1. Use Option 5 (Manual Copy) above
2. Or use the Python script
3. Or ask your system administrator to run the setup

### Still Having Issues?

1. Verify MCBDS.PublicUI exists and contains Components folder
2. Run from solution root (MCBDSHost), not from MCBDS.PublicUI.Android
3. Try the Python script: `python MCBDS.PublicUI.Android/setup-links.py`
4. Check that all paths use backslashes on Windows

## Development Workflow

### Making Component Changes

Since components are copied/linked from MCBDS.PublicUI:

1. **Edit components in MCBDS.PublicUI/**
   - Changes apply to both PublicUI and PublicUI.Android (if using links)
   - For copied files, re-run setup script to sync

2. **If you need Android-specific changes**:
   - Create override in `PublicUI.Android/Components/`
   - Or create conditional code using preprocessor directives

### Adding New Features

1. Add feature to MCBDS.PublicUI (main project)
2. Copy component to MCBDS.PublicUI.Android or re-run setup script
3. Test on Android device
4. For Android-only features, create in Android project

## Performance Considerations

- **Cold Start**: ~3-5 seconds (first app launch)
- **Hot Restart**: ~1-2 seconds
- **UI Responsiveness**: Smooth 60 FPS on most Android devices
- **Memory**: ~100-150 MB initial footprint

## Publishing to Google Play

1. Create signing key:
   ```bash
   keytool -genkey -v -keystore mcbds-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias mcbds-key
   ```

2. Update project file with signing info

3. Build signed release:
   ```bash
   dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
   ```

4. Upload APK to Google Play Console

## References

- [.NET MAUI Documentation](https://learn.microsoft.com/dotnet/maui/)
- [Android Development Guide](https://learn.microsoft.com/dotnet/maui/android)
- [Blazor Hybrid Apps](https://learn.microsoft.com/aspnet/core/blazor/hybrid/)
- [Android Manifest Documentation](https://developer.android.com/guide/topics/manifest/manifest-intro)

## Support

For issues or questions:
1. Check this SETUP.md file
2. Review README.md for architecture details
3. Check MCBDS.PublicUI project for component documentation
4. Refer to .NET MAUI official documentation

---

**Last Updated**: 2024
**Compatible With**: .NET 10, MAUI, Android 7.0+

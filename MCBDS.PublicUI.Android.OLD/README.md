# MCBDS.PublicUI.Android Project Setup

## Overview
MCBDS.PublicUI.Android is an Android-only variant of the MCBDS.PublicUI application, targeting .NET 10 and Android 24+.

## Project Structure

```
MCBDS.PublicUI.Android/
??? App.xaml                          # MAUI App root
??? App.xaml.cs
??? MainPage.xaml                     # Main entry page
??? MainPage.xaml.cs
??? MauiProgram.cs                    # MAUI configuration
??? MCBDS.PublicUI.Android.csproj     # Project file
??? Platforms/
?   ??? Android/
?       ??? MainActivity.cs           # Android activity
?       ??? AndroidManifest.xml       # Android permissions
??? Components/
?   ??? _Imports.razor                # Blazor imports
?   ??? Routes.razor                  # Blazor routing
?   ??? (Share with PublicUI)
??? wwwroot/
    ??? index.html                    # Blazor host
    ??? app.css                       # Global styles
    ??? lib/                          # Bootstrap and other libs

```

## Configuration

### Target Framework
- **Target:** net10.0-android
- **Min Android Version:** 24 (Android 7.0 Nougat)
- **Application ID:** com.mcbds.publicui.android

### Dependencies
- Microsoft.Maui.Controls
- Microsoft.AspNetCore.Components.WebView.Maui
- Microsoft.Extensions.Logging.Debug
- MCBDS.ClientUI.Shared (for services)

## Sharing Components

The MCBDS.PublicUI.Android project shares Blazor components with the main MCBDS.PublicUI project. To avoid duplication:

### Option 1: Use Symbolic Links (Recommended)
Create symbolic links from Components directory to shared components:

```powershell
# In MCBDS.PublicUI.Android directory
mklink /D Components ..\MCBDS.PublicUI\Components
mklink /D wwwroot\lib ..\MCBDS.PublicUI\wwwroot\lib
```

### Option 2: Create Shared Library
Move common components to `MCBDS.PublicUI.Shared`:

1. Create new Razor Class Library project
2. Move Components and shared resources there
3. Reference from both PublicUI and PublicUI.Android

### Option 3: Manual Synchronization
Keep components in both projects and synchronize manually (not recommended for large codebases).

## Building

### Build Android Release
```bash
dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android -c Release
```

### Publish to APK
```bash
dotnet publish MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android -c Release
```

## Key Differences from PublicUI

| Aspect | PublicUI | PublicUI.Android |
|--------|----------|------------------|
| Target Frameworks | Windows, iOS, Android, macOS | Android only |
| Application ID | com.companyname.mcbds.publicui | com.mcbds.publicui.android |
| Min Version | Windows 10.0.17763, iOS 15, Android 24 | Android 24+ |
| Use Case | Desktop/Mobile | Mobile/Tablet |

## Services Configuration

Both applications share the same service configuration:

- **ServerConfigService**: Manages server connections with local persistence
- **BedrockApiService**: Communicates with MCBDS.API
- **BackupSettingsService**: Handles backup configuration

Configuration is automatically initialized in `MauiProgram.cs`.

## Android-Specific Considerations

1. **Permissions**: See `AndroidManifest.xml` for required permissions
2. **Storage**: Uses `FileSystem.Current.AppDataDirectory` for data persistence
3. **Network**: Requires INTERNET and ACCESS_NETWORK_STATE permissions
4. **UI**: Responsive design works on various Android screen sizes

## Next Steps

1. Set up symbolic links or create shared library for components
2. Test on Android emulator or device
3. Update bundle ID in `AndroidManifest.xml` if needed
4. Customize app icon and splash screen in Resources folder
5. Build APK for distribution

## References

- [.NET MAUI Documentation](https://learn.microsoft.com/dotnet/maui/)
- [Android Platform Guide](https://learn.microsoft.com/dotnet/maui/android)
- [Blazor Hybrid Documentation](https://learn.microsoft.com/aspnet/core/blazor/hybrid/)

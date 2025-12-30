# MCBDS.PublicUI.Android - Project Summary

## What Was Created

A complete, dedicated **Android application** based on MCBDS.PublicUI that allows management of Minecraft Bedrock Dedicated Servers from Android devices and tablets.

## Project Details

| Property | Value |
|----------|-------|
| **Target Framework** | net10.0-android |
| **Min Android Version** | 24 (Android 7.0 Nougat) |
| **Application ID** | com.mcbds.publicui.android |
| **Type** | .NET MAUI + Blazor Hybrid App |
| **Architecture** | Single-file MAUI app |

## Files Created

### Core Application Files
- `App.xaml` - MAUI Application root UI definition
- `App.xaml.cs` - Application logic and window creation
- `MainPage.xaml` - Main entry page with BlazorWebView
- `MainPage.xaml.cs` - Page code-behind
- `MauiProgram.cs` - Dependency injection and MAUI configuration

### Project Configuration
- `MCBDS.PublicUI.Android.csproj` - Project file with build configuration
- `.gitignore` - Git ignore rules for Android/MAUI builds

### Android Platform Specific
- `Platforms/Android/MainActivity.cs` - Android activity entry point
- `Platforms/Android/AndroidManifest.xml` - Android permissions and configuration

### Blazor Components
- `Components/_Imports.razor` - Blazor using statements and imports
- `Components/Routes.razor` - Blazor routing configuration

### Web Assets
- `wwwroot/index.html` - Blazor host page
- `wwwroot/app.css` - Global application styles

### Documentation
- `README.md` - Architecture and configuration guide
- `SETUP.md` - Comprehensive setup and build instructions
- `setup-links.bat` - Windows batch setup script
- `setup-links.ps1` - PowerShell setup script

## How It Works

### Architecture
```
User Interface (Blazor Components)
          ?
BlazorWebView (XAML)
          ?
.NET MAUI Application
          ?
Services (HttpClient, ServerConfigService, BedrockApiService)
          ?
MCBDS.API (REST endpoints)
```

### Component Sharing
Instead of duplicating code, MCBDS.PublicUI.Android uses **symbolic links** to share:
- Blazor component files (.razor)
- CSS stylesheets
- Bootstrap and icon libraries

This means:
- ? Single source of truth for UI components
- ? Changes to PublicUI automatically apply to PublicUI.Android
- ? No code duplication
- ? Easier maintenance

### Key Features Included
1. **Server Selection** - Connect to different MCBDS servers
2. **Server Commands** - Send commands to the server with live log viewing
3. **Server Properties** - View server configuration
4. **Backup Management** - Configure and manage automatic backups
5. **System Monitoring** - Real-time status of server and API host
6. **Responsive UI** - Adapts to phone and tablet screens

## Getting Started

### 1. Initial Setup
Run one of the setup scripts to create symbolic links:

**PowerShell (Recommended):**
```powershell
# Run as Administrator
cd C:\path\to\MCBDSHost
.\MCBDS.PublicUI.Android\setup-links.ps1
```

**Command Prompt:**
```cmd
REM Run as Administrator
cd C:\path\to\MCBDSHost
MCBDS.PublicUI.Android\setup-links.bat
```

### 2. Build for Development
```bash
dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android
```

### 3. Run on Emulator
```bash
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### 4. Build Release APK
```bash
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
```

## Dependencies

### NuGet Packages
- `Microsoft.Maui.Controls` - MAUI framework
- `Microsoft.AspNetCore.Components.WebView.Maui` - Blazor WebView for MAUI
- `Microsoft.Extensions.Logging.Debug` - Logging for debugging

### Project References
- `MCBDS.ClientUI.Shared` - Shared services (BedrockApiService, ServerConfigService)

### Shared Components (via Symbolic Links)
- `MCBDS.PublicUI/Components/` - All Blazor components
- `MCBDS.PublicUI/wwwroot/lib/` - Bootstrap, icons, libraries

## Development Workflow

### Making Changes to Shared Components
1. Edit component files in `MCBDS.PublicUI/Components/`
2. Changes automatically reflect in PublicUI.Android (via symbolic links)
3. Rebuild PublicUI.Android to test on Android

### Android-Specific Changes
If you need Android-only modifications:
1. Create override file in `MCBDS.PublicUI.Android/Components/`
2. Use conditional compilation or routing to differentiate
3. Update symbolic links if needed

### Testing
- **Debug**: Use Android emulator for rapid iteration
- **Release**: Build APK and test on physical device
- **Performance**: Test on various Android devices (API 24-34)

## Project Structure Overview

```
MCBDS.PublicUI.Android/
??? Core Files
?   ??? App.xaml
?   ??? App.xaml.cs
?   ??? MainPage.xaml
?   ??? MainPage.xaml.cs
?   ??? MauiProgram.cs
?   ??? MCBDS.PublicUI.Android.csproj
?
??? Platforms/
?   ??? Android/
?       ??? MainActivity.cs
?       ??? AndroidManifest.xml
?
??? Components/ (symbolic links)
?   ??? Layout/
?   ??? Pages/
?   ??? ServerSwitcher.razor
?
??? wwwroot/
?   ??? index.html
?   ??? app.css
?   ??? lib/ (symbolic link)
?
??? Documentation
    ??? README.md
    ??? SETUP.md
    ??? setup-links.ps1
    ??? setup-links.bat
    ??? .gitignore
```

## Building the APK

### Debug APK
```bash
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Debug
# Output: bin/Debug/net10.0-android/publish/*.apk
```

### Release APK (Ready for Distribution)
```bash
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
# Output: bin/Release/net10.0-android/publish/*.apk
```

### Optional: Sign with Key
For distribution on Google Play, sign the APK with a keystore.

## System Requirements

### For Building
- .NET 10 SDK
- Android SDK with API 24+ platform
- Visual Studio 2022 (with MAUI workload) or VS Code

### For Running
- Android 7.0 (API 24) or higher
- Minimum 100MB free storage
- Internet connection (for API communication)

## Technical Highlights

? **Single Project** - Entire Android app in one project file
? **Component Reuse** - Shares UI with Windows/Web versions via symbolic links
? **Responsive Design** - Adapts to phones, tablets, and landscape mode
? **Service Injection** - Uses .NET DI for clean architecture
? **Hybrid App** - Combines XAML UI framework with Blazor web UI
? **Offline Support** - Saves server config locally
? **No Code Duplication** - Shared components, no manual sync needed

## Next Steps

1. ? Run setup scripts to create symbolic links
2. ? Build the project successfully  
3. Test on Android emulator or device
4. Customize app icon and branding if needed
5. Build release APK for distribution
6. (Optional) Publish to Google Play Store

## Support & Documentation

- **Setup Guide**: `SETUP.md` in this directory
- **Architecture**: `README.md` in this directory
- **Base Components**: See `MCBDS.PublicUI/` for component documentation
- **.NET MAUI**: https://learn.microsoft.com/dotnet/maui/
- **Blazor Hybrid**: https://learn.microsoft.com/aspnet/core/blazor/hybrid/

---

**Status**: ? Ready for Development
**Build Status**: ? Compiles Successfully
**Last Updated**: 2024

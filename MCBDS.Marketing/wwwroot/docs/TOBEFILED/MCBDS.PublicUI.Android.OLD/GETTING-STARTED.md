# MCBDS.PublicUI.Android - Setup Guide (Updated)

## ?? Overview

MCBDS.PublicUI.Android is an Android-only variant of MCBDS.PublicUI for managing Minecraft Bedrock Dedicated Servers on Android devices and tablets.

**Status**: ? Ready for setup  
**Target**: Android 7.0+ (API 24+)  
**Framework**: .NET MAUI + Blazor Hybrid

## ?? Quick Setup (5 minutes)

### Step 1: Choose Your Setup Method

**A. PowerShell (Windows, Recommended)**
```powershell
# Run as Administrator from solution root
cd C:\path\to\MCBDSHost
.\MCBDS.PublicUI.Android\setup-links.ps1
```

**B. Python (All Platforms)**
```bash
cd /path/to/MCBDSHost
python MCBDS.PublicUI.Android/setup-links.py
```

**C. Batch (Windows)**
```cmd
# Run as Administrator from solution root
cd C:\path\to\MCBDSHost
MCBDS.PublicUI.Android\setup-links.bat
```

**D. Manual Copy (No Admin Required)**
Just copy these directories:
- `MCBDS.PublicUI\Components\Layout` ? `MCBDS.PublicUI.Android\Components\Layout`
- `MCBDS.PublicUI\Components\Pages` ? `MCBDS.PublicUI.Android\Components\Pages`
- `MCBDS.PublicUI\Components\ServerSwitcher.razor*` ? `MCBDS.PublicUI.Android\Components\`
- `MCBDS.PublicUI\wwwroot\lib` ? `MCBDS.PublicUI.Android\wwwroot\lib`

### Step 2: Build
```bash
dotnet build MCBDS.PublicUI.Android -f net10.0-android
```

### Step 3: Run/Test
```bash
# Debug on emulator
dotnet run MCBDS.PublicUI.Android -f net10.0-android

# Release APK
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
```

## ?? What Gets Copied/Linked

| Source | Destination | Purpose |
|--------|-------------|---------|
| `MCBDS.PublicUI/Components/Layout/` | `Android/Components/Layout/` | UI layouts (MainLayout, NavMenu) |
| `MCBDS.PublicUI/Components/Pages/` | `Android/Components/Pages/` | App pages (Home, Commands, etc.) |
| `MCBDS.PublicUI/Components/ServerSwitcher.*` | `Android/Components/` | Server selection component |
| `MCBDS.PublicUI/wwwroot/lib/` | `Android/wwwroot/lib/` | Bootstrap, icons, libraries |

## ? Verify Setup

After running setup, check these directories exist:

```
MCBDS.PublicUI.Android/
??? Components/
?   ??? Layout/
?   ?   ??? MainLayout.razor
?   ?   ??? MainLayout.razor.css
?   ?   ??? NavMenu.razor
?   ?   ??? NavMenu.razor.css
?   ??? Pages/
?   ?   ??? Home.razor
?   ?   ??? Commands.razor
?   ?   ??? Commands.razor.css
?   ?   ??? ServerProperties.razor
?   ?   ??? BackupConfig.razor
?   ??? ServerSwitcher.razor
?   ??? ServerSwitcher.razor.css
??? wwwroot/
    ??? lib/
        ??? bootstrap/
        ??? (other libraries)
```

If missing, manually copy them.

## ??? Build Commands

```bash
# Debug build (fast)
dotnet build MCBDS.PublicUI.Android -f net10.0-android

# Release build (optimized)
dotnet build MCBDS.PublicUI.Android -f net10.0-android -c Release

# Run on emulator/device
dotnet run MCBDS.PublicUI.Android -f net10.0-android

# Create APK
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
```

## ?? Troubleshooting

### Setup Script Fails
- [ ] Run as Administrator
- [ ] Run from solution root (MCBDSHost), not from Android folder
- [ ] Close Visual Studio/file explorer that might lock files
- [ ] Try Python script instead: `python setup-links.py`
- [ ] Use manual copy if scripts don't work

### Build Fails ("Components not found")
- [ ] Verify directories exist in Android\Components\
- [ ] Delete `bin/` and `obj/` folders
- [ ] Rebuild: `dotnet build MCBDS.PublicUI.Android -f net10.0-android`

### APK Not Created
- [ ] Verify Release build completed
- [ ] Check: `MCBDS.PublicUI.Android\bin\Release\net10.0-android\publish\`

## ?? Files Provided

| File | Purpose |
|------|---------|
| `setup-links.ps1` | PowerShell setup script (Windows, recommended) |
| `setup-links.bat` | Batch script (Windows, requires admin) |
| `setup-links.py` | Python script (cross-platform, recommended) |
| `SETUP.md` | Detailed setup instructions |
| `README.md` | Architecture and design |
| `QUICK-REFERENCE.md` | Common commands |
| `PROJECT-SUMMARY.md` | Complete project overview |

## ?? Next Steps After Setup

1. ? Run setup script
2. ? Build project: `dotnet build`
3. ? Test on Android emulator: `dotnet run`
4. ? Configure server URL in app
5. ? Build release APK for distribution

## ?? System Requirements

**For Building:**
- .NET 10 SDK
- Android SDK API 24+
- Visual Studio 2022 (or VS Code + CLI tools)

**For Running:**
- Android 7.0+ (API 24+)
- ~150MB RAM
- Internet connection

##  ?? Key Files

- **MauiProgram.cs** - DI configuration
- **App.xaml** - MAUI app root
- **MainPage.xaml** - Blazor WebView host
- **Platforms/Android/MainActivity.cs** - Android entry point
- **AndroidManifest.xml** - Permissions and configuration

## ?? Documentation

See these files for more details:

- **SETUP.md** - Complete setup guide with 5 options
- **README.md** - Architecture and component organization  
- **QUICK-REFERENCE.md** - Command cheat sheet
- **PROJECT-SUMMARY.md** - Full project overview

## ? Features

? Server selection and connection management  
? Live command execution with log viewing  
? Real-time server monitoring  
? Backup scheduling and management  
? Responsive design for phones/tablets  
? Offline configuration storage  
? Same UI as Windows version

## ?? Development Notes

- Components are **copied/linked** from MCBDS.PublicUI
- Edit source components in MCBDS.PublicUI
- Re-run setup script to sync changes
- Or create Android-specific overrides if needed

## ?? Getting Help

1. **Components missing?** ? Run setup script again
2. **Build errors?** ? Delete `bin/`/`obj/`, rebuild
3. **App crashes?** ? Check AndroidManifest.xml permissions
4. **Can't connect?** ? Verify INTERNET permission enabled

## ?? Publishing to Google Play

See "Publishing to Google Play" section in SETUP.md for complete instructions.

---

**Ready to start?** Choose your setup method above and follow Step 1!  
**Need more details?** See SETUP.md for complete instructions.

**Status**: ? Build Successful | ? Documentation Complete | ? Awaiting Setup

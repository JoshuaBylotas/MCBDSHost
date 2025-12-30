# MCBDS.PublicUI.Android - Quick Reference

## ?? BLANK SCREEN AFTER SPLASH? READ THIS FIRST! ??

### If "adb" command not found:

```powershell
# Option 1: Run our setup script (finds and configures ADB)
.\MCBDS.PublicUI.Android\setup-adb.ps1

# Option 2: Use Chrome DevTools instead (EASIER!)
# Open Chrome, go to: chrome://inspect/#devices
# Find your app, click "inspect"
```

### Immediate Debug Steps:

**Use Chrome DevTools (No ADB needed!):**
1. Open Chrome browser on your PC
2. Navigate to: `chrome://inspect/#devices`
3. Find "MCBDS Manager" or "com.mcbds.publicui.android"
4. Click "inspect"
5. Check **Console tab** for JavaScript errors
6. Check **Network tab** for 404 errors (missing files)

**If you have ADB working:**
```bash
# Terminal 1: Watch Android logs
adb logcat | findstr "MCBDS\|Blazor\|Exception"

# Terminal 2: Run app
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### Common Blank Screen Fixes:

| Problem | Fix |
|---------|-----|
| "Loading..." forever | Check Chrome Console for JS errors |
| Blank white screen | index.html not deployed - rebuild |
| Brief flash then blank | Component missing - run setup-links.py |
| No errors but still blank | Check Chrome Network tab for 404s |
| "adb not recognized" | Run `.\setup-adb.ps1` or use Chrome DevTools |

**See BLANK_SCREEN_FIX.txt for complete guide**

---

## ?? Quick Start

### 1. Setup (One-time)
```powershell
# Run as Administrator OR use Python script
python MCBDS.PublicUI.Android/setup-links.py
```

### 2. Build
```bash
# Debug
dotnet build MCBDS.PublicUI.Android -f net10.0-android

# Release
dotnet build MCBDS.PublicUI.Android -f net10.0-android -c Release
```

### 3. Run
```bash
# On emulator/device
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### 4. Publish APK
```bash
dotnet publish MCBDS.PublicUI.Android -f net10.0-android -c Release
```

---

## ?? Project Structure

```
MCBDS.PublicUI.Android/
??? App.xaml / MainPage.xaml    ? MAUI UI layer
??? MauiProgram.cs              ? Configuration
??? Components/                 ? Blazor components (linked)
??? wwwroot/                    ? Web assets
??? Platforms/Android/          ? Android-specific
??? setup-adb.ps1              ? Find/setup ADB tool ?NEW
??? Documentation               ? Setup guides
```

---

## ?? Symbolic Links

These directories are **linked** to MCBDS.PublicUI to avoid duplication:
- `Components/Layout/` ? `../MCBDS.PublicUI/Components/Layout/`
- `Components/Pages/` ? `../MCBDS.PublicUI/Components/Pages/`
- `wwwroot/lib/` ? `../MCBDS.PublicUI/wwwroot/lib/`

**Changes to MCBDS.PublicUI automatically apply here!**

---

## ? Common Tasks

| Task | Command |
|------|---------|
| **Setup ADB** | `.\MCBDS.PublicUI.Android\setup-adb.ps1` ? |
| Clean build | `dotnet clean && dotnet build MCBDS.PublicUI.Android -f net10.0-android` |
| Debug build | `dotnet build -c Debug` |
| Release build | `dotnet build -c Release` |
| Run on Android | `dotnet run` |
| Build APK | `dotnet publish -c Release` |
| View output APK | `.\bin\Release\net10.0-android\publish\` |
| **Chrome DevTools** | Open `chrome://inspect/#devices` ? |
| Watch logs (if ADB works) | `adb logcat \| findstr "MCBDS"` |
| Clear app data | `adb shell pm clear com.mcbds.publicui.android` |

---

## ?? Build Output Locations

```
MCBDS.PublicUI.Android/
??? bin/
?   ??? Debug/net10.0-android/    ? Debug builds
?   ??? Release/net10.0-android/publish/  ? APK files here
??? obj/                          ? Build artifacts
```

---

## ?? Troubleshooting

| Issue | Solution |
|-------|----------|
| "adb not recognized" | Run `.\setup-adb.ps1` **OR** use Chrome DevTools |
| Components not found | Run setup script: `python setup-links.py` |
| Build fails | Delete `bin/` and `obj/`, rebuild |
| APK not created | Check Release build completed successfully |
| **Blank screen after splash** | **Use chrome://inspect or check BLANK_SCREEN_FIX.txt** |
| **App crashes on launch** | **Check DEBUGGING.md and use Chrome DevTools** |
| Can't connect to server | Verify INTERNET permission in manifest |
| Loading forever | Use chrome://inspect to check JS console |

---

## ?? Target Specifications

- **Platform**: Android 7.0+ (API 24+)
- **Min Size**: ~25MB APK
- **Runtime Memory**: 100-150MB
- **Target Devices**: Phones and Tablets

---

## ?? Development Workflow

### For UI Changes
1. Edit `.razor` files in `MCBDS.PublicUI/Components/`
2. Changes auto-apply to Android (via links)
3. Rebuild and test

### For Android-Only Changes
1. Create override in `MCBDS.PublicUI.Android/Components/`
2. Use conditional compilation if needed
3. Test thoroughly

---

## ?? Dependencies

- Microsoft.Maui.Controls
- Microsoft.AspNetCore.Components.WebView.Maui
- MCBDS.ClientUI.Shared (Services)

---

## ? Checklist

- [ ] Setup script run (`python setup-links.py`)
- [ ] Components directory has all files
- [ ] wwwroot has index.html and lib folder
- [ ] Solution builds without errors
- [ ] AndroidManifest.xml has INTERNET permission
- [ ] Tested on Android emulator or device
- [ ] Can debug with Chrome DevTools (`chrome://inspect`)
- [ ] (Optional) ADB setup complete if needed

---

## ?? Documentation

- **setup-adb.ps1** - Find and setup Android Debug Bridge ?NEW
- **BLANK_SCREEN_FIX.txt** - Fix blank screen issues
- **DEBUGGING.md** - Complete debugging guide
- **HOWTO_DEBUG.txt** - Quick debug reference
- **PROJECT-SUMMARY.md** - Complete overview
- **README.md** - Architecture details
- **SETUP.md** - Detailed setup guide

---

## ?? Useful Links

- [.NET MAUI Docs](https://learn.microsoft.com/dotnet/maui/)
- [Android Development](https://learn.microsoft.com/dotnet/maui/android)
- [Blazor Hybrid](https://learn.microsoft.com/aspnet/core/blazor/hybrid/)
- [Chrome DevTools for Android](https://developer.chrome.com/docs/devtools/remote-debugging/)
- [Android Platform Tools Download](https://developer.android.com/tools/releases/platform-tools)

---

## ?? Getting Help

**"adb not recognized"?**
1. Run: `.\MCBDS.PublicUI.Android\setup-adb.ps1`
2. OR: Use Chrome DevTools instead (easier!)
3. OR: Install from: https://developer.android.com/tools/releases/platform-tools

**Blank screen?**
1. Use Chrome: `chrome://inspect/#devices`
2. Click "inspect" on your app
3. Check Console and Network tabs
4. See BLANK_SCREEN_FIX.txt

**Need detailed logs?**
1. Use Chrome DevTools (recommended)
2. OR if ADB works: `adb logcat > full-log.txt`
3. Check full-log.txt for errors

---

**Last Updated**: 2024  
**Status**: ? Ready for Development | ?? Enhanced Debug Logging | ?? ADB Setup Tool Added

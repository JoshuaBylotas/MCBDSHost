# MCBDS.PublicUI.Android - Debug Guide

## The Problem

When running `dotnet run` you get:

```
The target process exited without raising a CoreCLR started event.
The program '[27632] dotnet.exe' has exited with code 2147516566 (0x80008096).
```

**This means the app crashed BEFORE the debugger attached.**

## Solution: View Android Device Logs

The app IS running on the Android device/emulator, but it's crashing. You need to see the **Android logs**, not the Visual Studio debugger.

### Step 1: Open Android Device Monitor / Logcat

**Option A: Android Studio (Recommended)**
```
1. Open Android Studio
2. Click "Device Manager" (left sidebar)
3. Start an emulator or connect a device
4. Bottom menu: "Logcat" tab
5. Filter by your app package name: com.mcbds.publicui.android
```

**Option B: Command Line (adb logcat)**
```bash
# First build and run
dotnet run MCBDS.PublicUI.Android -f net10.0-android

# In another terminal, watch the logs
adb logcat | findstr "MCBDS\|PID=.*com.mcbds\|Exception\|Error\|Debug"
```

**Option C: Visual Studio - Device Log**
```
1. Tools > Device Manager
2. Select your emulator/device  
3. View > Logs
```

### Step 2: Read the Debug Output

Now when you run the app, look for our debug messages:

```
? HttpClient registered
? ServerConfigService registered
? BedrockApiService registered
? Blazor WebView registered
? MAUI app built successfully
```

If you see these messages in Logcat, the app should launch.

### Step 3: Identify Where It Fails

Our code now logs each initialization step. If you see:

```
? ServerConfigService registration failed: ...
```

Then you know exactly which component is causing the crash.

## Common Issues and Fixes

### Issue 1: Components Directory Missing

**Error in Logcat:**
```
FileNotFoundException: ... Components\Layout\MainLayout.razor not found
```

**Fix:**
```bash
# Copy components from PublicUI
python MCBDS.PublicUI.Android/setup-links.py

# Then rebuild
dotnet build MCBDS.PublicUI.Android -f net10.0-android
```

### Issue 2: wwwroot/index.html Missing

**Error in Logcat:**
```
BlazorWebView initialization failed
Cannot find index.html
```

**Fix:**
- Verify `MCBDS.PublicUI.Android/wwwroot/index.html` exists
- Should contain a div with id="app"

### Issue 3: ServerConfigService Crash

**Error in Logcat:**
```
? ServerConfigService registration failed: System.IO.IOException
```

**Fix:**
- FileSystem.Current.AppDataDirectory might not be accessible
- Check AndroidManifest.xml has storage permissions

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Issue 4: No Debug Output At All

**Means:** App is crashing before even reaching MauiProgram

**What to do:**
1. Check Android Logcat for system-level errors
2. Verify all files are in place
3. Try with release build: `dotnet run -c Release`
4. Check that MCBDS.ClientUI.Shared is properly referenced

## How to Debug with Logcat

### View Real-Time Logs

```bash
# Watch all logs
adb logcat

# Filter to just your app
adb logcat | findstr "MCBDS"

# Filter to just errors
adb logcat | findstr "Error\|Exception\|FAILED"

# Save to file
adb logcat > logs.txt
```

### Search for Specific Messages

Look for:
- `?` symbols = successful initialization
- `?` symbols = initialization failures
- `CRITICAL ERROR` = MauiProgram failure
- `Exception` = any .NET exception

### Example Output When Working

```
D/monodroid: Using base directory 'data/data/com.mcbds.publicui.android'
D/monodroid-debug: Trying to load 'MCBDS.PublicUI.Android'
I/mono: ? HttpClient registered
I/mono: ? ServerConfigService registered
I/mono: ? BedrockApiService registered
I/mono: ? Blazor WebView registered
I/mono: ? MAUI app built successfully
I/ActivityManager: Displayed com.mcbds.publicui.android/.MainActivity: +2s234ms
```

## Step-by-Step Debug Process

### 1. Clean Everything
```bash
cd MCBDS.PublicUI.Android
rm -r bin obj
```

### 2. Setup Components
```bash
python setup-links.py
```

### 3. Rebuild
```bash
dotnet build MCBDS.PublicUI.Android -f net10.0-android
```

### 4. Start Logcat Monitoring
```bash
adb logcat | findstr "MCBDS"
```

### 5. Run App
```bash
# In another terminal
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### 6. Watch Logcat for Output
- Look for our `?` or `?` messages
- Note where it fails
- Copy the error message

### 7. Fix the Issue
Based on the error:
- Add missing files
- Fix permissions
- Update configuration

## If Still Stuck

### Get Full Stack Trace
```bash
adb logcat | findstr "Exception"
# Or search for "System.IO\|System.Net\|Initialization"
```

### Clear App Data and Cache
```bash
adb shell pm clear com.mcbds.publicui.android
dotnet run MCBDS.PublicUI.Android -f net10.0-android
```

### Try Release Build
```bash
dotnet run MCBDS.PublicUI.Android -f net10.0-android -c Release
```

### Check Physical Device vs Emulator
```bash
# List connected devices
adb devices

# Run on specific device
adb -s <device-id> logcat | findstr "MCBDS"
```

## Windows-Specific Note

If you're on Windows and get file access errors, check:

1. **File Paths**: Use backslashes in AndroidManifest.xml
2. **Permissions**: Run Visual Studio as Administrator (may be needed for adb)
3. **Antivirus**: Temporarily disable if causing file access issues
4. **Windows Firewall**: May block emulator communication

## Reference: Our Debug Messages

The app now outputs these messages in order (you should see them in Logcat):

```
MauiProgram.CreateMauiApp() starting
  ? HttpClient registered ?
  ? ServerConfigService registered ?
  ? BedrockApiService registered ?
  ? Blazor WebView registered ?
  ? Developer tools registered ?
  ? Building MAUI app...
  ? MAUI app built successfully ?

App.xaml.cs constructor
  ? InitializeComponent completed ?

App.CreateWindow()
  ? MainPage created ?
  ? Window created successfully ?

MainPage constructor
  ? InitializeComponent completed ?

BlazorWebView
  ? Initializing Blazor...
  ? Routes loaded ?
  ? App running! ?
```

If you see messages up to a certain point then it stops, that's where the error is.

## Getting Help

When you get an error:

1. **Copy the full error from Logcat**
2. **Note which `?` message appears** (or if none appear)
3. **Check if it's before or after "MAUI app built successfully"**
4. **Share the error message**

---

**Updated**: 2024  
**Android API**: 24+  
**Framework**: .NET 10 MAUI  
**Debug Tool**: Android Logcat (via Android Studio or adb)

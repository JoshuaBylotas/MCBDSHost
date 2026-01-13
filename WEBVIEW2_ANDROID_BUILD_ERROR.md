# WebView2 Windows Forms Android Build Error - Resolution

## Problem

Build error when building for Android (or other non-Windows platforms):

```
Precompiling failed for Microsoft.Web.WebView2.WinForms.dll with exit code 1.
Failed to load method 0x6000010 from 'Microsoft.Web.WebView2.WinForms.dll' due to 
Could not load file or assembly 'System.Windows.Forms, Version=4.0.0.0' or one of its dependencies.
AOT of image Microsoft.Web.WebView2.WinForms.dll failed.
```

## Root Cause

The `Microsoft.Web.WebView2` NuGet package was included for **all platforms** in a multi-targeted .NET MAUI project. This package contains Windows-specific assemblies (including `Microsoft.Web.WebView2.WinForms.dll`) that depend on `System.Windows.Forms`, which doesn't exist on Android, iOS, or macOS.

### Why This Happens

- .NET MAUI projects can target multiple platforms (Android, iOS, macOS Catalyst, Windows)
- WebView2 is a **Windows-only** technology
- When building for Android, the build process tries to include Windows assemblies
- Android AOT (Ahead-Of-Time compilation) fails because it can't resolve Windows dependencies

## Solution

**Make the WebView2 package reference conditional for Windows only.**

### Before (Incorrect):

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.Maui.Controls" Version="10.0.20" />
  <PackageReference Include="Microsoft.AspNetCore.Components.WebView.Maui" Version="10.0.0" />
  <PackageReference Include="Microsoft.Extensions.Logging.Debug" Version="10.0.1" />
  <PackageReference Include="Microsoft.Web.WebView2" Version="1.0.3179.45" />
</ItemGroup>
```

### After (Correct):

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.Maui.Controls" Version="10.0.20" />
  <PackageReference Include="Microsoft.AspNetCore.Components.WebView.Maui" Version="10.0.0" />
  <PackageReference Include="Microsoft.Extensions.Logging.Debug" Version="10.0.1" />
</ItemGroup>

<!-- Windows-only packages - WebView2 only works on Windows -->
<ItemGroup Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'">
  <PackageReference Include="Microsoft.Web.WebView2" Version="1.0.3179.45" />
</ItemGroup>
```

## Implementation Steps

1. **Edit the .csproj file** (`MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj`)

2. **Move the WebView2 package** to a conditional ItemGroup

3. **Clean the project:**
   ```powershell
   Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI\obj" -Recurse -Force
   Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI\bin" -Recurse -Force
   ```

4. **Restore packages:**
   ```powershell
   dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj"
   ```

5. **Rebuild the solution** in Visual Studio or via command line

## What Changed

**File**: `MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj`

- Removed `Microsoft.Web.WebView2` from the main `<ItemGroup>`
- Added new conditional `<ItemGroup>` that only includes WebView2 for Windows
- The condition `$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'` ensures the package is only included when building for Windows

## Verification

After making the change, verify:

1. **Android builds successfully** without WebView2 errors
2. **Windows builds still include WebView2** when needed
3. **iOS and macOS builds** also work without errors

```powershell
# Test build for Windows
dotnet build MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj -f net10.0-windows10.0.19041.0

# Test build for Android
dotnet build MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj -f net10.0-android
```

## Related Platform-Specific Packages

Other Windows-only packages that should be conditional:

- `Microsoft.Windows.SDK.Contracts`
- `Microsoft.WindowsAppSDK`
- `Microsoft.Windows.CsWinRT`
- Any WinUI 3 or UWP-specific packages

## Common Platform-Specific Package Scenarios

### Windows-only:
```xml
<ItemGroup Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'">
  <PackageReference Include="Microsoft.Web.WebView2" Version="1.0.3179.45" />
</ItemGroup>
```

### Android-only:
```xml
<ItemGroup Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'android'">
  <PackageReference Include="Xamarin.AndroidX.Core" Version="1.10.0" />
</ItemGroup>
```

### iOS-only:
```xml
<ItemGroup Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'ios'">
  <PackageReference Include="Xamarin.iOS.Something" Version="1.0.0" />
</ItemGroup>
```

## Why Use AspNetCore.Components.WebView.Maui Instead?

The package `Microsoft.AspNetCore.Components.WebView.Maui` is **cross-platform** and works on all MAUI-supported platforms. It provides:

- WebView for Android (using Android WebView)
- WebView for iOS (using WKWebView)
- WebView for macOS Catalyst (using WKWebView)
- WebView for Windows (using WebView2 when available)

**Use `Microsoft.Web.WebView2` directly only when:**
- You need Windows-specific WebView2 APIs
- You're building a Windows-only feature
- You need advanced WebView2 functionality not exposed by MAUI

## Prevention

To prevent similar issues in the future:

1. **Check package documentation** - See if a package is platform-specific
2. **Use conditional ItemGroups** - Always condition platform-specific packages
3. **Test all platforms** - Build for all target platforms before committing
4. **Review package dependencies** - Check what dependencies are pulled in

## Quick Fix Command

```powershell
# Clean, restore, and rebuild
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI\obj","MCBDS.ClientUI\MCBDS.ClientUI\bin" -Recurse -Force -ErrorAction SilentlyContinue
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj"
dotnet build "MCBDS.ClientUI\MCBDS.ClientUI\MCBDS.ClientUI.csproj"
```

## Status

? **Issue Resolved** - WebView2 package is now conditional for Windows only, Android builds will succeed.

---

**Last Updated:** January 12, 2026  
**Resolution:** Made `Microsoft.Web.WebView2` package reference conditional for Windows platform only

# Find and Setup ADB for Android Debugging
# Run this script to locate adb.exe and add it to PATH

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Android Debug Bridge (ADB) Setup for MCBDS.PublicUI.Android"
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Search for adb.exe
Write-Host "Searching for adb.exe on your system..." -ForegroundColor Yellow
Write-Host ""

$possiblePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
    "${env:ProgramFiles(x86)}\Android\android-sdk\platform-tools",
    "C:\Android\platform-tools",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools"
)

$adbPath = $null

foreach ($path in $possiblePaths) {
    if (Test-Path "$path\adb.exe") {
        $adbPath = $path
        Write-Host "? Found ADB at: $adbPath" -ForegroundColor Green
        break
    }
}

if (-not $adbPath) {
    Write-Host "Searching entire system (this may take a minute)..." -ForegroundColor Yellow
    $found = Get-ChildItem -Path "C:\" -Filter "adb.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $adbPath = $found.DirectoryName
        Write-Host "? Found ADB at: $adbPath" -ForegroundColor Green
    }
}

if ($adbPath) {
    Write-Host ""
    Write-Host "ADB Location: $adbPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Test if adb works
    $adbExe = "$adbPath\adb.exe"
    try {
        $version = & $adbExe version 2>&1 | Select-Object -First 1
        Write-Host "ADB Version: $version" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not execute adb.exe" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Use full path (works now, no changes needed):" -ForegroundColor White
    Write-Host "   & `"$adbExe`" logcat | Select-String 'MCBDS'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Add to PATH (permanent, need to restart PowerShell):" -ForegroundColor White
    Write-Host "   Run this script with -AddToPath flag" -ForegroundColor Gray
    Write-Host ""
    
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -like "*$adbPath*") {
        Write-Host "? ADB is already in your PATH!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now use: adb logcat" -ForegroundColor White
    } else {
        Write-Host "Do you want to add ADB to your PATH? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            try {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$adbPath", "User")
                Write-Host ""
                Write-Host "? Added ADB to PATH successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "IMPORTANT: Close and reopen PowerShell for changes to take effect" -ForegroundColor Yellow
                Write-Host "Then you can use: adb logcat" -ForegroundColor White
            } catch {
                Write-Host ""
                Write-Host "? Failed to add to PATH. You may need to run PowerShell as Administrator." -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Quick Commands:" -ForegroundColor Cyan
    Write-Host "  List devices:  & `"$adbExe`" devices" -ForegroundColor Gray
    Write-Host "  Clear logs:    & `"$adbExe`" logcat -c" -ForegroundColor Gray
    Write-Host "  View logs:     & `"$adbExe`" logcat | Select-String 'MCBDS'" -ForegroundColor Gray
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "? ADB not found on your system" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Install Android Studio:" -ForegroundColor White
    Write-Host "   Download from: https://developer.android.com/studio" -ForegroundColor Gray
    Write-Host "   ADB is included with Android Studio" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Install Android SDK Platform Tools only:" -ForegroundColor White
    Write-Host "   Download from: https://developer.android.com/tools/releases/platform-tools" -ForegroundColor Gray
    Write-Host "   Extract to: C:\Android\platform-tools\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Use Chrome DevTools instead (no ADB needed):" -ForegroundColor White
    Write-Host "   1. Open Chrome browser" -ForegroundColor Gray
    Write-Host "   2. Go to: chrome://inspect/#devices" -ForegroundColor Gray
    Write-Host "   3. Find your app and click 'inspect'" -ForegroundColor Gray
    Write-Host "   4. Check Console and Network tabs" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan

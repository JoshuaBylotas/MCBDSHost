# Emergency Debug Script - Run this to diagnose the blank screen issue
# This will show you EXACTLY what's happening

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  MCBDS.PublicUI.Android Emergency Diagnostics"
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Find ADB - check PATH first since we added it there
Write-Host "Finding ADB..." -ForegroundColor Yellow

# Method 1: Check if adb is in PATH (fastest)
$adb = $null
try {
    $adbTest = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbTest) {
        $adb = $adbTest.Source
        Write-Host "? Found ADB in PATH: $adb" -ForegroundColor Green
    }
} catch {}

# Method 2: Search common locations
if (-not $adb) {
    Write-Host "Not in PATH, searching common locations..." -ForegroundColor Yellow
    
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\platform-tools\adb.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools\adb.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools\adb.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\Extensions\Xamarin.VisualStudio\Android\platform-tools\adb.exe",
        "${env:ProgramFiles(x86)}\Android\android-sdk\platform-tools\adb.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $adb = $path
            Write-Host "? Found ADB at: $adb" -ForegroundColor Green
            break
        }
    }
}

# Method 3: Deep search if still not found
if (-not $adb) {
    Write-Host "Searching entire system (may take a moment)..." -ForegroundColor Yellow
    $found = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "adb.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $adb = $found.FullName
        Write-Host "? Found ADB at: $adb" -ForegroundColor Green
    }
}

if ($adb) {
    Write-Host ""
    
    # Check if device is connected
    Write-Host "Checking connected devices..." -ForegroundColor Yellow
    $devices = & $adb devices
    Write-Host $devices
    Write-Host ""
    
    # Check if app is installed
    Write-Host "Checking if app is installed..." -ForegroundColor Yellow
    $installed = & $adb shell pm list packages | Select-String "mcbds"
    if ($installed) {
        Write-Host "? App is installed: $installed" -ForegroundColor Green
    } else {
        Write-Host "? App is NOT installed" -ForegroundColor Red
        Write-Host "Run: dotnet run MCBDS.PublicUI.Android -f net10.0-android" -ForegroundColor Yellow
        exit
    }
    Write-Host ""
    
    # Check if app is running
    Write-Host "Checking if app is running..." -ForegroundColor Yellow
    $running = & $adb shell ps | Select-String "mcbds"
    if ($running) {
        Write-Host "? App process is running" -ForegroundColor Green
        Write-Host $running
    } else {
        Write-Host "? App is NOT running" -ForegroundColor Red
        Write-Host "Start the app first!" -ForegroundColor Yellow
        exit
    }
    Write-Host ""
    
    # Get our debug markers
    Write-Host "Checking initialization status..." -ForegroundColor Yellow
    Write-Host "(Looking for ? and ? markers we added)" -ForegroundColor Gray
    Write-Host ""
    $markers = & $adb logcat -d | Select-String "?|?"
    if ($markers) {
        $markers | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "? No debug markers found" -ForegroundColor Yellow
        Write-Host "App might have crashed before logging started" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Check for exceptions
    Write-Host "Checking for exceptions..." -ForegroundColor Yellow
    $exceptions = & $adb logcat -d | Select-String "Exception|FATAL" | Select-Object -Last 10
    if ($exceptions) {
        Write-Host "? Found exceptions:" -ForegroundColor Red
        $exceptions | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    } else {
        Write-Host "? No exceptions found" -ForegroundColor Green
    }
    Write-Host ""
    
    # Check for our specific errors
    Write-Host "Checking for MCBDS-specific errors..." -ForegroundColor Yellow
    $mcbdsErrors = & $adb logcat -d | Select-String "MCBDS.*Error|MCBDS.*Failed|CRITICAL ERROR" | Select-Object -Last 10
    if ($mcbdsErrors) {
        Write-Host "? Found MCBDS errors:" -ForegroundColor Red
        $mcbdsErrors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    } else {
        Write-Host "? No MCBDS-specific errors" -ForegroundColor Green
    }
    Write-Host ""
    
    # Check for Blazor/WebView specific messages
    Write-Host "Checking for Blazor/WebView messages..." -ForegroundColor Yellow
    $blazorMessages = & $adb logcat -d | Select-String "BlazorWebView|Blazor.*started|chromium" | Select-Object -Last 10
    if ($blazorMessages) {
        Write-Host "Found Blazor/WebView messages:" -ForegroundColor Cyan
        $blazorMessages | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
    } else {
        Write-Host "? No Blazor/WebView messages found" -ForegroundColor Yellow
        Write-Host "WebView might not have initialized" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Save full log
    Write-Host "Saving full log to debug-full.txt..." -ForegroundColor Yellow
    & $adb logcat -d > debug-full.txt
    Write-Host "? Saved to: $(Get-Location)\debug-full.txt" -ForegroundColor Green
    Write-Host ""
    
    # Summary
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "  Summary"
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Device Connected: $($devices -like '*device*')" -ForegroundColor White
    Write-Host "App Installed:    $($installed -ne $null)" -ForegroundColor White
    Write-Host "App Running:      $($running -ne $null)" -ForegroundColor White
    Write-Host "Debug Markers:    $($markers.Count) found" -ForegroundColor White
    Write-Host "Exceptions:       $($exceptions.Count) found" -ForegroundColor White
    Write-Host "Blazor Messages:  $($blazorMessages.Count) found" -ForegroundColor White
    Write-Host ""
    
    if ($markers.Count -eq 0) {
        Write-Host "? PROBLEM: No debug markers found!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This means the app crashed VERY early, before our logging started." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible causes:" -ForegroundColor White
        Write-Host "  1. MCBDS.ClientUI.Shared.dll not deployed" -ForegroundColor Gray
        Write-Host "  2. AndroidManifest.xml missing permissions" -ForegroundColor Gray
        Write-Host "  3. MauiProgram.CreateMauiApp() crashed" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Check debug-full.txt for 'AndroidRuntime' or 'FATAL' errors" -ForegroundColor Gray
        Write-Host "  2. Look for FileNotFoundException or other exceptions" -ForegroundColor Gray
        Write-Host "  3. Try: dotnet clean && python setup-links.py && dotnet build" -ForegroundColor Gray
    } elseif ($exceptions.Count -gt 0) {
        Write-Host "? PROBLEM: Exceptions found!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Check the exceptions listed above." -ForegroundColor Yellow
        Write-Host "Also check debug-full.txt for full context." -ForegroundColor Yellow
    } elseif ($blazorMessages.Count -eq 0) {
        Write-Host "? PROBLEM: BlazorWebView did not initialize!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The app started but BlazorWebView never loaded." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible causes:" -ForegroundColor White
        Write-Host "  1. MainPage.xaml BlazorWebView configuration error" -ForegroundColor Gray
        Write-Host "  2. wwwroot/index.html missing or invalid" -ForegroundColor Gray
        Write-Host "  3. Components/Routes.razor not found" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Verify: Components\Routes.razor exists" -ForegroundColor Gray
        Write-Host "  2. Verify: wwwroot\index.html exists" -ForegroundColor Gray
        Write-Host "  3. Run: python setup-links.py" -ForegroundColor Gray
    } else {
        Write-Host "? App appears to be running normally" -ForegroundColor Green
        Write-Host ""
        Write-Host "If you still see a blank screen:" -ForegroundColor Yellow
        Write-Host "  1. Use Chrome DevTools: chrome://inspect/#devices" -ForegroundColor Gray
        Write-Host "  2. Check Console for JavaScript errors" -ForegroundColor Gray
        Write-Host "  3. Check Network tab for 404 errors" -ForegroundColor Gray
    }
    
} else {
    Write-Host "? ADB not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "This is strange - the previous script found it." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try:" -ForegroundColor White
    Write-Host "  1. Close and reopen PowerShell (PATH changes need restart)" -ForegroundColor Gray
    Write-Host "  2. Then run this script again" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or manually check:" -ForegroundColor White
    Write-Host '  where.exe adb' -ForegroundColor Gray
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

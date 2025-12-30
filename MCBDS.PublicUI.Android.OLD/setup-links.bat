@echo off
REM Setup script for MCBDS.PublicUI.Android
REM This script creates symbolic links to share components with MCBDS.PublicUI

setlocal enabledelayedexpansion

echo.
echo Setting up MCBDS.PublicUI.Android...
echo.

REM Get the script directory (this is MCBDS.PublicUI.Android)
set "ANDROID_DIR=%~dp0"
REM Remove trailing backslash
if "%ANDROID_DIR:~-1%"=="\" set "ANDROID_DIR=%ANDROID_DIR:~0,-1%"

REM Get parent directory and append MCBDS.PublicUI
for %%A in ("%ANDROID_DIR%") do set "PARENT_DIR=%%~dpA"
set "PUBLICUI_DIR=%PARENT_DIR%MCBDS.PublicUI"

REM Remove trailing backslash from PUBLICUI_DIR
if "%PUBLICUI_DIR:~-1%"=="\" set "PUBLICUI_DIR=%PUBLICUI_DIR:~0,-1%"

echo Android Project: !ANDROID_DIR!
echo PublicUI Project: !PUBLICUI_DIR!
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run Command Prompt as Administrator.
    pause
    exit /b 1
)

REM Verify PublicUI exists
if not exist "!PUBLICUI_DIR!" (
    echo ERROR: PublicUI project not found at: !PUBLICUI_DIR!
    echo Make sure MCBDS.PublicUI directory exists in the parent folder.
    pause
    exit /b 1
)

REM Create symbolic links for shared components
echo Creating symbolic links...
echo.

REM Components\Layout Directory
if exist "!ANDROID_DIR!\Components\Layout" (
    echo [SKIP] Components\Layout already exists
) else (
    echo Creating link: Components\Layout
    mklink /D "!ANDROID_DIR!\Components\Layout" "!PUBLICUI_DIR!\Components\Layout"
    if !errorLevel! equ 0 (
        echo [OK] Created Components\Layout
    ) else (
        echo [ERROR] Failed to create Components\Layout
    )
)

REM Components\Pages Directory
if exist "!ANDROID_DIR!\Components\Pages" (
    echo [SKIP] Components\Pages already exists
) else (
    echo Creating link: Components\Pages
    mklink /D "!ANDROID_DIR!\Components\Pages" "!PUBLICUI_DIR!\Components\Pages"
    if !errorLevel! equ 0 (
        echo [OK] Created Components\Pages
    ) else (
        echo [ERROR] Failed to create Components\Pages
    )
)

REM ServerSwitcher.razor file
if exist "!ANDROID_DIR!\Components\ServerSwitcher.razor" (
    echo [SKIP] ServerSwitcher.razor already exists
) else (
    echo Creating link: ServerSwitcher.razor
    mklink "!ANDROID_DIR!\Components\ServerSwitcher.razor" "!PUBLICUI_DIR!\Components\ServerSwitcher.razor"
    if !errorLevel! equ 0 (
        echo [OK] Created ServerSwitcher.razor
    ) else (
        echo [ERROR] Failed to create ServerSwitcher.razor
    )
)

REM ServerSwitcher.razor.css file
if exist "!ANDROID_DIR!\Components\ServerSwitcher.razor.css" (
    echo [SKIP] ServerSwitcher.razor.css already exists
) else (
    echo Creating link: ServerSwitcher.razor.css
    mklink "!ANDROID_DIR!\Components\ServerSwitcher.razor.css" "!PUBLICUI_DIR!\Components\ServerSwitcher.razor.css"
    if !errorLevel! equ 0 (
        echo [OK] Created ServerSwitcher.razor.css
    ) else (
        echo [ERROR] Failed to create ServerSwitcher.razor.css
    )
)

REM wwwroot\lib Directory
if exist "!ANDROID_DIR!\wwwroot\lib" (
    echo [SKIP] wwwroot\lib already exists
) else (
    echo Creating link: wwwroot\lib
    mklink /D "!ANDROID_DIR!\wwwroot\lib" "!PUBLICUI_DIR!\wwwroot\lib"
    if !errorLevel! equ 0 (
        echo [OK] Created wwwroot\lib
    ) else (
        echo [ERROR] Failed to create wwwroot\lib
    )
)

echo.
echo Setup complete!
echo.
echo Next steps:
echo 1. Verify the symbolic links were created correctly
echo 2. Build the project: dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android
echo 3. Test on Android device/emulator
echo.
pause

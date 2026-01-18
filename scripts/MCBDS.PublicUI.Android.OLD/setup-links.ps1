# Setup script for MCBDS.PublicUI.Android
# This script creates symbolic links to share components with MCBDS.PublicUI

param(
    [switch]$Force
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

# Get paths - script is IN the MCBDS.PublicUI.Android directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidDir = $scriptDir
$publicuiDir = Join-Path (Split-Path -Parent $scriptDir) "MCBDS.PublicUI"

Write-Host ""
Write-Host "Setting up MCBDS.PublicUI.Android..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Android Project: $androidDir"
Write-Host "PublicUI Project: $publicuiDir"
Write-Host ""

# Verify PublicUI exists
if (-not (Test-Path $publicuiDir)) {
    Write-Error "PublicUI project not found at: $publicuiDir"
    Write-Error "Make sure you run this script from the MCBDS.PublicUI.Android directory."
    exit 1
}

# Function to create symbolic link
function New-SymbolicLink {
    param(
        [string]$Link,
        [string]$Target,
        [switch]$Directory
    )
    
    $linkDir = Split-Path -Parent $Link
    if (-not (Test-Path $linkDir)) {
        New-Item -ItemType Directory -Path $linkDir -Force | Out-Null
    }
    
    if (Test-Path $Link) {
        if ($Force) {
            Remove-Item $Link -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "  [SKIP] $Link already exists"
            return
        }
    }
    
    # Verify target exists
    if (-not (Test-Path $Target)) {
        Write-Host "  [ERROR] Target not found: $Target" -ForegroundColor Red
        return
    }
    
    try {
        if ($Directory) {
            New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Created directory link: $(Split-Path -Leaf $Link)" -ForegroundColor Green
        } else {
            New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Created file link: $(Split-Path -Leaf $Link)" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [ERROR] Failed to create link: $_" -ForegroundColor Red
    }
}

Write-Host "Creating symbolic links..." -ForegroundColor Cyan
Write-Host ""

# Create directory links for Components
$layoutTarget = Join-Path $publicuiDir "Components\Layout"
$pagesTarget = Join-Path $publicuiDir "Components\Pages"
$layoutLink = Join-Path $androidDir "Components\Layout"
$pagesLink = Join-Path $androidDir "Components\Pages"

New-SymbolicLink -Link $layoutLink -Target $layoutTarget -Directory
New-SymbolicLink -Link $pagesLink -Target $pagesTarget -Directory

# Create file links for ServerSwitcher
$serverSwitcherTarget = Join-Path $publicuiDir "Components\ServerSwitcher.razor"
$serverSwitcherCssTarget = Join-Path $publicuiDir "Components\ServerSwitcher.razor.css"
$serverSwitcherLink = Join-Path $androidDir "Components\ServerSwitcher.razor"
$serverSwitcherCssLink = Join-Path $androidDir "Components\ServerSwitcher.razor.css"

New-SymbolicLink -Link $serverSwitcherLink -Target $serverSwitcherTarget
New-SymbolicLink -Link $serverSwitcherCssLink -Target $serverSwitcherCssTarget

# Create lib link
$libTarget = Join-Path $publicuiDir "wwwroot\lib"
$libLink = Join-Path $androidDir "wwwroot\lib"

New-SymbolicLink -Link $libLink -Target $libTarget -Directory

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Verify the symbolic links were created correctly"
Write-Host "2. Build the project: dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android"
Write-Host "3. Test on Android device/emulator"
Write-Host ""

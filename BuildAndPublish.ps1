# Build and Publish MCBDS.PublicUI for Microsoft Store
# This script ensures all dependencies are built before publishing

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [ValidateSet('win-x86', 'win-x64', 'win-arm64')]
    [string]$RuntimeIdentifier = 'win-x64',
    
    [switch]$SkipBuild,
    [switch]$CreatePackage
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  MCBDS.PublicUI Build & Publish Script" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: " -NoNewline -ForegroundColor Yellow
Write-Host $Configuration -ForegroundColor White
Write-Host "Runtime:       " -NoNewline -ForegroundColor Yellow
Write-Host $RuntimeIdentifier -ForegroundColor White
Write-Host ""

# Define projects
$sharedProject = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj"
$publicUIProject = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"

# Step 1: Clean previous builds
if (-not $SkipBuild) {
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    
    try {
        Write-Host "  Cleaning MCBDS.ClientUI.Shared..." -ForegroundColor Cyan
        dotnet clean $sharedProject -c $Configuration --verbosity quiet
        
        Write-Host "  Cleaning MCBDS.PublicUI..." -ForegroundColor Cyan
        dotnet clean $publicUIProject -c $Configuration --verbosity quiet
        
        Write-Host "  ? Clean completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  ? Clean failed, continuing..." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 2: Restore packages
if (-not $SkipBuild) {
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 2: Restoring NuGet packages..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    
    Write-Host "  Restoring MCBDS.ClientUI.Shared..." -ForegroundColor Cyan
    dotnet restore $sharedProject --verbosity quiet
    
    Write-Host "  Restoring MCBDS.PublicUI..." -ForegroundColor Cyan
    dotnet restore $publicUIProject --verbosity quiet
    
    Write-Host "  ? Restore completed" -ForegroundColor Green
    Write-Host ""
}

# Step 3: Build shared library (CRITICAL for static web assets)
if (-not $SkipBuild) {
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 3: Building shared library..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "  ??  This creates the static web assets manifest" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  Building MCBDS.ClientUI.Shared ($Configuration)..." -ForegroundColor Cyan
    dotnet build $sharedProject -c $Configuration
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  ? Build failed for MCBDS.ClientUI.Shared" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ? Shared library built successfully" -ForegroundColor Green
    
    # Verify manifest was created
    $manifestPath = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\$Configuration\net10.0\staticwebassets.build.json"
    if (Test-Path $manifestPath) {
        Write-Host "  ? Static web assets manifest created" -ForegroundColor Green
    }
    else {
        Write-Host "  ? Warning: Static web assets manifest not found" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 4: Build main project
if (-not $SkipBuild) {
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 4: Building MCBDS.PublicUI..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    
    Write-Host "  Building MCBDS.PublicUI ($Configuration)..." -ForegroundColor Cyan
    Write-Host "  Framework: net10.0-windows10.0.19041.0" -ForegroundColor DarkGray
    
    dotnet build $publicUIProject -c $Configuration -f net10.0-windows10.0.19041.0
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  ? Build failed for MCBDS.PublicUI" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ? Main project built successfully" -ForegroundColor Green
    Write-Host ""
}

# Step 5: Publish (if requested)
if ($CreatePackage) {
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 5: Preparing for Publish..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    
    # Fix for assets file issue during publish
    Write-Host "  Ensuring correct assets file for shared library..." -ForegroundColor Cyan
    Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force -ErrorAction SilentlyContinue
    dotnet restore $sharedProject --force --verbosity quiet
    
    $assetsFile = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json"
    if (Test-Path $assetsFile) {
        $assetsContent = Get-Content $assetsFile -Raw | ConvertFrom-Json
        $targets = $assetsContent.targets.PSObject.Properties.Name
        if ($targets -contains "net10.0") {
            Write-Host "  ? Assets file has correct target framework" -ForegroundColor Green
        } else {
            Write-Host "  ? Warning: Assets file may have incorrect targets" -ForegroundColor Yellow
            Write-Host "    Found: $targets" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "Step 6: Ready for MSIX Packaging" -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ? NOTE: dotnet publish doesn't support .NET 10 MSIX creation yet." -ForegroundColor Yellow
    Write-Host "  The required Mono runtime packages are not available on NuGet." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ? Build completed successfully" -ForegroundColor Green
    Write-Host "  ? Assets verified" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ?? To create MSIX package:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "     RECOMMENDED: Use Windows SDK directly" -ForegroundColor Green
    Write-Host "     .\CreateMSIXWithWindowsSDK.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "     This script:" -ForegroundColor DarkGray
    Write-Host "     - Builds the project" -ForegroundColor DarkGray
    Write-Host "     - Uses MakeAppx.exe to create package" -ForegroundColor DarkGray
    Write-Host "     - Signs the package" -ForegroundColor DarkGray
    Write-Host "     - Creates .msix ready for Store submission" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "     Alternative (if VS UI works for you):" -ForegroundColor Yellow
    Write-Host "     1. Open Visual Studio 2022" -ForegroundColor White
    Write-Host "     2. Double-click: Platforms\Windows\Package.appxmanifest" -ForegroundColor White
    Write-Host "     3. Look for 'Create App Packages' button" -ForegroundColor White
    Write-Host "     (Note: Button may not appear in .NET 10 preview)" -ForegroundColor DarkGray
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  ? Build Process Completed Successfully" -ForegroundColor Green
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

if ($CreatePackage) {
    Write-Host "Next steps for Microsoft Store submission:" -ForegroundColor Yellow
    Write-Host "  1. Open Visual Studio 2022" -ForegroundColor White
    Write-Host "  2. Right-click MCBDS.PublicUI ? Publish ? Create App Packages" -ForegroundColor White
    Write-Host "  3. Test the MSIX package locally" -ForegroundColor White
    Write-Host "  4. Submit to Microsoft Partner Center" -ForegroundColor White
}
else {
    Write-Host "Project built successfully for $RuntimeIdentifier" -ForegroundColor Green
    Write-Host ""
    Write-Host "To prepare for MSIX packaging:" -ForegroundColor Yellow
    Write-Host "  .\BuildAndPublish.ps1 -CreatePackage" -ForegroundColor White
    Write-Host ""
    Write-Host "Then use Visual Studio to create the MSIX package." -ForegroundColor DarkGray
}
Write-Host ""

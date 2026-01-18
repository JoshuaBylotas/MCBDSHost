# Create MSIX Package Using MSBuild
# This bypasses Visual Studio's UI and creates the package directly

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [ValidateSet('x86', 'x64', 'ARM64')]
    [string]$Platform = 'x64',
    
    [Parameter()]
    [string]$OutputPath = "AppPackages"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Create MSIX Package Using MSBuild" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Platform:      $Platform" -ForegroundColor Yellow
Write-Host ""

# Step 1: Fix assets file first
Write-Host "Step 1: Fixing assets file..." -ForegroundColor Yellow
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force -ErrorAction SilentlyContinue
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" --force --verbosity quiet
Write-Host "? Assets file fixed" -ForegroundColor Green
Write-Host ""

# Step 2: Restore the main project
Write-Host "Step 2: Restoring MCBDS.PublicUI..." -ForegroundColor Yellow
dotnet restore "MCBDS.PublicUI\MCBDS.PublicUI.csproj" --verbosity quiet
Write-Host "? Restore completed" -ForegroundColor Green
Write-Host ""

# Step 3: Build the project
Write-Host "Step 3: Building project..." -ForegroundColor Yellow
$buildArgs = @(
    "MCBDS.PublicUI\MCBDS.PublicUI.csproj",
    "/t:Build",
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform",
    "/p:TargetFramework=net10.0-windows10.0.19041.0",
    "/p:WindowsPackageType=MSIX",
    "/verbosity:minimal"
)

msbuild @buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "? Build successful" -ForegroundColor Green
Write-Host ""

# Step 4: Create the MSIX package
Write-Host "Step 4: Creating MSIX package..." -ForegroundColor Yellow
Write-Host ""

# Increment version
$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"
if (Test-Path $manifestPath) {
    Write-Host "Reading current version from manifest..." -ForegroundColor Cyan
    [xml]$manifest = Get-Content $manifestPath
    $identity = $manifest.Package.Identity
    $currentVersion = $identity.Version
    Write-Host "Current version: $currentVersion" -ForegroundColor White
    
    # Parse version
    $versionParts = $currentVersion -split '\.'
    $major = [int]$versionParts[0]
    $minor = [int]$versionParts[1]
    $build = [int]$versionParts[2]
    $revision = [int]$versionParts[3]
    
    # Increment revision
    $revision++
    $newVersion = "$major.$minor.$build.$revision"
    Write-Host "New version: $newVersion" -ForegroundColor Green
    Write-Host ""
}

# Create app package using MSBuild
$packageArgs = @(
    "MCBDS.PublicUI\MCBDS.PublicUI.csproj",
    "/t:Publish",
    "/p:Configuration=$Configuration",
    "/p:Platform=$Platform",
    "/p:TargetFramework=net10.0-windows10.0.19041.0",
    "/p:WindowsPackageType=MSIX",
    "/p:GenerateAppxPackageOnBuild=true",
    "/p:AppxPackageDir=$OutputPath\",
    "/p:AppxBundle=Always",
    "/p:UapAppxPackageBuildMode=SideloadOnly",
    "/verbosity:normal"
)

Write-Host "Creating MSIX package..." -ForegroundColor Cyan
msbuild @packageArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "? Package creation failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "This is expected with .NET 10 preview." -ForegroundColor Yellow
    Write-Host "MSBuild cannot create MSIX packages for .NET 10 yet." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Two options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Use Windows SDK directly (RECOMMENDED):" -ForegroundColor Green
    Write-Host "  .\CreateMSIXWithWindowsSDK.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Try Visual Studio (may not have UI option):" -ForegroundColor Yellow
    Write-Host "  1. Open Platforms\Windows\Package.appxmanifest" -ForegroundColor White
    Write-Host "  2. Look for 'Create App Packages' button" -ForegroundColor White
    Write-Host "  (Note: This button may not appear in .NET 10 preview)" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? MSIX Package Created Successfully" -ForegroundColor Green
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

# Find the created package
$packages = Get-ChildItem "$OutputPath" -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue
if ($packages) {
    Write-Host "Package(s) created:" -ForegroundColor Cyan
    foreach ($pkg in $packages) {
        Write-Host "  ?? $($pkg.FullName)" -ForegroundColor White
        Write-Host "     Size: $([math]::Round($pkg.Length / 1MB, 2)) MB" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test the package locally" -ForegroundColor White
Write-Host "  2. Submit to Microsoft Partner Center" -ForegroundColor White
Write-Host ""

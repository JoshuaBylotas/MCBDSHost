# Create Unsigned Store Package from Existing Build
# Use this if building fails due to .NET 10 preview NuGet issues

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [ValidateSet('x86', 'x64', 'ARM64')]
    [string]$Architecture = 'x64'
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Create Unsigned Store Package (From Existing Build)" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script packages an existing build without rebuilding." -ForegroundColor Yellow
Write-Host "Make sure you've built the project in Visual Studio first!" -ForegroundColor Yellow
Write-Host ""

$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"

# Step 1: Check manifest
Write-Host "Step 1: Reading manifest..." -ForegroundColor Yellow
if (-not (Test-Path $manifestPath)) {
    Write-Host "? ERROR: Manifest file not found: $manifestPath" -ForegroundColor Red
    exit 1
}

[xml]$manifest = Get-Content $manifestPath
$publisher = $manifest.Package.Identity.Publisher
$packageName = $manifest.Package.Identity.Name
$version = $manifest.Package.Identity.Version

Write-Host "  Package Name: $packageName" -ForegroundColor Gray
Write-Host "  Publisher: $publisher" -ForegroundColor Gray
Write-Host "  Version: $version" -ForegroundColor Gray
Write-Host "? Manifest verified" -ForegroundColor Green
Write-Host ""

# Step 2: Find build output
Write-Host "Step 2: Locating existing build..." -ForegroundColor Yellow
$targetFramework = "net10.0-windows10.0.19041.0"
$runtime = "win-$($Architecture.ToLower())"

$possiblePaths = @(
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework\$runtime",
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework",
    "MCBDS.PublicUI\bin\x64\$Configuration\$targetFramework",
    "MCBDS.PublicUI\bin\$Architecture\$Configuration\$targetFramework"
)

$buildOutput = $null
foreach ($path in $possiblePaths) {
    Write-Host "  Checking: $path" -ForegroundColor Gray
    if (Test-Path "$path\MCBDS.PublicUI.exe") {
        $buildOutput = $path
        Write-Host "  ? Found executable!" -ForegroundColor Green
        break
    }
}

if (-not $buildOutput) {
    Write-Host ""
    Write-Host "? ERROR: No existing build found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the project first:" -ForegroundColor Yellow
    Write-Host "  1. Open Visual Studio" -ForegroundColor White
    Write-Host "  2. Set Configuration: $Configuration" -ForegroundColor White
    Write-Host "  3. Set Platform: x64" -ForegroundColor White
    Write-Host "  4. Build ? Build Solution (or F7)" -ForegroundColor White
    Write-Host "  5. Wait for build to complete" -ForegroundColor White
    Write-Host "  6. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Searched paths:" -ForegroundColor Gray
    foreach ($path in $possiblePaths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "? Found build: $buildOutput" -ForegroundColor Green
Write-Host ""

# Step 3: Stage files
Write-Host "Step 3: Staging files for packaging..." -ForegroundColor Yellow
$stagingDir = "AppPackages\Staging"
$packageDir = "AppPackages\MCBDS.PublicUI_$version"

Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $packageDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copy build output
Write-Host "  Copying build files..." -ForegroundColor Gray
Copy-Item "$buildOutput\*" -Destination $stagingDir -Recurse -Force

# Create Assets directory in staging
$assetsDir = Join-Path $stagingDir "Assets"
New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

# Copy Windows assets to Assets folder (manifest expects them there)
$windowsAssetsPath = "MCBDS.PublicUI\Platforms\Windows\Assets"
if (Test-Path $windowsAssetsPath) {
    Write-Host "  Copying Windows assets..." -ForegroundColor Gray
    # Copy all PNG files (including scaled versions)
    Copy-Item "$windowsAssetsPath\*.png" -Destination $assetsDir -Force
    $assetsCount = (Get-ChildItem $assetsDir -Filter "*.png" | Measure-Object).Count
    Write-Host "  Assets copied: $assetsCount PNG files" -ForegroundColor Gray
}

# Copy manifest with correct name (AppxManifest.xml, not Package.appxmanifest)
Write-Host "  Copying manifest..." -ForegroundColor Gray
Copy-Item $manifestPath -Destination "$stagingDir\AppxManifest.xml" -Force

# Fix the manifest language (x-generate is not valid for Store)
Write-Host "  Fixing manifest language..." -ForegroundColor Gray
[xml]$stagingManifest = Get-Content "$stagingDir\AppxManifest.xml"
$stagingManifest.Package.Resources.Resource.Language = "en-US"
$stagingManifest.Save((Resolve-Path "$stagingDir\AppxManifest.xml").Path)

# Verify splash screen exists
if (-not (Test-Path "$assetsDir\SplashScreen.transparent.png")) {
    Write-Host "??  WARNING: SplashScreen.transparent.png not found in Assets" -ForegroundColor Yellow
}

# List staged files
$stagedFiles = Get-ChildItem $stagingDir -Recurse | Measure-Object
Write-Host "  Total files staged: $($stagedFiles.Count)" -ForegroundColor Gray

Write-Host "? Files staged" -ForegroundColor Green
Write-Host ""

# Step 4: Create MSIX
Write-Host "Step 4: Creating MSIX package..." -ForegroundColor Yellow

# Find Windows SDK
$sdkPath = "C:\Program Files (x86)\Windows Kits\10\bin"
$sdkVersions = Get-ChildItem $sdkPath -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | 
    Sort-Object Name -Descending

if (-not $sdkVersions) {
    Write-Host "? ERROR: Windows SDK not found" -ForegroundColor Red
    Write-Host "   Install from: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

$sdkVersion = $sdkVersions[0].Name
$makeAppx = Join-Path $sdkPath "$sdkVersion\x64\makeappx.exe"
Write-Host "  SDK Version: $sdkVersion" -ForegroundColor Gray

$msixPath = Join-Path $packageDir "MCBDS.PublicUI_${version}_$Architecture.msix"

Write-Host "  Creating UNSIGNED package..." -ForegroundColor Cyan
& $makeAppx pack /d $stagingDir /p $msixPath /l /nv

if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $msixPath))) {
    Write-Host "? ERROR: Failed to create MSIX package" -ForegroundColor Red
    Write-Host "   MakeAppx exit code: $LASTEXITCODE" -ForegroundColor Gray
    exit 1
}

Write-Host "? MSIX created" -ForegroundColor Green
Write-Host ""

# Step 5: Verify unsigned
Write-Host "Step 5: Verifying package is unsigned..." -ForegroundColor Yellow
$sig = Get-AuthenticodeSignature $msixPath

Write-Host "  Signature Status: $($sig.Status)" -ForegroundColor Gray

if ($sig.Status -eq 'Valid') {
    Write-Host ""
    Write-Host "??  WARNING: Package is SIGNED!" -ForegroundColor Yellow
    Write-Host "   Signer: $($sig.SignerCertificate.Subject)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   This means the build was signed by MSBuild." -ForegroundColor Yellow
    Write-Host "   This WILL cause identity mismatch at Partner Center!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   To fix:" -ForegroundColor Cyan
    Write-Host "   1. Open MCBDS.PublicUI.csproj" -ForegroundColor White
    Write-Host "   2. Change: <AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>" -ForegroundColor White
    Write-Host "   3. To: <AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>" -ForegroundColor White
    Write-Host "   4. Save and rebuild in Visual Studio" -ForegroundColor White
    Write-Host "   5. Run this script again" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "? Package is unsigned (correct for Store)" -ForegroundColor Green
}
Write-Host ""

# Cleanup
Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "??????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Package Created" -ForegroundColor Green
Write-Host "??????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""
Write-Host "?? Package: $msixPath" -ForegroundColor White
Write-Host "?? Size: $([Math]::Round((Get-Item $msixPath).Length / 1MB, 2)) MB" -ForegroundColor Gray

if ($sig.Status -eq 'Valid') {
    Write-Host "?? Signing: SIGNED (? WRONG for Store - see warning above)" -ForegroundColor Red
} else {
    Write-Host "?? Signing: UNSIGNED (? CORRECT for Store)" -ForegroundColor Green
}

Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

if ($sig.Status -ne 'Valid') {
    Write-Host "Upload to Partner Center:" -ForegroundColor White
    Write-Host "  https://partner.microsoft.com/dashboard" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Expected result:" -ForegroundColor White
    Write-Host "  ? No identity mismatch errors" -ForegroundColor Green
    Write-Host "  ? Package validation passes" -ForegroundColor Green
    Write-Host "  ? Ready for certification" -ForegroundColor Green
} else {
    Write-Host "??  DO NOT upload this package - it's signed!" -ForegroundColor Yellow
    Write-Host "   Fix the project file first (see warning above)" -ForegroundColor Yellow
}

Write-Host ""

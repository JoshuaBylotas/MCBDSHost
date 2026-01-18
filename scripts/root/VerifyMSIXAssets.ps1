# Verify MSIX Package Contents
# Checks if assets are properly included in the build output

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [ValidateSet('win-x86', 'win-x64', 'win-arm64')]
    [string]$RuntimeIdentifier = 'win-x64'
)

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  MSIX Package Asset Verification" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$targetFramework = "net10.0-windows10.0.19041.0"
$buildOutput = "MCBDS.PublicUI\bin\$Configuration\$targetFramework\$RuntimeIdentifier"

if (-not (Test-Path $buildOutput)) {
    Write-Host "? Build output directory not found:" -ForegroundColor Red
    Write-Host "   $buildOutput" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run a build first:" -ForegroundColor Yellow
    Write-Host "  .\BuildAndPublish.ps1 -Configuration $Configuration -RuntimeIdentifier $RuntimeIdentifier" -ForegroundColor White
    exit 1
}

Write-Host "Build Output: $buildOutput" -ForegroundColor Cyan
Write-Host ""

# Check for Assets directory in build output
$assetsDir = Join-Path $buildOutput "Assets"

Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "Checking Assets in Build Output" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

if (Test-Path $assetsDir) {
    Write-Host "? Assets directory exists in build output" -ForegroundColor Green
    Write-Host "  Path: $assetsDir" -ForegroundColor DarkGray
    Write-Host ""
    
    $assets = Get-ChildItem $assetsDir -Filter "*.png" -File
    
    if ($assets.Count -gt 0) {
        Write-Host "Assets found ($($assets.Count)):" -ForegroundColor Cyan
        foreach ($asset in $assets) {
            $sizeKB = [math]::Round($asset.Length / 1KB, 1)
            Write-Host "  ? $($asset.Name)" -ForegroundColor Green -NoNewline
            Write-Host " ($sizeKB KB)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "? No PNG assets found in Assets directory" -ForegroundColor Yellow
    }
} else {
    Write-Host "? Assets directory NOT found in build output" -ForegroundColor Red
    Write-Host "   Expected: $assetsDir" -ForegroundColor Red
}

Write-Host ""

# Check required assets
$requiredAssets = @(
    'StoreLogo.transparent.png',
    'Square44x44Logo.transparent.png',
    'Square71x71Logo.transparent.png',
    'Square150x150Logo.transparent.png',
    'Square310x310Logo.transparent.png',
    'Wide310x150Logo.transparent.png',
    'SplashScreen.transparent.png'
)

Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "Required Assets Checklist" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$missing = 0
foreach ($asset in $requiredAssets) {
    $path = Join-Path $assetsDir $asset
    if (Test-Path $path) {
        Write-Host "  ? $asset" -ForegroundColor Green
    } else {
        Write-Host "  ? $asset (MISSING)" -ForegroundColor Red
        $missing++
    }
}

Write-Host ""

# Check for AppxManifest
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "AppxManifest Check" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$manifestPath = Join-Path $buildOutput "AppxManifest.xml"
if (Test-Path $manifestPath) {
    Write-Host "? AppxManifest.xml found" -ForegroundColor Green
    
    $manifest = Get-Content $manifestPath -Raw
    
    # Check asset references
    $references = @()
    if ($manifest -match 'Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Square150x150Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Square44x44Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Square71x71Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Square310x310Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Wide310x150Logo="([^"]+)"') { $references += $matches[1] }
    if ($manifest -match 'Image="([^"]+)"') { $references += $matches[1] }
    
    Write-Host ""
    Write-Host "Asset references in manifest:" -ForegroundColor Cyan
    foreach ($ref in $references | Select-Object -Unique) {
        $fullPath = Join-Path $buildOutput $ref
        if (Test-Path $fullPath) {
            Write-Host "  ? $ref" -ForegroundColor Green
        } else {
            Write-Host "  ? $ref (FILE NOT FOUND)" -ForegroundColor Red
            $missing++
        }
    }
} else {
    Write-Host "? AppxManifest.xml not found (normal for non-packaged builds)" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

if ($missing -eq 0) {
    Write-Host "? All required assets are present in build output" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready to create MSIX package!" -ForegroundColor Green
} else {
    Write-Host "? $missing asset(s) missing from build output" -ForegroundColor Red
    Write-Host ""
    Write-Host "The MSIX package will fail validation without these assets." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Solution:" -ForegroundColor Yellow
    Write-Host "  1. Verify assets exist in source: MCBDS.PublicUI\Platforms\Windows\Assets\" -ForegroundColor White
    Write-Host "  2. Rebuild the project: .\BuildAndPublish.ps1" -ForegroundColor White
    Write-Host "  3. Run this verification again" -ForegroundColor White
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

exit $missing

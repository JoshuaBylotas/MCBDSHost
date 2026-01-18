# Verify Microsoft Store Readiness for MCBDS.PublicUI
# Checks all requirements before Microsoft Store submission

$ErrorActionPreference = "Continue"
$projectPath = "MCBDS.PublicUI"
$assetsPath = Join-Path $projectPath "Platforms\Windows\Assets"
$manifestPath = Join-Path $projectPath "Platforms\Windows\Package.appxmanifest"
$csprojPath = Join-Path $projectPath "MCBDS.PublicUI.csproj"

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Microsoft Store Readiness Verification" -ForegroundColor Cyan
Write-Host "  MCBDS.PublicUI" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$checks = 0
$passed = 0
$warnings = 0

# Function to check file exists
function Test-FileExists {
    param([string]$Path, [string]$Description)
    
    $script:checks++
    if (Test-Path $Path) {
        Write-Host "  ? " -ForegroundColor Green -NoNewline
        Write-Host $Description
        $script:passed++
        return $true
    } else {
        Write-Host "  ? " -ForegroundColor Red -NoNewline
        Write-Host "$Description - NOT FOUND" -ForegroundColor Red
        return $false
    }
}

# Check 1: Required Assets
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "1. Required Asset Files" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray

$requiredAssets = @(
    @{ File = "Square44x44Logo.transparent.png"; Size = "44×44"; Name = "App List Icon" }
    @{ File = "Square71x71Logo.transparent.png"; Size = "71×71"; Name = "Small Tile" }
    @{ File = "Square150x150Logo.transparent.png"; Size = "150×150"; Name = "Medium Tile" }
    @{ File = "Square310x310Logo.transparent.png"; Size = "310×310"; Name = "Large Tile" }
    @{ File = "Wide310x150Logo.transparent.png"; Size = "310×150"; Name = "Wide Tile" }
    @{ File = "StoreLogo.transparent.png"; Size = "50×50"; Name = "Store Logo" }
    @{ File = "SplashScreen.transparent.png"; Size = "620×300"; Name = "Splash Screen" }
)

foreach ($asset in $requiredAssets) {
    $path = Join-Path $assetsPath $asset.File
    Test-FileExists -Path $path -Description "$($asset.Name) ($($asset.Size))" | Out-Null
}

# Check 2: Package Manifest
Write-Host ""
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "2. Package.appxmanifest Configuration" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray

if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw
    
    # Check asset references
    $checks++
    if ($manifest -match 'StoreLogo\.transparent\.png') {
        Write-Host "  ? Store Logo reference updated" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Store Logo reference NOT updated" -ForegroundColor Red
    }
    
    $checks++
    if ($manifest -match 'SplashScreen\.transparent\.png') {
        Write-Host "  ? Splash Screen reference updated" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Splash Screen reference NOT updated" -ForegroundColor Red
    }
    
    # Extract package info
    if ($manifest -match 'DisplayName="([^"]+)"') {
        Write-Host "  ? Display Name: " -ForegroundColor Cyan -NoNewline
        Write-Host $matches[1] -ForegroundColor White
    }
    
    if ($manifest -match 'Version="([^"]+)"') {
        Write-Host "  ? Version: " -ForegroundColor Cyan -NoNewline
        Write-Host $matches[1] -ForegroundColor White
    }
    
    if ($manifest -match 'PublisherDisplayName="([^"]+)"') {
        Write-Host "  ? Publisher: " -ForegroundColor Cyan -NoNewline
        Write-Host $matches[1] -ForegroundColor White
    }
} else {
    Write-Host "  ? Package.appxmanifest not found" -ForegroundColor Red
}

# Check 3: Project File
Write-Host ""
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "3. Project File Configuration" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray

if (Test-Path $csprojPath) {
    $csproj = Get-Content $csprojPath -Raw
    
    $checks++
    if ($csproj -match 'WindowsPackageType.*MSIX') {
        Write-Host "  ? Windows Package Type set to MSIX" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Windows Package Type not set to MSIX" -ForegroundColor Yellow
        $warnings++
    }
    
    $checks++
    if ($csproj -match 'AppxPackageSigningEnabled.*True') {
        Write-Host "  ? Package signing enabled" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Package signing not enabled" -ForegroundColor Yellow
        $warnings++
    }
    
    $checks++
    if ($csproj -match 'PackageCertificateThumbprint') {
        Write-Host "  ? Package certificate configured" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Package certificate NOT configured" -ForegroundColor Red
    }
    
    $checks++
    $assetCount = ([regex]::Matches($csproj, '\.transparent\.png')).Count
    if ($assetCount -ge 7) {
        Write-Host "  ? Asset references in project file ($assetCount found)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ? Only $assetCount transparent asset references found" -ForegroundColor Yellow
        $warnings++
    }
}

# Check 4: Build Status
Write-Host ""
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "4. Build Configuration" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????????" -ForegroundColor DarkGray

$checks++
if (Test-Path "MCBDS.PublicUI\bin\Debug\net10.0-windows10.0.19041.0") {
    Write-Host "  ? Debug build output exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ? No Debug build found - run build before packaging" -ForegroundColor Yellow
    $warnings++
}

# Summary
Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ? Passed: " -NoNewline -ForegroundColor Green
Write-Host "$passed / $checks" -ForegroundColor White

if ($warnings -gt 0) {
    Write-Host "  ? Warnings: " -NoNewline -ForegroundColor Yellow
    Write-Host $warnings -ForegroundColor White
}

$failed = $checks - $passed
if ($failed -gt 0) {
    Write-Host "  ? Failed: " -NoNewline -ForegroundColor Red
    Write-Host $failed -ForegroundColor White
}

Write-Host ""

if ($passed -eq $checks) {
    Write-Host "  ?? ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host "  ? Ready for Microsoft Store packaging" -ForegroundColor Green
} elseif ($failed -eq 0 -and $warnings -gt 0) {
    Write-Host "  ??  MINOR ISSUES DETECTED" -ForegroundColor Yellow
    Write-Host "  ??  Review warnings before submitting" -ForegroundColor Yellow
} else {
    Write-Host "  ? ISSUES DETECTED" -ForegroundColor Red
    Write-Host "  ??  Fix failed checks before submitting" -ForegroundColor Red
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Next steps
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review any warnings or failures above" -ForegroundColor White
Write-Host "  2. Build the project in Release mode" -ForegroundColor White
Write-Host "  3. Right-click project ? Publish ? Create App Packages" -ForegroundColor White
Write-Host "  4. Test the MSIX package locally" -ForegroundColor White
Write-Host "  5. Submit to Microsoft Partner Center" -ForegroundColor White
Write-Host ""

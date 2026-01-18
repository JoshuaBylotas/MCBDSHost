# Create MSIX Package Using Windows SDK Tools
# Works with .NET 10 by using existing build output
# Supports both Store submission (unsigned) and local testing (signed)

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [ValidateSet('x86', 'x64', 'ARM64')]
    [string]$Architecture = 'x64',
    
    [Parameter()]
    [switch]$ForStore,
    
    [Parameter()]
    [switch]$Sign,
    
    [Parameter()]
    [switch]$SkipVersionIncrement
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
if ($ForStore) {
    Write-Host "  Create MSIX Package - FOR MICROSOFT STORE" -ForegroundColor Cyan
} else {
    Write-Host "  Create MSIX Package - FOR LOCAL TESTING" -ForegroundColor Cyan
}
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Validate parameters
if ($ForStore -and $Sign) {
    Write-Host "ERROR: Cannot use -ForStore and -Sign together" -ForegroundColor Red
    Write-Host "Store packages should NOT be signed manually." -ForegroundColor Yellow
    Write-Host "Microsoft will sign them during certification." -ForegroundColor Yellow
    exit 1
}

# Show package type
if ($ForStore) {
    Write-Host "?? Package Type: Microsoft Store Submission (UNSIGNED)" -ForegroundColor Green
    Write-Host "   Microsoft will sign this during certification" -ForegroundColor Gray
} elseif ($Sign) {
    Write-Host "?? Package Type: Local Testing (SIGNED)" -ForegroundColor Green
    Write-Host "   Will be signed with development certificate" -ForegroundColor Gray
} else {
    Write-Host "?? Package Type: Local Testing (UNSIGNED)" -ForegroundColor Yellow
    Write-Host "   You may need to install the certificate separately" -ForegroundColor Gray
}
Write-Host ""

# Find Windows SDK
$sdkPath = "C:\Program Files (x86)\Windows Kits\10\bin"
$sdkVersions = Get-ChildItem $sdkPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
if (-not $sdkVersions) {
    Write-Host "? Windows SDK not found" -ForegroundColor Red
    Write-Host "Install Windows SDK from: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

$sdkVersion = $sdkVersions[0].Name
$makeAppx = Join-Path $sdkPath "$sdkVersion\x64\makeappx.exe"
$signTool = Join-Path $sdkPath "$sdkVersion\x64\signtool.exe"

Write-Host "? Windows SDK: $sdkVersion" -ForegroundColor Green
Write-Host ""

# Step 1: Build using our working script
Write-Host "Step 1: Building project..." -ForegroundColor Yellow
& ".\BuildAndPublish.ps1" -Configuration $Configuration
if ($LASTEXITCODE -ne 0) { 
    Write-Host "? Build failed" -ForegroundColor Red
    exit 1 
}
Write-Host ""

# Step 2: Find build output
$targetFramework = "net10.0-windows10.0.19041.0"
$buildPaths = @(
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework\win-$($Architecture.ToLower())",
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework"
)

$buildOutput = $null
foreach ($path in $buildPaths) {
    if (Test-Path $path) {
        $buildOutput = $path
        break
    }
}

if (-not $buildOutput) {
    Write-Host "? Build output not found" -ForegroundColor Red
    Write-Host "Searched paths:" -ForegroundColor Yellow
    foreach ($path in $buildPaths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "Step 2: Found build output" -ForegroundColor Green
Write-Host "  $buildOutput" -ForegroundColor DarkGray
Write-Host ""

# Step 3: Update version (optional)
$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"
[xml]$manifest = Get-Content $manifestPath
$currentVersion = $manifest.Package.Identity.Version

if ($SkipVersionIncrement) {
    Write-Host "Step 3: Using current version (no increment)" -ForegroundColor Yellow
    $newVersion = $currentVersion
} else {
    Write-Host "Step 3: Updating version..." -ForegroundColor Yellow
    $versionParts = $currentVersion -split '\.'
    $newVersion = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2]).$([int]$versionParts[3] + 1)"
    $manifest.Package.Identity.Version = $newVersion
    $manifest.Save((Resolve-Path $manifestPath).Path)
    Write-Host "  Old: $currentVersion" -ForegroundColor Gray
    Write-Host "  New: $newVersion" -ForegroundColor Green
}

Write-Host "? Version: $newVersion" -ForegroundColor Green
Write-Host ""

# Step 4: Verify Store identity (if ForStore)
if ($ForStore) {
    Write-Host "Step 4: Verifying Store identity..." -ForegroundColor Yellow
    $publisher = $manifest.Package.Identity.Publisher
    $name = $manifest.Package.Identity.Name
    
    Write-Host "  Package Name: $name" -ForegroundColor Gray
    Write-Host "  Publisher: $publisher" -ForegroundColor Gray
    
    if ($publisher -notmatch '^CN=[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$') {
        Write-Host ""
        Write-Host "??  WARNING: Publisher doesn't look like a Store identity!" -ForegroundColor Yellow
        Write-Host "   Expected format: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ForegroundColor Yellow
        Write-Host "   Current: $publisher" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To fix this:" -ForegroundColor Yellow
        Write-Host "  1. Open Visual Studio" -ForegroundColor White
        Write-Host "  2. Right-click project ? Publish ? Associate App with the Store" -ForegroundColor White
        Write-Host "  3. Sign in to Partner Center" -ForegroundColor White
        Write-Host "  4. Select your reserved app" -ForegroundColor White
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Host "Aborted." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "? Store identity looks correct" -ForegroundColor Green
    }
    Write-Host ""
} else {
    Write-Host "Step 4: Skipping Store identity check (not building for Store)" -ForegroundColor Gray
    Write-Host ""
}

# Step 5: Stage files
$stepNum = if ($ForStore) { 5 } else { 4 }
Write-Host "Step ${stepNum}: Staging files..." -ForegroundColor Yellow
$stagingDir = "AppPackages\Staging"
$packageDir = "AppPackages\MCBDS.PublicUI_$newVersion"

Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $packageDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

Copy-Item "$buildOutput\*" -Destination $stagingDir -Recurse -Force
Copy-Item $manifestPath -Destination $stagingDir -Force

if (-not (Test-Path "$stagingDir\MCBDS.PublicUI.exe")) {
    Write-Host "? Executable not found in staging directory" -ForegroundColor Red
    exit 1
}

Write-Host "? Files staged" -ForegroundColor Green
Write-Host ""

# Step 6: Create MSIX
$stepNum++
Write-Host "Step ${stepNum}: Creating MSIX..." -ForegroundColor Yellow
$msixPath = Join-Path $packageDir "MCBDS.PublicUI_${newVersion}_$Architecture.msix"

if ($ForStore) {
    Write-Host "  Creating UNSIGNED package (for Store submission)..." -ForegroundColor Gray
} else {
    Write-Host "  Creating package..." -ForegroundColor Gray
}

& $makeAppx pack /d $stagingDir /p $msixPath /l

if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $msixPath))) {
    Write-Host "? Failed to create MSIX" -ForegroundColor Red
    exit 1
}

Write-Host "? MSIX created" -ForegroundColor Green
Write-Host ""

# Step 7: Sign (optional)
if ($Sign) {
    $stepNum++
    Write-Host "Step ${stepNum}: Signing..." -ForegroundColor Yellow
    
    $cert = Get-ChildItem Cert:\CurrentUser\My,Cert:\LocalMachine\My -ErrorAction SilentlyContinue | 
        Where-Object { $_.Thumbprint -eq "B97A80AD152EF3F18075E8F6B31A219112319F2B" } | 
        Select-Object -First 1

    if ($cert) {
        Write-Host "  Certificate found: $($cert.Subject)" -ForegroundColor Gray
        Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        
        & $signTool sign /fd SHA256 /sha1 $cert.Thumbprint /td SHA256 /tr http://timestamp.digicert.com $msixPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "? Package signed successfully" -ForegroundColor Green
        } else {
            Write-Host "??  Signing failed (but package was created)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "??  Development certificate not found" -ForegroundColor Yellow
        Write-Host "   Thumbprint: B97A80AD152EF3F18075E8F6B31A219112319F2B" -ForegroundColor Gray
        Write-Host "   Package created but NOT signed" -ForegroundColor Yellow
    }
    Write-Host ""
} elseif ($ForStore) {
    Write-Host "Step ${stepNum}: Skipping signing (Store packages should be unsigned)" -ForegroundColor Gray
    Write-Host "  ??  Microsoft will sign this package during certification" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Step ${stepNum}: Skipping signing (use -Sign to sign)" -ForegroundColor Gray
    Write-Host ""
}

# Cleanup
Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Package Created Successfully!" -ForegroundColor Green
Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""
Write-Host "?? Package: $msixPath" -ForegroundColor White
Write-Host "?? Size: $([Math]::Round((Get-Item $msixPath).Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

if ($ForStore) {
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS: Upload to Microsoft Store" -ForegroundColor Cyan
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This package is UNSIGNED and ready for Store submission." -ForegroundColor Green
    Write-Host ""
    Write-Host "To submit to Microsoft Store:" -ForegroundColor White
    Write-Host "  1. Go to: https://partner.microsoft.com/dashboard" -ForegroundColor Gray
    Write-Host "  2. Navigate to your app: MCBDS Manager" -ForegroundColor Gray
    Write-Host "  3. Go to Packages section" -ForegroundColor Gray
    Write-Host "  4. Upload this file: $msixPath" -ForegroundColor Gray
    Write-Host "  5. Complete your submission" -ForegroundColor Gray
    Write-Host ""
    Write-Host "??  IMPORTANT:" -ForegroundColor Yellow
    Write-Host "   - This package is UNSIGNED (correct for Store)" -ForegroundColor Yellow
    Write-Host "   - Microsoft will sign it during certification" -ForegroundColor Yellow
    Write-Host "   - Do NOT manually sign Store packages" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "For multi-architecture bundle (.msixupload):" -ForegroundColor Cyan
    Write-Host "  Use Visual Studio ? Create App Packages ? Microsoft Store" -ForegroundColor Gray
    Write-Host ""
} elseif ($Sign) {
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS: Install and Test" -ForegroundColor Cyan
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This package is SIGNED and ready for local testing." -ForegroundColor Green
    Write-Host ""
    Write-Host "To install:" -ForegroundColor White
    Write-Host "  Add-AppxPackage -Path '$msixPath'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or run the install script:" -ForegroundColor White
    Write-Host "  .\InstallCertAndMSIX.ps1" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS: Sign or Test" -ForegroundColor Cyan
    Write-Host "????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This package is UNSIGNED." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To sign for local testing:" -ForegroundColor White
    Write-Host "  .\CreateMSIXPackage.ps1 -Sign" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To create for Store submission:" -ForegroundColor White
    Write-Host "  .\CreateMSIXPackage.ps1 -ForStore" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

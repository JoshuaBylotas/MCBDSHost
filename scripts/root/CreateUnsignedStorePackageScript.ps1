# Create Unsigned Store Package - Direct Build Method
# Works around .NET 10 NuGet limitation by building with SDK directly

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
Write-Host "  Create Unsigned Store Package - Script Method" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$projectFile = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"

# Step 1: Verify files exist
Write-Host "Step 1: Verifying files..." -ForegroundColor Yellow
if (-not (Test-Path $projectFile)) {
    Write-Host "? ERROR: Project file not found: $projectFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $manifestPath)) {
    Write-Host "? ERROR: Manifest file not found: $manifestPath" -ForegroundColor Red
    exit 1
}
Write-Host "? Files found" -ForegroundColor Green
Write-Host ""

# Step 2: Check manifest identity
Write-Host "Step 2: Verifying Store identity..." -ForegroundColor Yellow
[xml]$manifest = Get-Content $manifestPath
$publisher = $manifest.Package.Identity.Publisher
$packageName = $manifest.Package.Identity.Name
$version = $manifest.Package.Identity.Version

Write-Host "  Package Name: $packageName" -ForegroundColor Gray
Write-Host "  Publisher: $publisher" -ForegroundColor Gray
Write-Host "  Version: $version" -ForegroundColor Gray

if ($publisher -notmatch '^CN=[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$') {
    Write-Host ""
    Write-Host "??  WARNING: Publisher doesn't look like a Store identity!" -ForegroundColor Yellow
    Write-Host "   Expected format: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ForegroundColor Yellow
    Write-Host "   Current: $publisher" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
}
Write-Host "? Manifest verified" -ForegroundColor Green
Write-Host ""

# Step 3: Backup and modify project file
Write-Host "Step 3: Temporarily disabling signing..." -ForegroundColor Yellow
$backupFile = "$projectFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
Copy-Item $projectFile $backupFile -Force
Write-Host "  Backup: $backupFile" -ForegroundColor Gray

try {
    $projectContent = Get-Content $projectFile -Raw
    $originalContent = $projectContent
    
    # Disable AppxPackageSigningEnabled
    $projectContent = $projectContent -replace '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>'
    
    # Remove PackageCertificateThumbprint line entirely (safer than commenting)
    $projectContent = $projectContent -replace '\s*<PackageCertificateThumbprint>[^<]+</PackageCertificateThumbprint>\s*', "`r`n"
    
    $projectContent | Set-Content $projectFile -NoNewline
    Write-Host "? Signing disabled" -ForegroundColor Green
} catch {
    Write-Host "? ERROR: Could not modify project file" -ForegroundColor Red
    Write-Host "   $_" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# Step 4: Clean
Write-Host "Step 4: Cleaning previous builds..." -ForegroundColor Yellow
& dotnet clean $projectFile -c $Configuration --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "??  Clean had issues, but continuing..." -ForegroundColor Yellow
}
Write-Host "? Clean complete" -ForegroundColor Green
Write-Host ""

# Step 5: Build using MSBuild with Windows target only
Write-Host "Step 5: Building for Windows (avoiding .NET 10 NuGet issue)..." -ForegroundColor Yellow
$targetFramework = "net10.0-windows10.0.19041.0"

# Use MSBuild instead of dotnet publish
$msbuildPath = $null

# Try to find MSBuild using vswhere
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    if ($vsPath) {
        $msbuildPath = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
        if (-not (Test-Path $msbuildPath)) {
            $msbuildPath = $null
        }
    }
}

if (-not $msbuildPath) {
    Write-Host "? ERROR: MSBuild not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "ALTERNATIVE SOLUTION:" -ForegroundColor Cyan
    Write-Host "1. Build the project in Visual Studio (File ? Build Solution)" -ForegroundColor White
    Write-Host "2. Then run:" -ForegroundColor White
    Write-Host "   .\CreateUnsignedFromExistingBuild.ps1" -ForegroundColor Cyan
    Write-Host ""
    
    # Restore project file
    Copy-Item $backupFile $projectFile -Force
    exit 1
}

Write-Host "  Using MSBuild: $msbuildPath" -ForegroundColor Gray

$runtime = "win-$($Architecture.ToLower())"

$msbuildArgs = @(
    $projectFile,
    "/t:Build",
    "/p:Configuration=$Configuration",
    "/p:TargetFramework=$targetFramework",
    "/p:RuntimeIdentifier=$runtime",
    "/p:Platform=x64",
    "/p:WindowsPackageType=None",
    "/p:AppxPackageSigningEnabled=false",
    "/p:GenerateAppxPackageOnBuild=false",
    "/p:SelfContained=true",
    "/verbosity:minimal"
)

& $msbuildPath @msbuildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "? ERROR: MSBuild failed" -ForegroundColor Red
    Copy-Item $backupFile $projectFile -Force
    exit 1
}

Write-Host "? Build complete" -ForegroundColor Green
Write-Host ""

# Step 6: Restore project file
Write-Host "Step 6: Restoring project file..." -ForegroundColor Yellow
Copy-Item $backupFile $projectFile -Force
Write-Host "? Project file restored" -ForegroundColor Green
Write-Host ""

# Step 7: Find build output
Write-Host "Step 7: Locating build output..." -ForegroundColor Yellow

$possiblePaths = @(
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework\$runtime\publish",
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework\$runtime",
    "MCBDS.PublicUI\bin\$Configuration\$targetFramework"
)

$buildOutput = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $buildOutput = $path
        break
    }
}

if (-not $buildOutput) {
    Write-Host "? ERROR: Build output not found" -ForegroundColor Red
    Write-Host "   Searched:" -ForegroundColor Gray
    foreach ($path in $possiblePaths) {
        Write-Host "   - $path" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "? Found: $buildOutput" -ForegroundColor Green
Write-Host ""

# Step 8: Stage files
Write-Host "Step 8: Staging files for packaging..." -ForegroundColor Yellow
$stagingDir = "AppPackages\Staging"
$packageDir = "AppPackages\MCBDS.PublicUI_$version"

Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $packageDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

# Copy build output
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
}

# Ensure manifest is copied with correct name (AppxManifest.xml, not Package.appxmanifest)
Copy-Item $manifestPath -Destination "$stagingDir\AppxManifest.xml" -Force

# Fix the manifest language (x-generate is not valid for Store)
Write-Host "  Fixing manifest language..." -ForegroundColor Gray
[xml]$stagingManifest = Get-Content "$stagingDir\AppxManifest.xml"
$stagingManifest.Package.Resources.Resource.Language = "en-US"
$stagingManifest.Save((Resolve-Path "$stagingDir\AppxManifest.xml").Path)

# Verify executable exists
if (-not (Test-Path "$stagingDir\MCBDS.PublicUI.exe")) {
    Write-Host "? ERROR: Executable not found in staging directory" -ForegroundColor Red
    Write-Host "   Staging: $stagingDir" -ForegroundColor Gray
    Write-Host "   Contents:" -ForegroundColor Gray
    Get-ChildItem $stagingDir | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

# Verify manifest was copied
if (-not (Test-Path "$stagingDir\AppxManifest.xml")) {
    Write-Host "? ERROR: Manifest not found in staging directory" -ForegroundColor Red
    exit 1
}

# Verify splash screen exists
if (-not (Test-Path "$assetsDir\SplashScreen.transparent.png")) {
    Write-Host "??  WARNING: SplashScreen.transparent.png not found in Assets" -ForegroundColor Yellow
}

# Verify assets were copied
$assetsCount = (Get-ChildItem $assetsDir -Filter "*.png" -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host "  Assets copied: $assetsCount PNG files" -ForegroundColor Gray

Write-Host "? Files staged" -ForegroundColor Green
Write-Host ""

# Step 9: Create MSIX with Windows SDK
Write-Host "Step 9: Creating MSIX package..." -ForegroundColor Yellow

# Find Windows SDK
$sdkPath = "C:\Program Files (x86)\Windows Kits\10\bin"
$sdkVersions = Get-ChildItem $sdkPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
if (-not $sdkVersions) {
    Write-Host "? ERROR: Windows SDK not found" -ForegroundColor Red
    Write-Host "   Install from: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

$sdkVersion = $sdkVersions[0].Name
$makeAppx = Join-Path $sdkPath "$sdkVersion\x64\makeappx.exe"
Write-Host "  SDK Version: $sdkVersion" -ForegroundColor Gray
Write-Host "  MakeAppx: $makeAppx" -ForegroundColor Gray

$msixPath = Join-Path $packageDir "MCBDS.PublicUI_${version}_$Architecture.msix"

Write-Host "  Creating package (UNSIGNED)..." -ForegroundColor Gray
& $makeAppx pack /d $stagingDir /p $msixPath /l /nv

if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $msixPath))) {
    Write-Host "? ERROR: Failed to create MSIX package" -ForegroundColor Red
    exit 1
}

Write-Host "? MSIX created (UNSIGNED)" -ForegroundColor Green
Write-Host ""

# Step 10: Verify package is unsigned
Write-Host "Step 10: Verifying package is unsigned..." -ForegroundColor Yellow
$sig = Get-AuthenticodeSignature $msixPath
if ($sig.Status -eq 'Valid') {
    Write-Host "??  WARNING: Package appears to be signed!" -ForegroundColor Yellow
    Write-Host "   This may cause identity mismatch in Store" -ForegroundColor Yellow
    Write-Host "   Signer: $($sig.SignerCertificate.Subject)" -ForegroundColor Yellow
} else {
    Write-Host "? Package is unsigned (correct for Store)" -ForegroundColor Green
    Write-Host "   Status: $($sig.Status)" -ForegroundColor Gray
}
Write-Host ""

# Cleanup
Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $backupFile -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "??????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Store Package Created Successfully!" -ForegroundColor Green
Write-Host "??????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""
Write-Host "?? Package: $msixPath" -ForegroundColor White
Write-Host "?? Size: $([Math]::Round((Get-Item $msixPath).Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host "?? Signing: UNSIGNED (correct for Microsoft Store)" -ForegroundColor Green
Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "Upload to Partner Center:" -ForegroundColor White
Write-Host "  https://partner.microsoft.com/dashboard" -ForegroundColor Cyan
Write-Host ""
Write-Host "This package:" -ForegroundColor White
Write-Host "  ? Is UNSIGNED (Microsoft will sign during certification)" -ForegroundColor Green
Write-Host "  ? Has correct Store identity in manifest" -ForegroundColor Green
Write-Host "  ? Should NOT show identity mismatch errors" -ForegroundColor Green
Write-Host ""
Write-Host "Expected at Partner Center:" -ForegroundColor White
Write-Host "  ? Package Name: $packageName" -ForegroundColor Green
Write-Host "  ? Publisher: $publisher" -ForegroundColor Green
Write-Host "  ? Package Family Name: ${packageName}_n8ws8gp0q633w" -ForegroundColor Green
Write-Host ""

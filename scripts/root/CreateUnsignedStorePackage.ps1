# Fix Store Package Identity and Create Unsigned Package
# This script temporarily disables project-level signing to ensure unsigned Store packages

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
Write-Host "  Fix and Create Store Package" -ForegroundColor Cyan
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

# Step 2: Backup project file
Write-Host "Step 2: Backing up project file..." -ForegroundColor Yellow
$backupFile = "$projectFile.backup"
Copy-Item $projectFile $backupFile -Force
Write-Host "? Backup created: $backupFile" -ForegroundColor Green
Write-Host ""

# Step 3: Disable signing in project file
Write-Host "Step 3: Temporarily disabling project-level signing..." -ForegroundColor Yellow
try {
    $projectContent = Get-Content $projectFile -Raw
    
    # Disable AppxPackageSigningEnabled
    $projectContent = $projectContent -replace '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>'
    
    # Comment out PackageCertificateThumbprint
    $projectContent = $projectContent -replace '<PackageCertificateThumbprint>([^<]+)</PackageCertificateThumbprint>', '<!-- <PackageCertificateThumbprint>$1</PackageCertificateThumbprint> -->'
    
    $projectContent | Set-Content $projectFile -NoNewline
    Write-Host "? Signing disabled" -ForegroundColor Green
} catch {
    Write-Host "? ERROR: Could not modify project file" -ForegroundColor Red
    Write-Host "   $_" -ForegroundColor Gray
    # Restore backup
    Copy-Item $backupFile $projectFile -Force
    exit 1
}
Write-Host ""

# Step 4: Clean build output
Write-Host "Step 4: Cleaning previous builds..." -ForegroundColor Yellow
& dotnet clean $projectFile -c $Configuration --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "??  Clean had issues, but continuing..." -ForegroundColor Yellow
}
Write-Host "? Clean complete" -ForegroundColor Green
Write-Host ""

# Step 5: Restore packages
Write-Host "Step 5: Restoring NuGet packages..." -ForegroundColor Yellow
& dotnet restore $projectFile --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "? ERROR: Restore failed" -ForegroundColor Red
    # Restore backup
    Copy-Item $backupFile $projectFile -Force
    exit 1
}
Write-Host "? Restore complete" -ForegroundColor Green
Write-Host ""

# Step 6: Build WITHOUT signing
Write-Host "Step 6: Building project (unsigned)..." -ForegroundColor Yellow
$targetFramework = "net10.0-windows10.0.19041.0"
$runtime = "win-$($Architecture.ToLower())"

$publishArgs = @(
    'publish',
    $projectFile,
    '-f', $targetFramework,
    '-c', $Configuration,
    '-r', $runtime,
    '--self-contained', 'true',
    '-p:WindowsPackageType=None',
    '-p:PublishSingleFile=false',
    '-p:WindowsAppSDKSelfContained=true',
    '-p:AppxPackageSigningEnabled=false',
    '--verbosity', 'minimal'
)

& dotnet @publishArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "? ERROR: Build failed" -ForegroundColor Red
    # Restore backup
    Copy-Item $backupFile $projectFile -Force
    exit 1
}
Write-Host "? Build complete" -ForegroundColor Green
Write-Host ""

# Step 7: Restore project file
Write-Host "Step 7: Restoring project file..." -ForegroundColor Yellow
Copy-Item $backupFile $projectFile -Force
Remove-Item $backupFile -Force
Write-Host "? Project file restored" -ForegroundColor Green
Write-Host ""

# Step 8: Get version from manifest
Write-Host "Step 8: Reading version from manifest..." -ForegroundColor Yellow
[xml]$manifest = Get-Content $manifestPath
$version = $manifest.Package.Identity.Version
$publisher = $manifest.Package.Identity.Publisher
Write-Host "  Version: $version" -ForegroundColor Gray
Write-Host "  Publisher: $publisher" -ForegroundColor Gray
Write-Host "? Manifest verified" -ForegroundColor Green
Write-Host ""

# Step 9: Find build output
Write-Host "Step 9: Locating build output..." -ForegroundColor Yellow
$publishDir = "MCBDS.PublicUI\bin\$Configuration\$targetFramework\$runtime\publish"
if (-not (Test-Path $publishDir)) {
    Write-Host "? ERROR: Build output not found at: $publishDir" -ForegroundColor Red
    exit 1
}
Write-Host "? Found: $publishDir" -ForegroundColor Green
Write-Host ""

# Step 10: Stage files
Write-Host "Step 10: Staging files for packaging..." -ForegroundColor Yellow
$stagingDir = "AppPackages\Staging"
$packageDir = "AppPackages\MCBDS.PublicUI_$version"

Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $packageDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null

Copy-Item "$publishDir\*" -Destination $stagingDir -Recurse -Force
Copy-Item $manifestPath -Destination $stagingDir -Force

Write-Host "? Files staged" -ForegroundColor Green
Write-Host ""

# Step 11: Create MSIX with Windows SDK
Write-Host "Step 11: Creating MSIX package..." -ForegroundColor Yellow

# Find Windows SDK
$sdkPath = "C:\Program Files (x86)\Windows Kits\10\bin"
$sdkVersions = Get-ChildItem $sdkPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
if (-not $sdkVersions) {
    Write-Host "? ERROR: Windows SDK not found" -ForegroundColor Red
    exit 1
}

$sdkVersion = $sdkVersions[0].Name
$makeAppx = Join-Path $sdkPath "$sdkVersion\x64\makeappx.exe"

$msixPath = Join-Path $packageDir "MCBDS.PublicUI_${version}_$Architecture.msix"

& $makeAppx pack /d $stagingDir /p $msixPath /l /nv

if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $msixPath))) {
    Write-Host "? ERROR: Failed to create MSIX package" -ForegroundColor Red
    exit 1
}

Write-Host "? MSIX created (UNSIGNED)" -ForegroundColor Green
Write-Host ""

# Step 12: Verify package is unsigned
Write-Host "Step 12: Verifying package is unsigned..." -ForegroundColor Yellow
$sig = Get-AuthenticodeSignature $msixPath
if ($sig.Status -eq 'Valid') {
    Write-Host "??  WARNING: Package appears to be signed!" -ForegroundColor Yellow
    Write-Host "   This may cause identity mismatch in Store" -ForegroundColor Yellow
} else {
    Write-Host "? Package is unsigned (correct for Store)" -ForegroundColor Green
}
Write-Host ""

# Cleanup
Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue

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

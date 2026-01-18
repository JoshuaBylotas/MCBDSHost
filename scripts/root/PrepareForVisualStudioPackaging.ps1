# Create Unsigned Store Package - Visual Studio Method
# Uses MSBuild with Store configuration (bypasses NuGet runtime package issue)

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Create Unsigned Store Package (Visual Studio)" -ForegroundColor Cyan
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
}
Write-Host "? Manifest verified" -ForegroundColor Green
Write-Host ""

# Step 3: Backup project file
Write-Host "Step 3: Backing up project file..." -ForegroundColor Yellow
$backupFile = "$projectFile.backup"
Copy-Item $projectFile $backupFile -Force
Write-Host "? Backup created" -ForegroundColor Green
Write-Host ""

# Step 4: Modify project file to disable signing
Write-Host "Step 4: Disabling signing in project file..." -ForegroundColor Yellow
try {
    $projectContent = Get-Content $projectFile -Raw
    
    # Disable AppxPackageSigningEnabled
    $projectContent = $projectContent -replace '<AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>', '<AppxPackageSigningEnabled>False</AppxPackageSigningEnabled>'
    
    # Remove PackageCertificateThumbprint line entirely (safer than commenting)
    $projectContent = $projectContent -replace '\s*<PackageCertificateThumbprint>[^<]+</PackageCertificateThumbprint>\s*', "`r`n"
    
    $projectContent | Set-Content $projectFile -NoNewline
    Write-Host "? Signing disabled" -ForegroundColor Green
} catch {
    Write-Host "? ERROR: Could not modify project file" -ForegroundColor Red
    Write-Host "   $_" -ForegroundColor Gray
    Copy-Item $backupFile $projectFile -Force
    exit 1
}
Write-Host ""

Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  MANUAL STEPS REQUIRED" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "The project file has been modified to disable signing." -ForegroundColor Yellow
Write-Host ""
Write-Host "Now you need to create the package in Visual Studio:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Open Visual Studio 2022" -ForegroundColor Cyan
Write-Host "  2. Open solution: MCBDSHost.sln" -ForegroundColor Cyan
Write-Host "  3. Right-click MCBDS.PublicUI project" -ForegroundColor Cyan
Write-Host "  4. Select: Publish ? Create App Packages..." -ForegroundColor Cyan
Write-Host "  5. Choose: Microsoft Store (select MCBDS Manager)" -ForegroundColor Cyan
Write-Host "  6. Sign in to Partner Center" -ForegroundColor Cyan
Write-Host "  7. Configure:" -ForegroundColor Cyan
Write-Host "     - Architecture: x64 (or x64, x86, ARM64)" -ForegroundColor Gray
Write-Host "     - Generate app bundle: Always" -ForegroundColor Gray
Write-Host "  8. Click Create" -ForegroundColor Cyan
Write-Host ""
Write-Host "??  IMPORTANT: The package will be created UNSIGNED because" -ForegroundColor Yellow
Write-Host "   signing was disabled in the project file." -ForegroundColor Yellow
Write-Host ""
Write-Host "After Visual Studio completes:" -ForegroundColor White
Write-Host "  9. Run: .\RestoreProjectFile.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "The package will be in:" -ForegroundColor White
Write-Host "  AppPackages\MCBDS.PublicUI_${version}_Test\" -ForegroundColor Gray
Write-Host ""
Write-Host "Upload the .msixupload file to Partner Center" -ForegroundColor White
Write-Host ""

# Create restore script
$restoreScriptContent = @"
# Restore Project File After Packaging

`$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "Restoring project file..." -ForegroundColor Yellow

`$projectFile = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
`$backupFile = "`$projectFile.backup"

if (Test-Path `$backupFile) {
    Copy-Item `$backupFile `$projectFile -Force
    Remove-Item `$backupFile -Force
    Write-Host "? Project file restored" -ForegroundColor Green
} else {
    Write-Host "??  Backup file not found" -ForegroundColor Yellow
}

Write-Host ""
"@

$restoreScriptContent | Out-File -FilePath "RestoreProjectFile.ps1" -Encoding UTF8 -Force

Write-Host "? Restore script created: RestoreProjectFile.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

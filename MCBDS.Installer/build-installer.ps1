# Build and Create NSIS Installer for MCBDS API Service
# This script publishes the Windows Service and builds the NSIS installer

param(
    [string]$Configuration = "Release",
    [string]$NsisPath = "C:\Program Files (x86)\NSIS\makensis.exe"
)

# Colors for output
$Success = "Green"
$Error = "Red"
$Info = "Cyan"

Write-Host "========================================" -ForegroundColor $Info
Write-Host "MCBDS API Service Installer Build Script" -ForegroundColor $Info
Write-Host "========================================" -ForegroundColor $Info

# Step 1: Check NSIS installation
Write-Host "`n[1/3] Checking NSIS installation..." -ForegroundColor $Info
if (-not (Test-Path $NsisPath)) {
    Write-Host "ERROR: NSIS not found at $NsisPath" -ForegroundColor $Error
    Write-Host "Please install NSIS from: https://nsis.sourceforge.io/" -ForegroundColor $Error
    Write-Host "Or update the -NsisPath parameter." -ForegroundColor $Error
    exit 1
}
Write-Host "? NSIS found" -ForegroundColor $Success

# Step 2: Publish Windows Service
Write-Host "`n[2/3] Publishing Windows Service..." -ForegroundColor $Info
$ServiceProjectPath = "MCBDS.WindowsService\MCBDS.WindowsService.csproj"

if (-not (Test-Path $ServiceProjectPath)) {
    Write-Host "ERROR: Windows Service project not found at $ServiceProjectPath" -ForegroundColor $Error
    exit 1
}

$PublishOutput = dotnet publish $ServiceProjectPath -c $Configuration -r win-x64 --self-contained 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to publish Windows Service" -ForegroundColor $Error
    Write-Host $PublishOutput
    exit 1
}
Write-Host "? Windows Service published" -ForegroundColor $Success

# Step 3: Build NSIS Installer
Write-Host "`n[3/3] Building NSIS installer..." -ForegroundColor $Info
$NsiScript = "MCBDS.Installer\MCBDSInstaller.nsi"

if (-not (Test-Path $NsiScript)) {
    Write-Host "ERROR: NSIS script not found at $NsiScript" -ForegroundColor $Error
    exit 1
}

# Build NSIS (output path is specified in the .nsi script)
$BuildOutput = & $NsisPath $NsiScript 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: NSIS build failed" -ForegroundColor $Error
    Write-Host $BuildOutput
    exit 1
}
Write-Host "? Installer built successfully" -ForegroundColor $Success

# Verify the installer was created
$InstallerPath = "MCBDS.API.Service.Installer.exe"
if (-not (Test-Path $InstallerPath)) {
    Write-Host "ERROR: Installer file not found at $InstallerPath" -ForegroundColor $Error
    exit 1
}

# Get file size
$FileSize = (Get-Item $InstallerPath).Length
if ($FileSize -lt 5MB) {
    Write-Host "WARNING: Installer is only $(($FileSize / 1MB).ToString('F2')) MB" -ForegroundColor "Yellow"
}

# Step 4: Show completion message
Write-Host "`n========================================" -ForegroundColor $Info
Write-Host "Build Complete!" -ForegroundColor $Success
Write-Host "========================================" -ForegroundColor $Info
Write-Host "`nInstaller created: MCBDS.API.Service.Installer.exe" -ForegroundColor $Success
Write-Host "`nNext steps:" -ForegroundColor $Info
Write-Host "1. Copy the installer to a distribution location" -ForegroundColor $Info
Write-Host "2. Run the installer with admin privileges" -ForegroundColor $Info
Write-Host "3. The service will start automatically" -ForegroundColor $Info
Write-Host "4. Access the API at: http://localhost:8080" -ForegroundColor $Info

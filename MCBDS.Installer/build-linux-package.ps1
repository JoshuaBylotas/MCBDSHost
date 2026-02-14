# MCBDS API Linux Package Builder
# Creates versioned Linux deployment package
# 
# Usage:
#   .\build-linux-package.ps1                    # Builds v1.1.51 (default)
#   .\build-linux-package.ps1 -Version "1.2.0"   # Builds v1.2.0
#
# Output Structure:
#   publish/
#     ?? {Version}/
#          ?? mcbds-api-linux-x64-v{Version}.zip
#          ?? files/ (extracted contents)

param(
    [Parameter(HelpMessage="Version number for the release (e.g., 1.1.51, 1.2.0)")]
    [string]$Version = "1.1.51",
    
    [Parameter(HelpMessage="Build configuration (Release or Debug)")]
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    
    [Parameter(HelpMessage="Base output directory name (relative to script location)")]
    [string]$OutputDirName = "publish"
)

$ErrorActionPreference = "Stop"

# Get script directory and repository root
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = Get-Location
}

# Repository root is one level up from MCBDS.Installer
$repoRoot = Split-Path $scriptDir -Parent

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MCBDS API Linux Package Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Repository Root: $repoRoot" -ForegroundColor Gray
Write-Host "Version:         $Version" -ForegroundColor White
Write-Host "Configuration:   $Configuration" -ForegroundColor White
Write-Host "Output Path:     $OutputDirName\$Version\" -ForegroundColor White
Write-Host "Package Name:    mcbds-api-linux-x64-v$Version.zip" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Define paths (relative to repository root)
$projectPath = Join-Path $repoRoot "MCBDS.API\MCBDS.API.csproj"
$baseOutputDir = Join-Path $repoRoot $OutputDirName
$versionDir = Join-Path $baseOutputDir $Version
$publishDir = Join-Path $versionDir "files"
$zipFileName = "mcbds-api-linux-x64-v$Version.zip"
$zipPath = Join-Path $versionDir $zipFileName

Write-Host "`nResolved Paths:" -ForegroundColor Gray
Write-Host "  Project:  $projectPath" -ForegroundColor DarkGray
Write-Host "  Output:   $baseOutputDir" -ForegroundColor DarkGray
Write-Host "  Version:  $versionDir" -ForegroundColor DarkGray
Write-Host "  Publish:  $publishDir" -ForegroundColor DarkGray
Write-Host "  Zip File: $zipPath" -ForegroundColor DarkGray

# Check if project exists
if (-not (Test-Path $projectPath)) {
    Write-Error "Project file not found: $projectPath"
    exit 1
}

# Clean and create output directories
Write-Host "`n[1/5] Preparing output directory..." -ForegroundColor Yellow

# Only clean the Linux-specific 'files' subdirectory, never touch .exe files
if (Test-Path $publishDir) {
    Write-Host "Removing existing Linux build files: $publishDir" -ForegroundColor Gray
    Remove-Item -Path $publishDir -Recurse -Force
}

# Remove old Linux zip if it exists
if (Test-Path $zipPath) {
    Write-Host "Removing existing Linux zip: $zipFileName" -ForegroundColor Gray
    Remove-Item -Path $zipPath -Force
}

# Create all necessary directories
Write-Host "Creating directory structure: publish\$Version\" -ForegroundColor Gray
New-Item -ItemType Directory -Path $baseOutputDir -Force | Out-Null
New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

# Verify directories were created
if (-not (Test-Path $publishDir)) {
    Write-Error "Failed to create publish directory: $publishDir"
    exit 1
}

# Check if Windows installer exists in same directory (informational only)
$exeFiles = Get-ChildItem -Path $versionDir -Filter "*.exe" -ErrorAction SilentlyContinue
if ($exeFiles) {
    Write-Host "? Windows installer files detected in same directory (will not be modified):" -ForegroundColor Cyan
    $exeFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
}

Write-Host "? Directory structure created" -ForegroundColor Green

# Publish for Linux x64
Write-Host "`n[2/5] Publishing MCBDS.API for linux-x64..." -ForegroundColor Yellow
Write-Host "Configuration: $Configuration" -ForegroundColor Gray
Write-Host "Target: linux-x64 (framework-dependent)" -ForegroundColor Gray

dotnet publish $projectPath `
    --configuration $Configuration `
    --runtime linux-x64 `
    --self-contained false `
    --output $publishDir `
    /p:PublishSingleFile=false `
    /p:PublishTrimmed=false `
    /p:DebugType=None `
    /p:DebugSymbols=false

if ($LASTEXITCODE -ne 0) {
    Write-Error "dotnet publish failed with exit code $LASTEXITCODE"
    exit 1
}

Write-Host "? Publish completed successfully" -ForegroundColor Green

# Create comprehensive appsettings.json with all settings
Write-Host "`n[3/5] Creating configuration file..." -ForegroundColor Yellow

$appSettings = @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "Runner": {
    "ExePath": "/opt/mcbds/binaries/bedrock_server",
    "WorkingDirectory": "/opt/mcbds/binaries"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "/opt/mcbds/backups",
    "MaxBackupsToKeep": 30,
    "Enabled": true
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:8080"
      }
    }
  }
}
"@

$appSettings | Out-File -FilePath "$publishDir\appsettings.json" -Encoding UTF8
Write-Host "? Created appsettings.json" -ForegroundColor Green

# Create README for the package (version-aware)
Write-Host "`n[4/5] Creating package README..." -ForegroundColor Yellow
$readme = @"
# MCBDS API Linux Package v$Version

## Contents
This package contains the MCBDS Manager API v$Version compiled for Linux x64.

## Installation
See INSTALLATION.md or visit:
https://www.mc-bds.com/get-started

## Quick Start
1. Extract to /opt/mcbds/api
2. Install .NET 10 ASP.NET Core Runtime
3. Make executable: chmod +x MCBDS.API
4. Configure appsettings.Production.json
5. Run: ./MCBDS.API

## Requirements
- .NET 10 ASP.NET Core Runtime
- Ubuntu 20.04+ or compatible Linux distribution
- x64 architecture

## Support
- GitHub: https://github.com/JoshuaBylotas/MCBDSHost
- Website: https://www.mc-bds.com
- Issues: https://github.com/JoshuaBylotas/MCBDSHost/issues

## Version
$Version - $(Get-Date -Format "yyyy-MM-dd")
"@

$readme | Out-File -FilePath "$publishDir\README.md" -Encoding UTF8
Write-Host "? Created README.md (v$Version)" -ForegroundColor Green

# Copy installation guide from MCBDS.Installer directory
$installGuide = Join-Path $scriptDir "LINUX-INSTALLATION-GUIDE.md"
if (Test-Path $installGuide) {
    Copy-Item $installGuide -Destination "$publishDir\INSTALLATION.md"
    Write-Host "? Copied installation guide" -ForegroundColor Green
} else {
    Write-Host "? Installation guide not found at: $installGuide" -ForegroundColor Yellow
}

# Create zip package
Write-Host "`n[5/5] Creating zip package..." -ForegroundColor Yellow
if (Test-Path $zipPath) {
    Write-Host "Removing existing zip file..." -ForegroundColor Gray
    Remove-Item -Path $zipPath -Force
}

# Ensure parent directory exists
$zipParentDir = Split-Path -Parent $zipPath
if (-not (Test-Path $zipParentDir)) {
    New-Item -ItemType Directory -Path $zipParentDir -Force | Out-Null
}

# Use .NET compression
Write-Host "Compressing files..." -ForegroundColor Gray
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($publishDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

if (-not (Test-Path $zipPath)) {
    Write-Error "Failed to create zip file at: $zipPath"
    exit 1
}

# Get file size
$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "? Created $zipFileName ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green

# Display summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BUILD SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Package: $zipFileName" -ForegroundColor White
Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
Write-Host "Location: $(Resolve-Path $zipPath)" -ForegroundColor White
Write-Host "Output Directory: $(Resolve-Path $versionDir)" -ForegroundColor White
Write-Host "Runtime: linux-x64 (framework-dependent)" -ForegroundColor White
Write-Host "Requires: .NET 10 ASP.NET Core Runtime" -ForegroundColor White

Write-Host "`nOutput structure:" -ForegroundColor Yellow
Write-Host "publish\" -ForegroundColor Gray
Write-Host "  ?? $Version\" -ForegroundColor Gray
Write-Host "       ?? $zipFileName" -ForegroundColor Gray
Write-Host "       ?? files\ (extracted contents)" -ForegroundColor Gray

Write-Host "`nPublished files:" -ForegroundColor Yellow
Get-ChildItem -Path $publishDir | Select-Object Name, @{Name="Size";Expression={"{0:N2} KB" -f ($_.Length / 1KB)}} | Format-Table -AutoSize

Write-Host "? Linux package build completed successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Test the package on a Linux system" -ForegroundColor Gray
Write-Host "   - Extract $zipFileName" -ForegroundColor Gray
Write-Host "   - Follow LINUX-INSTALLATION-GUIDE.md instructions" -ForegroundColor Gray
Write-Host "2. Upload $zipFileName to GitHub Releases" -ForegroundColor Gray
Write-Host "3. Update download URL in LINUX-INSTALLATION-GUIDE.md" -ForegroundColor Gray
Write-Host "   - Replace [DOWNLOAD_URL] with actual URL" -ForegroundColor Gray
Write-Host "4. Update mc-bds.com downloads page" -ForegroundColor Gray
Write-Host "`nPackage ready at: $(Resolve-Path $zipPath)" -ForegroundColor Cyan

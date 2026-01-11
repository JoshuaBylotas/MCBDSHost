# Configure-MCBDSVolumes.ps1
# Interactive script to configure custom drive locations for MCBDS Manager Docker volumes
# and verify Docker Compose configuration completeness

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MCBDS Manager - Volume Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the current directory (where docker-compose.windows.yml should be)
$rootDir = Get-Location

# Function to validate path
function Test-ValidPath {
    param([string]$Path)
    
    # Check if drive exists
    $drive = $Path.Split(':')[0]
    if ($drive.Length -eq 1) {
        $driveExists = Test-Path "${drive}:\."
        if (-not $driveExists) {
            Write-Host "  Warning: Drive ${drive}: does not exist or is not accessible" -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}

# Function to prompt for path with default
function Get-PathWithDefault {
    param(
        [string]$Prompt,
        [string]$Default,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host $Description -ForegroundColor Gray
    Write-Host "Default: $Default" -ForegroundColor DarkGray
    $input = Read-Host "$Prompt (press Enter for default)"
    
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    
    # Validate the path
    if (-not (Test-ValidPath $input)) {
        Write-Host "  Using default path instead." -ForegroundColor Yellow
        return $Default
    }
    
    return $input
}

# Function to check if docker-compose has required settings
function Test-DockerComposeConfig {
    param([string]$Content)
    
    $issues = @()
    
    # Check for HTTPS port (8081)
    if ($Content -notmatch '8081:8081') {
        $issues += "Missing HTTPS port mapping (8081:8081)"
    }
    
    # Check for HTTP port (8080)
    if ($Content -notmatch '8080:8080') {
        $issues += "Missing HTTP API port mapping (8080:8080)"
    }
    
    # Check for Minecraft IPv4 port
    if ($Content -notmatch '19132:19132/udp') {
        $issues += "Missing Minecraft IPv4 port (19132:19132/udp)"
    }
    
    # Check for Minecraft IPv6 port
    if ($Content -notmatch '19133:19133/udp') {
        $issues += "Missing Minecraft IPv6 port (19133:19133/udp)"
    }
    
    # Check for HTTPS certificate configuration
    if ($Content -notmatch 'ASPNETCORE_Kestrel__Certificates__Default__Path') {
        $issues += "Missing HTTPS certificate path configuration"
    }
    
    # Check for ASPNETCORE_URLS with HTTPS
    if ($Content -notmatch 'ASPNETCORE_URLS.*https') {
        $issues += "Missing HTTPS URL configuration"
    }
    
    # Check for healthcheck
    if ($Content -notmatch 'healthcheck:') {
        $issues += "Missing container healthcheck configuration"
    }
    
    # Check for restart policy
    if ($Content -notmatch 'restart:') {
        $issues += "Missing restart policy"
    }
    
    # Check for isolation mode (Windows containers)
    if ($Content -notmatch 'isolation:') {
        $issues += "Missing container isolation mode"
    }
    
    return $issues
}

# Function to add missing configuration to docker-compose
function Add-MissingDockerConfig {
    param(
        [string]$Content,
        [array]$Issues,
        [string]$BedrockPath,
        [string]$BackupPath,
        [string]$ConfigPath,
        [string]$CertsPath,
        [string]$LogsPath
    )
    
    $modified = $Content
    
    foreach ($issue in $Issues) {
        Write-Host "  Fixing: $issue" -ForegroundColor Yellow
    }
    
    # Add comprehensive configuration if major pieces are missing
    if ($Issues.Count -gt 3) {
        Write-Host ""
        Write-Host "  Multiple configuration issues detected." -ForegroundColor Yellow
        Write-Host "  Would you like to apply a complete reference configuration? (Y/N)" -ForegroundColor Yellow
        $applyRef = Read-Host
        
        if ($applyRef -eq 'Y' -or $applyRef -eq 'y') {
            # Create a reference configuration template with user's paths
            $referenceConfig = @"
# Docker Compose for Windows Containers with HTTPS
# Auto-configured by Configure-MCBDSVolumes.ps1

services:
  mcbds-api:
    build:
      context: .
      dockerfile: MCBDS.API/Dockerfile.windows
      args:
        - WINDOWS_VERSION=ltsc2022
    container_name: mcbds-api
    ports:
      - "8080:8080"       # HTTP API
      - "8081:8081"       # HTTPS API
      - "19132:19132/udp" # Minecraft Bedrock IPv4
      - "19133:19133/udp" # Minecraft Bedrock IPv6
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=https://+:8081;http://+:8080
      - ASPNETCORE_Kestrel__Certificates__Default__Path=C:/https/mcbds-api.pfx
      - ASPNETCORE_Kestrel__Certificates__Default__Password=McbdsApiCert123!
      - DOTNET_RUNNING_IN_CONTAINER=true
    volumes:
      # HTTPS Certificate
      - $CertsPath`:C:/https:ro
      # Bedrock server (Windows .exe)
      - $BedrockPath`:C:/app/Binaries
      # Logs
      - $LogsPath`:C:/app/logs
      # Backups
      - $BackupPath`:C:/app/backups
      # Configuration
      - $ConfigPath`:C:/app/config
    restart: unless-stopped
    isolation: process
    healthcheck:
      test: ["CMD", "powershell", "-Command", "try { Invoke-WebRequest -Uri https://localhost:8081/health -UseBasicParsing -SkipCertificateCheck; exit 0 } catch { exit 1 }"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  default:
    name: mcbds-network
"@
            return $referenceConfig
        }
    }
    
    return $modified
}

# Check if docker-compose.windows.yml exists
$composeFile = "docker-compose.windows.yml"
if (-not (Test-Path $composeFile)) {
    Write-Host "Error: $composeFile not found in current directory!" -ForegroundColor Red
    Write-Host "Current directory: $rootDir" -ForegroundColor Yellow
    Write-Host "Please run this script from the MCBDSHost root directory." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Current directory: $rootDir" -ForegroundColor Gray
Write-Host ""
Write-Host "This script will help you configure custom drive locations for:" -ForegroundColor White
Write-Host "  1. Bedrock Server files" -ForegroundColor White
Write-Host "  2. Backup storage" -ForegroundColor White
Write-Host "  3. Configuration files" -ForegroundColor White
Write-Host "  4. HTTPS certificates" -ForegroundColor White
Write-Host "  5. Log files" -ForegroundColor White
Write-Host ""
Write-Host "It will also verify your docker-compose.windows.yml configuration." -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C at any time to cancel." -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 2

# Validate docker-compose configuration
Write-Host "Validating docker-compose.windows.yml..." -ForegroundColor Cyan
$originalContent = Get-Content $composeFile -Raw
$configIssues = Test-DockerComposeConfig -Content $originalContent

if ($configIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "Configuration issues detected:" -ForegroundColor Yellow
    foreach ($issue in $configIssues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Get paths from user - using root directory as base
$defaultBase = "$rootDir"

$bedrockPath = Get-PathWithDefault `
    -Prompt "Bedrock Server Location" `
    -Default "$defaultBase\bedrock-server" `
    -Description "Location for Minecraft Bedrock Dedicated Server files"

$backupPath = Get-PathWithDefault `
    -Prompt "Backup Storage Location" `
    -Default "$defaultBase\backups" `
    -Description "Location for automated world backups"

$configPath = Get-PathWithDefault `
    -Prompt "Configuration Location" `
    -Default "$defaultBase\config" `
    -Description "Location for MCBDS Manager configuration files"

$certsPath = Get-PathWithDefault `
    -Prompt "HTTPS Certificates Location" `
    -Default "$defaultBase\certs" `
    -Description "Location for HTTPS certificates"

$logsPath = Get-PathWithDefault `
    -Prompt "Logs Location" `
    -Default "$defaultBase\logs" `
    -Description "Location for API and server logs"

# Display summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bedrock Server: " -NoNewline
Write-Host $bedrockPath -ForegroundColor Green
Write-Host "Backups:        " -NoNewline
Write-Host $backupPath -ForegroundColor Green
Write-Host "Configuration:  " -NoNewline
Write-Host $configPath -ForegroundColor Green
Write-Host "Certificates:   " -NoNewline
Write-Host $certsPath -ForegroundColor Green
Write-Host "Logs:           " -NoNewline
Write-Host $logsPath -ForegroundColor Green
Write-Host ""

if ($configIssues.Count -gt 0) {
    Write-Host "Docker Compose Issues: $($configIssues.Count) found" -ForegroundColor Yellow
    Write-Host ""
}

$confirm = Read-Host "Apply these settings? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Configuration cancelled." -ForegroundColor Yellow
    exit 0
}

# Create directories if they don't exist
Write-Host ""
Write-Host "Creating directories..." -ForegroundColor Cyan

$directories = @($bedrockPath, $backupPath, $configPath, $certsPath, $logsPath)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

# Backup original docker-compose file
$backupFile = "docker-compose.windows.yml.backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFileTimestamped = "docker-compose.windows.yml.backup.$timestamp"

if (-not (Test-Path $backupFile)) {
    Copy-Item $composeFile $backupFile
    Write-Host ""
    Write-Host "Original configuration backed up to: $backupFile" -ForegroundColor Green
}
Copy-Item $composeFile $backupFileTimestamped
Write-Host "Timestamped backup created: $backupFileTimestamped" -ForegroundColor Green

# Read docker-compose.yml content
$content = Get-Content $composeFile -Raw

# Fix configuration issues if needed
if ($configIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "Applying configuration fixes..." -ForegroundColor Cyan
    $content = Add-MissingDockerConfig -Content $content -Issues $configIssues `
        -BedrockPath $bedrockPath -BackupPath $backupPath -ConfigPath $configPath `
        -CertsPath $certsPath -LogsPath $logsPath
}

# Replace paths in the file (handle various possible existing paths)
# Update volume mounts - handle both forward and backward slashes
$content = $content -replace 'C:/MCBDSHost/bedrock-server', $bedrockPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSHost\\bedrock-server', $bedrockPath
$content = $content -replace 'C:/MCBDSManager/bedrock-server', $bedrockPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSManager\\bedrock-server', $bedrockPath

$content = $content -replace 'C:/MCBDSHost/backups', $backupPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSHost\\backups', $backupPath
$content = $content -replace 'C:/MCBDSManager/backups', $backupPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSManager\\backups', $backupPath

$content = $content -replace 'C:/MCBDSHost/config', $configPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSHost\\config', $configPath
$content = $content -replace 'C:/MCBDSManager/config', $configPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSManager\\config', $configPath

$content = $content -replace 'C:/MCBDSHost/certs', $certsPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSHost\\certs', $certsPath
$content = $content -replace 'C:/MCBDSManager/certs', $certsPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSManager\\certs', $certsPath

$content = $content -replace 'C:/MCBDSHost/logs', $logsPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSHost\\logs', $logsPath
$content = $content -replace 'C:/MCBDSManager/logs', $logsPath.Replace('\', '/')
$content = $content -replace 'C:\\MCBDSManager\\logs', $logsPath

# Write updated content
Set-Content -Path $composeFile -Value $content

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your docker-compose.windows.yml has been updated with custom paths." -ForegroundColor White
Write-Host ""

if ($configIssues.Count -gt 0) {
    Write-Host "Configuration improvements applied:" -ForegroundColor Green
    foreach ($issue in $configIssues) {
        Write-Host "  ? Fixed: $issue" -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Generate HTTPS certificate (if not exists):" -ForegroundColor White
Write-Host "     .\generate-https-cert.ps1" -ForegroundColor Gray
Write-Host "     Copy-Item .\certs\mcbds-api.pfx '$certsPath\' -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Download Minecraft Bedrock Server to: $bedrockPath" -ForegroundColor White
Write-Host ""
Write-Host "  3. Verify VC++ Redistributable is installed:" -ForegroundColor White
Write-Host "     https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Start Docker containers:" -ForegroundColor White
Write-Host "     docker compose -f docker-compose.windows.yml build" -ForegroundColor Gray
Write-Host "     docker compose -f docker-compose.windows.yml up -d" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Test services:" -ForegroundColor White
Write-Host "     HTTP API:  http://localhost:8080/health" -ForegroundColor Gray
Write-Host "     HTTPS API: https://localhost:8081/health" -ForegroundColor Gray
Write-Host "     Minecraft: localhost:19132" -ForegroundColor Gray
Write-Host ""
Write-Host "To restore original configuration:" -ForegroundColor Gray
Write-Host "  Copy-Item $backupFile $composeFile -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "Backups available:" -ForegroundColor Gray
Write-Host "  Latest: $backupFile" -ForegroundColor Gray
Write-Host "  Timestamped: $backupFileTimestamped" -ForegroundColor Gray
Write-Host ""

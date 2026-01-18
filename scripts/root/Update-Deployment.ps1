################################################################################
# MCBDSHost Deployment Update Script (Windows)
# 
# This script pulls the latest code from GitHub and updates the running
# Docker containers with zero-downtime deployment strategy.
#
# Usage: .\Update-Deployment.ps1 [-Force] [-NoBackup]
################################################################################

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoBackup
)

# Configuration
$ScriptDir = $PSScriptRoot
$BackupDir = Join-Path $ScriptDir "backups"
$LogFile = Join-Path $ScriptDir "update-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

################################################################################
# Helper Functions
################################################################################

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
    Add-Content -Path $LogFile -Value $logMessage
}

function Confirm-Action {
    param([string]$Message)
    
    if ($Force) {
        return $true
    }
    
    $response = Read-Host "$Message (y/n)"
    return $response -match '^[Yy]$'
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    # Check if Docker is installed
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Log "Docker is not installed. Please install Docker Desktop first." "ERROR"
        exit 1
    }
    
    # Check if Docker Compose is available
    try {
        docker compose version | Out-Null
    }
    catch {
        Write-Log "Docker Compose is not available. Please install Docker Desktop with Compose plugin." "ERROR"
        exit 1
    }
    
    # Check if Git is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log "Git is not installed. Please install Git first." "ERROR"
        exit 1
    }
    
    # Check if we're in a git repository
    try {
        git rev-parse --git-dir | Out-Null
    }
    catch {
        Write-Log "Not in a Git repository. Please run this script from the MCBDSHost directory." "ERROR"
        exit 1
    }
    
    Write-Log "All prerequisites met ?" "SUCCESS"
}

function Backup-Volumes {
    if ($NoBackup) {
        Write-Log "Skipping backup as requested" "WARNING"
        return
    }
    
    Write-Log "Creating backup of Docker volumes..." "INFO"
    
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Backup worlds
    $worldsVolume = docker volume ls --format "{{.Name}}" | Select-String "mcbds-worlds"
    if ($worldsVolume) {
        Write-Log "Backing up world data..." "INFO"
        docker run --rm `
            -v mcbds-worlds:/data `
            -v "${BackupDir}:/backup" `
            alpine tar czf "/backup/worlds-backup-$timestamp.tar.gz" /data
        Write-Log "World data backed up to: $BackupDir\worlds-backup-$timestamp.tar.gz" "SUCCESS"
    }
    
    # Backup config
    $configVolume = docker volume ls --format "{{.Name}}" | Select-String "mcbds-config"
    if ($configVolume) {
        Write-Log "Backing up configuration..." "INFO"
        docker run --rm `
            -v mcbds-config:/data `
            -v "${BackupDir}:/backup" `
            alpine tar czf "/backup/config-backup-$timestamp.tar.gz" /data
        Write-Log "Configuration backed up to: $BackupDir\config-backup-$timestamp.tar.gz" "SUCCESS"
    }
    
    Write-Log "Backup completed ?" "SUCCESS"
}

function Test-ForUpdates {
    Write-Log "Checking for updates..." "INFO"
    
    # Fetch latest from remote
    git fetch origin master
    
    # Check if there are updates
    $local = git rev-parse HEAD
    $remote = git rev-parse origin/master
    
    if ($local -eq $remote) {
        Write-Log "Already up to date. No updates needed." "INFO"
        if (-not (Confirm-Action "Do you want to rebuild anyway?")) {
            exit 0
        }
    }
    else {
        Write-Log "Updates available" "INFO"
        git log --oneline HEAD..origin/master
    }
}

function Update-Code {
    Write-Log "Pulling latest code from GitHub..." "INFO"
    
    # Check for local changes
    $hasChanges = git diff-index --quiet HEAD
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Local changes detected" "WARNING"
        if (Confirm-Action "Do you want to stash local changes?") {
            git stash
            Write-Log "Local changes stashed" "INFO"
        }
        else {
            Write-Log "Cannot pull with local changes. Aborting." "ERROR"
            exit 1
        }
    }
    
    # Pull latest code
    git pull origin master
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Code updated successfully ?" "SUCCESS"
    }
    else {
        Write-Log "Failed to pull latest code" "ERROR"
        exit 1
    }
}

function Stop-Containers {
    Write-Log "Stopping running containers..." "INFO"
    
    $runningContainers = docker compose ps --services --filter "status=running"
    if ($runningContainers) {
        docker compose down
        Write-Log "Containers stopped ?" "SUCCESS"
    }
    else {
        Write-Log "No running containers found" "INFO"
    }
}

function Build-Images {
    Write-Log "Building Docker images..." "INFO"
    
    docker compose build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Images built successfully ?" "SUCCESS"
    }
    else {
        Write-Log "Failed to build Docker images" "ERROR"
        exit 1
    }
}

function Start-Containers {
    Write-Log "Starting containers..." "INFO"
    
    docker compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Containers started ?" "SUCCESS"
    }
    else {
        Write-Log "Failed to start containers" "ERROR"
        exit 1
    }
}

function Test-Deployment {
    Write-Log "Verifying deployment..." "INFO"
    
    # Wait for containers to be healthy
    Start-Sleep -Seconds 5
    
    # Check if containers are running
    $runningContainers = docker compose ps --services --filter "status=running"
    if ($runningContainers) {
        Write-Log "Containers are running ?" "SUCCESS"
    }
    else {
        Write-Log "Containers failed to start" "ERROR"
        docker compose logs
        exit 1
    }
    
    # Check API health endpoint
    Write-Log "Checking API health..." "INFO"
    $maxAttempts = 30
    $healthy = $false
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                Write-Log "API health check passed ?" "SUCCESS"
                $healthy = $true
                break
            }
        }
        catch {
            if ($i -eq $maxAttempts) {
                Write-Log "API health check failed after $maxAttempts attempts" "WARNING"
            }
            else {
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-Status {
    Write-Log "Deployment Status:" "INFO"
    docker compose ps
    
    Write-Host ""
    Write-Log "Recent Logs:" "INFO"
    docker compose logs --tail=20
}

function Remove-OldBackups {
    Write-Log "Cleaning up old backups (keeping last 5)..." "INFO"
    
    if (Test-Path $BackupDir) {
        # Keep only the 5 most recent backups
        Get-ChildItem "$BackupDir\worlds-backup-*.tar.gz" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -Skip 5 | 
            Remove-Item -Force
        
        Get-ChildItem "$BackupDir\config-backup-*.tar.gz" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -Skip 5 | 
            Remove-Item -Force
        
        Write-Log "Old backups cleaned up ?" "SUCCESS"
    }
}

################################################################################
# Main Execution
################################################################################

Write-Log "=========================================" "INFO"
Write-Log "MCBDSHost Deployment Update Started" "INFO"
Write-Log "=========================================" "INFO"

# Run update steps
try {
    Test-Prerequisites
    Test-ForUpdates
    
    if (-not $Force) {
        Write-Host ""
        Write-Log "This will update your deployment and may cause brief downtime." "WARNING"
        if (-not (Confirm-Action "Do you want to continue?")) {
            Write-Log "Update cancelled by user" "INFO"
            exit 0
        }
    }
    
    Backup-Volumes
    Update-Code
    Stop-Containers
    Build-Images
    Start-Containers
    Test-Deployment
    Remove-OldBackups
    Show-Status
    
    Write-Log "=========================================" "SUCCESS"
    Write-Log "Update Completed Successfully! ?" "SUCCESS"
    Write-Log "=========================================" "SUCCESS"
    Write-Log "Log file: $LogFile" "INFO"
}
catch {
    Write-Log "An error occurred during update: $_" "ERROR"
    Write-Log "Check the log file for details: $LogFile" "ERROR"
    exit 1
}

exit 0

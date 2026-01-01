# Windows Server 2025 Docker Deployment Guide

## Overview

Deploy MCBDSHost to Windows Server 2025 using Docker Desktop for Windows. This guide covers complete setup from a fresh Windows Server installation using an external bedrock-server directory at `C:\MCBDSHost\bedrock-server`.

## Prerequisites

- **Windows Server 2025** (also works with Windows Server 2019/2022 or Windows 10/11 Pro)
- **4GB RAM minimum** (8GB+ recommended)
- **Administrator access**
- **Internet connection**

---

## Complete Installation Steps

### Step 1: Enable Windows Features

Open **PowerShell as Administrator** and run:

```powershell
# Enable Hyper-V and Containers features
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart

# Restart the server (REQUIRED)
Restart-Computer
```

**Wait for the server to restart before continuing.**

---

### Step 2: Install Docker Desktop

After restart, open **PowerShell as Administrator**:

```powershell
# Option A: Using winget (Recommended for Windows Server 2025)
winget install -e --id Docker.DockerDesktop

# Option B: Manual download if winget is not available
# Download from: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
# Run the installer and follow the wizard
```

**After installation:**
1. Restart your computer if prompted
2. Launch Docker Desktop from the Start menu
3. Wait for Docker Desktop to fully start (icon in system tray shows "Docker Desktop is running")
4. Accept the Docker Desktop license agreement

**Verify Docker installation:**

```powershell
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker is working
docker run hello-world
```

Expected output should show Docker version and a "Hello from Docker!" message.

---

### Step 3: Install Git for Windows

```powershell
# Using winget
winget install -e --id Git.Git

# Close and reopen PowerShell after installation to refresh PATH
```

**Verify Git installation:**

```powershell
git --version
```

---

### Step 4: Create Directory Structure and Clone Repository

```powershell
# Create the main deployment directory
New-Item -Path "C:\MCBDSHost" -ItemType Directory -Force

# Navigate to the directory
Set-Location "C:\MCBDSHost"

# Clone the repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git

# Navigate into the project
Set-Location "C:\MCBDSHost\MCBDSHost"

# Verify you're in the correct directory
Get-Location
# Should show: C:\MCBDSHost\MCBDSHost
```

**If you already have the repository cloned, pull latest changes:**

```powershell
# Navigate to the project directory
Set-Location "C:\MCBDSHost\MCBDSHost"

# Pull latest changes from the repository
git pull origin master
```

### GitHub Authentication (If Private Repository)

If prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (NOT your GitHub password)
- Create token at: https://github.com/settings/tokens
- Required scope: `repo`

---

### Step 5: Download Minecraft Bedrock Server

The bedrock server files are stored **externally** at `C:\MCBDSHost\bedrock-server\` on your host machine. This allows you to update the Minecraft server without rebuilding Docker images.

```powershell
# Create the external bedrock-server directory
New-Item -Path "C:\MCBDSHost\bedrock-server" -ItemType Directory -Force

# Navigate to the bedrock-server directory
Set-Location "C:\MCBDSHost\bedrock-server"

# Download the latest Bedrock Server for Windows
# Check https://www.minecraft.net/en-us/download/server/bedrock for the latest version URL
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.44.01.zip"
$output = "bedrock-server.zip"

Write-Host "Downloading Minecraft Bedrock Server..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $output

# Extract the zip file
Write-Host "Extracting files..." -ForegroundColor Cyan
Expand-Archive -Path bedrock-server.zip -DestinationPath . -Force

# Clean up the zip file
Remove-Item bedrock-server.zip

# Verify bedrock_server.exe exists
if (Test-Path "bedrock_server.exe") {
    Write-Host "SUCCESS: bedrock_server.exe found!" -ForegroundColor Green
} else {
    Write-Host "ERROR: bedrock_server.exe not found!" -ForegroundColor Red
}

# Return to project directory
Set-Location "C:\MCBDSHost\MCBDSHost"
```

---

### Step 6: Configure Windows Firewall

```powershell
# Run as Administrator - Create firewall rules for MCBDSHost

Write-Host "Creating firewall rules..." -ForegroundColor Cyan

# Web UI port
New-NetFirewallRule -DisplayName "MCBDSHost - Web UI" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow

# API port
New-NetFirewallRule -DisplayName "MCBDSHost - API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

# Minecraft IPv4 port
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv4" -Direction Inbound -LocalPort 19132 -Protocol UDP -Action Allow

# Minecraft IPv6 port
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv6" -Direction Inbound -LocalPort 19133 -Protocol UDP -Action Allow

# Verify rules were created
Write-Host "Firewall rules created:" -ForegroundColor Green
Get-NetFirewallRule -DisplayName "MCBDSHost*" | Format-Table DisplayName, Enabled, Direction
```

---

### Step 7: Build and Start Docker Services

```powershell
# Ensure you're in the project directory
Set-Location "C:\MCBDSHost\MCBDSHost"

# Build the Docker images (first time will take several minutes)
Write-Host "Building Docker images... This may take 5-10 minutes on first run." -ForegroundColor Cyan
docker compose -f docker-compose.windows.yml build --no-cache

# Start the services in detached mode
Write-Host "Starting services..." -ForegroundColor Cyan
docker compose -f docker-compose.windows.yml up -d

# View the logs to monitor startup
Write-Host "Services started! Showing logs (Ctrl+C to exit logs):" -ForegroundColor Green
docker compose -f docker-compose.windows.yml logs -f
```

---

### Step 8: Verify Deployment

Open a **new PowerShell window** and run:

```powershell
# Check container status
docker compose -f docker-compose.windows.yml ps

# Test API health endpoint
try {
    $response = Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing
    Write-Host "API Health Check: $($response.StatusCode) - OK" -ForegroundColor Green
} catch {
    Write-Host "API Health Check: Failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Web UI
try {
    $response = Invoke-WebRequest -Uri http://localhost:5000 -UseBasicParsing
    Write-Host "Web UI Check: $($response.StatusCode) - OK" -ForegroundColor Green
} catch {
    Write-Host "Web UI Check: Failed - $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## Access Your Services

| Service | Local URL | Remote URL |
|---------|-----------|------------|
| **Web UI** | http://localhost:5000 | http://YOUR-SERVER-IP:5000 |
| **API** | http://localhost:8080 | http://YOUR-SERVER-IP:8080 |
| **Minecraft Server** | localhost:19132 | YOUR-SERVER-IP:19132 |

---

## Quick Reference Commands

### View Logs

```powershell
# All services
docker compose -f docker-compose.windows.yml logs -f

# API only
docker compose -f docker-compose.windows.yml logs -f mcbds-api

# Web UI only
docker compose -f docker-compose.windows.yml logs -f mcbds-clientui-web
```

### Restart Services

```powershell
docker compose -f docker-compose.windows.yml restart
```

### Stop Services

```powershell
docker compose -f docker-compose.windows.yml down
```

### Update Deployment (Pull Latest Code)

```powershell
Set-Location "C:\MCBDSHost\MCBDSHost"

# Pull latest changes
git pull origin master

# Stop services
docker compose -f docker-compose.windows.yml down

# Rebuild and restart
docker compose -f docker-compose.windows.yml build --no-cache
docker compose -f docker-compose.windows.yml up -d
```

---

## Updating Minecraft Bedrock Server

Since the bedrock-server is mounted from the host, you can update it **without rebuilding Docker images**:

```powershell
# Navigate to bedrock-server directory
Set-Location "C:\MCBDSHost\bedrock-server"

# Backup current version
Copy-Item "bedrock_server.exe" "bedrock_server.exe.backup"
Copy-Item "server.properties" "server.properties.backup"

# Download new version (update URL to latest version)
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.50.01.zip"
Invoke-WebRequest -Uri $url -OutFile "bedrock-server-new.zip"

# Extract (overwrites executables but preserves worlds folder)
Expand-Archive -Path "bedrock-server-new.zip" -DestinationPath "." -Force

# Clean up
Remove-Item "bedrock-server-new.zip"

# Restart the API container only (NO rebuild needed!)
Set-Location "C:\MCBDSHost\MCBDSHost"
docker compose -f docker-compose.windows.yml restart mcbds-api

# Watch logs to verify new version started
docker compose -f docker-compose.windows.yml logs -f mcbds-api
```

---

## Troubleshooting

### Docker Desktop Not Starting

```powershell
# Check Windows features are enabled
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Get-WindowsOptionalFeature -Online -FeatureName Containers

# If State is not "Enabled", enable them:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
Restart-Computer
```

### Container Won't Start

```powershell
# Check container logs for errors
docker compose -f docker-compose.windows.yml logs mcbds-api

# Check Docker events
docker events --since 10m
```

### Bedrock Server Won't Start

```powershell
# Verify bedrock_server.exe exists on the HOST
if (Test-Path "C:\MCBDSHost\bedrock-server\bedrock_server.exe") {
    Write-Host "bedrock_server.exe found" -ForegroundColor Green
    (Get-Item "C:\MCBDSHost\bedrock-server\bedrock_server.exe").VersionInfo
} else {
    Write-Host "bedrock_server.exe NOT FOUND - Please download it" -ForegroundColor Red
}
```

### Port Already in Use

```powershell
# Find what's using port 8080
$process = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($process) {
    $proc = Get-Process -Id $process.OwningProcess
    Write-Host "Port 8080 in use by: $($proc.ProcessName) (PID: $($proc.Id))"
}
```

### Reset Everything and Start Fresh

```powershell
Set-Location "C:\MCBDSHost\MCBDSHost"

# Stop and remove all containers and volumes
docker compose -f docker-compose.windows.yml down -v

# Remove images
docker rmi mcbdshost-mcbds-api:latest -f
docker rmi mcbdshost-mcbds-clientui-web:latest -f

# Rebuild from scratch
docker compose -f docker-compose.windows.yml build --no-cache
docker compose -f docker-compose.windows.yml up -d
```

---

## Optional: Configure as Windows Service

To run MCBDSHost automatically on system startup:

### Install NSSM (Non-Sucking Service Manager)

```powershell
# Using Chocolatey (install Chocolatey first if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install NSSM
choco install nssm -y
```

### Create the Service

```powershell
# Create service
nssm install MCBDSHost "C:\Program Files\Docker\Docker\resources\bin\docker-compose.exe"

# Configure service
nssm set MCBDSHost AppDirectory "C:\MCBDSHost\MCBDSHost"
nssm set MCBDSHost AppParameters "-f docker-compose.windows.yml up"
nssm set MCBDSHost DisplayName "MCBDSHost Minecraft Server"
nssm set MCBDSHost Description "Minecraft Bedrock Dedicated Server with Web UI"
nssm set MCBDSHost Start SERVICE_AUTO_START
nssm set MCBDSHost AppExit Default Restart
nssm set MCBDSHost AppRestartDelay 5000

# Start the service
nssm start MCBDSHost

# Verify service status
Get-Service MCBDSHost
```

---

## Directory Structure Summary

After completing installation, your directory structure should be:

```
C:\MCBDSHost\
??? MCBDSHost\                    # Git repository (project files)
?   ??? docker-compose.windows.yml
?   ??? MCBDS.API\
?   ??? MCBDS.ClientUI\
?   ??? ...
?
??? bedrock-server\               # External Minecraft server files
    ??? bedrock_server.exe
    ??? server.properties
    ??? worlds\
    ??? ...
```

**Key Points:**
- `C:\MCBDSHost\MCBDSHost\` - The Git repository with application code
- `C:\MCBDSHost\bedrock-server\` - External Minecraft server files (mounted into container)
- World data is stored in `C:\MCBDSHost\bedrock-server\worlds\`

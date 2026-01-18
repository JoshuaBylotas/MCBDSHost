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

# Create required directories
New-Item -Path "C:\MCBDSHost\certs" -ItemType Directory -Force
New-Item -Path "C:\MCBDSHost\logs" -ItemType Directory -Force
New-Item -Path "C:\MCBDSHost\backups" -ItemType Directory -Force
```

```powershell
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

```powershell
# Create the external bedrock-server directory
New-Item -Path "C:\MCBDSHost\bedrock-server" -ItemType Directory -Force
Set-Location "C:\MCBDSHost\bedrock-server"

# Download the latest Bedrock Server for Windows
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.44.01.zip"
Invoke-WebRequest -Uri $url -OutFile "bedrock-server.zip"

# Extract the zip file
Expand-Archive -Path bedrock-server.zip -DestinationPath . -Force
Remove-Item bedrock-server.zip

# Verify
if (Test-Path "bedrock_server.exe") {
    Write-Host "SUCCESS: bedrock_server.exe found!" -ForegroundColor Green
}

Set-Location "C:\MCBDSHost\MCBDSHost"
```

---

### Step 6: Generate HTTPS Certificate (Required for Web Clients)

```powershell
# Navigate to project directory
Set-Location "C:\MCBDSHost\MCBDSHost"

# Run the certificate generator script
.\generate-https-cert.ps1
```

The script will:
- Ask for your server's IP address
- Generate a self-signed certificate valid for 5 years
- Save it to `C:\MCBDSHost\MCBDSHost\certs\mcbds-api.pfx`

**Copy certificate to deployment location:**
```powershell
Copy-Item ".\certs\mcbds-api.pfx" "C:\MCBDSHost\certs\" -Force
```

---

### Step 7: Configure Windows Firewall

```powershell
# Web UI port
New-NetFirewallRule -DisplayName "MCBDSHost - Web UI" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow

# API HTTP port
New-NetFirewallRule -DisplayName "MCBDSHost - API HTTP" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

# API HTTPS port
New-NetFirewallRule -DisplayName "MCBDSHost - API HTTPS" -Direction Inbound -LocalPort 8081 -Protocol TCP -Action Allow

# Minecraft ports
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv4" -Direction Inbound -LocalPort 19132 -Protocol UDP -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv6" -Direction Inbound -LocalPort 19133 -Protocol UDP -Action Allow

# Verify
Get-NetFirewallRule -DisplayName "MCBDSHost*" | Format-Table DisplayName, Enabled
```

---

### Step 8: Build and Start Docker Services

```powershell
Set-Location "C:\MCBDSHost\MCBDSHost"

# Build the Docker images
Write-Host "Building Docker images..." -ForegroundColor Cyan
docker compose -f docker-compose.windows.yml build --no-cache

# Start the services
Write-Host "Starting services..." -ForegroundColor Cyan
docker compose -f docker-compose.windows.yml up -d

# View logs
docker compose -f docker-compose.windows.yml logs -f
```

---

### Step 9: Verify Deployment

```powershell
# Check container status
docker compose -f docker-compose.windows.yml ps

# Test HTTP API
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing

# Test HTTPS API
Invoke-WebRequest -Uri https://localhost:8081/health -UseBasicParsing -SkipCertificateCheck

# Test Web UI
Invoke-WebRequest -Uri http://localhost:5000 -UseBasicParsing
```

---

## Access Your Services

| Service | Protocol | Local URL | Remote URL |
|---------|----------|-----------|------------|
| **Web UI** | HTTP | http://localhost:5000 | http://YOUR-SERVER-IP:5000 |
| **API** | HTTP | http://localhost:8080 | http://YOUR-SERVER-IP:8080 |
| **API** | HTTPS | https://localhost:8081 | https://YOUR-SERVER-IP:8081 |
| **Minecraft** | UDP | localhost:19132 | YOUR-SERVER-IP:19132 |

### For PublicUI.Web (External Web Client)

When connecting from an HTTPS website (like https://mc-bds.com), use the **HTTPS** API URL:
- `https://YOUR-SERVER-IP:8081`

---

## Quick Reference Commands

```powershell
# View logs
docker compose -f docker-compose.windows.yml logs -f

# Restart services
docker compose -f docker-compose.windows.yml restart

# Stop services
docker compose -f docker-compose.windows.yml down

# Update deployment
git pull origin master
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml build --no-cache
docker compose -f docker-compose.windows.yml up -d
```

---

## Directory Structure

```
C:\MCBDSHost\
??? MCBDSHost\                    # Git repository
?   ??? docker-compose.windows.yml
?   ??? generate-https-cert.ps1
?   ??? certs\                    # Generated certificates
?   ??? ...
??? certs\                        # Deployed certificates
?   ??? mcbds-api.pfx
??? bedrock-server\               # Minecraft server files
?   ??? bedrock_server.exe
?   ??? worlds\
??? logs\                         # API logs
??? backups\                      # World backups
```

---

## Troubleshooting

### Mixed Content Error in Browser

If using PublicUI.Web from an HTTPS site and getting "Mixed Content" errors:
1. Make sure you're using `https://YOUR-SERVER-IP:8081` (not http)
2. Accept the self-signed certificate warning in your browser
3. Verify HTTPS is working: `curl -k https://YOUR-SERVER-IP:8081/health`

### Certificate Not Found

```powershell
# Verify certificate exists
Test-Path "C:\MCBDSHost\certs\mcbds-api.pfx"

# Regenerate if needed
Set-Location "C:\MCBDSHost\MCBDSHost"
.\generate-https-cert.ps1
Copy-Item ".\certs\mcbds-api.pfx" "C:\MCBDSHost\certs\" -Force
docker compose -f docker-compose.windows.yml restart
```

### Container Won't Start

```powershell
docker compose -f docker-compose.windows.yml logs mcbds-api
docker events --since 10m
```

---

*Last Updated: January 2025*

# Windows Server Docker Deployment Guide

## Overview

Deploy MCBDSHost to Windows Server using Docker Desktop for Windows. This guide covers complete setup from a fresh Windows Server installation.

## Prerequisites

- **Windows Server 2019** or newer (or Windows 10/11 Pro)
- **4GB RAM minimum** (8GB+ recommended)
- **Administrator access**
- **Internet connection**

## Step 1: Install Docker Desktop for Windows

### Option A: Using PowerShell (Recommended)

```powershell
# Run PowerShell as Administrator

# Enable Hyper-V and Containers features
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart

# Restart the server
Restart-Computer

# After restart, download and install Docker Desktop
# Download URL: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe

# Or use winget (Windows Package Manager)
winget install -e --id Docker.DockerDesktop
```

### Option B: Manual Installation

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer
3. Follow the installation wizard
4. Restart your computer when prompted
5. Launch Docker Desktop and wait for it to start

### Verify Docker Installation

```powershell
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker is working
docker run hello-world
```

## Step 2: Install Git for Windows

```powershell
# Using winget
winget install -e --id Git.Git

# Or download from: https://git-scm.com/download/win
```

Verify Git installation:
```powershell
git --version
```

## Step 3: Clone the Repository

```powershell
# Create a deployment directory
New-Item -Path "C:\MCBDSHost" -ItemType Directory -Force
Set-Location "C:\MCBDSHost"

# Clone the repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
Set-Location MCBDSHost
```

### GitHub Authentication

If you have a private repository:

```powershell
# You'll be prompted for credentials
# Username: YourGitHubUsername
# Password: Use a Personal Access Token (not your GitHub password)

# Create token at: https://github.com/settings/tokens
# Required scope: repo
```

## Step 4: Download Minecraft Bedrock Server

```powershell
# Navigate to bedrock-server directory
Set-Location "C:\MCBDSHost\MCBDSHost\MCBDS.API\bedrock-server"

# Download the latest Bedrock Server for Windows
# Get the latest version from: https://www.minecraft.net/en-us/download/server/bedrock

# Using PowerShell to download (replace URL with latest version)
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.44.01.zip"
$output = "bedrock-server.zip"
Invoke-WebRequest -Uri $url -OutFile $output

# Extract the zip file
Expand-Archive -Path bedrock-server.zip -DestinationPath . -Force

# Clean up zip file
Remove-Item bedrock-server.zip

# Return to project root
Set-Location "C:\MCBDSHost\MCBDSHost"
```

## Step 5: Configure for Windows Docker

### Update Docker Configuration

Create or update `docker-compose.windows.yml`:

```powershell
# Create Windows-specific docker-compose file
@"
# Docker Compose for Windows Server Deployment
version: '3.8'

services:
  # Minecraft Bedrock Dedicated Server API
  mcbds-api:
    build:
      context: .
      dockerfile: MCBDS.API/Dockerfile.windows
    container_name: mcbds-api
    ports:
      - "8080:8080"       # HTTP API
      - "8081:8081"       # HTTPS API (if configured)
      - "19132:19132/udp" # Minecraft Bedrock IPv4
      - "19133:19133/udp" # Minecraft Bedrock IPv6
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_HTTP_PORTS=8080
      - ASPNETCORE_HTTPS_PORTS=8081
    volumes:
      # Persist world data and server configuration
      - mcbds-worlds:C:/app/Binaries/worlds
      - mcbds-config:C:/app/Binaries
      - mcbds-logs:C:/app/logs
      - mcbds-backups:C:/app/backups
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  # Client Web UI - Blazor Server application
  mcbds-clientui-web:
    build:
      context: .
      dockerfile: MCBDS.ClientUI/MCBDS.ClientUI.Web/Dockerfile
    container_name: mcbds-clientui-web
    ports:
      - "5000:8080"  # Web UI accessible on port 5000
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_HTTP_PORTS=8080
      - ApiSettings__BaseUrl=http://mcbds-api:8080
    depends_on:
      mcbds-api:
        condition: service_healthy
    restart: unless-stopped

volumes:
  mcbds-worlds:
    driver: local
  mcbds-config:
    driver: local
  mcbds-logs:
    driver: local
  mcbds-backups:
    driver: local
"@ | Out-File -FilePath docker-compose.windows.yml -Encoding UTF8
```

### Create Windows-Specific Dockerfile

```powershell
# Create Windows Dockerfile
@"
# Windows Server Docker deployment
FROM mcr.microsoft.com/dotnet/aspnet:10.0-nanoserver-ltsc2022 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
EXPOSE 19132/udp
EXPOSE 19133/udp

FROM mcr.microsoft.com/dotnet/sdk:10.0-nanoserver-ltsc2022 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MCBDS.API/MCBDS.API.csproj", "MCBDS.API/"]
COPY ["MCBDSHost.ServiceDefaults/MCBDSHost.ServiceDefaults.csproj", "MCBDSHost.ServiceDefaults/"]
RUN dotnet restore "./MCBDS.API/MCBDS.API.csproj"
COPY . .
WORKDIR "/src/MCBDS.API"
RUN dotnet build "./MCBDS.API.csproj" -c %BUILD_CONFIGURATION% -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./MCBDS.API.csproj" -c %BUILD_CONFIGURATION% -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app

# Create necessary directories
RUN mkdir C:\\app\\Binaries && mkdir C:\\app\\logs && mkdir C:\\app\\backups

# Copy the Bedrock server files
COPY ["MCBDS.API/bedrock-server/", "C:/app/Binaries/"]

# Copy the published app
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "MCBDS.API.dll"]
"@ | Out-File -FilePath MCBDS.API/Dockerfile.windows -Encoding UTF8
```

### Update appsettings for Windows Paths

The existing `appsettings.Production.json` needs Windows-compatible paths:

```powershell
@"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Runner": {
    "ExePath": "C:\\app\\Binaries\\bedrock_server.exe",
    "LogFilePath": "C:\\app\\logs\\runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\app\\backups",
    "MaxBackupsToKeep": 30
  }
}
"@ | Out-File -FilePath MCBDS.API/appsettings.Production.json -Encoding UTF8 -Force
```

## Step 6: Configure Windows Firewall

```powershell
# Run as Administrator

# Allow Docker traffic
New-NetFirewallRule -DisplayName "MCBDSHost - Web UI" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost - API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv4" -Direction Inbound -LocalPort 19132 -Protocol UDP -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost - Minecraft IPv6" -Direction Inbound -LocalPort 19133 -Protocol UDP -Action Allow

# Verify rules were created
Get-NetFirewallRule -DisplayName "MCBDSHost*"
```

## Step 7: Build and Start Services

```powershell
# Navigate to project directory
Set-Location "C:\MCBDSHost\MCBDSHost"

# Build the Docker images (first time will take several minutes)
docker compose -f docker-compose.windows.yml build --no-cache

# Start the services
docker compose -f docker-compose.windows.yml up -d

# View logs
docker compose -f docker-compose.windows.yml logs -f
```

## Step 8: Verify Deployment

```powershell
# Check container status
docker compose -f docker-compose.windows.yml ps

# Test API endpoint
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing

# Check if Minecraft port is listening
Get-NetUDPEndpoint | Where-Object LocalPort -eq 19132
```

### Access Your Services

- **Web UI**: http://localhost:5000 or http://server-ip:5000
- **API**: http://localhost:8080 or http://server-ip:8080
- **Minecraft Server**: server-ip:19132

## Management Commands

### View Logs

```powershell
# All services
docker compose -f docker-compose.windows.yml logs -f

# Specific service
docker compose -f docker-compose.windows.yml logs -f mcbds-api
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

### Update Deployment

```powershell
Set-Location "C:\MCBDSHost\MCBDSHost"
git pull origin master
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml build --no-cache
docker compose -f docker-compose.windows.yml up -d
```

### Backup World Data

```powershell
# Create backup directory
New-Item -Path "C:\MCBDSHost\Backups" -ItemType Directory -Force

# Backup using Docker
docker run --rm -v mcbdshost-mcbds-worlds:C:/data -v C:/MCBDSHost/Backups:C:/backup mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c "xcopy C:\data C:\backup\worlds-$((Get-Date).ToString('yyyyMMdd-HHmmss'))\ /E /I /H /Y"
```

## Configure as Windows Service (Optional)

To run Docker Compose as a Windows Service:

### Install NSSM (Non-Sucking Service Manager)

```powershell
# Using Chocolatey
choco install nssm -y

# Or download from: https://nssm.cc/download
```

### Create Service

```powershell
# Create service
nssm install MCBDSHost "C:\Program Files\Docker\Docker\resources\bin\docker-compose.exe"

# Set service parameters
nssm set MCBDSHost AppDirectory "C:\MCBDSHost\MCBDSHost"
nssm set MCBDSHost AppParameters "-f docker-compose.windows.yml up"
nssm set MCBDSHost DisplayName "MCBDSHost Minecraft Server"
nssm set MCBDSHost Description "Minecraft Bedrock Dedicated Server with Web UI"
nssm set MCBDSHost Start SERVICE_AUTO_START

# Set service to restart on failure
nssm set MCBDSHost AppExit Default Restart
nssm set MCBDSHost AppRestartDelay 5000

# Start the service
nssm start MCBDSHost

# Check service status
nssm status MCBDSHost
```

### Manage Service

```powershell
# Start service
Start-Service MCBDSHost

# Stop service
Stop-Service MCBDSHost

# Restart service
Restart-Service MCBDSHost

# Check status
Get-Service MCBDSHost
```

## Troubleshooting

### Docker Desktop Not Starting

```powershell
# Check Windows features
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Get-WindowsOptionalFeature -Online -FeatureName Containers

# Enable if needed
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
Restart-Computer
```

### Container Won't Start

```powershell
# Check container logs
docker compose -f docker-compose.windows.yml logs mcbds-api

# Check Docker logs
Get-EventLog -LogName Application -Source Docker -Newest 50
```

### Port Already in Use

```powershell
# Find process using port
Get-NetTCPConnection -LocalPort 8080 | Select-Object OwningProcess
Get-Process -Id <ProcessId>

# Kill process if needed
Stop-Process -Id <ProcessId> -Force
```

### Bedrock Server Won't Start

```powershell
# Check if bedrock_server.exe exists
Test-Path "C:\MCBDSHost\MCBDSHost\MCBDS.API\bedrock-server\bedrock_server.exe"

# Verify it's the Windows version (not Linux)
(Get-Item "C:\MCBDSHost\MCBDSHost\MCBDS.API\bedrock-server\bedrock_server.exe").VersionInfo
```

### Reset Everything

```powershell
# Stop and remove all containers and volumes
docker compose -f docker-compose.windows.yml down -v

# Remove images
docker rmi mcbdshost-mcbds-api:latest
docker rmi mcbdshost-mcbds-clientui-web:latest

# Rebuild
docker compose -f docker-compose.windows.yml build --no-cache
docker compose -f docker-compose.windows.yml up -d
```

## Performance Optimization

### Increase Docker Resources

1. Open Docker Desktop
2. Go to Settings ? Resources
3. Increase CPU and Memory allocation:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 4GB minimum, 8GB+ recommended
4. Click "Apply & Restart"

### Windows Server Optimization

```powershell
# Disable unnecessary services
Set-Service -Name "Themes" -StartupType Disabled
Set-Service -Name "Windows Search" -StartupType Disabled

# Optimize power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable Windows Defender real-time scanning (if security policy allows)
Set-MpPreference -DisableRealtimeMonitoring $true
```

## Security Best Practices

### Enable HTTPS

```powershell
# Generate self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "yourdomain.com" -CertStoreLocation "Cert:\LocalMachine\My"

# Export certificate
$certPath = "C:\MCBDSHost\certificate.pfx"
$certPassword = ConvertTo-SecureString -String "YourSecurePassword" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPassword

# Update docker-compose to use certificate
# Add to mcbds-api environment:
# - ASPNETCORE_Kestrel__Certificates__Default__Path=/app/certificate.pfx
# - ASPNETCORE_Kestrel__Certificates__Default__Password=YourSecurePassword
```

### Restrict Network Access

```powershell
# Allow only specific IP ranges
New-NetFirewallRule -DisplayName "MCBDSHost - Restricted Access" `
  -Direction Inbound -LocalPort 5000,8080 -Protocol TCP -Action Allow `
  -RemoteAddress "192.168.1.0/24"
```

## Monitoring

### View Resource Usage

```powershell
# Container stats
docker stats

# Detailed container info
docker compose -f docker-compose.windows.yml ps -a
docker inspect mcbds-api
```

### Setup Logging

```powershell
# Configure Docker logging driver
# Edit C:\ProgramData\Docker\config\daemon.json
@"
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
"@ | Out-File -FilePath "C:\ProgramData\Docker\config\daemon.json" -Encoding UTF8

# Restart Docker
Restart-Service docker
```

## Backup and Restore

### Automated Backup Script

```powershell
# Save as C:\MCBDSHost\backup-script.ps1
$backupDir = "C:\MCBDSHost\Backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Create backup directory
New-Item -Path "$backupDir\$timestamp" -ItemType Directory -Force

# Backup volumes
docker run --rm `
  -v mcbdshost-mcbds-worlds:C:/source/worlds `
  -v mcbdshost-mcbds-config:C:/source/config `
  -v "$backupDir\${timestamp}:C:/backup" `
  mcr.microsoft.com/windows/nanoserver:ltsc2022 `
  cmd /c "xcopy C:\source C:\backup\ /E /I /H /Y"

Write-Host "Backup completed: $backupDir\$timestamp"
```

### Schedule Automated Backups

```powershell
# Create scheduled task for daily backups
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-File C:\MCBDSHost\backup-script.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "MCBDSHost Daily Backup" `
  -Action $action -Trigger $trigger -Principal $principal `
  -Description "Daily backup of MCBDSHost worlds and configuration"
```

## Updating Minecraft Server

```powershell
# Download new version
Set-Location "C:\MCBDSHost\MCBDSHost\MCBDS.API\bedrock-server"

# Backup current version
Copy-Item "bedrock_server.exe" "bedrock_server.exe.backup"

# Download new version
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.50.01.zip"
Invoke-WebRequest -Uri $url -OutFile "bedrock-server-new.zip"

# Extract
Expand-Archive -Path "bedrock-server-new.zip" -DestinationPath "." -Force

# Restart services
Set-Location "C:\MCBDSHost\MCBDSHost"
docker compose -f docker-compose.windows.yml restart mcbds-api
```

## Additional Resources

- **Docker Desktop Documentation**: https://docs.docker.com/desktop/windows/
- **Windows Server Container Documentation**: https://docs.microsoft.com/en-us/virtualization/windowscontainers/
- **Minecraft Bedrock Server**: https://www.minecraft.net/en-us/download/server/bedrock
- **Project Repository**: https://github.com/JoshuaBylotas/MCBDSHost

## Support

For issues specific to:
- **Windows Server deployment**: Check Event Viewer (Application and Container logs)
- **Docker issues**: Check Docker Desktop logs in `%LOCALAPPDATA%\Docker\log`
- **Application issues**: Check container logs with `docker compose logs`

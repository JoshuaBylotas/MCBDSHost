# MCBDS Manager - Custom Volume Configuration Guide

This guide explains how to configure custom drive locations for MCBDS Manager Docker volumes.

## Overview

By default, MCBDS Manager stores all data in `C:\MCBDSManager\`. However, you may want to:
- Store game files on a fast SSD (D:\ drive)
- Store backups on a large HDD (E:\ drive)
- Organize data across multiple drives
- Use a specific drive with more space

The **Configure-MCBDSVolumes.ps1** script also validates your `docker-compose.windows.yml` configuration and checks for:
- ? Required port mappings (8080, 8081, 19132, 19133)
- ? HTTPS certificate configuration
- ? Container health checks
- ? Restart policies
- ? Windows container isolation settings

## Quick Start

### Interactive Configuration (Recommended)

```powershell
# Navigate to your MCBDSHost directory
cd C:\MCBDSManager

# Run the configuration script
.\Configure-MCBDSVolumes.ps1
```

The script will:
1. ? Validate docker-compose.windows.yml for missing settings
2. ? Prompt you for custom paths (5 locations)
3. ? Validate drive availability
4. ? Create directories
5. ? Update `docker-compose.windows.yml`
6. ? Backup original configuration (with timestamp)
7. ? Apply configuration fixes if needed
8. ? Provide next steps with commands

## What Gets Configured

### 1. Bedrock Server Location
**Default:** `C:\MCBDSManager\bedrock-server`

This directory contains:
- `bedrock_server.exe` - The Minecraft server executable
- `worlds/` - World saves
- `server.properties` - Server configuration
- `allowlist.json`, `permissions.json` - Player permissions

**Example custom paths:**
- `D:\Minecraft\bedrock-server` - Fast SSD for performance
- `E:\Games\minecraft-server` - Dedicated games drive

### 2. Backup Storage
**Default:** `C:\MCBDSManager\backups`

This directory contains:
- Automated world backups (ZIP files)
- Timestamped backup archives
- Can grow large over time

**Example custom paths:**
- `E:\Backups\minecraft` - Large HDD with lots of space
- `F:\Archives\mcbds` - Network attached storage (NAS)

### 3. Configuration Files
**Default:** `C:\MCBDSManager\config`

This directory contains:
- MCBDS Manager settings
- Backup configuration
- Application state

**Example custom paths:**
- `C:\MCBDSManager\config` - Keep on system drive
- `D:\Config\mcbds` - With other application configs

### 4. HTTPS Certificates ? NEW
**Default:** `C:\MCBDSManager\certs`

This directory contains:
- `mcbds-api.pfx` - HTTPS certificate for secure API
- Certificate password configuration

**Example custom paths:**
- `C:\MCBDSManager\certs` - Keep secure on system drive
- `D:\Security\certs` - Dedicated security folder

### 5. Log Files ? NEW
**Default:** `C:\MCBDSManager\logs`

This directory contains:
- API logs
- Server logs
- Debug information
- Error traces

**Example custom paths:**
- `C:\MCBDSManager\logs` - Local for fast access
- `E:\Logs\mcbds` - Separate drive for log analysis

## Configuration Validation ? NEW

The script now validates your `docker-compose.windows.yml` for:

### Required Port Mappings
```yaml
ports:
  - "8080:8080"       # HTTP API
  - "8081:8081"       # HTTPS API (Required for web clients)
  - "19132:19132/udp" # Minecraft IPv4
  - "19133:19133/udp" # Minecraft IPv6
```

### HTTPS Configuration
```yaml
environment:
  - ASPNETCORE_URLS=https://+:8081;http://+:8080
  - ASPNETCORE_Kestrel__Certificates__Default__Path=C:/https/mcbds-api.pfx
  - ASPNETCORE_Kestrel__Certificates__Default__Password=McbdsApiCert123!
```

### Health Check
```yaml
healthcheck:
  test: ["CMD", "powershell", "-Command", "try { Invoke-WebRequest -Uri https://localhost:8081/health -UseBasicParsing -SkipCertificateCheck; exit 0 } catch { exit 1 }"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Container Settings
```yaml
restart: unless-stopped
isolation: process
```

## Using the Script

### Interactive Mode

```powershell
PS C:\MCBDSManager> .\Configure-MCBDSVolumes.ps1

========================================
  MCBDS Manager - Volume Configuration
========================================

This script will help you configure custom drive locations for:
  1. Bedrock Server files
  2. Backup storage
  3. Configuration files
  4. HTTPS certificates
  5. Log files

It will also verify your docker-compose.windows.yml configuration.

Validating docker-compose.windows.yml...

Configuration issues detected:
  - Missing HTTPS port mapping (8081:8081)
  - Missing HTTPS certificate path configuration
  - Missing container healthcheck configuration

Location for Minecraft Bedrock Dedicated Server files
Default: C:\MCBDSManager\bedrock-server
Bedrock Server Location (press Enter for default): D:\Minecraft\bedrock-server

Location for automated world backups
Default: C:\MCBDSManager\backups
Backup Storage Location (press Enter for default): E:\Backups\minecraft

Location for MCBDS Manager configuration files
Default: C:\MCBDSManager\config
Configuration Location (press Enter for default): 

Location for HTTPS certificates
Default: C:\MCBDSManager\certs
HTTPS Certificates Location (press Enter for default):

Location for API and server logs
Default: C:\MCBDSManager\logs
Logs Location (press Enter for default): E:\Logs\mcbds

========================================
  Configuration Summary
========================================

Bedrock Server: D:\Minecraft\bedrock-server
Backups:        E:\Backups\minecraft
Configuration:  C:\MCBDSManager\config
Certificates:   C:\MCBDSManager\certs
Logs:           E:\Logs\mcbds

Docker Compose Issues: 3 found

Apply these settings? (Y/N): Y

Creating directories...
  Created: D:\Minecraft\bedrock-server
  Created: E:\Backups\minecraft
  Exists: C:\MCBDSManager\config
  Exists: C:\MCBDSManager\certs
  Created: E:\Logs\mcbds

Original configuration backed up to: docker-compose.windows.yml.backup
Timestamped backup created: docker-compose.windows.yml.backup.20250107-143022

Applying configuration fixes...
  Fixing: Missing HTTPS port mapping (8081:8081)
  Fixing: Missing HTTPS certificate path configuration
  Fixing: Missing container healthcheck configuration

========================================
  Configuration Complete!
========================================

Your docker-compose.windows.yml has been updated with custom paths.

Configuration improvements applied:
  ? Fixed: Missing HTTPS port mapping (8081:8081)
  ? Fixed: Missing HTTPS certificate path configuration
  ? Fixed: Missing container healthcheck configuration

Next Steps:
  1. Generate HTTPS certificate (if not exists):
     .\generate-https-cert.ps1
     Copy-Item .\certs\mcbds-api.pfx C:\MCBDSManager\certs\ -Force

  2. Download Minecraft Bedrock Server to: D:\Minecraft\bedrock-server

  3. Verify VC++ Redistributable is installed:
     https://aka.ms/vs/17/release/vc_redist.x64.exe

  4. Start Docker containers:
     docker compose -f docker-compose.windows.yml build
     docker compose -f docker-compose.windows.yml up -d

  5. Test services:
     HTTP API:  http://localhost:8080/health
     HTTPS API: https://localhost:8081/health
     Minecraft: localhost:19132

To restore original configuration:
  Copy-Item docker-compose.windows.yml.backup docker-compose.windows.yml -Force

Backups available:
  Latest: docker-compose.windows.yml.backup
  Timestamped: docker-compose.windows.yml.backup.20250107-143022
```

## Prerequisites ? UPDATED

Before running the script, ensure you have:

1. **Docker Desktop** installed and running
2. **Windows Container mode** enabled
3. **VC++ Redistributable** (x64) installed
   - Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
   - Required for Minecraft Bedrock Server
4. **PowerShell 5.1+** (comes with Windows)
5. **Administrator privileges** (for Docker operations)

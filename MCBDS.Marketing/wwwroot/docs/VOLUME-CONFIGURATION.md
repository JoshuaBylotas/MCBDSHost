# MCBDS Manager - Custom Volume Configuration Guide

This guide explains how to configure custom drive locations for MCBDS Manager Docker volumes.

## Overview

By default, MCBDS Manager stores all data in `C:\MCBDSManager\`. However, you may want to:
- Store game files on a fast SSD (D:\ drive)
- Store backups on a large HDD (E:\ drive)
- Organize data across multiple drives
- Use a specific drive with more space

## Quick Start

### Interactive Configuration (Recommended)

```powershell
# Navigate to your MCBDSHost directory
cd C:\MCBDSManager

# Run the configuration script
.\Configure-MCBDSVolumes.ps1
```

The script will:
1. ? Prompt you for custom paths
2. ? Validate drive availability
3. ? Create directories
4. ? Update `docker-compose.windows.yml`
5. ? Backup original configuration

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

Location for Minecraft Bedrock Dedicated Server files
Default: C:\MCBDSManager\bedrock-server
Bedrock Server Location (press Enter for default): D:\Minecraft\bedrock-server

Location for automated world backups
Default: C:\MCBDSManager\backups
Backup Storage Location (press Enter for default): E:\Backups\minecraft

Location for MCBDS Manager configuration files
Default: C:\MCBDSManager\config
Configuration Location (press Enter for default): 

========================================
  Configuration Summary
========================================

Bedrock Server: D:\Minecraft\bedrock-server
Backups:        E:\Backups\minecraft
Configuration:  C:\MCBDSManager\config

Apply these settings? (Y/N): Y

Creating directories...
  Created: D:\Minecraft\bedrock-server
  Created: E:\Backups\minecraft
  Exists: C:\MCBDSManager\config

Original configuration backed up to: docker-compose.windows.yml.backup

========================================
  Configuration Complete!
========================================

Your docker-compose.windows.yml has been updated with custom paths.

Next Steps:
  1. Download Minecraft Bedrock Server to: D:\Minecraft\bedrock-server
  2. Run: docker compose -f docker-compose.windows.yml up -d
```

## Manual Configuration

If you prefer to configure manually, edit `docker-compose.windows.yml`:

### Before (Default)
```yaml
services:
  mcbds-api:
    volumes:
      - C:\MCBDSManager\bedrock-server:/bedrock
      - C:\MCBDSManager\backups:/app/backups
      - C:\MCBDSManager\config:/app/config
```

### After (Custom Paths)
```yaml
services:
  mcbds-api:
    volumes:
      - D:\Minecraft\bedrock-server:/bedrock
      - E:\Backups\minecraft:/app/backups
      - C:\MCBDSManager\config:/app/config
```

## Common Configurations

### Configuration 1: Fast SSD + Large HDD
```
D:\ (SSD 256GB)    ? Bedrock Server (needs speed)
E:\ (HDD 2TB)      ? Backups (needs space)
C:\ (SSD)          ? Configuration (small files)
```

```powershell
# In Configure-MCBDSVolumes.ps1:
Bedrock Server Location: D:\Minecraft\bedrock-server
Backup Storage Location: E:\Backups\minecraft
Configuration Location: C:\MCBDSManager\config
```

### Configuration 2: All on One Drive
```
D:\ (SSD 1TB) ? Everything
```

```powershell
# In Configure-MCBDSVolumes.ps1:
Bedrock Server Location: D:\MCBDSManager\bedrock-server
Backup Storage Location: D:\MCBDSManager\backups
Configuration Location: D:\MCBDSManager\config
```

### Configuration 3: Network Storage
```
C:\ (SSD)       ? Bedrock Server (local performance)
\\NAS\Share\    ? Backups (remote storage)
C:\ (SSD)       ? Configuration
```

```powershell
# In Configure-MCBDSVolumes.ps1:
Bedrock Server Location: C:\MCBDSManager\bedrock-server
Backup Storage Location: \\NAS\Backups\minecraft
Configuration Location: C:\MCBDSManager\config
```

## Validation

The script validates:
- ? Drive exists and is accessible
- ? You have permission to create directories
- ? Invalid drive letters are rejected
- ? Network paths are warned (may have issues)

## Best Practices

### Drive Selection

? **Good Choices:**
- Local fixed drives (C:\, D:\, E:\)
- SSDs for Bedrock Server (performance)
- Large HDDs for backups (space)

? **Avoid:**
- Removable USB drives (may disconnect)
- Mapped network drives (performance issues)
- Cloud synced folders (conflicts with Docker)

### Space Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Bedrock Server | 2GB | 10GB |
| Backups | 5GB | 50GB+ |
| Configuration | 100MB | 500MB |

### Performance Tips

1. **Use SSD for Bedrock Server** - Reduces world loading time
2. **Use HDD for Backups** - Backups don't need speed
3. **Keep Config on C:\ Drive** - Small and rarely accessed

## Troubleshooting

### Script Errors

**Error: "docker-compose.windows.yml not found"**
```powershell
# Make sure you're in the correct directory
cd C:\MCBDSManager
# Or wherever you cloned MCBDSHost
```

**Error: "Drive X: does not exist"**
```powershell
# Check available drives
Get-PSDrive -PSProvider FileSystem

# The script will use default path instead
```

### Docker Issues

**Error: "invalid mount config"**
```yaml
# Make sure paths don't have trailing slashes
? volumes:
  - D:\Minecraft\bedrock-server:/bedrock

? volumes:
  - D:\Minecraft\bedrock-server\:/bedrock  # Don't add trailing \
```

**Error: "Path not found"**
```powershell
# Make sure directories exist before starting Docker
New-Item -Path "D:\Minecraft\bedrock-server" -ItemType Directory -Force
```

### Permissions

Run PowerShell as Administrator if you get permission errors:
```powershell
# Right-click PowerShell ? Run as Administrator
cd C:\MCBDSManager
.\Configure-MCBDSVolumes.ps1
```

## Restoring Defaults

To revert to default paths:

```powershell
# If backup exists:
Copy-Item docker-compose.windows.yml.backup docker-compose.windows.yml -Force

# Or re-clone from GitHub:
git checkout docker-compose.windows.yml
```

## Moving Existing Data

If you already have data and want to move it:

```powershell
# Stop containers
docker compose -f docker-compose.windows.yml down

# Move data to new location
Move-Item -Path "C:\MCBDSManager\bedrock-server\*" -Destination "D:\Minecraft\bedrock-server\" -Force
Move-Item -Path "C:\MCBDSManager\backups\*" -Destination "E:\Backups\minecraft\" -Force

# Update configuration
.\Configure-MCBDSVolumes.ps1

# Start containers with new paths
docker compose -f docker-compose.windows.yml up -d
```

## Script Source Code

The script is located at: `Configure-MCBDSVolumes.ps1`

You can also download it directly:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JoshuaBylotas/MCBDSHost/master/Configure-MCBDSVolumes.ps1" -OutFile "Configure-MCBDSVolumes.ps1"
```

## Advanced: Environment Variables

For automation, set environment variables:

```powershell
$env:MCBDS_BEDROCK_PATH = "D:\Minecraft\bedrock-server"
$env:MCBDS_BACKUP_PATH = "E:\Backups\minecraft"
$env:MCBDS_CONFIG_PATH = "C:\MCBDSManager\config"

# Then run script (it could be modified to read these)
```

## Support

For issues with volume configuration:
- Check this guide's troubleshooting section
- Verify Docker is running: `docker --version`
- Check disk space: `Get-PSDrive`
- Visit: https://www.mc-bds.com/get-started

---

**Last Updated:** January 7, 2025  
**Script Version:** 1.0  
**Compatible With:** MCBDS Manager 1.0+

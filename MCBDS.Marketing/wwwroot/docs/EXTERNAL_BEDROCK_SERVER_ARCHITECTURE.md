# Bedrock Server External Volume Architecture

## Overview

The Minecraft Bedrock Server files are now stored **outside** the Docker container on the host filesystem and mounted as a volume. This eliminates the need to rebuild Docker images when updating the Minecraft server.

## Directory Structure

### Windows
```
C:\MCBDSHost\
??? bedrock-server\          # ? Bedrock server files (MOUNTED INTO CONTAINER)
?   ??? bedrock_server.exe
?   ??? server.properties
?   ??? permissions.json
?   ??? allowlist.json
?   ??? worlds\              # Minecraft worlds (also mounted separately)
??? MCBDSHost\               # ? Git repository (application code)
    ??? MCBDS.API\
    ??? docker-compose.windows.yml
    ??? ...
```

### Linux
```
/opt/mcbdshost/
??? bedrock-server/          # ? Bedrock server files (MOUNTED INTO CONTAINER)
    ??? bedrock_server
    ??? server.properties
    ??? permissions.json
    ??? allowlist.json
    ??? worlds/              # Minecraft worlds (also mounted separately)

~/MCBDSHost/                 # ? Git repository (application code)
??? MCBDS.API/
??? docker-compose.yml
??? ...
```

## Volume Mounts

### Windows (`docker-compose.windows.yml`)
```yaml
volumes:
  - C:/MCBDSHost/bedrock-server:C:/app/Binaries  # Server executable & config
  - mcbds-worlds:C:/app/Binaries/worlds          # World data (Docker volume)
  - mcbds-logs:C:/app/logs                        # Logs (Docker volume)
  - mcbds-backups:C:/app/backups                  # Backups (Docker volume)
```

### Linux (`docker-compose.yml`)
```yaml
volumes:
  - /opt/mcbdshost/bedrock-server:/app/Binaries  # Server executable & config
  - mcbds-worlds:/app/Binaries/worlds            # World data (Docker volume)
  - mcbds-logs:/app/logs                          # Logs (Docker volume)
  - mcbds-backups:/app/backups                    # Backups (Docker volume)
```

## Benefits

### 1. **No Rebuild Required for Updates**
Previously:
```powershell
# OLD WAY (slow)
docker compose down
# Download new server
docker compose build --no-cache  # ? 5-10 minutes
docker compose up -d
```

Now:
```powershell
# NEW WAY (fast)
cd C:\MCBDSHost\bedrock-server
# Download and extract new server files
cd C:\MCBDSHost\MCBDSHost
docker compose -f docker-compose.windows.yml restart mcbds-api  # ? 10 seconds!
```

### 2. **Easier Server Configuration**
Edit server files directly on the host:
```powershell
# Windows
notepad C:\MCBDSHost\bedrock-server\server.properties

# Linux
sudo nano /opt/mcbdshost/bedrock-server/server.properties

# Restart container to apply changes
docker compose restart mcbds-api
```

### 3. **Direct Access to Server Files**
- Backup/restore is easier
- Can edit allowlist.json, permissions.json directly
- Can inspect logs without `docker exec`

### 4. **Smaller Docker Images**
- Bedrock server files (~200MB) not in image
- Faster image pulls/pushes
- Less storage used

## Initial Setup

### Windows
```powershell
# 1. Create bedrock-server directory
New-Item -Path "C:\MCBDSHost\bedrock-server" -ItemType Directory -Force
cd C:\MCBDSHost\bedrock-server

# 2. Download Bedrock Server
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.44.01.zip"
Invoke-WebRequest -Uri $url -OutFile "bedrock-server.zip"
Expand-Archive -Path bedrock-server.zip -DestinationPath . -Force
Remove-Item bedrock-server.zip

# 3. Start Docker containers
cd C:\MCBDSHost\MCBDSHost
docker compose -f docker-compose.windows.yml up --build -d
```

### Linux
```bash
# 1. Create bedrock-server directory
sudo mkdir -p /opt/mcbdshost/bedrock-server
cd /opt/mcbdshost/bedrock-server

# 2. Download Bedrock Server
sudo wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.44.01.zip
sudo unzip bedrock-server-*.zip
sudo chmod +x bedrock_server
sudo rm bedrock-server-*.zip

# 3. Start Docker containers
cd ~/MCBDSHost
docker compose up --build -d
```

## Updating Minecraft Server

### Windows
```powershell
cd C:\MCBDSHost\bedrock-server

# Backup current version
Copy-Item "bedrock_server.exe" "bedrock_server.exe.backup"

# Download new version
$url = "https://minecraft.azureedge.net/bin-win/bedrock-server-1.21.50.01.zip"
Invoke-WebRequest -Uri $url -OutFile "update.zip"
Expand-Archive -Path update.zip -DestinationPath . -Force
Remove-Item update.zip

# Restart container (NO REBUILD!)
cd C:\MCBDSHost\MCBDSHost
docker compose -f docker-compose.windows.yml restart mcbds-api
```

### Linux
```bash
cd /opt/mcbdshost/bedrock-server

# Backup current version
sudo cp bedrock_server bedrock_server.backup

# Download new version
sudo wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.50.01.zip -O update.zip
sudo unzip -o update.zip
sudo chmod +x bedrock_server
sudo rm update.zip

# Restart container (NO REBUILD!)
cd ~/MCBDSHost
docker compose restart mcbds-api
```

## Migration from Old Architecture

If you have an existing deployment with bedrock-server inside the Docker image:

### Windows
```powershell
# 1. Stop containers
docker compose -f docker-compose.windows.yml down

# 2. Create external directory and download server
New-Item -Path "C:\MCBDSHost\bedrock-server" -ItemType Directory -Force
cd C:\MCBDSHost\bedrock-server
# Download as shown in Initial Setup

# 3. Copy world data from old volume (if exists)
docker run --rm -v mcbdshost-mcbds-worlds:C:/source -v C:/MCBDSHost/bedrock-server/worlds:C:/dest mcr.microsoft.com/windows/nanoserver cmd /c "xcopy C:\source C:\dest /E /I /H /Y"

# 4. Pull latest code with volume mounts
cd C:\MCBDSHost\MCBDSHost
git pull origin master

# 5. Rebuild and start
docker compose -f docker-compose.windows.yml up --build -d
```

### Linux
```bash
# 1. Stop containers
docker compose down

# 2. Create external directory and download server
sudo mkdir -p /opt/mcbdshost/bedrock-server
cd /opt/mcbdshost/bedrock-server
# Download as shown in Initial Setup

# 3. Copy world data from old volume (if exists)
docker run --rm -v mcbdshost-mcbds-worlds:/source -v /opt/mcbdshost/bedrock-server/worlds:/dest alpine sh -c "cp -a /source/* /dest/"

# 4. Pull latest code with volume mounts
cd ~/MCBDSHost
git pull origin master

# 5. Rebuild and start
docker compose up --build -d
```

## Troubleshooting

### "Cannot find bedrock_server.exe"

**Cause:** The external directory doesn't exist or doesn't have the server files.

**Fix:**
```powershell
# Windows
Test-Path "C:\MCBDSHost\bedrock-server\bedrock_server.exe"
# If False, download the server as shown in Initial Setup

# Linux
ls -la /opt/mcbdshost/bedrock-server/bedrock_server
# If not found, download the server as shown in Initial Setup
```

### "Permission denied"

**Cause:** (Linux only) The container user can't read the mounted directory.

**Fix:**
```bash
sudo chown -R 1000:1000 /opt/mcbdshost/bedrock-server
sudo chmod -R 755 /opt/mcbdshost/bedrock-server
```

### Worlds not persisting

**Cause:** Worlds are in a separate Docker volume, not in bedrock-server directory.

**Explanation:** This is intentional! Worlds are kept in a Docker-managed volume (`mcbds-worlds`) for better performance and easier backups. The server executable and config are in the mounted directory, but worlds are separate.

To backup worlds:
```powershell
# Windows
docker run --rm -v mcbdshost-mcbds-worlds:C:/data -v C:/Backups:C:/backup mcr.microsoft.com/windows/nanoserver cmd /c "xcopy C:\data C:\backup\worlds-%date% /E /I /H /Y"

# Linux
docker run --rm -v mcbdshost-mcbds-worlds:/data -v ~/backups:/backup alpine tar czf /backup/worlds-$(date +%Y%m%d).tar.gz -C /data .
```

## Performance Considerations

### Docker Volume vs Host Mount
- **Docker volumes** (`mcbds-worlds`) are optimized by Docker and perform better for high I/O operations like world saving
- **Host mounts** (`bedrock-server`) are fine for executables and config files that are read once at startup

This hybrid approach gives the best of both worlds:
- Fast world I/O through Docker volumes
- Easy maintenance through host-mounted executables

## Backup Strategy

### Full Backup
```powershell
# Windows
$backup = "C:\Backups\mcbds-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -Path $backup -ItemType Directory

# Backup server config
Copy-Item -Path "C:\MCBDSHost\bedrock-server\*" -Destination "$backup\server" -Recurse -Exclude worlds

# Backup worlds (from Docker volume)
docker run --rm -v mcbdshost-mcbds-worlds:C:/data -v "$backup\worlds:C:/backup" mcr.microsoft.com/windows/nanoserver cmd /c "xcopy C:\data C:\backup /E /I /H /Y"
```

```bash
# Linux
backup="/backups/mcbds-$(date +%Y%m%d-%H%M%S)"
mkdir -p $backup

# Backup server config
cp -r /opt/mcbdshost/bedrock-server/* $backup/server/ --exclude=worlds

# Backup worlds (from Docker volume)
docker run --rm -v mcbdshost-mcbds-worlds:/data -v $backup/worlds:/backup alpine sh -c "cp -a /data/* /backup/"
```

## Summary

The new architecture separates concerns:
- **Application code** ? Git repository
- **Server executable & config** ? Host-mounted directory (easy updates)
- **World data** ? Docker volume (best performance)
- **Logs & backups** ? Docker volumes (persistent, easy to manage)

This design makes it **easier to update** Minecraft versions while keeping **good performance** for world data.

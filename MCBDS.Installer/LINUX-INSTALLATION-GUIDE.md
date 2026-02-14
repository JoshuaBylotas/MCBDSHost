# MCBDS API Linux Installation Guide

Complete guide for installing MCBDS Manager API on Ubuntu Linux (fresh installation).

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [System Preparation](#system-preparation)
3. [Install .NET 10 Runtime](#install-net-10-runtime)
4. [Deploy MCBDS API](#deploy-mcbds-api)
5. [Install Minecraft Bedrock Server](#install-minecraft-bedrock-server)
6. [Configure systemd Service](#configure-systemd-service)
7. [Firewall Configuration](#firewall-configuration)
8. [SSL/HTTPS Setup (Optional)](#sslhttps-setup-optional)
9. [Backup Configuration](#backup-configuration)
10. [Verification & Testing](#verification--testing)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### User Account Requirements
- **Admin/sudo access required** for initial setup and system configuration
- Commands will be marked with the required user context:
  - `sudo` commands - Run as your admin user
  - `sudo su - mcbds` - Commands run as the mcbds service user
- The guide will indicate when to switch between users

### Supported Ubuntu Versions
- Ubuntu 22.04 LTS (recommended)
- Ubuntu 24.04 LTS
- Ubuntu 20.04 LTS (minimum)

### Hardware Requirements
- **CPU**: 2+ cores (4+ recommended for multiple players)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 5GB+ free space
- **Network**: Static IP or DDNS (for external access)

### Required Ports
- **8080** - HTTP API Endpoints
- **8081** - HTTPS API Endpoints (optional)
- **19132/UDP** - Minecraft Bedrock IPv4
- **19133/UDP** - Minecraft Bedrock IPv6

### Important Notes
- **This is an API-only installation** - No web dashboard UI is included
- **Management Options**:
  - REST API calls (curl, Postman, scripts)
  - MAUI mobile app (Android/iOS) connecting to API
  - Web UI available separately (future package)

---

## System Preparation

### 1. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Essential Tools
```bash
sudo apt install -y curl wget unzip vim systemd ufw
```

### 3. Create Service User (recommended for security)
```bash
# Create dedicated user for MCBDS service
sudo useradd -r -m -d /opt/mcbds -s /bin/bash mcbds

# Set password (optional, for SSH access)
# sudo passwd mcbds
```

---

## Install .NET 10 Runtime

### Ubuntu 22.04/24.04
```bash
# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET 10 ASP.NET Core Runtime
sudo apt update
sudo apt install -y aspnetcore-runtime-10.0

# Verify installation
dotnet --list-runtimes
```

**Expected Output:**
```
Microsoft.AspNetCore.App 10.0.x [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
Microsoft.NETCore.App 10.0.x [/usr/share/dotnet/shared/Microsoft.NETCore.App]
```

---

## Deploy MCBDS API

### Download and Install API Package

#### 1. Download Latest Release
```bash
# Switch to service user
sudo su - mcbds

# Create directory structure
mkdir -p /opt/mcbds/{api,binaries,backups,logs}
cd /opt/mcbds/api

# Download release package
wget https://www.mc-bds.com/downloads/mcbds-api-linux-x64-v1.1.51.zip -O mcbds-api.zip

# Extract package
unzip mcbds-api.zip
rm mcbds-api.zip
```

#### 2. Make Executable
```bash
# Still as mcbds user
chmod +x /opt/mcbds/api/MCBDS.API

# Exit back to admin user for next steps
exit
```

> **Note**: Download the latest Linux package from [mc-bds.com/linux-installation](https://www.mc-bds.com/linux-installation) or check the [releases page](https://github.com/JoshuaBylotas/MCBDSHost/releases).

---

## Install Minecraft Bedrock Server

### 1. Install Required Dependencies (as admin)
```bash
# Exit from mcbds user if currently logged in
exit

# Run as admin/sudo user
sudo apt install -y libcurl4 openssl libc6 libstdc++6
```

### 2. Download Bedrock Server (as mcbds user)

**Option A: Automatic Download (Recommended)**
```bash
# Switch to service user
sudo su - mcbds
cd /opt/mcbds/binaries

# Get latest download URL from Minecraft.net
# Visit https://www.minecraft.net/en-us/download/server/bedrock
# Right-click "Download" button ? Copy link address ? Use below

# Example (replace with current version URL):
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-VERSION.zip

# Extract
unzip bedrock-server-*.zip
rm bedrock-server-*.zip
```

**Option B: Manual Download**
1. Visit https://www.minecraft.net/en-us/download/server/bedrock
2. Accept EULA and click "Download for Ubuntu (Linux)"
3. Right-click download button and copy link address
4. Use the copied URL with wget:
```bash
# Switch to service user
sudo su - mcbds
cd /opt/mcbds/binaries
wget [PASTE_COPIED_URL_HERE]
unzip bedrock-server-*.zip
rm bedrock-server-*.zip
```

> **Note**: The download URL changes with each Minecraft version release. Always get the latest URL from the official Minecraft website.

### 3. Accept EULA
```bash
# Edit server.properties or eula.txt if present
# Bedrock server doesn't have EULA file, but check server.properties
echo "# Bedrock Server Configuration" > /opt/mcbds/binaries/server.properties
```

### 4. Test Bedrock Server Manually (optional)
```bash
# If not already logged in as mcbds user
sudo su - mcbds
cd /opt/mcbds/binaries
LD_LIBRARY_PATH=. ./bedrock_server

# Press Ctrl+C to stop after verifying it starts

# Exit back to admin user
exit
```

---

## Configure systemd Service

> **Note**: The following steps require admin/sudo privileges. If you're logged in as `mcbds` user, type `exit` to return to your admin account.

### 1. Create Service File
```bash
# Run as admin user with sudo
sudo vim /etc/systemd/system/mcbds-api.service
```

**Service Configuration:**
```ini
[Unit]
Description=MCBDS Manager API Service
After=network.target

[Service]
Type=simple
User=mcbds
Group=mcbds
WorkingDirectory=/opt/mcbds/api
ExecStart=/opt/mcbds/api/MCBDS.API
Restart=on-failure
RestartSec=10

# Environment variables
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ASPNETCORE_URLS=http://0.0.0.0:8080

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/mcbds/api /opt/mcbds/binaries /opt/mcbds/backups /opt/mcbds/logs

# Resource limits
LimitNOFILE=65535
MemoryLimit=4G

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mcbds-api

[Install]
WantedBy=multi-user.target
```

### 2. Configure API Settings
```bash
sudo vim /opt/mcbds/api/appsettings.json
```

**Configuration:**
```json
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
```

### 3. Set Permissions
```bash
# Run as admin user with sudo
sudo chown -R mcbds:mcbds /opt/mcbds
sudo chmod -R 755 /opt/mcbds/api
sudo chmod -R 755 /opt/mcbds/binaries
sudo chmod -R 775 /opt/mcbds/backups
sudo chmod -R 775 /opt/mcbds/logs
```

### 4. Enable and Start Service
```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable mcbds-api.service

# Start service
sudo systemctl start mcbds-api.service

# Check status
sudo systemctl status mcbds-api.service
```

---

## Firewall Configuration

### Using UFW (Ubuntu Firewall)

#### 1. Enable UFW (if not already enabled)
```bash
sudo ufw status
# If inactive:
sudo ufw enable
```

#### 2. Allow Required Ports
```bash
# Allow SSH (if managing remotely)
sudo ufw allow 22/tcp comment 'SSH'

# Allow MCBDS API HTTP
sudo ufw allow 8080/tcp comment 'MCBDS API HTTP'

# Allow MCBDS API HTTPS (optional)
sudo ufw allow 8081/tcp comment 'MCBDS API HTTPS'

# Allow Minecraft Bedrock Server
sudo ufw allow 19132/udp comment 'Minecraft Bedrock IPv4'
sudo ufw allow 19133/udp comment 'Minecraft Bedrock IPv6'

# Reload firewall
sudo ufw reload

# Verify rules
sudo ufw status numbered
```

### Using iptables (alternative)
```bash
# Allow HTTP API
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# Allow Minecraft ports
sudo iptables -A INPUT -p udp --dport 19132 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 19133 -j ACCEPT

# Save rules
sudo netfilter-persistent save
```

---

## SSL/HTTPS Setup (Optional)

### Option A: Self-Signed Certificate (Development/Internal Use)

#### 1. Generate Certificate
```bash
sudo su - mcbds
cd /opt/mcbds/api

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/mcbds/api/mcbds-selfsigned.key \
  -out /opt/mcbds/api/mcbds-selfsigned.crt \
  -subj "/CN=mcbds-server"

# Convert to PFX format for .NET
openssl pkcs12 -export \
  -out /opt/mcbds/api/mcbds-selfsigned.pfx \
  -inkey /opt/mcbds/api/mcbds-selfsigned.key \
  -in /opt/mcbds/api/mcbds-selfsigned.crt \
  -password pass:YourSecurePassword
```

#### 2. Update appsettings.json
```json
{
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:8080"
      },
      "Https": {
        "Url": "https://0.0.0.0:8081",
        "Certificate": {
          "Path": "/opt/mcbds/api/mcbds-selfsigned.pfx",
          "Password": "YourSecurePassword"
        }
      }
    }
  }
}
```

### Option B: Let's Encrypt (Production with Domain)

#### 1. Install Certbot
```bash
sudo apt install -y certbot
```

#### 2. Obtain Certificate
```bash
# Ensure port 80 is accessible
sudo ufw allow 80/tcp

# Get certificate (standalone mode)
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Certificates will be in /etc/letsencrypt/live/yourdomain.com/
```

#### 3. Convert to PFX
```bash
sudo openssl pkcs12 -export \
  -out /opt/mcbds/api/letsencrypt.pfx \
  -inkey /etc/letsencrypt/live/yourdomain.com/privkey.pem \
  -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem \
  -password pass:YourSecurePassword

sudo chown mcbds:mcbds /opt/mcbds/api/letsencrypt.pfx
```

#### 4. Setup Auto-Renewal
```bash
# Create renewal hook
sudo vim /etc/letsencrypt/renewal-hooks/post/restart-mcbds.sh
```

```bash
#!/bin/bash
openssl pkcs12 -export \
  -out /opt/mcbds/api/letsencrypt.pfx \
  -inkey /etc/letsencrypt/live/yourdomain.com/privkey.pem \
  -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem \
  -password pass:YourSecurePassword
chown mcbds:mcbds /opt/mcbds/api/letsencrypt.pfx
systemctl restart mcbds-api.service
```

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/restart-mcbds.sh
```

### Option C: Reverse Proxy with Nginx

#### 1. Install Nginx
```bash
sudo apt install -y nginx
```

#### 2. Configure Nginx
```bash
sudo vim /etc/nginx/sites-available/mcbds
```

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for SignalR
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### 3. Enable Site
```bash
sudo ln -s /etc/nginx/sites-available/mcbds /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Backup Configuration

### 1. Verify Backup Directory
```bash
sudo mkdir -p /opt/mcbds/backups
sudo chown mcbds:mcbds /opt/mcbds/backups
```

### 2. Configure Backup Settings in appsettings.json
```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "/opt/mcbds/backups",
    "MaxBackupsToKeep": 30,
    "Enabled": true
  }
}
```

### 3. Setup External Backup (Optional)
```bash
# Create backup script for offsite storage
sudo vim /opt/mcbds/backup-to-remote.sh
```

```bash
#!/bin/bash
# Sync backups to remote location (S3, NAS, etc.)
BACKUP_DIR="/opt/mcbds/backups"
REMOTE_DIR="user@remote-server:/backups/mcbds"

# Using rsync
rsync -avz --delete $BACKUP_DIR/ $REMOTE_DIR/

# Or using rclone for cloud storage
# rclone sync $BACKUP_DIR remote:mcbds-backups
```

```bash
sudo chmod +x /opt/mcbds/backup-to-remote.sh
sudo chown mcbds:mcbds /opt/mcbds/backup-to-remote.sh
```

### 4. Setup Cron Job (Optional)
```bash
sudo crontab -u mcbds -e
```

```cron
# Sync backups to remote every 6 hours
0 */6 * * * /opt/mcbds/backup-to-remote.sh >> /opt/mcbds/logs/backup-sync.log 2>&1
```

---

## Verification & Testing

### 1. Check Service Status
```bash
# View service status
sudo systemctl status mcbds-api.service

# View real-time logs
sudo journalctl -u mcbds-api.service -f

# View recent logs
sudo journalctl -u mcbds-api.service -n 100
```

### 2. Test API Endpoints
```bash
# Health check
curl http://localhost:8080/health

# Get server version
curl http://localhost:8080/api/version

# Check server status
curl http://localhost:8080/api/runner/status

# Get server properties
curl http://localhost:8080/api/serverproperties

# List backups
curl http://localhost:8080/api/backup/list
```

### 3. Test from Remote Machine
```bash
# Replace YOUR_SERVER_IP with your server's IP address
curl http://YOUR_SERVER_IP:8080/health
curl http://YOUR_SERVER_IP:8080/api/runner/status
```

### 4. Test Minecraft Connection
```bash
# From Minecraft Bedrock client:
# Add server: YOUR_SERVER_IP:19132

# Check if port is listening
sudo netstat -tulpn | grep 19132
```

### 5. Verify Backups
```bash
# Check backup directory
ls -lh /opt/mcbds/backups/

# Monitor backup logs
sudo journalctl -u mcbds-api.service | grep -i backup
```

---

## Troubleshooting

### Service Won't Start

#### Check Logs
```bash
sudo journalctl -u mcbds-api.service -n 100 --no-pager
```

#### Common Issues
1. **Missing appsettings.json**
```bash
# Error: "The configuration file 'appsettings.json' was not found"
   
# Create comprehensive configuration file
sudo su - mcbds
cat > /opt/mcbds/api/appsettings.json << 'EOF'
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
EOF
exit
   
# Restart service
sudo systemctl restart mcbds-api.service
```

2. **Port Already in Use**
   ```bash
   # Check what's using port 8080
   sudo netstat -tulpn | grep 8080
   sudo lsof -i :8080
   ```

2. **Permission Denied**
   ```bash
   # Fix ownership
   sudo chown -R mcbds:mcbds /opt/mcbds
   
   # Fix permissions
   sudo chmod +x /opt/mcbds/api/MCBDS.API
   sudo chmod +x /opt/mcbds/binaries/bedrock_server
   ```

3. **Missing .NET Runtime**
   ```bash
   dotnet --list-runtimes
   # Should show aspnetcore-runtime-10.0
   ```

### Bedrock Server Won't Start

#### Missing Dependencies
```bash
# Install required libraries
sudo apt install -y libcurl4 openssl libc6 libstdc++6

# Check library dependencies
ldd /opt/mcbds/binaries/bedrock_server
```

#### Test Manually
```bash
sudo su - mcbds
cd /opt/mcbds/binaries
LD_LIBRARY_PATH=. ./bedrock_server
```

### Connection Issues

#### Check Firewall
```bash
# Verify UFW rules
sudo ufw status numbered

# Test port connectivity from external machine
nc -zv YOUR_SERVER_IP 8080
nc -zuv YOUR_SERVER_IP 19132
```

#### Check Network Binding
```bash
# Verify API is listening on all interfaces
sudo netstat -tulpn | grep 8080
# Should show 0.0.0.0:8080, not 127.0.0.1:8080
```

### Performance Issues

#### Monitor Resources
```bash
# CPU and memory usage
htop

# Disk I/O
iotop

# Service-specific metrics
systemctl status mcbds-api.service
```

#### Increase Resource Limits
```bash
sudo vim /etc/systemd/system/mcbds-api.service
```

```ini
[Service]
MemoryLimit=8G
LimitNOFILE=100000
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart mcbds-api.service
```

### Backup Issues

#### Check Backup Directory
```bash
# Verify permissions
ls -ld /opt/mcbds/backups

# Check disk space
df -h /opt/mcbds/backups

# View backup logs
sudo journalctl -u mcbds-api.service | grep -i backup
```

---

## Next Steps

After successful installation:

### 1. Configure Server Properties
Edit the Bedrock server configuration:
```bash
sudo vim /opt/mcbds/binaries/server.properties
```
Set server name, game mode, difficulty, max players, etc.

### 2. Manage via REST API

**Start Server:**
```bash
curl -X POST http://localhost:8080/api/runner/start
```

**Stop Server:**
```bash
curl -X POST http://localhost:8080/api/runner/stop
```

**Send Command:**
```bash
curl -X POST http://localhost:8080/api/runner/command \
  -H "Content-Type: application/json" \
  -d '{"command": "say Hello from API!"}'
```

**Get Allowlist:**
```bash
curl http://localhost:8080/api/allowlist
```

**Add Player to Allowlist:**
```bash
curl -X POST http://localhost:8080/api/allowlist \
  -H "Content-Type: application/json" \
  -d '{"xuid": "1234567890123456", "name": "PlayerName"}'
```

**Create Backup:**
```bash
curl -X POST http://localhost:8080/api/backup/create
```

### 3. Install Resource/Behavior Packs

**Via API (Upload):**
```bash
# Upload resource pack
curl -X POST http://localhost:8080/api/packs/resource \
  -F "file=@mypack.zip"

# Upload behavior pack
curl -X POST http://localhost:8080/api/packs/behavior \
  -F "file=@mybehaviorpack.zip"
```

**Manual Installation:**
```bash
# Copy packs to server
scp mypack.zip mcbds@YOUR_SERVER_IP:/tmp/

# Extract to appropriate directory
sudo su - mcbds
unzip /tmp/mypack.zip -d /opt/mcbds/binaries/resource_packs/
```

### 4. Monitor Server

**View Logs:**
```bash
# Real-time logs
sudo journalctl -u mcbds-api.service -f

# Recent logs
sudo journalctl -u mcbds-api.service -n 100
```

**Check Status:**
```bash
# API status
curl http://localhost:8080/api/runner/status | jq

# Service status
sudo systemctl status mcbds-api.service
```

### 5. Connect with MAUI Mobile App
1. Download the MCBDS Manager mobile app (Android/iOS)
2. Add server with IP: `http://YOUR_SERVER_IP:8080`
3. Manage server with native mobile interface

### 6. Setup External Access (if needed)
- Configure router port forwarding (8080, 19132, 19133)
- Setup DDNS for dynamic IP
- Consider VPN for security
- Use reverse proxy (nginx) with SSL for production

---

## Security Recommendations

### 1. Run as Non-Root User
? Already implemented in this guide (mcbds user)

### 2. Enable Firewall
```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### 3. Keep System Updated
```bash
# Setup automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 4. Use SSH Key Authentication
```bash
# Disable password authentication
sudo vim /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart ssh
```

### 5. Setup Fail2Ban
```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 6. Regular Backups
- Enable automated backups in appsettings.json
- Setup offsite backup sync
- Test restore procedures regularly

---

## Support & Resources

- **GitHub Repository**: https://github.com/JoshuaBylotas/MCBDSHost
- **Issue Tracker**: https://github.com/JoshuaBylotas/MCBDSHost/issues
- **Official Website**: https://www.mc-bds.com
- **Minecraft Bedrock Server**: https://www.minecraft.net/en-us/download/server/bedrock

---

## Changelog

- **v1.0** - Initial Linux installation guide
- Compatible with MCBDS Manager v1.1.51

---

## API Documentation

For complete API documentation and available endpoints, see:
- API Reference: https://github.com/JoshuaBylotas/MCBDSHost/wiki/API-Reference
- OpenAPI/Swagger: Access at `http://YOUR_SERVER_IP:8080/openapi/v1.json` (development mode)

### Available API Endpoints:

**Runner Management:**
- `GET /api/runner/status` - Get server status
- `POST /api/runner/start` - Start Bedrock server
- `POST /api/runner/stop` - Stop Bedrock server
- `POST /api/runner/restart` - Restart Bedrock server
- `POST /api/runner/command` - Send console command
- `GET /api/runner/output` - Get console output

**Server Configuration:**
- `GET /api/serverproperties` - Get server.properties
- `PUT /api/serverproperties` - Update server.properties

**Allowlist Management:**
- `GET /api/allowlist` - Get allowlist
- `POST /api/allowlist` - Add player
- `DELETE /api/allowlist/{xuid}` - Remove player

**Pack Management:**
- `GET /api/packs/resource` - List resource packs
- `POST /api/packs/resource` - Upload resource pack
- `GET /api/packs/behavior` - List behavior packs
- `POST /api/packs/behavior` - Upload behavior pack
- `DELETE /api/packs/{type}/{name}` - Delete pack

**Backup Management:**
- `GET /api/backup/list` - List backups
- `POST /api/backup/create` - Create backup
- `GET /api/backup/download/{filename}` - Download backup
- `DELETE /api/backup/{filename}` - Delete backup
- `GET /api/backup/settings` - Get backup configuration
- `PUT /api/backup/settings` - Update backup configuration

**Xbox Live:**
- `GET /api/xboxlive/lookup?gamertag={gamertag}` - Lookup player XUID

**System:**
- `GET /health` - Health check endpoint
- `GET /api/version` - Get API version

---

## Package Distribution

The MCBDS API Linux package (`mcbds-api-linux-x64-v1.1.51.zip`) will be hosted for download. The package includes:

- ? Pre-compiled .NET 10 API binaries (framework-dependent)
- ? All required dependencies and libraries
- ? Default configuration files
- ? REST API endpoints for server management
- ? No web dashboard UI (API-only)
- ? No Minecraft Bedrock server binaries (must be downloaded separately)

**Package Requirements:**
- .NET 10 ASP.NET Core Runtime (installed via steps in this guide)
- Ubuntu 20.04+ or compatible Linux distribution
- x64 architecture

**Management Options:**
- REST API calls (documented above)
- MAUI mobile app (download separately)
- Web UI (available in separate package - coming soon)

**Hosting Locations**:
- Website: `https://www.mc-bds.com/linux-installation`
- Direct download: `https://www.mc-bds.com/downloads/mcbds-api-linux-x64-v1.1.51.zip`
- GitHub Releases: `https://github.com/JoshuaBylotas/MCBDSHost/releases`

---

**Need Help?**
- Check troubleshooting section above
- Review systemd service logs: `sudo journalctl -u mcbds-api.service`
- Open an issue on GitHub with detailed logs and error messages

# Let's Encrypt SSL/TLS Certificate Setup for MCBDS Manager

**Last Updated:** January 7, 2025  
**Applies To:** MCBDS Manager on Windows Server and Linux

---

## Overview

This guide explains how to obtain and configure free SSL/TLS certificates from Let's Encrypt for MCBDS Manager, replacing the self-signed certificates with trusted certificates recognized by all browsers.

### What is Let's Encrypt?

Let's Encrypt is a free, automated, and open Certificate Authority (CA) that provides SSL/TLS certificates trusted by all major browsers. Certificates are valid for 90 days and can be automatically renewed.

### Benefits

? **Free** - No cost for certificates  
? **Trusted** - Recognized by all browsers (no security warnings)  
? **Automated** - Easy renewal process  
? **Secure** - Industry-standard encryption  
? **Professional** - HTTPS with valid certificate

---

## Prerequisites

### For All Platforms

- Domain name pointing to your server's public IP address
- Open ports on your router/firewall:
  - Port 80 (HTTP) - Required for Let's Encrypt validation
  - Port 443 (HTTPS) - For secure traffic
  - Port 19132 (UDP) - Minecraft Bedrock Server
- Public IP address or dynamic DNS service

### For Windows

- Windows Server 2019/2022/2025 or Windows 10/11 Pro
- Administrator access
- PowerShell 5.1 or later
- IIS (optional, for HTTP challenge)

### For Linux

- Ubuntu 20.04+, Debian 11+, or compatible distribution
- Root or sudo access
- Port 80 available for validation

---

## DNS Challenge with Cloudflare (No Port 80 Required)

If you cannot open port 80 (e.g., behind NAT, strict firewall, or ISP blocks port 80), you can use DNS validation with Cloudflare. This method doesn't require any ports to be open.

### Prerequisites

- Domain managed by Cloudflare
- Cloudflare API token with DNS edit permissions
- Domain DNS already pointing to Cloudflare nameservers

---

### Windows Setup with Cloudflare DNS

#### Step 1: Get Cloudflare API Token

1. Log in to https://dash.cloudflare.com/
2. Go to "My Profile" ? "API Tokens"
3. Click "Create Token"
4. Use "Edit zone DNS" template or create custom token:
   - **Permissions:**
     - Zone ? DNS ? Edit
     - Zone ? Zone ? Read
   - **Zone Resources:**
     - Include ? Specific zone ? yourdomain.com
5. Click "Continue to summary" ? "Create Token"
6. Copy the token (you'll only see it once!)

#### Step 2: Install Win-ACME with DNS Plugin

```powershell
# Create directory for Win-ACME
New-Item -Path "C:\Tools\win-acme" -ItemType Directory -Force
cd C:\Tools\win-acme

# Download latest release from GitHub
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/win-acme/win-acme/releases/latest"
$downloadUrl = $latestRelease.assets | Where-Object { $_.name -like "*x64.pluggable.zip" } | Select-Object -First 1 -ExpandProperty browser_download_url

Invoke-WebRequest -Uri $downloadUrl -OutFile "win-acme.zip"
Expand-Archive -Path "win-acme.zip" -DestinationPath . -Force
Remove-Item "win-acme.zip"

# Verify installation
.\wacs.exe --version
```

#### Step 3: Create Cloudflare API Token File

```powershell
# Store Cloudflare API token securely
$cloudflareToken = "your_cloudflare_api_token_here"  # Replace with your actual token
$tokenFile = "C:\Tools\win-acme\cloudflare-token.txt"

# Save token to file
Set-Content -Path $tokenFile -Value $cloudflareToken -NoNewline

# Secure the file (only Administrators and SYSTEM can access)
icacls $tokenFile /inheritance:r
icacls $tokenFile /grant "SYSTEM:(F)"
icacls $tokenFile /grant "Administrators:(F)"

Write-Host "Cloudflare token saved to: $tokenFile" -ForegroundColor Green
```

#### Step 4: Request Certificate Using DNS Validation

```powershell
# Run Win-ACME with Cloudflare DNS validation
cd C:\Tools\win-acme

# Interactive mode (Recommended for first-time setup)
.\wacs.exe

# Follow prompts:
# 1. Choose "N" for new certificate
# 2. Select "Manual input"
# 3. Enter domain: mcbds.yourdomain.com
# 4. Choose "dns-01" validation
# 5. Select "Cloudflare" as DNS provider
# 6. Enter Cloudflare API token when prompted
# 7. Select PFX file output
# 8. Choose destination path and password
```

**Alternative: Command-line mode (Advanced)**

```powershell
# For automated/scripted certificate requests
# Note: Check Win-ACME documentation for current parameter syntax
.\wacs.exe `
    --source manual `
    --host mcbds.yourdomain.com `
    --validation dns-01 `
    --validationplugin cloudflare `
    --store pfxfile `
    --pfxfilepath "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs" `
    --pfxfilename "mcbds-api.pfx" `
    --pfxpassword "YourSecurePassword123!" `
    --installation none

# You will be prompted to enter your Cloudflare API token interactively
```

#### Step 5: Configure Docker with Certificate

```powershell
# Update docker-compose.windows.yml
$composeFile = "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\docker-compose.windows.yml"
$pfxPassword = "YourSecurePassword123!"

# Verify certificate was created
if (Test-Path "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx") {
    Write-Host "? Certificate created successfully!" -ForegroundColor Green
} else {
    Write-Host "? Certificate not found!" -ForegroundColor Red
    exit 1
}

# Update docker-compose with certificate password
$content = Get-Content $composeFile -Raw
$content = $content -replace 'ASPNETCORE_Kestrel__Certificates__Default__Password=.*', "ASPNETCORE_Kestrel__Certificates__Default__Password=$pfxPassword"
Set-Content -Path $composeFile -Value $content

# Restart Docker containers
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml up -d

Write-Host "? Docker containers restarted with Cloudflare certificate!" -ForegroundColor Green
```

#### Step 6: Configure Automatic Renewal

```powershell
# Win-ACME automatically creates a scheduled task
# Verify it exists
Get-ScheduledTask -TaskName "win-acme renew*"

# Test renewal
cd C:\Tools\win-acme
.\wacs.exe --renew --force

# Create post-renewal script for Docker restart
$renewalScript = @"
`$certSource = "C:\ProgramData\win-acme\httpsacme-v02.api.letsencrypt.org\Certificates\mcbds.yourdomain.com-chain.pfx"
`$certDest = "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx"

if (Test-Path `$certSource) {
    Copy-Item `$certSource `$certDest -Force
    Write-Host "Certificate copied successfully" -ForegroundColor Green
    
    # Restart Docker
    cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost
    docker compose -f docker-compose.windows.yml restart mcbds-api
    
    Write-Host "Docker restarted with new certificate" -ForegroundColor Green
} else {
    Write-Host "Certificate not found at `$certSource" -ForegroundColor Red
}
"@

Set-Content -Path "C:\Tools\win-acme\copy-cert-to-docker.ps1" -Value $renewalScript

Write-Host "Renewal script created at: C:\Tools\win-acme\copy-cert-to-docker.ps1" -ForegroundColor Green
```

---

### Linux Setup with Cloudflare DNS

#### Step 1: Install Certbot with Cloudflare Plugin

**Ubuntu/Debian:**
```bash
# Install Certbot and Cloudflare plugin
sudo apt update
sudo apt install certbot python3-certbot-dns-cloudflare -y
```

**CentOS/RHEL 8+:**
```bash
# Enable EPEL repository
sudo dnf install epel-release -y

# Install Certbot and Cloudflare plugin
sudo dnf install certbot python3-certbot-dns-cloudflare -y
```

**CentOS/RHEL 7:**
```bash
# Enable EPEL repository
sudo yum install epel-release -y

# Install Certbot and Cloudflare plugin
sudo yum install certbot python2-certbot-dns-cloudflare -y
```

#### Step 2: Configure Cloudflare Credentials

```bash
# Create Cloudflare credentials file
sudo mkdir -p /root/.secrets
sudo nano /root/.secrets/cloudflare.ini
```

Add the following content (replace with your Cloudflare API token):

```ini
# Cloudflare API token (recommended)
dns_cloudflare_api_token = your_cloudflare_api_token_here

# Alternative: Cloudflare API key (legacy, less secure)
# dns_cloudflare_email = your-email@example.com
# dns_cloudflare_api_key = your_global_api_key_here
```

Secure the credentials file:

```bash
# Restrict access to root only
sudo chmod 600 /root/.secrets/cloudflare.ini

# Verify permissions
ls -la /root/.secrets/cloudflare.ini
# Should show: -rw------- 1 root root
```

#### Step 3: Request Certificate with DNS Validation

```bash
# Request certificate using Cloudflare DNS
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 60 \
    -d mcbds.yourdomain.com \
    --email your-email@example.com \
    --agree-tos \
    --non-interactive

# Certificates will be saved to:
# /etc/letsencrypt/live/mcbds.yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/mcbds.yourdomain.com/privkey.pem

# Check certificate
sudo certbot certificates
```

#### Step 4: Convert to PFX for Docker

```bash
# Set variables
export DOMAIN="mcbds.yourdomain.com"
export PFX_PASSWORD="YourSecurePassword123!"  # Change this!

# Convert to PFX format
sudo openssl pkcs12 -export \
    -out /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx \
    -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -passout pass:$PFX_PASSWORD

# Copy to project directory
sudo cp /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx ~/MCBDSHost/certs/
sudo chown $USER:$USER ~/MCBDSHost/certs/mcbds-api.pfx
sudo chmod 600 ~/MCBDSHost/certs/mcbds-api.pfx

echo "? Certificate created and copied successfully!"
```

#### Step 5: Configure Docker

```bash
# Update docker-compose.yml with certificate password
cd ~/MCBDSHost
nano docker-compose.linux.yml

# Update this line:
# ASPNETCORE_Kestrel__Certificates__Default__Password=YourSecurePassword123!
# Change to:
# ASPNETCORE_Kestrel__Certificates__Default__Password=YourSecurePassword123!

# Start Docker containers
docker compose up -d

# Verify certificate
curl -k https://localhost:8081/health
```

#### Step 6: Set Up Automatic Renewal

Create renewal hook:

```bash
# Create renewal hook script
sudo nano /etc/letsencrypt/renewal-hooks/post/mcbds-cloudflare-renewal.sh
```

Add this content:

```bash
#!/bin/bash

DOMAIN="mcbds.yourdomain.com"
PFX_PASSWORD="YourSecurePassword123!"
PROJECT_DIR="$HOME/MCBDSHost"

# Convert to PFX
openssl pkcs12 -export \
    -out /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx \
    -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -passout pass:$PFX_PASSWORD

# Copy to project
cp /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx $PROJECT_DIR/certs/
chown $USER:$USER $PROJECT_DIR/certs/mcbds-api.pfx
chmod 600 $PROJECT_DIR/certs/mcbds-api.pfx

# Restart Docker
cd $PROJECT_DIR
docker compose restart mcbds-api

logger "MCBDS Manager certificate renewed via Cloudflare DNS and Docker restarted"
echo "? Certificate renewed successfully!"
```

Make executable and test:

```bash
# Make script executable
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/mcbds-cloudflare-renewal.sh

# Test renewal (dry run)
sudo certbot renew --dry-run

# Check auto-renewal timer
sudo systemctl status certbot.timer

# Enable if not enabled
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## Windows Setup

### Option 1: Using Win-ACME (Recommended)

Win-ACME is a powerful ACME client for Windows that supports automatic renewal.

#### Step 1: Download Win-ACME

```powershell
# Create directory for Win-ACME
New-Item -Path "C:\Tools\win-acme" -ItemType Directory -Force
cd C:\Tools\win-acme

# Download latest release from GitHub
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/win-acme/win-acme/releases/latest"
$downloadUrl = $latestRelease.assets | Where-Object { $_.name -like "*x64.pluggable.zip" } | Select-Object -First 1 -ExpandProperty browser_download_url

Invoke-WebRequest -Uri $downloadUrl -OutFile "win-acme.zip"
Expand-Archive -Path "win-acme.zip" -DestinationPath . -Force
Remove-Item "win-acme.zip"

# Verify installation
.\wacs.exe --version
```

#### Step 2: Configure Firewall for HTTP Challenge

```powershell
# Allow HTTP traffic for Let's Encrypt validation
New-NetFirewallRule -DisplayName "HTTP for Let's Encrypt" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

# Ensure HTTPS is also allowed
New-NetFirewallRule -DisplayName "HTTPS Traffic" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
```

#### Step 3: Request Certificate

```powershell
# Run Win-ACME interactively
.\wacs.exe

# Follow the prompts:
# 1. Choose "N" for new certificate
# 2. Select "Manual input" for domain names
# 3. Enter your domain (e.g., mcbds.yourdomain.com)
# 4. Choose "http-01" validation
# 5. Select "Self-hosting" validation method
# 6. Choose port 80 for validation
# 7. Select "PFX archive" for certificate format
# 8. Choose installation method (Windows Certificate Store recommended)
```

#### Step 4: Export Certificate for Docker

```powershell
# After Win-ACME creates the certificate, export it
$domain = "mcbds.yourdomain.com"
$certPath = "C:\ProgramData\win-acme\httpsacme-v02.api.letsencrypt.org\Certificates"
$pfxPassword = "YourSecurePassword123!"  # Change this!

# Find the latest certificate
$latestCert = Get-ChildItem "$certPath\$domain-*" | 
              Where-Object { $_.Extension -eq ".pfx" } | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

# Copy to MCBDS Manager certs directory
Copy-Item $latestCert.FullName "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx" -Force

Write-Host "Certificate copied successfully!" -ForegroundColor Green
Write-Host "Certificate path: $($latestCert.FullName)" -ForegroundColor Cyan
```

#### Step 5: Update Docker Compose Configuration

```powershell
# Update docker-compose.windows.yml with your domain and password
$composeFile = "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\docker-compose.windows.yml"
$content = Get-Content $composeFile -Raw

# Update certificate password
$content = $content -replace 'ASPNETCORE_Kestrel__Certificates__Default__Password=.*', "ASPNETCORE_Kestrel__Certificates__Default__Password=$pfxPassword"

Set-Content -Path $composeFile -Value $content

# Restart Docker containers
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml up -d

Write-Host "Docker containers restarted with Let's Encrypt certificate!" -ForegroundColor Green
```

#### Step 6: Configure Automatic Renewal

Win-ACME automatically creates a scheduled task for renewal. Verify it:

```powershell
# Check scheduled task
Get-ScheduledTask -TaskName "win-acme renew*"

# Test renewal manually
cd C:\Tools\win-acme
.\wacs.exe --renew --force
```

Create a script to copy renewed certificates to Docker:

```powershell
# Create renewal script
$renewalScript = @"
`$domain = "mcbds.yourdomain.com"
`$certPath = "C:\ProgramData\win-acme\httpsacme-v02.api.letsencrypt.org\Certificates"
`$destPath = "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx"

# Find latest certificate
`$latestCert = Get-ChildItem "`$certPath\`$domain-*" | 
              Where-Object { `$_.Extension -eq ".pfx" } | 
              Sort-Object LastWriteTime -Descending | 
              Select-Object -First 1

if (`$latestCert) {
    Copy-Item `$latestCert.FullName `$destPath -Force
    
    # Restart Docker containers
    cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost
    docker compose -f docker-compose.windows.yml restart mcbds-api
    
    Write-Host "Certificate renewed and Docker restarted!" -ForegroundColor Green
} else {
    Write-Host "No certificate found!" -ForegroundColor Red
}
"@

Set-Content -Path "C:\Tools\win-acme\copy-cert-to-docker.ps1" -Value $renewalScript

# Update Win-ACME task to run the script after renewal
# This requires editing the scheduled task to add a script execution step
```

---

### Option 2: Using Certify The Web (GUI)

Certify The Web provides a user-friendly GUI for managing Let's Encrypt certificates.

#### Step 1: Install Certify The Web

1. Download from https://certifytheweb.com/
2. Run the installer
3. Launch Certify The Web

#### Step 2: Create New Certificate

1. Click "New Certificate"
2. Enter your domain name (e.g., mcbds.yourdomain.com)
3. Choose "http-01" challenge
4. Select validation method
5. Click "Request Certificate"

#### Step 3: Export and Configure

Similar to Win-ACME, export the certificate and configure Docker as shown above.

---

## Linux Setup

### Using Certbot (Official Let's Encrypt Client)

#### Step 1: Install Certbot

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install certbot -y
```

**CentOS/RHEL:**
```bash
sudo yum install epel-release -y
sudo yum install certbot -y
```

#### Step 2: Stop Services (Temporary)

```bash
# Stop Docker containers to free port 80
cd ~/MCBDSHost
docker compose down
```

#### Step 3: Request Certificate

```bash
# Request certificate with standalone validation
sudo certbot certonly --standalone \
    --preferred-challenges http \
    -d mcbds.yourdomain.com \
    --email your-email@example.com \
    --agree-tos \
    --non-interactive

# Certificates will be saved to:
# /etc/letsencrypt/live/mcbds.yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/mcbds.yourdomain.com/privkey.pem
```

#### Step 4: Convert to PFX Format

Docker requires certificates in PFX format:

```bash
# Set password for PFX file
export PFX_PASSWORD="YourSecurePassword123!"  # Change this!
export DOMAIN="mcbds.yourdomain.com"

# Convert to PFX
sudo openssl pkcs12 -export \
    -out /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx \
    -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -passout pass:$PFX_PASSWORD

# Copy to project directory
sudo cp /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx ~/MCBDSHost/certs/
sudo chown $USER:$USER ~/MCBDSHost/certs/mcbds-api.pfx
sudo chmod 600 ~/MCBDSHost/certs/mcbds-api.pfx
```

#### Step 5: Update Docker Compose

```bash
cd ~/MCBDSHost

# Update docker-compose.yml with certificate password
# (Assuming you're using docker-compose.linux.yml)
nano docker-compose.linux.yml

# Find and update this line:
# ASPNETCORE_Kestrel__Certificates__Default__Password=McbdsApiCert123!
# Change to:
# ASPNETCORE_Kestrel__Certificates__Default__Password=YourSecurePassword123!

# Save and exit (Ctrl+X, Y, Enter)
```

#### Step 6: Start Services

```bash
# Start Docker containers with new certificate
docker compose up -d

# Verify HTTPS is working
curl -k https://localhost:8081/health
```

#### Step 7: Configure Automatic Renewal

Create a renewal hook to convert and copy certificates:

```bash
# Create renewal hook script
sudo nano /etc/letsencrypt/renewal-hooks/post/mcbds-renewal.sh
```

Add this content:

```bash
#!/bin/bash

DOMAIN="mcbds.yourdomain.com"
PFX_PASSWORD="YourSecurePassword123!"  # Match your password!
PROJECT_DIR="/home/youruser/MCBDSHost"  # Update with your path!

# Convert to PFX
openssl pkcs12 -export \
    -out /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx \
    -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -passout pass:$PFX_PASSWORD

# Copy to project
cp /etc/letsencrypt/live/$DOMAIN/mcbds-api.pfx $PROJECT_DIR/certs/
chown youruser:youruser $PROJECT_DIR/certs/mcbds-api.pfx
chmod 600 $PROJECT_DIR/certs/mcbds-api.pfx

# Restart Docker containers
cd $PROJECT_DIR
docker compose restart mcbds-api

logger "MCBDS Manager certificate renewed and Docker restarted"
```

Make the script executable:

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/mcbds-renewal.sh
```

Test automatic renewal:

```bash
# Dry run to test renewal
sudo certbot renew --dry-run

# Check renewal timer
sudo systemctl status certbot.timer

# Enable auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## DNS Configuration

Before requesting certificates, ensure your DNS is properly configured:

### A Record Setup

```
Type: A
Host: mcbds (or your subdomain)
Value: Your server's public IP
TTL: 300 (5 minutes)
```

### Verify DNS

```powershell
# Windows
nslookup mcbds.yourdomain.com

# Linux
dig mcbds.yourdomain.com
host mcbds.yourdomain.com
```

Wait for DNS propagation (usually 5-30 minutes) before requesting certificates.

---

## Dynamic DNS Setup

If you don't have a static IP, use a Dynamic DNS service:

### Popular DDNS Providers

- **No-IP** - https://www.noip.com/
- **DuckDNS** - https://www.duckdns.org/
- **Dynu** - https://www.dynu.com/
- **FreeDNS** - https://freedns.afraid.org/

### Example: DuckDNS Setup

1. Register at https://www.duckdns.org/
2. Create a subdomain (e.g., mcbds.duckdns.org)
3. Install DuckDNS update client:

**Windows (PowerShell):**
```powershell
# Download update script
Invoke-WebRequest -Uri "https://www.duckdns.org/update/your-subdomain/your-token" -OutFile "$null"

# Create scheduled task to run every 5 minutes
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-Command `"Invoke-WebRequest -Uri 'https://www.duckdns.org/update/your-subdomain/your-token' -UseBasicParsing`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName "DuckDNS Update" -Action $action -Trigger $trigger -User "SYSTEM"
```

**Linux (cron):**
```bash
# Create update script
echo "curl 'https://www.duckdns.org/update/your-subdomain/your-token'" | sudo tee /usr/local/bin/duckdns.sh
sudo chmod +x /usr/local/bin/duckdns.sh

# Add to crontab (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/duckdns.sh") | crontab -
```

---

## Troubleshooting

### Common Issues

#### Certificate Validation Failed

**Problem:** Let's Encrypt cannot validate domain ownership

**Solutions:**
```powershell
# Check port 80 is open
Test-NetConnection -ComputerName mcbds.yourdomain.com -Port 80

# Check firewall
Get-NetFirewallRule -DisplayName "*80*" | Where-Object { $_.Enabled -eq "True" }

# Verify DNS
nslookup mcbds.yourdomain.com

# Check if another service is using port 80
netstat -ano | findstr :80
```

#### Certificate Not Trusted

**Problem:** Browser still shows security warning

**Solutions:**
- Clear browser cache
- Check certificate chain in browser
- Verify certificate is from Let's Encrypt (not self-signed)
- Ensure system date/time is correct

#### Docker Cannot Load Certificate

**Problem:** Container fails to start with certificate error

**Solutions:**
```powershell
# Verify certificate file exists
Test-Path "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx"

# Check certificate password matches docker-compose.yml
# Password in: ASPNETCORE_Kestrel__Certificates__Default__Password

# Test certificate is valid
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import("C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx", "YourPassword", "DefaultKeySet")
$cert | Format-List Subject, Issuer, NotBefore, NotAfter
```

#### Renewal Fails

**Problem:** Automatic renewal doesn't work

**Solutions:**
```bash
# Linux - Check certbot timer
sudo systemctl status certbot.timer

# Windows - Check scheduled task
Get-ScheduledTask -TaskName "win-acme*"

# Test renewal manually
sudo certbot renew --dry-run  # Linux
.\wacs.exe --renew --force    # Windows (Win-ACME)
```

---

## Security Best Practices

### Certificate Storage

```powershell
# Windows - Set proper permissions on certificate
icacls "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx" /grant "SYSTEM:F" /grant "Administrators:F"
icacls "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx" /inheritance:r

# Linux - Restrict certificate access
chmod 600 ~/MCBDSHost/certs/mcbds-api.pfx
chown root:docker ~/MCBDSHost/certs/mcbds-api.pfx
```

### Password Management

- Use strong, unique passwords for PFX files
- Store passwords securely (e.g., Azure Key Vault, AWS Secrets Manager)
- Don't commit passwords to Git
- Rotate passwords periodically

### Monitoring

Set up monitoring for certificate expiration:

```powershell
# Windows - Check certificate expiration
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import("C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx", "YourPassword", "DefaultKeySet")
$daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days
Write-Host "Certificate expires in $daysUntilExpiration days" -ForegroundColor $(if($daysUntilExpiration -lt 30){"Yellow"}else{"Green"})
```

---

## Testing Your Configuration

### Test HTTPS Endpoint

```powershell
# Windows
Invoke-WebRequest -Uri https://mcbds.yourdomain.com:8081/health -UseBasicParsing

# Linux
curl https://mcbds.yourdomain.com:8081/health
```

### Check Certificate Details

```powershell
# Windows
$cert = Invoke-WebRequest -Uri https://mcbds.yourdomain.com:8081/health
$cert.BaseResponse.ServerCertificate | Format-List Subject, Issuer, NotBefore, NotAfter
```

### SSL Labs Test

For production deployments, test your SSL configuration:

1. Visit https://www.ssllabs.com/ssltest/
2. Enter your domain (mcbds.yourdomain.com)
3. Wait for analysis
4. Aim for A+ rating

---

## Migration from Self-Signed to Let's Encrypt

If you're currently using self-signed certificates:

```powershell
# 1. Backup existing self-signed certificate
Copy-Item "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api.pfx" `
          "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\certs\mcbds-api-selfsigned.pfx.backup"

# 2. Follow Let's Encrypt setup above

# 3. Update docker-compose.yml with new password

# 4. Restart containers
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml up -d

# 5. Verify HTTPS works without browser warnings
```

---

## Cost Comparison

| Certificate Type | Cost | Validity | Auto-Renewal | Browser Trust |
|-----------------|------|----------|--------------|---------------|
| **Let's Encrypt** | **Free** | **90 days** | **Yes** | **?** |
| Self-Signed | Free | Custom | Manual | ? (warnings) |
| Commercial CA | $50-500/year | 1-2 years | Manual | ? |

---

## Recommended Configuration

### Production Deployment

```yaml
# docker-compose.windows.yml (recommended settings)
services:
  mcbds-api:
    environment:
      # Force HTTPS
      - ASPNETCORE_URLS=https://+:8081
      # Let's Encrypt certificate
      - ASPNETCORE_Kestrel__Certificates__Default__Path=C:/https/mcbds-api.pfx
      - ASPNETCORE_Kestrel__Certificates__Default__Password=${CERT_PASSWORD}
      # Security headers
      - ASPNETCORE_HTTPS_PORT=8081
    ports:
      - "443:8081"  # Use standard HTTPS port
```

### Environment Variables

```powershell
# Store certificate password as environment variable
[System.Environment]::SetEnvironmentVariable("CERT_PASSWORD", "YourSecurePassword123!", "Machine")

# Update docker-compose to use environment variable
# ASPNETCORE_Kestrel__Certificates__Default__Password=${CERT_PASSWORD}
```

---

## References

- **Let's Encrypt:** https://letsencrypt.org/
- **Win-ACME:** https://www.win-acme.com/
- **Certbot:** https://certbot.eff.org/
- **Certify The Web:** https://certifytheweb.com/
- **SSL Labs Testing:** https://www.ssllabs.com/ssltest/

---

## Support

For issues with Let's Encrypt setup:

1. Check the troubleshooting section above
2. Review Let's Encrypt documentation
3. Verify DNS configuration
4. Check firewall settings
5. Review Docker logs: `docker compose logs -f mcbds-api`

---

**Last Updated:** January 7, 2025  
**Version:** 1.0  
**Compatibility:** MCBDS Manager 1.0+, Windows Server 2019+, Ubuntu 20.04+

# Let's Encrypt / ACME Certificate Setup for MCBDS API

This guide shows how to get a **free, trusted SSL certificate** from Let's Encrypt using ACME.

---

## Prerequisites

- **Public domain name** pointing to your server (e.g., `api.yourdomain.com`)
- **Port 80** open for HTTP validation (or DNS provider API access for DNS validation)
- **Email address** for renewal notifications

---

## Windows Server Setup

### Step 1: Install Certbot

```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Certbot
choco install certbot -y

# Verify installation
certbot --version
```

### Step 2: Stop IIS/Docker (Temporarily)

Certbot needs port 80:

```powershell
# Stop Docker container
docker compose -f docker-compose.https.windows-server.yml down

# Or stop IIS if running
iisreset /stop
```

### Step 3: Generate Certificate

```powershell
# Replace with your domain and email
certbot certonly --standalone `
    -d api.yourdomain.com `
    --email your@email.com `
    --agree-tos `
    --no-eff-email

# Certificate will be saved to:
# C:\Certbot\live\api.yourdomain.com\
```

### Step 4: Convert to PFX Format

```powershell
# Install OpenSSL (if not installed)
choco install openssl -y

# Set variables
$domain = "api.yourdomain.com"
$certPath = "C:\Certbot\live\$domain"
$outputPath = "C:\MCBDSHost\certs\mcbds-api.pfx"
$password = "YourSecurePassword123!"

# Convert to PFX
openssl pkcs12 -export `
    -out $outputPath `
    -inkey "$certPath\privkey.pem" `
    -in "$certPath\fullchain.pem" `
    -password pass:$password

Write-Host "Certificate created at: $outputPath" -ForegroundColor Green
```

### Step 5: Update Docker Compose

Edit `docker-compose.https.windows-server.yml`:

```yaml
environment:
  - ASPNETCORE_Kestrel__Certificates__Default__Password=YourSecurePassword123!
```

### Step 6: Restart Container

```powershell
docker compose -f docker-compose.https.windows-server.yml up -d
```

---

## Linux Server Setup

```bash
# Install Certbot
sudo apt update
sudo apt install certbot -y

# Stop Docker to free port 80
docker compose -f docker-compose.linux.yml down

# Generate certificate
sudo certbot certonly --standalone \
    -d api.yourdomain.com \
    --email your@email.com \
    --agree-tos \
    --no-eff-email

# Convert to PFX
sudo openssl pkcs12 -export \
    -out /opt/mcbdshost/certs/mcbds-api.pfx \
    -inkey /etc/letsencrypt/live/api.yourdomain.com/privkey.pem \
    -in /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem \
    -password pass:YourSecurePassword123!

# Set permissions
sudo chmod 644 /opt/mcbdshost/certs/mcbds-api.pfx

# Restart Docker
docker compose -f docker-compose.linux.yml up -d
```

---

## DNS Challenge (No Public Port 80 Needed)

If port 80 is blocked or you're behind a firewall:

### For Cloudflare DNS

```powershell
# Install Cloudflare plugin
pip install certbot-dns-cloudflare

# Create credentials file
@"
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
"@ | Out-File -FilePath cloudflare.ini -Encoding ASCII

# Generate certificate
certbot certonly `
    --dns-cloudflare `
    --dns-cloudflare-credentials cloudflare.ini `
    -d api.yourdomain.com `
    --email your@email.com `
    --agree-tos
```

---

## Auto-Renewal Script

Create `C:\MCBDSHost\MCBDSHost\renew-letsencrypt-cert.ps1`:

```powershell
# Automatic Let's Encrypt Certificate Renewal Script
$domain = "api.yourdomain.com"
$certPassword = "YourSecurePassword123!"
$pfxOutput = "C:\MCBDSHost\certs\mcbds-api.pfx"
$certPath = "C:\Certbot\live\$domain"

Write-Host "Starting certificate renewal..." -ForegroundColor Cyan

# Renew certificate
certbot renew --quiet --standalone --pre-hook "docker compose -f C:\MCBDSHost\MCBDSHost\docker-compose.https.windows-server.yml down" --post-hook "Write-Host 'Renewal complete'"

# Check if renewal occurred
if ($LASTEXITCODE -eq 0) {
    Write-Host "Converting to PFX..." -ForegroundColor Cyan
    
    # Convert to PFX
    openssl pkcs12 -export `
        -out $pfxOutput `
        -inkey "$certPath\privkey.pem" `
        -in "$certPath\fullchain.pem" `
        -password pass:$certPassword
    
    Write-Host "Restarting Docker container..." -ForegroundColor Cyan
    
    # Restart container
    docker compose -f C:\MCBDSHost\MCBDSHost\docker-compose.https.windows-server.yml up -d
    
    Write-Host "Certificate renewed successfully!" -ForegroundColor Green
} else {
    Write-Host "No renewal needed or renewal failed" -ForegroundColor Yellow
}
```

### Schedule Auto-Renewal (Monthly)

```powershell
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\MCBDSHost\MCBDSHost\renew-letsencrypt-cert.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 3am

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "RenewMCBDSCertificate" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "Renew Let's Encrypt certificate for MCBDS API monthly"

Write-Host "Scheduled task created: RenewMCBDSCertificate" -ForegroundColor Green
```

---

## Certificate Expiry

Let's Encrypt certificates:
- **Valid for 90 days**
- **Auto-renewal recommended after 60 days**
- **Email notifications** sent before expiry

---

## Troubleshooting

### Port 80 Already in Use

```powershell
# Find what's using port 80
Get-NetTCPConnection -LocalPort 80 | Select-Object OwningProcess
Get-Process -Id <PID>

# Stop IIS
iisreset /stop

# Or stop Docker
docker compose down
```

### Domain Not Resolving

```powershell
# Test DNS
nslookup api.yourdomain.com

# Should return your server's public IP
```

### Firewall Blocking Port 80

```powershell
# Open port 80 temporarily
New-NetFirewallRule -DisplayName "ACME HTTP Challenge" `
    -Direction Inbound -Port 80 -Protocol TCP -Action Allow
```

---

## Benefits Over Self-Signed

| Feature | Self-Signed | Let's Encrypt |
|---------|-------------|---------------|
| Browser trust | ? Warning | ? Trusted |
| Cost | Free | Free |
| Expiry | 5 years | 90 days (auto-renew) |
| Domain validation | None | Yes |
| Use case | Internal | Production |

---

*Last Updated: January 2025*

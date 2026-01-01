# HTTPS Setup for Docker API Server

This guide explains how to add HTTPS support to your existing MCBDS API Docker deployment using a self-signed certificate.

---

## Files Included

| File | Purpose |
|------|---------|
| `docker-compose.https.yml` | Docker Compose file with HTTPS configuration |
| `generate-https-cert.sh` | Linux/macOS certificate generator script |
| `generate-https-cert.ps1` | Windows certificate generator script |
| `DOCKER-HTTPS-SETUP.md` | This documentation file |

---

## Prerequisites

- Docker and docker-compose already installed
- MCBDS API container already running
- Access to the server via SSH or terminal

---

## Quick Start (3 Commands)

### On Linux Server

```bash
# 1. Generate certificate
chmod +x generate-https-cert.sh
./generate-https-cert.sh

# 2. Stop current container and start with HTTPS
docker-compose down
docker-compose -f docker-compose.https.yml up -d

# 3. Test HTTPS
curl -k https://localhost:8081/api/runner/status
```

### On Windows (then copy to Linux server)

```powershell
# 1. Generate certificate
.\generate-https-cert.ps1

# 2. Copy certs folder to Linux server
scp -r .\certs user@your-server:/path/to/MCBDSHost/

# Then on the Linux server:
docker-compose -f docker-compose.https.yml up -d
```

---

## Step-by-Step Instructions

### Step 1: Generate Self-Signed Certificate

#### Option A: Use the Provided Script (Recommended)

**Linux/macOS:**
```bash
chmod +x generate-https-cert.sh
./generate-https-cert.sh
```

**Windows (PowerShell as Administrator):**
```powershell
.\generate-https-cert.ps1
```

The script will:
- Ask for your server's IP address
- Create a `./certs/` directory
- Generate a self-signed certificate valid for 5 years
- Create the PFX file needed by .NET

#### Option B: Manual Generation (Linux)

```bash
# Create certs directory
mkdir -p ./certs

# Generate certificate (replace YOUR_SERVER_IP)
openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
    -keyout ./certs/mcbds-api.key \
    -out ./certs/mcbds-api.crt \
    -subj "/CN=mcbds-api/O=MCBDSHost/C=US" \
    -addext "subjectAltName=DNS:localhost,DNS:mcbds-api,IP:127.0.0.1,IP:YOUR_SERVER_IP"

# Convert to PFX format
openssl pkcs12 -export -out ./certs/mcbds-api.pfx \
    -inkey ./certs/mcbds-api.key \
    -in ./certs/mcbds-api.crt \
    -password pass:McbdsApiCert123!

# Set permissions
chmod 600 ./certs/mcbds-api.pfx
```

---

### Step 2: Deploy with HTTPS

```bash
# Stop current container
docker-compose down

# Start with HTTPS configuration
docker-compose -f docker-compose.https.yml up -d

# View logs to verify startup
docker logs -f mcbds-api
```

You should see output like:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://[::]:8081
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://[::]:8080
```

---

### Step 3: Verify HTTPS is Working

```bash
# Test HTTP (should still work)
curl http://localhost:8080/api/runner/status

# Test HTTPS (use -k to ignore self-signed cert warning)
curl -k https://localhost:8081/api/runner/status

# Test from external IP
curl -k https://YOUR_SERVER_IP:8081/api/runner/status
```

---

### Step 4: Update PublicUI.Web

In your web browser:
1. Open PublicUI.Web (e.g., `https://mc-bds.com`)
2. Click the **Server** dropdown
3. Add new server: `https://YOUR_SERVER_IP:8081`
4. Select the new HTTPS server

Or clear localStorage and reload:
```javascript
localStorage.removeItem('mcbds_server_config');
location.reload();
```

---

### Step 5: Open Firewall Port

```bash
# UFW (Ubuntu)
sudo ufw allow 8081/tcp

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

---

## Quick Reference

### Ports
| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Internal/fallback |
| 8081 | HTTPS | Web clients |

### Default Password
The default certificate password is: `McbdsApiCert123!`

You can change this in both the generation script and `docker-compose.https.yml`.

### Commands
```bash
# Start with HTTPS
docker-compose -f docker-compose.https.yml up -d

# View logs
docker logs -f mcbds-api

# Restart
docker-compose -f docker-compose.https.yml restart

# Stop
docker-compose -f docker-compose.https.yml down

# Test HTTPS
curl -k https://localhost:8081/api/runner/status
```

---

## Troubleshooting

### Certificate Not Found
```bash
docker exec mcbds-api ls -la /https/
# Should show mcbds-api.pfx
```

### Invalid Password
Ensure the password in `docker-compose.https.yml` matches what was used to create the PFX.

### Connection Refused
```bash
# Check container logs
docker logs mcbds-api

# Verify port is open
docker exec mcbds-api netstat -tlnp | grep 8081
```

### Browser Certificate Warning
This is normal for self-signed certificates. Click **Advanced** ? **Proceed anyway**.

---

## Security Notes

1. **Change the default password** for production use
2. **Self-signed certs** are only for internal use - use Let's Encrypt for public servers
3. Certificate expires in 5 years - set a reminder to renew

---

*Last Updated: January 2025*

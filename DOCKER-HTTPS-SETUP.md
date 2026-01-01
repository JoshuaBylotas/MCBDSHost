# HTTPS Setup for Docker API Server

This guide explains how to add HTTPS support to your existing MCBDS API Docker deployment using a self-signed certificate.

---

## Files Included

| File | Purpose |
|------|---------|
| `docker-compose.windows.yml` | Windows Docker with HTTPS |
| `docker-compose.linux.yml` | Linux Docker with HTTPS |
| `generate-https-cert.ps1` | Windows certificate generator |
| `generate-https-cert.sh` | Linux certificate generator |

---

## Quick Start

### Windows Server

```powershell
# 1. Generate certificate
Set-Location "C:\MCBDSHost\MCBDSHost"
.\generate-https-cert.ps1

# 2. Copy cert to deployment location
Copy-Item ".\certs\mcbds-api.pfx" "C:\MCBDSHost\certs\" -Force

# 3. Restart containers
docker compose -f docker-compose.windows.yml down
docker compose -f docker-compose.windows.yml up -d

# 4. Test HTTPS
Invoke-WebRequest -Uri "https://localhost:8081/api/runner/status" -SkipCertificateCheck
```

### Linux Server

```bash
# 1. Generate certificate
chmod +x generate-https-cert.sh
./generate-https-cert.sh

# 2. Copy cert to deployment location
sudo mkdir -p /opt/mcbdshost/certs
sudo cp ./certs/mcbds-api.pfx /opt/mcbdshost/certs/

# 3. Restart containers
docker compose -f docker-compose.linux.yml down
docker compose -f docker-compose.linux.yml up -d

# 4. Test HTTPS
curl -k https://localhost:8081/api/runner/status
```

---

## Ports Reference

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Internal/legacy API access |
| 8081 | HTTPS | Secure API access (for web clients) |
| 5000 | HTTP | Web UI |
| 19132 | UDP | Minecraft Bedrock IPv4 |
| 19133 | UDP | Minecraft Bedrock IPv6 |

---

## Certificate Password

Default password: `McbdsApiCert123!`

Change this in:
- `generate-https-cert.ps1` or `generate-https-cert.sh`
- `docker-compose.windows.yml` or `docker-compose.linux.yml`

---

## For PublicUI.Web (External Web Client)

When connecting from an HTTPS website, use:
```
https://YOUR-SERVER-IP:8081
```

**NOT** `http://...` - this will cause Mixed Content errors.

---

## Troubleshooting

### Mixed Content Error
Use `https://` URL, not `http://`

### Certificate Warning in Browser
This is normal for self-signed certs. Click **Advanced** ? **Proceed anyway**.

### Connection Refused on 8081
```bash
# Check container is running
docker ps

# Check logs
docker logs mcbds-api
```

---

*Last Updated: January 2025*

# MCBDS Manager Service Configuration Guide

This document describes all available configuration options for the MCBDS Manager API Service (`appsettings.json`).

## Table of Contents
- [Basic Configuration](#basic-configuration)
- [Network & Endpoints](#network--endpoints)
- [SSL/HTTPS Configuration](#sslhttps-configuration)
- [Minecraft Bedrock Server Settings](#minecraft-bedrock-server-settings)
- [Backup Configuration](#backup-configuration)
- [Xbox Live Integration](#xbox-live-integration)
- [Logging Configuration](#logging-configuration)
- [Security Best Practices](#security-best-practices)

---

## Basic Configuration

### Allowed Hosts
```json
{
  "AllowedHosts": "*"
}
```

**Description**: Controls which host headers the API will accept.
- `"*"` - Accept requests from any host (development/internal use)
- `"localhost;192.168.1.100"` - Restrict to specific hosts (production)

**Recommendation**: Use `"*"` for internal networks, restrict for internet-facing deployments.

---

## Network & Endpoints

### HTTP Endpoint (Required)
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:8080"
      }
    }
  }
}
```

**Parameters**:
- `0.0.0.0` - Bind to all network interfaces (allows remote access)
- `localhost` - Local access only
- `8080` - Port number (configurable, must match firewall rules)

**Example Configurations**:
```json
// Local access only
"Http": {
  "Url": "http://localhost:8080"
}

// Specific IP binding
"Http": {
  "Url": "http://192.168.1.100:8080"
}
```

### HTTPS Endpoint (Optional)
```json
{
  "Kestrel": {
    "Endpoints": {
      "Https": {
        "Url": "https://0.0.0.0:8081",
        "Certificate": {
          "Path": "C:/path/to/certificate.pfx",
          "Password": "YourSecurePassword"
        }
      }
    }
  }
}
```

**Parameters**:
- `Url` - HTTPS binding (typically port 443 or 8081)
- `Certificate.Path` - Absolute path to PFX certificate file
- `Certificate.Password` - Certificate password (store securely!)

**When to Use HTTPS**:
- ? Remote access over internet
- ? Production deployments
- ? Sensitive player data access
- ? Not required for localhost-only access

---

## SSL/HTTPS Configuration

### Creating a Self-Signed Certificate

**For Development/Testing**:
```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate `
    -Subject "CN=MCBDS-API" `
    -DnsName "localhost", "your-server-name" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

# Export to PFX
$password = ConvertTo-SecureString -String "YourPassword123!" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "C:\certs\mcbds-api.pfx" -Password $password
```

**For Production**:
- Use a certificate from a trusted Certificate Authority (CA)
- Consider Let's Encrypt for free SSL certificates
- Store certificates in a secure location with restricted permissions

### Certificate File Permissions
```powershell
# Restrict access to certificate file (Windows)
icacls "C:\certs\mcbds-api.pfx" /inheritance:r
icacls "C:\certs\mcbds-api.pfx" /grant:r "NETWORK SERVICE:(R)"
icacls "C:\certs\mcbds-api.pfx" /grant:r "Administrators:(F)"
```

---

## Minecraft Bedrock Server Settings

```json
{
  "Runner": {
    "ExePath": "C:/path/to/bedrock_server.exe",
    "LogFilePath": "C:/path/to/logs/api.log"
  }
}
```

### ExePath (Required)
**Description**: Absolute path to the Minecraft Bedrock Dedicated Server executable.

**Default Installer Path**: 
```
C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe
```

**Requirements**:
- ? Must point to `bedrock_server.exe` (Windows) or `bedrock_server` (Linux)
- ? All bedrock server files must be in the same directory
- ? Service account must have read/execute permissions

**Download Bedrock Server**:
- Official: https://www.minecraft.net/en-us/download/server/bedrock
- Extract all files to the specified directory

### LogFilePath (Required)
**Description**: Location where the MCBDS Manager API logs will be written.

**Default Path**:
```
C:/Program Files/MCBDS Manager/logs/api.log
```

**Log Rotation**: Logs are automatically rotated by the service. Old logs are preserved with timestamps.

---

## Backup Configuration

```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:/path/to/backups",
    "MaxBackupsToKeep": 30
  }
}
```

### FrequencyMinutes
**Description**: How often to automatically backup the Minecraft world.

**Values**:
- Minimum: `5` (not recommended, high disk I/O)
- Default: `30` (recommended)
- Maximum: `1440` (24 hours)

**Example**:
```json
"FrequencyMinutes": 60  // Backup every hour
```

### BackupDirectory
**Description**: Location where world backups are stored.

**Default Path**:
```
C:/Program Files/MCBDS Manager/backups
```

**Requirements**:
- ? Service account must have write permissions
- ? Sufficient disk space for multiple backups
- ? Consider using a separate drive for large worlds

**Disk Space Calculation**:
```
Space Needed = World Size × MaxBackupsToKeep
Example: 500 MB world × 30 backups = 15 GB
```

### MaxBackupsToKeep
**Description**: Maximum number of backup copies to retain. Oldest backups are automatically deleted.

**Recommendations**:
- Small worlds (< 100 MB): `50-100` backups
- Medium worlds (100-500 MB): `30-50` backups
- Large worlds (> 500 MB): `10-30` backups

**Example**:
```json
"MaxBackupsToKeep": 20  // Keep last 20 backups
```

---

## Xbox Live Integration

```json
{
  "XboxLive": {
    "ApiKey": "your-api-key-here",
    "ApiBaseUrl": "https://xbl.io/api/v2",
    "EnableCaching": true,
    "CacheExpirationMinutes": 1440
  }
}
```

### ApiKey (Required for Xbox Live features)
**Description**: API key for Xbox Live player data lookups.

**Obtain API Key**:
1. Visit: https://xbl.io
2. Create account and generate API key
3. Copy key to configuration

**Features Enabled**:
- ? Player Gamertag lookup
- ? Player profile information
- ? Achievement data
- ? Xbox Live presence

**Security**:
```json
// ? DO NOT commit API keys to version control
// ? Use environment variables or secure storage
"ApiKey": "%XBOX_API_KEY%"
```

### ApiBaseUrl
**Description**: Xbox Live API endpoint.

**Default**: `https://xbl.io/api/v2`

**Note**: Do not change unless using a different Xbox API provider.

### EnableCaching
**Description**: Cache Xbox Live API responses to reduce API calls and improve performance.

**Values**:
- `true` - Enable caching (recommended)
- `false` - Disable caching (higher API usage)

**Benefits of Caching**:
- ? Reduced API quota consumption
- ? Faster response times
- ? Lower latency for repeated requests

### CacheExpirationMinutes
**Description**: How long to cache Xbox Live data before refreshing.

**Recommendations**:
- `1440` (24 hours) - Player profiles (default)
- `60` - Real-time presence data
- `10080` (7 days) - Achievement data

**Example**:
```json
"CacheExpirationMinutes": 720  // 12 hours
```

---

## Logging Configuration

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

### Log Levels

| Level | Description | When to Use |
|-------|-------------|-------------|
| `Trace` | Extremely detailed logs | Deep debugging |
| `Debug` | Detailed application flow | Development |
| `Information` | General informational messages | Production (default) |
| `Warning` | Unexpected events that don't stop execution | Production |
| `Error` | Errors and exceptions | Always enabled |
| `Critical` | Fatal errors causing shutdown | Always enabled |
| `None` | No logging | Not recommended |

### Recommended Configurations

**Development**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  }
}
```

**Production**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

**Troubleshooting**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Debug",
      "MCBDS": "Trace"
    }
  }
}
```

---

## Security Best Practices

### 1. Certificate Security
```powershell
# ? DO: Store certificates in protected directory
C:/ProgramData/MCBDS/certs/

# ? DON'T: Store in web-accessible directory
C:/inetpub/wwwroot/certs/  # NEVER!

# ? DO: Use strong passwords
"Password": "P@ssw0rd123!ComplexSecure"

# ? DON'T: Use weak or default passwords
"Password": "password"  # NEVER!
```

### 2. API Key Security
```json
// ? DON'T: Hardcode in appsettings.json
{
  "XboxLive": {
    "ApiKey": "actual-key-visible-in-file"
  }
}

// ? DO: Use environment variables
{
  "XboxLive": {
    "ApiKey": "%XBOX_API_KEY%"
  }
}
```

**Set Environment Variable**:
```powershell
# System-wide (requires admin)
[System.Environment]::SetEnvironmentVariable("XBOX_API_KEY", "your-key-here", "Machine")

# Restart service to apply
Restart-Service MCBDSAPIService
```

### 3. File Permissions

**Windows**:
```powershell
# Configuration files - Read only for service account
icacls "C:\Program Files\MCBDS Manager\appsettings.json" /grant "NETWORK SERVICE:(R)"

# Data directories - Read/Write for service account
icacls "C:\Program Files\MCBDS Manager\backups" /grant "NETWORK SERVICE:(M)"
```

**Linux**:
```bash
# Configuration files
chmod 640 /opt/mcbds/appsettings.json
chown mcbds:mcbds /opt/mcbds/appsettings.json

# Data directories
chmod 750 /opt/mcbds/backups
chown mcbds:mcbds /opt/mcbds/backups
```

### 4. Network Security

**Firewall Rules (Windows)**:
```powershell
# HTTP only (local network)
New-NetFirewallRule -DisplayName "MCBDS API HTTP" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# HTTPS (internet-facing)
New-NetFirewallRule -DisplayName "MCBDS API HTTPS" -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow

# Restrict to specific subnet
New-NetFirewallRule -DisplayName "MCBDS API" -Direction Inbound -Protocol TCP -LocalPort 8080 -RemoteAddress 192.168.1.0/24 -Action Allow
```

### 5. Least Privilege

**Service Account Permissions**:
- ? Read: Configuration files, bedrock server executable
- ? Write: Logs directory, backups directory
- ? No admin rights required
- ? No write access to program files directory

---

## Example Configurations

### Minimal Configuration (HTTP only, no Xbox Live)
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "Urls": "http://localhost:8080",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:8080"
      }
    }
  },
  "Runner": {
    "ExePath": "C:/Program Files/MCBDS Manager/Binaries/bedrock_server.exe",
    "LogFilePath": "C:/Program Files/MCBDS Manager/logs/api.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:/Program Files/MCBDS Manager/backups",
    "MaxBackupsToKeep": 30
  }
}
```

### Production Configuration (HTTPS + Xbox Live)
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "mcbds.yourdomain.com",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:8080"
      },
      "Https": {
        "Url": "https://0.0.0.0:443",
        "Certificate": {
          "Path": "C:/ProgramData/MCBDS/certs/production.pfx",
          "Password": "%CERT_PASSWORD%"
        }
      }
    }
  },
  "Runner": {
    "ExePath": "C:/GameServers/Bedrock/bedrock_server.exe",
    "LogFilePath": "C:/GameServers/Logs/mcbds-api.log"
  },
  "Backup": {
    "FrequencyMinutes": 60,
    "BackupDirectory": "D:/Backups/MCBDS",
    "MaxBackupsToKeep": 48
  },
  "XboxLive": {
    "ApiKey": "%XBOX_API_KEY%",
    "ApiBaseUrl": "https://xbl.io/api/v2",
    "EnableCaching": true,
    "CacheExpirationMinutes": 1440
  }
}
```

### Development Configuration
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "Urls": "http://localhost:5000",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://localhost:5000"
      }
    }
  },
  "Runner": {
    "ExePath": "C:/Dev/bedrock-server/bedrock_server.exe",
    "LogFilePath": "C:/Dev/logs/api.log"
  },
  "Backup": {
    "FrequencyMinutes": 15,
    "BackupDirectory": "C:/Dev/backups",
    "MaxBackupsToKeep": 10
  },
  "XboxLive": {
    "ApiKey": "dev-api-key",
    "ApiBaseUrl": "https://xbl.io/api/v2",
    "EnableCaching": false,
    "CacheExpirationMinutes": 5
  }
}
```

---

## Troubleshooting

### Service Won't Start

**Check Configuration Syntax**:
```powershell
# Validate JSON syntax
Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
```

**Check Service Logs**:
```powershell
# View service logs
Get-Content "C:\Program Files\MCBDS Manager\logs\api.log" -Tail 50
```

### HTTPS Certificate Errors

**Verify Certificate**:
```powershell
# Check certificate validity
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\path\to\cert.pfx", "password")
$cert | Format-List Subject, NotAfter, HasPrivateKey
```

**Common Issues**:
- ? Certificate expired (`NotAfter` in the past)
- ? Missing private key (`HasPrivateKey = False`)
- ? Wrong password
- ? File permissions (service account can't read file)

### Backup Not Working

**Check Disk Space**:
```powershell
Get-PSDrive C | Select-Object Free
```

**Check Permissions**:
```powershell
# Test write access
Test-Path "C:\Program Files\MCBDS Manager\backups" -PathType Container
```

---

## Configuration File Location

**Default Installation**:
```
C:\Program Files\MCBDS Manager\appsettings.json
```

**After Configuration Changes**:
```powershell
# Restart service to apply changes
Restart-Service MCBDSAPIService

# Verify service is running
Get-Service MCBDSAPIService
```

---

## Support

For additional help:
- ?? Main Documentation: `README.md`
- ?? Installation Guide: `INSTALLATION-GUIDE.md`
- ?? Issue Tracker: https://github.com/JoshuaBylotas/MCBDSHost/issues

---

**Last Updated**: 2025-01-16  
**Version**: 1.0

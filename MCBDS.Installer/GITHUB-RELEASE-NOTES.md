# MCBDS API Service Installer - Release Guide

## Overview

The MCBDS API Service Installer is a standalone Windows executable that provides the fastest and simplest way to deploy Minecraft Bedrock Dedicated Server management on Windows systems.

**Current Version:** 1.0.1  
**Release Date:** January 2025  
**Platform:** Windows 64-bit (Windows 10+, Windows Server 2016+)

---

## What's Included

### Installation Package
- **File:** `MCBDS.API.Service.Installer.exe`
- **Size:** ~50MB (includes .NET 10 runtime)
- **Type:** NSIS (Nullsoft Scriptable Install System)

### Components
- ? MCBDS API Service (.NET 10)
- ? Windows Service Registration
- ? Automatic Startup Configuration
- ? Windows Firewall Rule Setup
- ? Configuration File Generation
- ? Bedrock Server Integration

---

## Installation Overview

### Minimum Requirements
- **OS:** Windows 10 (Build 1909+) or Windows Server 2016+
- **RAM:** 4GB minimum
- **CPU:** 2 cores minimum
- **Disk Space:** 10GB free
- **Network:** Internet connection for initial download

### Recommended Specification
- **OS:** Windows 11 or Windows Server 2022+
- **RAM:** 8GB+
- **CPU:** 4+ cores
- **Disk Space:** 20GB+ (SSD preferred)
- **Network:** Stable, low-latency connection

---

## Installation Steps

### Quick Start (5-10 minutes)

1. **Download Installer**
   - Download `MCBDS.API.Service.Installer.exe` from releases
   - Right-click ? "Run as administrator"

2. **Follow Setup Wizard**
   - Configure storage paths (Binaries, Logs, Backups)
   - Set HTTP port (default: 8080)
   - Configure backup frequency (default: 30 minutes)
   - Download Minecraft Bedrock Server

3. **Complete Installation**
   - Installer verifies bedrock_server.exe
   - Registers Windows Service
   - Configures Firewall rules
   - Starts service automatically

4. **Access Management Interface**
   - Open browser to `http://localhost:8080`
   - Or access from another machine: `http://<server-ip>:8080`

---

## Configuration

### Default Settings
After installation, configure MCBDS by editing:
```
C:\Program Files\MCBDS API Service\appsettings.json
```

### Key Configuration Options

**HTTP Port:**
```json
"Urls": "http://0.0.0.0:8080"
```
Change `8080` to use a different port.

**Backup Settings:**
```json
"Backup": {
  "FrequencyMinutes": 30,
  "BackupDirectory": "C:/Program Files/MCBDS API Service/backups",
  "MaxBackupsToKeep": 30
}
```

**Bedrock Server Path:**
```json
"Runner": {
  "ExePath": "C:/Program Files/MCBDS API Service/Binaries/bedrock_server.exe",
  "LogFilePath": "C:/Program Files/MCBDS API Service/logs/api.log"
}
```

**After editing, restart the service:**
1. Open Services (Win + R ? `services.msc`)
2. Find "MCBDS API Service"
3. Right-click ? Restart

---

## Features

### Automatic Updates
- Service automatically restarts if system reboots
- Periodic backup system with configurable frequency
- Backup rotation (keeps only specified number of backups)

### Management Interface
- Web-based dashboard at http://localhost:8080
- Server status monitoring
- World backup management
- Server properties configuration
- Real-time server logs

### Security Features
- Firewall rules automatically configured
- Administrator rights required for installation
- Service runs with minimal required permissions
- Configuration files use JSON with variable substitution

### Reliability
- Automatic crash detection and restart
- Built-in error logging
- Windows Service integration for OS-level control
- Persistent configuration across reboots

---

## Troubleshooting

### Service Won't Start
**Check:**
1. Verify `bedrock_server.exe` exists in configured Binaries location
2. Check log file: `C:\Program Files\MCBDS API Service\logs\api.log`
3. Open Event Viewer ? Windows Logs ? Application for .NET errors
4. Ensure .NET 10 Runtime is installed

**Common Fixes:**
```powershell
# Check service status
Get-Service -Name MCBDSAPIService

# View service logs
Get-Content "C:\Program Files\MCBDS API Service\logs\api.log" -Tail 50

# Restart service
Restart-Service -Name MCBDSAPIService -Force
```

### Port Already in Use
**Solution:**
1. Edit `appsettings.json`
2. Change port in `"Urls"` line
3. Restart service from Services.msc

**Find what's using a port:**
```powershell
netstat -ano | findstr :8080
```

### Can't Access from Another Computer
**Check:**
1. Verify server's IP address: `ipconfig`
2. Ensure Windows Firewall allows port (installer does this automatically)
3. Try accessing locally first: `http://localhost:8080`
4. Confirm both machines on same network
5. Check firewall rule: `New-NetFirewallRule -Name "MCBDS API" -DisplayName "MCBDS API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow`

---

## Uninstallation

### Remove the Service

**Via Installer:**
```powershell
cd "C:\Program Files\MCBDS API Service"
.\MCBDS.WindowsService.exe uninstall
```

**Via Control Panel:**
1. Settings ? Apps ? Apps & features
2. Search "MCBDS"
3. Click ? Uninstall
4. Follow uninstaller prompts

**Manual Cleanup:**
```powershell
# Stop service
net stop MCBDSAPIService

# Uninstall service
sc delete MCBDSAPIService

# Remove directory
Remove-Item -Path "C:\Program Files\MCBDS API Service" -Recurse -Force
```

---

## Architecture

### Service Architecture
```
Windows Service (MCBDS.WindowsService.exe)
??? ASP.NET Core Web API (Kestrel on port 8080)
??? Runner Hosted Service (Manages bedrock_server.exe)
??? Backup Hosted Service (Automatic world backups)
??? Configuration Management (appsettings.json)
```

### Folder Structure
```
C:\Program Files\MCBDS API Service\
??? MCBDS.WindowsService.exe         (Main service executable)
??? MCBDS.API.dll                     (API library)
??? appsettings.json                  (Main configuration)
??? appsettings.user.json             (User overrides)
??? Binaries/
?   ??? bedrock_server.exe            (Minecraft server)
?   ??? bedrock_server.exe.pdb        (Debug symbols)
?   ??? ...other bedrock files...
??? logs/
?   ??? api.log                       (Service logs)
??? backups/
    ??? world_backup_[timestamp].zip  (World backups)
```

---

## Comparison: Installer vs. Docker

| Feature | Installer | Docker |
|---------|-----------|--------|
| **Setup Time** | 5-10 minutes | 15-20 minutes |
| **Complexity** | Very Simple | Moderate |
| **Best For** | Windows Servers | Linux, Cloud, Enterprise |
| **Performance** | Native (no overhead) | Container overhead |
| **Support** | Primary | Community |
| **Auto-restart** | Yes (Windows Service) | Yes (with compose) |
| **Scaling** | Single machine | Multi-container |

---

## Supported Platforms

### Operating Systems
- ? Windows 10 (Build 1909+)
- ? Windows 11
- ? Windows Server 2016+
- ? Windows Server 2019
- ? Windows Server 2022

### Minecraft Bedrock Versions
- Compatible with Minecraft Bedrock Dedicated Server (all recent versions)
- Auto-detection of bedrock_server.exe
- Support for custom server properties

---

## Development Information

### Building from Source
```powershell
# Clone repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Build installer
.\MCBDS.Installer\build-installer.ps1

# Output: MCBDS.API.Service.Installer.exe
```

### Prerequisites for Building
- Windows 10+ with NSIS installed
- .NET 10 SDK
- Visual Studio 2022+ (optional but recommended)

### Build Process
1. Compiles MCBDS.WindowsService in Release mode
2. Bundles published binaries
3. Generates NSIS installer script
4. Creates signed executable

---

## FAQ

**Q: Can I run multiple instances?**  
A: The current installer creates a single service. For multiple instances, either deploy multiple machines or use Docker.

**Q: Does it support HTTPS?**  
A: The installer uses HTTP by default. For HTTPS, use a reverse proxy (nginx, IIS) in front of the service.

**Q: Can I change the installation path?**  
A: Yes, the installer allows customizing the installation directory and path locations.

**Q: What if bedrock_server.exe is missing?**  
A: The installer verifies the executable exists. Download from Minecraft.net and extract to the configured Binaries location.

**Q: How do I update MCBDS?**  
A: Uninstall the old version and run the new installer. Configuration and world data are preserved.

**Q: Is there cloud backup support?**  
A: The installer creates local backups. For cloud backups, configure the backup directory on a cloud-synced drive (OneDrive, etc.).

---

## Support & Documentation

### Online Resources
- **Official Website:** https://www.mc-bds.com
- **GitHub Repository:** https://github.com/JoshuaBylotas/MCBDSHost
- **Installation Guide:** https://www.mc-bds.com/installer
- **Documentation:** https://www.mc-bds.com/docs

### Getting Help
1. Check [Installation Guide](https://www.mc-bds.com/installer) for common issues
2. Review [Troubleshooting Section](#troubleshooting) above
3. Check GitHub Issues for known problems
4. Contact support at https://www.mc-bds.com/contact

---

## Version History

### v1.0.1 (Current - January 2025)
- ? Initial stable release
- ? Windows Service integration
- ? Automatic backup system
- ? Web-based management interface
- ? Firewall configuration automation

### Future Roadmap
- HTTPS support
- Multiple instance support
- Cloud backup integration
- Advanced monitoring and metrics

---

## License

MCBDS API Service is open source and available under the MIT License.  
See LICENSE file in repository for details.

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with description

Visit https://github.com/JoshuaBylotas/MCBDSHost for contribution guidelines.

---

**Last Updated:** January 2025  
**Maintainer:** Joshua Bylotas  
**Repository:** https://github.com/JoshuaBylotas/MCBDSHost

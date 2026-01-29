# NSIS Installer - Quick Reference

## One-Command Installation

```powershell
# First time only - install NSIS from: https://nsis.sourceforge.io/

# Then build the installer:
.\MCBDS.Installer\build-installer.ps1
```

Output: `MCBDS.API.Service.Installer.exe`

---

## File Quick Links

| Purpose | File |
|---------|------|
| **Build Automation** | `build-installer.ps1` |
| **Installer Definition** | `MCBDSInstaller.nsi` |
| **Setup Instructions** | `INSTALLER-SETUP-GUIDE.md` |
| **End-User Guide** | `NSIS-README.md` |
| **Overview** | `NSIS-MIGRATION-SUMMARY.md` |
| **Service Code** | `MCBDS.WindowsService/Program.cs` |

---

## Default Settings

```
Service Name:      MCBDSAPIService
Display Name:      MCBDS API Service
Port:              8080 (HTTP)
Install Location:  C:\Program Files\MCBDS API Service
Auto-Start:        Yes
Firewall Rule:     TCP port 8080 inbound
```

---

## Service Management Commands

```powershell
# Start service
net start MCBDSAPIService

# Stop service
net stop MCBDSAPIService

# Check status
Get-Service MCBDSAPIService

# Restart
net stop MCBDSAPIService
net start MCBDSAPIService
```

---

## Installation Methods

### Interactive (Recommended for users)
```powershell
# Right-click installer, select "Run as Administrator"
# or
.\MCBDS.API.Service.Installer.exe
```

### Silent (For automation)
```powershell
MCBDS.API.Service.Installer.exe /S /D=C:\MCBDS
# /S = Silent mode
# /D = Custom install directory
```

---

## Verify Installation

```powershell
# Check service exists
Get-Service MCBDSAPIService

# Check firewall rule
netsh advfirewall firewall show rule all | findstr MCBDS

# Test API endpoint
curl http://localhost:8080/health

# View logs
Get-Content "C:\Program Files\MCBDS API Service\logs\runner.log" -Tail 50
```

---

## Customize Before Building

### Change Installation Directory
Edit `MCBDSInstaller.nsi` line 28:
```nsi
InstallDir "$PROGRAMFILES64\Your\Custom\Path"
```

### Change Service Name
Edit `MCBDSInstaller.nsi` and `Program.cs`:
```nsi
; In MCBDSInstaller.nsi
ServiceName = "YourServiceName"

# In Program.cs
private const string ServiceName = "YourServiceName";
```

### Change Port
Edit `Program.cs` and `appsettings.json`:
```csharp
serverOptions.ListenAnyIP(8081); // Change port
```

---

## Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| NSIS not found | Install from https://nsis.sourceforge.io/ |
| Build fails | Run PowerShell as Administrator |
| Service won't start | Check Event Viewer, verify port not in use |
| No network access | `netsh advfirewall firewall show rule all \| findstr MCBDS` |
| Large installer | Use `--no-self-contained` flag (requires .NET installed) |

---

## Build from Scratch (Manual)

```powershell
# 1. Publish the service
dotnet publish MCBDS.WindowsService\MCBDS.WindowsService.csproj `
  -c Release -r win-x64 --self-contained

# 2. Build installer (adjust path if needed)
& "C:\Program Files (x86)\NSIS\makensis.exe" "MCBDS.Installer\MCBDSInstaller.nsi"

# 3. Result: MCBDS.API.Service.Installer.exe
```

---

## NSIS Documentation

- **Official**: https://nsis.sourceforge.io/
- **Docs**: https://nsis.sourceforge.io/Docs/
- **Examples**: https://nsis.sourceforge.io/Examples

---

## Key Advantages Over WiX

? **Free** - No licensing costs  
? **Simple** - Easy to understand scripts  
? **Small** - Lightweight installer  
? **Active** - Regular updates  
? **Fast** - Quick builds  
? **Windows Service Ready** - Built-in support  

---

## Environment Requirements

**Development Machine**:
- Windows 10/11 (for admin rights)
- .NET 10 SDK installed
- NSIS v3.09+ installed
- PowerShell 5.0+

**Target Machine** (running the service):
- Windows Server 2016+ or Windows 10+
- Administrator privileges (for installation)
- Port 8080 available
- ~150MB disk space (includes .NET runtime)

---

## Production Release Checklist

- [ ] Tested on clean Windows machine
- [ ] Service starts automatically on boot
- [ ] Firewall rule applied correctly
- [ ] API responds on port 8080
- [ ] Uninstaller removes all files
- [ ] No registry entries left after uninstall
- [ ] Version numbers updated
- [ ] Installer signed (optional, for trusted distribution)
- [ ] Documentation updated
- [ ] Changes committed to git

---

**Need help?** See `INSTALLER-SETUP-GUIDE.md` for detailed instructions.

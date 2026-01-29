# GitHub Release Publishing Template

Use this template when creating a new release on GitHub for the MCBDS API Service Installer.

---

## Release Title
```
MCBDS API Service Installer v1.0.1
```

## Release Description (Paste Below)

### ?? MCBDS API Service Installer

**The fastest way to deploy Minecraft Bedrock Server management on Windows!**

#### ? Features
- ? **One-Click Setup** - Installation in 5-10 minutes
- ?? **Windows Native** - Runs as a Windows Service
- ?? **Auto-Restart** - Automatically starts on system reboot
- ?? **Automatic Backups** - Configurable world backup system
- ?? **Web Dashboard** - Manage your server from any browser
- ??? **Secure** - Administrator-verified installation process

#### ?? System Requirements
- **OS:** Windows 10 (Build 1909+) or Windows Server 2016+
- **RAM:** 4GB minimum (8GB recommended)
- **CPU:** 2 cores minimum (4+ recommended)
- **Disk Space:** 10GB free
- **Network:** Internet connection

#### ?? What's Included
- MCBDS API Service (.NET 10)
- ASP.NET Core Web Dashboard (runs on port 8080)
- Windows Service Integration
- Automatic Firewall Configuration
- Bedrock Server Management Tools

#### ?? Quick Start
1. **Download** `MCBDS.API.Service.Installer.exe`
2. **Run as Administrator** (right-click ? Run as administrator)
3. **Follow Setup Wizard** (~5-10 minutes)
4. **Access Dashboard** at http://localhost:8080

#### ?? Documentation
- [Installation Guide](https://www.mc-bds.com/installer)
- [Full Documentation](https://www.mc-bds.com/docs)
- [Troubleshooting](https://www.mc-bds.com/installer#troubleshooting)
- [GitHub Repository](https://github.com/JoshuaBylotas/MCBDSHost)

#### ?? Configuration
After installation, customize settings in:
```
C:\Program Files\MCBDS API Service\appsettings.json
```

- Change API port (default: 8080)
- Configure backup frequency (default: 30 minutes)
- Set maximum backups to keep (default: 30)

#### ?? Known Issues
None reported yet. Please report any issues on GitHub.

#### ?? Release Notes
**v1.0.1 - Current Release**
- Initial stable release
- Full Windows Service integration
- Automatic backup system
- Web-based management interface
- Firewall configuration automation

---

## Assets Section

### File Upload
Upload this file with the release:
- `MCBDS.API.Service.Installer.exe` (~50MB)

### Asset Details
```
Name: MCBDS.API.Service.Installer.exe
Type: Windows 64-bit Executable
Size: ~50MB (includes .NET 10 runtime)
Version: 1.0.1
```

---

## Release Notes Checkbox

Before publishing, verify:
- [ ] Tested installer on Windows 10/11
- [ ] Tested installer on Windows Server
- [ ] Verified bedrock_server.exe integration
- [ ] Confirmed Windows Service registration
- [ ] Tested firewall rule creation
- [ ] Verified backup system works
- [ ] Web dashboard accessible at http://localhost:8080
- [ ] Documentation updated
- [ ] GITHUB-RELEASE-NOTES.md updated
- [ ] Version number matches (v1.0.1)

---

## Tags
- `windows`
- `installer`
- `bedrock-server`
- `minecraft`
- `management`
- `windows-service`

---

## Release Type
- **[ ]** Pre-release
- **[x]** Latest release

---

## Publishing Instructions

### Step 1: Prepare Files
```powershell
# Build installer
.\MCBDS.Installer\build-installer.ps1

# Verify output
Test-Path ".\MCBDS.API.Service.Installer.exe"
```

### Step 2: Create GitHub Release
1. Go to https://github.com/JoshuaBylotas/MCBDSHost/releases
2. Click "Draft a new release"
3. Set tag: `v1.0.1`
4. Set title: `MCBDS API Service Installer v1.0.1`
5. Paste release description (above)
6. Upload `MCBDS.API.Service.Installer.exe`

### Step 3: Publish
1. Click "Publish release"
2. Monitor for any issues reported by users
3. Update documentation if needed

### Step 4: Announcement (Optional)
Share release on:
- Twitter/X: `https://twitter.com/MCBDSHost`
- Reddit: r/Minecraft
- MinecraftForums
- Discord communities

---

## Alternative Deployment Methods

Users wanting other deployment options:
- **Docker:** See [Get Started](https://www.mc-bds.com/get-started) page
- **Manual Setup:** See [Full Documentation](https://www.mc-bds.com/docs)
- **Cloud Deployment:** Docker image available

---

## Support Resources

Direct users to:
- **Issues:** https://github.com/JoshuaBylotas/MCBDSHost/issues
- **Website:** https://www.mc-bds.com
- **Contact:** https://www.mc-bds.com/contact
- **Docs:** https://www.mc-bds.com/docs

---

## Version Numbering

- **Major:** Breaking changes (e.g., 2.0.0)
- **Minor:** New features (e.g., 1.1.0)
- **Patch:** Bug fixes (e.g., 1.0.1)

---

## Next Release Checklist

For v1.0.2 or later:

- [ ] Update version in all files
- [ ] Update GITHUB-RELEASE-NOTES.md
- [ ] Test on multiple Windows versions
- [ ] Update documentation
- [ ] Create release tag
- [ ] Build installer
- [ ] Create GitHub release
- [ ] Announce update

---

**Release Template Version:** 1.0  
**Last Updated:** January 2025  
**Maintainer:** Joshua Bylotas

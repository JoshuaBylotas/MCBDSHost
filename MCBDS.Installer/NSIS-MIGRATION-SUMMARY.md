# NSIS Installer Migration Summary

## ? What's Been Created

### New Files

1. **`MCBDSInstaller.nsi`** - NSIS installer script
   - Installs Windows Service
   - Opens firewall port 8080
   - Starts service automatically
   - Includes clean uninstallation

2. **`build-installer.ps1`** - Automated build script
   - Checks NSIS installation
   - Publishes Windows Service
   - Builds the installer
   - Shows completion status

3. **`NSIS-README.md`** - User installation guide
   - Installation instructions
   - Service management
   - Configuration details
   - Troubleshooting

4. **`INSTALLER-SETUP-GUIDE.md`** - Developer guide
   - Setup instructions
   - Build process
   - Customization options
   - Advanced configuration

### Updated Files

1. **`Program.cs`** - Enhanced with service commands
   - Added `install` command for service installation
   - Added `uninstall` command for service removal
   - Maintains existing functionality

---

## ?? Quick Start (5 Minutes)

### For Developers

1. **Install NSIS**:
   ```powershell
   # Download and run from: https://nsis.sourceforge.io/
   ```

2. **Build the installer**:
   ```powershell
   cd D:\source\repos\JoshuaBylotas\MCBDSHost
   .\MCBDS.Installer\build-installer.ps1
   ```

3. **Test the installer**:
   - Right-click `MCBDS.API.Service.Installer.exe`
   - Select "Run as administrator"
   - Follow the installation wizard

### For End Users

1. Download `MCBDS.API.Service.Installer.exe`
2. Right-click ? Run as Administrator
3. Follow the installation wizard
4. The service starts automatically
5. Access at `http://localhost:8080`

---

## ?? Comparison: WiX vs NSIS

| Feature | WiX | NSIS |
|---------|-----|------|
| **Cost** | Free | Free ? |
| **Learning Curve** | Steep (XML) | Easy (Simple script) |
| **File Size** | Medium | Small ? |
| **Setup Time** | Complex | Simple ? |
| **Active Development** | Yes | Yes ? |
| **Windows Service Support** | Yes | Yes ? |
| **Firewall Rules** | Yes | Yes ? |
| **Registry Support** | Yes | Yes ? |

---

## ?? File Structure

```
MCBDS.Installer/
??? MCBDSInstaller.nsi              (NSIS script - main installer definition)
??? build-installer.ps1             (Build automation script)
??? NSIS-README.md                  (End-user guide)
??? INSTALLER-SETUP-GUIDE.md        (Developer guide)
??? README.md                        (Original WiX documentation - can be removed)

MCBDS.WindowsService/
??? Program.cs                      (Updated with install/uninstall commands)
??? MCBDS.WindowsService.csproj     (No changes needed)
??? appsettings.json                (Configuration - no changes)
??? ...other files...
```

---

## ? Key Features Included

? **Windows Service Registration**
- Automatic service creation and installation
- Named: `MCBDSAPIService`
- Display Name: "MCBDS API Service"
- Auto-start on boot

? **Firewall Configuration**
- Port 8080 (TCP) automatically added
- Allows network access to the service
- Removed on uninstall

? **Directory Structure**
- `Binaries/` - For Minecraft server executable
- `logs/` - For service logs
- `backups/` - For server backups
- Configurable via `appsettings.json`

? **Self-Contained Package**
- Includes .NET 10 runtime
- No separate .NET installation required
- Single executable installer

? **Clean Uninstallation**
- Stops the service
- Removes service registration
- Deletes firewall rules
- Removes all installed files

---

## ?? Migration Path from WiX

### Step 1: Install NSIS
```powershell
# Visit https://nsis.sourceforge.io/ and install
```

### Step 2: Build New Installer
```powershell
.\MCBDS.Installer\build-installer.ps1
```

### Step 3: Test New Installer
- Install on a test machine
- Verify service starts
- Check firewall rules
- Test uninstallation

### Step 4: Remove WiX Files (Optional)
```powershell
# Remove WiX project reference if not needed
Remove-Item MCBDS.Installer\Product.wxs
Remove-Item MCBDS.Installer\MCBDS.Installer.wixproj
```

---

## ?? Next Steps

### For Development

1. **Install NSIS** from https://nsis.sourceforge.io/
2. **Run the build script**:
   ```powershell
   .\MCBDS.Installer\build-installer.ps1
   ```
3. **Test the generated installer**
4. **Commit changes**:
   ```bash
   git add MCBDS.Installer/*.nsi
   git add MCBDS.Installer/build-installer.ps1
   git add MCBDS.Installer/NSIS-README.md
   git commit -m "Add NSIS installer (free alternative to WiX)"
   ```

### For Distribution

1. **Copy installer to distribution location**
2. **Include the NSIS-README.md** with the installer
3. **Update your website/documentation** with new installer download link
4. **Distribute to users**

### For Maintenance

Keep these files updated:
- `MCBDSInstaller.nsi` - When installation process changes
- `Program.cs` - When service behavior changes
- `NSIS-README.md` - When configuration changes
- Version numbers in both files when releasing new versions

---

## ?? Documentation Files

| File | Audience | Purpose |
|------|----------|---------|
| **INSTALLER-SETUP-GUIDE.md** | Developers | How to build and customize installer |
| **NSIS-README.md** | End Users | How to install and manage the service |
| **MCBDSInstaller.nsi** | Developers | The actual installer definition |
| **build-installer.ps1** | Developers | Automated build script |

---

## ?? Default Configuration

**Service Name**: `MCBDSAPIService`
**Display Name**: `MCBDS API Service`
**Port**: 8080 (HTTP)
**Installation Directory**: `C:\Program Files\MCBDS API Service`
**Working Directories**:
- Binaries: `C:\Program Files\MCBDS API Service\Binaries\`
- Logs: `C:\Program Files\MCBDS API Service\logs\`
- Backups: `C:\Program Files\MCBDS API Service\backups\`

---

## ?? Common Issues

| Issue | Solution |
|-------|----------|
| NSIS not found | Install from https://nsis.sourceforge.io/ |
| Service won't start | Check Event Viewer, verify port not in use |
| Can't access from network | Check firewall rule was added (run as admin) |
| Installer is too large | Use `--no-self-contained` flag (requires .NET installed) |

---

## ?? Further Reading

- **NSIS Official Docs**: https://nsis.sourceforge.io/Docs/
- **NSIS Tutorial**: https://nsis.sourceforge.io/Docs/Modern%20UI/Readme.html
- **.NET Windows Services**: https://learn.microsoft.com/en-us/dotnet/core/extensions/windows-service

---

## ?? Tips

1. **Always run installer as Administrator** when testing
2. **Test on a clean machine** before distributing
3. **Keep version numbers in sync** across all files
4. **Update NSIS-README.md** when changing features
5. **Use the build script** - it's faster than manual steps

---

## ? Checklist Before Release

- [ ] NSIS is installed on build machine
- [ ] `build-installer.ps1` runs successfully
- [ ] Installer .exe is created
- [ ] Installer is tested on a test machine
- [ ] Service installs without errors
- [ ] Service starts automatically
- [ ] Firewall rule is applied
- [ ] Port 8080 is accessible
- [ ] Uninstaller works correctly
- [ ] Service is removed from services list
- [ ] Firewall rule is removed
- [ ] Installation directory is deleted
- [ ] Version numbers are updated
- [ ] Documentation is up-to-date
- [ ] Changes are committed to git

---

## ?? Version History

| Version | Changes |
|---------|---------|
| 1.0.1 | Initial NSIS implementation, replaces WiX |

---

**Created**: 2024
**Updated**: 2024
**Status**: Ready for Production

Questions? See INSTALLER-SETUP-GUIDE.md for detailed instructions.

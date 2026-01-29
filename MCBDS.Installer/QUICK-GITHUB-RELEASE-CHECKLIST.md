# Quick GitHub Release Checklist

Copy this checklist and use it when preparing each release.

---

## Pre-Release (1 Day Before)

- [ ] Update version number in all files
  - [ ] `MCBDS.WindowsService\MCBDS.WindowsService.csproj`
  - [ ] `MCBDS.API\MCBDS.API.csproj`
  - [ ] `MCBDS.Installer\MCBDSInstaller.nsi`
  - [ ] `GITHUB-RELEASE-NOTES.md`

- [ ] Update documentation
  - [ ] Update feature list if applicable
  - [ ] Update troubleshooting if bugs were fixed
  - [ ] Review installation steps for accuracy

- [ ] Test installer
  - [ ] Build on Windows 10
  - [ ] Build on Windows 11
  - [ ] Test installation on clean system
  - [ ] Verify Windows Service starts
  - [ ] Verify web dashboard accessible
  - [ ] Verify backup system works

---

## Release Day

### Step 1: Build Installer
```powershell
cd D:\source\repos\JoshuaBylotas\MCBDSHost
.\MCBDS.Installer\build-installer.ps1
```

**Expected Output:**
- `MCBDS.API.Service.Installer.exe` (~50MB)
- Build completes with no errors

### Step 2: Verify Build
```powershell
Test-Path ".\MCBDS.API.Service.Installer.exe"
(Get-Item ".\MCBDS.API.Service.Installer.exe").Length / 1MB  # Should be ~50MB
```

### Step 3: Create GitHub Release
1. Go to: https://github.com/JoshuaBylotas/MCBDSHost/releases
2. Click "Draft a new release"
3. **Tag version:** `v1.0.1` (match your version)
4. **Release title:** `MCBDS API Service Installer v1.0.1`
5. **Description:** Copy from `GITHUB-PUBLISHING-TEMPLATE.md`
6. **Set as Latest Release:** ? Check
7. **Upload file:** Drag & drop `MCBDS.API.Service.Installer.exe`

### Step 4: Review & Publish
- [ ] Title is correct
- [ ] Description is properly formatted
- [ ] Installer file uploaded
- [ ] Version number matches everywhere

**Click "Publish release"** ?

### Step 5: Post-Release Validation
- [ ] Release shows on GitHub releases page
- [ ] Installer file downloads correctly
- [ ] Release notes display properly
- [ ] Tags are correct

---

## Post-Release (After Publishing)

### Announcements
- [ ] Post on Twitter/X
- [ ] Post on Reddit (r/Minecraft)
- [ ] Update Discord communities
- [ ] Post on MinecraftForums (if applicable)

### Monitoring
- [ ] Monitor GitHub Issues for bug reports
- [ ] Monitor Discussions if enabled
- [ ] Check website traffic for increase
- [ ] Note any user feedback

### Documentation
- [ ] Update website if features changed
- [ ] Update CHANGELOG.md (if using one)
- [ ] Update API documentation
- [ ] Pin release announcement (if applicable)

---

## Release Announcement Template

### Twitter/X
```
?? MCBDS API Service Installer v1.0.1 is now available!

? Install in just 5-10 minutes on Windows
?? One-click Windows Service setup
?? Automatic world backups
?? Web dashboard at http://localhost:8080

Download now: https://github.com/JoshuaBylotas/MCBDSHost/releases

#Minecraft #Windows #ServerManagement
```

### Reddit (r/Minecraft)
```
[RELEASE] MCBDS API Service Installer v1.0.1 - Windows Server Management

Hello Minecraft Bedrock Server enthusiasts! 

We're excited to announce the release of MCBDS API Service Installer v1.0.1, 
the easiest way to deploy and manage Minecraft Bedrock Dedicated Server on Windows.

**Key Features:**
- One-click installation (5-10 minutes)
- Windows Service integration
- Automatic backup system
- Web-based management dashboard

**Download:** [GitHub Releases](https://github.com/JoshuaBylotas/MCBDSHost/releases)
**Documentation:** [Website](https://www.mc-bds.com)

Would love to hear your feedback!
```

---

## Common Tasks

### Check File Size
```powershell
$size = (Get-Item ".\MCBDS.API.Service.Installer.exe").Length / 1MB
Write-Host "Installer size: ${size}MB"
```

### Calculate SHA256 Hash (For integrity verification)
```powershell
Get-FileHash ".\MCBDS.API.Service.Installer.exe" -Algorithm SHA256 | Select-Object Hash
```

### Clean Build
```powershell
# Remove previous build artifacts
rm -r .\MCBDS.WindowsService\bin -Force
rm -r .\MCBDS.WindowsService\obj -Force
rm -r .\MCBDS.API\bin -Force
rm -r .\MCBDS.API\obj -Force

# Build fresh
.\MCBDS.Installer\build-installer.ps1
```

---

## Version Numbering

**Format:** `Major.Minor.Patch`

- **Major (X):** Breaking changes, architecture overhaul
  - Example: `1.0.0` ? `2.0.0`
  
- **Minor (Y):** New features, improvements
  - Example: `1.0.0` ? `1.1.0`
  
- **Patch (Z):** Bug fixes, small improvements
  - Example: `1.0.0` ? `1.0.1`

**Examples:**
- `v1.0.0` - Initial stable release
- `v1.0.1` - Bug fixes only
- `v1.1.0` - New feature: Backup scheduling
- `v2.0.0` - Complete redesign, breaking changes

---

## Rollback Procedure (If Issues Found)

If critical issues are discovered after release:

1. **Create hotfix branch**
   ```powershell
   git checkout -b hotfix/v1.0.2
   ```

2. **Fix the issue**
   - Identify root cause
   - Apply minimal fix
   - Test thoroughly

3. **Release hotfix**
   - Increment patch version
   - Create new release tag
   - Publish new installer

4. **Mark old release**
   - Edit old release on GitHub
   - Add "?? DEPRECATED - Use v1.0.2 instead"
   - Do NOT delete, just mark as old

---

## Template File Locations

**Use these files when publishing:**

1. **Release Notes:** `MCBDS.Installer\GITHUB-RELEASE-NOTES.md`
2. **Publishing Template:** `MCBDS.Installer\GITHUB-PUBLISHING-TEMPLATE.md`
3. **This Checklist:** `MCBDS.Installer\QUICK-GITHUB-RELEASE-CHECKLIST.md`

---

## Questions?

Refer to:
- **Installation Guide:** https://www.mc-bds.com/installer
- **Full Docs:** https://www.mc-bds.com/docs
- **GitHub Issues:** https://github.com/JoshuaBylotas/MCBDSHost/issues

---

**Last Updated:** January 2025  
**Frequency:** Use for every release  
**Estimated Time:** 30 minutes (including build)

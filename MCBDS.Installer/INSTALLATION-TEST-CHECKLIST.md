# Installation Test Checklist

Use this checklist after rebuilding and installing to verify all fixes are working.

## Pre-Installation

### Build Phase
- [ ] Run build script as Administrator:
  ```powershell
  Set-Location "D:\source\repos\JoshuaBylotas\MCBDSHost"
  .\MCBDS.Installer\build-installer.ps1 -IncrementVersion
  ```
- [ ] Build completes without errors
- [ ] Output shows "Build Complete!"
- [ ] Installer created in `Publish\[version]\`
- [ ] Installer file size > 5 MB
- [ ] Certificate files created in `MCBDS.Installer\`

---

## Installation Phase

### Pre-Installation Steps
- [ ] Close any running MCBDS services
- [ ] Delete previous version from `C:\Program Files\MCBDS Manager\` (if upgrading)
- [ ] Clear temp files (optional): `Remove-Item $env:TEMP\CodeSigning.* , $env:TEMP\MCBDS.PublicUI.msix`

### Run Installer
- [ ] **Right-click** installer EXE
- [ ] **Select "Run as administrator"**
- [ ] **Click "Yes"** on UAC prompt (this is CRITICAL)
- [ ] Installer launches
- [ ] Welcome screen appears
- [ ] Configuration wizard presents options:
  - [ ] HTTP Port (default: 8080)
  - [ ] Backup frequency (default: 30)
  - [ ] Max backups (default: 30)
  - [ ] Create Start Menu shortcuts
- [ ] Complete wizard and click Install
- [ ] Installation shows progress (extracts files, installs service, etc.)
- [ ] Installation completes with message about install.log

---

## Post-Installation Verification

### Check Installation Log (MOST IMPORTANT)
```powershell
Get-Content "C:\Program Files\MCBDS Manager\install.log"
```

Look for and verify these lines:
- [ ] ? "Version: [your version]"
- [ ] ? "Installation Directory: C:\Program Files\MCBDS Manager"
- [ ] ? "Extracting API Service files..."
- [ ] ? "Installing code signing certificate..."
- [ ] ? "Certificate file successfully copied to temp"
- [ ] ? "Code signing certificate installed successfully" (not "WARNING")
- [ ] ? "MSIX package successfully copied to temp"
- [ ] ? "MSIX package installed successfully"
- [ ] ? "appsettings.json created successfully" OR "Configuration merged successfully"
- [ ] ? "Installation completed successfully!"

**? If you see:**
- "ERROR" entries ? See TROUBLESHOOTING-GUIDE.md
- "WARNING: Certificate installation failed" ? Run Verify Certificate section below
- "MSIX installation returned code: (non-zero)" ? See TROUBLESHOOTING-GUIDE.md MSIX section

### Verify Installation Files Exist
```powershell
Test-Path "C:\Program Files\MCBDS Manager\install.log"        # Should exist
Test-Path "C:\Program Files\MCBDS Manager\appsettings.json"    # Should exist
Test-Path "C:\Program Files\MCBDS Manager\MCBDS.WindowsService.exe"
```

All three should return `True`

### Check appsettings.json Format

**CRITICAL: Paths must use FORWARD SLASHES `/`**

```powershell
$config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
$config | ConvertTo-Json | Write-Host
```

**Verify in output:**
- [ ] All paths use forward slashes `/` NOT backslashes `\`
- [ ] Example: `"ExePath": "C:/Program Files/MCBDS Manager/..."`
- [ ] Example: `"LogFilePath": "C:/Program Files/MCBDS Manager/logs/runner.log"`
- [ ] Example: `"BackupDirectory": "C:/Program Files/MCBDS Manager/backups"`

**? If paths have backslashes:**
```
"ExePath": "C:\Program Files\MCBDS Manager\..."  ? WRONG
```
? Follow fix in TROUBLESHOOTING-GUIDE.md ? Issue "Application Won't Start - JSON Parse Error"

### Verify Service Installation

```powershell
Get-Service -Name MCBDSAPIService | Format-List *
```

Should show:
- [ ] ? `Status : Running`
- [ ] ? `Name : MCBDSAPIService`
- [ ] ? `StartType : Automatic`
- [ ] ? `DisplayName : MCBDS API Service`

**If Status is "Stopped":**
```powershell
Start-Service -Name MCBDSAPIService
Start-Sleep -Seconds 2
Get-Service -Name MCBDSAPIService
```

**If service won't start:**
- [ ] Check Event Viewer: `Get-EventLog -LogName Application -Source MCBDSAPIService -Newest 5`
- [ ] Check JSON syntax: `Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json`
- [ ] See TROUBLESHOOTING-GUIDE.md ? "Service Won't Start"

### Verify API Access

```powershell
# Test API health endpoint
$response = Invoke-WebRequest -Uri "http://localhost:8080/health" -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 200) {
    Write-Host "? API is responding" -ForegroundColor Green
} else {
    Write-Host "? API returned status: $($response.StatusCode)" -ForegroundColor Red
}
```

Or open browser and go to: `http://localhost:8080`

**Should see:**
- [ ] ? API response OR web interface loads
- [ ] ? No SSL certificate warnings
- [ ] ? No 404 or connection errors

**If not responding:**
- [ ] Verify service is running: `Get-Service MCBDSAPIService`
- [ ] Check port not in use: `netstat -ano | findstr :8080`
- [ ] Check firewall rule: `netsh advfirewall firewall show rule name="MCBDS API Service*"`

### Verify Certificate Installation (Check Log First)

```powershell
# Look in install.log for certificate status
Select-String "certificate" "C:\Program Files\MCBDS Manager\install.log"
```

**Should show:**
- [ ] ? "Code signing certificate installed successfully"

**If log shows certificate installed, verify:**
```powershell
# Check if certificate is actually installed
$cert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
if ($cert) {
    Write-Host "? Certificate found in Trusted Root" -ForegroundColor Green
    Write-Host "  Subject: $($cert.Subject)"
    Write-Host "  Expires: $($cert.NotAfter)"
} else {
    Write-Host "? Certificate NOT in Trusted Root" -ForegroundColor Yellow
}
```

**If certificate was installed but not found in trusted root:**
- [ ] Check if running with admin privileges: `[bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")`
- [ ] See TROUBLESHOOTING-GUIDE.md ? "Certificate Not in Trusted Root Store"

### Verify MSIX Installation (Optional)

```powershell
# Check if MSIX is installed
Get-AppxPackage -Name "*MCBDS*"
```

**If MSIX package is listed:**
- [ ] ? MSIX installation succeeded
- [ ] ? Desktop app can be launched from Start Menu

**If not found:**
- [ ] Check install.log for MSIX error
- [ ] Verify certificate installation first (MSIX needs trusted cert)
- [ ] See TROUBLESHOOTING-GUIDE.md ? "MSIX Installation Failed"

---

## Summary Checks

Run this quick PowerShell script to verify everything:

```powershell
# Quick verification script
Write-Host "MCBDS Installation Verification" -ForegroundColor Cyan

$issues = @()

# 1. Check log file
if (Test-Path "C:\Program Files\MCBDS Manager\install.log") {
    Write-Host "? install.log exists" -ForegroundColor Green
    $errors = Select-String "ERROR" "C:\Program Files\MCBDS Manager\install.log"
    if ($errors) {
        Write-Host "? Errors found in log" -ForegroundColor Red
        $issues += "Install log has errors"
    }
} else {
    Write-Host "? install.log not found" -ForegroundColor Red
    $issues += "Install log missing"
}

# 2. Check config
if (Test-Path "C:\Program Files\MCBDS Manager\appsettings.json") {
    Write-Host "? appsettings.json exists" -ForegroundColor Green
    try {
        $config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
        Write-Host "? JSON is valid" -ForegroundColor Green
        
        # Check for backslashes
        $jsonStr = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" -Raw
        if ($jsonStr -match '\\') {
            Write-Host "? JSON contains unescaped backslashes" -ForegroundColor Red
            $issues += "JSON path escaping issue"
        }
    } catch {
        Write-Host "? Invalid JSON" -ForegroundColor Red
        $issues += "JSON parse error"
    }
} else {
    Write-Host "? appsettings.json not found" -ForegroundColor Red
    $issues += "Configuration missing"
}

# 3. Check service
$svc = Get-Service -Name MCBDSAPIService -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -eq "Running") {
        Write-Host "? Service is Running" -ForegroundColor Green
    } else {
        Write-Host "? Service is $($svc.Status)" -ForegroundColor Red
        $issues += "Service not running"
    }
} else {
    Write-Host "? Service not found" -ForegroundColor Red
    $issues += "Service missing"
}

# 4. Check API
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -ErrorAction Stop -TimeoutSec 5
    Write-Host "? API responding" -ForegroundColor Green
} catch {
    Write-Host "? API not responding" -ForegroundColor Red
    $issues += "API not accessible"
}

# 5. Check certificate
$cert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
if ($cert) {
    Write-Host "? Certificate in Trusted Root" -ForegroundColor Green
} else {
    Write-Host "? Certificate not in Trusted Root" -ForegroundColor Yellow
    $issues += "Certificate not trusted (MSIX may have warnings)"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "? All checks passed!" -ForegroundColor Green
} else {
    Write-Host "? Issues found:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  - $_" }
    Write-Host "`nSee TROUBLESHOOTING-GUIDE.md for solutions" -ForegroundColor Yellow
}
```

---

## Expected Result

After passing all checks:

? **Installation Log**
- Shows "Installation completed successfully!"
- No ERROR entries
- Certificate installed successfully
- appsettings.json created/merged successfully

? **Configuration**
- appsettings.json exists and is valid JSON
- All paths use forward slashes `/`

? **Service**
- MCBDSAPIService is Running
- Startup type is Automatic
- Can be accessed via `http://localhost:8080`

? **Certificate** (if requested)
- Installed in Trusted Root
- Shows "Pinecrest Consultants" subject

---

## Troubleshooting Matrix

| Issue | Check | Solution |
|-------|-------|----------|
| JSON Parse Error | install.log + appsettings.json | Fix backslashes ? forward slashes |
| Service won't start | JSON validity | Validate and fix JSON syntax |
| API not responding | Service status | Start service + check firewall |
| MSIX fails | install.log + certificate | Reinstall with admin + cert installation |
| Certificate not trusted | Trusted Root store | Reinstall as admin OR manual install |
| Port in use | netstat output | Change port in appsettings.json |

---

For detailed solutions, see:
- **[TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)** - Full troubleshooting procedures
- **[POST-INSTALLATION-VERIFICATION.md](POST-INSTALLATION-VERIFICATION.md)** - Detailed verification steps
- **[README-FIXES.md](README-FIXES.md)** - What was fixed and why

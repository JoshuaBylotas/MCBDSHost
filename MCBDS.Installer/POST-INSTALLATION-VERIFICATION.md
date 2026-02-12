# MCBDS Manager - Installation Verification Checklist

After installing MCBDS Manager, use this checklist to verify everything is working correctly.

## Immediate Post-Installation (Within 2 minutes)

### Step 1: Check Installation Log
**File Location:** `C:\Program Files\MCBDS Manager\install.log`

```powershell
# From PowerShell, view the log
Get-Content "C:\Program Files\MCBDS Manager\install.log"

# Or search for errors
Select-String "ERROR|ERROR:" "C:\Program Files\MCBDS Manager\install.log"
```

**Expected Content:**
- ? "Installation completed successfully!"
- ? "Code signing certificate installed successfully"
- ? "appsettings.json created successfully" OR "Configuration merged successfully"
- ? "Service will start automatically"

### Step 2: Verify Windows Service is Running

```powershell
# Check service status
Get-Service -Name MCBDSAPIService

# Output should show:
# Status   Name
# ------   ----
# Running  MCBDSAPIService

# If not running, start it
Start-Service -Name MCBDSAPIService
```

### Step 3: Verify Configuration File

```powershell
# Check if appsettings.json exists
Test-Path "C:\Program Files\MCBDS Manager\appsettings.json"

# Validate JSON syntax
$config = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
Write-Host "appsettings.json is valid JSON ?"

# Check configuration values
$config | ConvertTo-Json | Write-Host
```

**Expected Configuration:**
```json
{
  "Urls": "http://0.0.0.0:8080",
  "Runner": {
    "ExePath": "C:/path/to/bedrock_server",
    "LogFilePath": "C:/path/to/logs/runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:/path/to/backups",
    "MaxBackupsToKeep": 30
  }
}
```

**Note:** All paths should use **forward slashes** `/` not backslashes `\`

### Step 4: Test API Accessibility

```powershell
# Test if API is listening on port 8080
$response = Invoke-WebRequest -Uri "http://localhost:8080/health" -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 200) {
    Write-Host "? API is responding on port 8080"
} else {
    Write-Host "? API is not responding - check install.log"
}
```

Or use a browser:
1. Open: `http://localhost:8080`
2. You should see a response (either Web UI or API response)

### Step 5: Verify Certificate Installation

```powershell
# Check if certificate is in Trusted Root
$cert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}

if ($cert) {
    Write-Host "? Certificate is installed in LocalMachine Trusted Root"
    Write-Host "  Subject: $($cert.Subject)"
    Write-Host "  Expires: $($cert.NotAfter)"
} else {
    Write-Host "? Certificate NOT found in LocalMachine Trusted Root"
    Write-Host "  (MSIX may have installation warnings)"
}
```

### Step 6: Check Logs Directory

```powershell
# Check if logs directory exists and has files
$logsDir = "C:\Program Files\MCBDS Manager\logs"
if (Test-Path $logsDir) {
    Write-Host "? Logs directory exists"
    Get-ChildItem $logsDir | Format-Table -AutoSize
} else {
    Write-Host "? Logs directory not created yet (will be created when needed)"
}
```

## If Something Went Wrong

### Service Won't Start

```powershell
# 1. Check service status
Get-Service -Name MCBDSAPIService | Format-List *

# 2. Check for errors in Event Viewer
Get-EventLog -LogName Application -Source MCBDSAPIService -Newest 5

# 3. Check appsettings.json for JSON errors
$test = Get-Content "C:\Program Files\MCBDS Manager\appsettings.json" | ConvertFrom-Json
# If this fails, the JSON is invalid
```

**Solution:** See [TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)

### MSIX App Installation Failed

```powershell
# 1. Check certificate installation in log
Select-String "certificate" "C:\Program Files\MCBDS Manager\install.log"

# 2. Try manual MSIX installation
Add-AppxPackage -Path "Path\To\MCBDS.PublicUI.msix"

# 3. Or check what's installed
Get-AppxPackage -Name "*MCBDS*"
```

**Solution:** See [TROUBLESHOOTING-GUIDE.md - MSIX Installation Failed](TROUBLESHOOTING-GUIDE.md)

### API Not Accessible

```powershell
# 1. Verify service is running
Get-Service -Name MCBDSAPIService

# 2. Check if port is listening
netstat -ano | findstr :8080

# 3. Check firewall rule
netsh advfirewall firewall show rule name="MCBDS API Service*"

# 4. Check for port conflicts
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object OwningProcess
```

## Quick Diagnostic Script

Save this as `diagnose.ps1` and run as Administrator:

```powershell
# MCBDS Installation Diagnostic Script
Write-Host "========== MCBDS Manager Installation Diagnostics ==========" -ForegroundColor Cyan
Write-Host ""

# 1. Check install.log
Write-Host "1. Checking installation log..." -ForegroundColor Yellow
$logPath = "C:\Program Files\MCBDS Manager\install.log"
if (Test-Path $logPath) {
    Write-Host "? Log file exists" -ForegroundColor Green
    $errors = Select-String "ERROR" $logPath
    if ($errors) {
        Write-Host "? Errors found in log:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "? No errors in log" -ForegroundColor Green
    }
} else {
    Write-Host "? Log file not found" -ForegroundColor Red
}

# 2. Check service
Write-Host "`n2. Checking Windows Service..." -ForegroundColor Yellow
$svc = Get-Service -Name MCBDSAPIService -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "? Service exists: $($svc.Status)" -ForegroundColor Green
    if ($svc.Status -ne "Running") {
        Write-Host "  Attempting to start..." -ForegroundColor Yellow
        Start-Service -Name MCBDSAPIService -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "? Service not found" -ForegroundColor Red
}

# 3. Check configuration
Write-Host "`n3. Checking appsettings.json..." -ForegroundColor Yellow
$configPath = "C:\Program Files\MCBDS Manager\appsettings.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Host "? Configuration is valid JSON" -ForegroundColor Green
        Write-Host "  Port: $($config.Urls)"
    } catch {
        Write-Host "? Invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "? Configuration file not found" -ForegroundColor Red
}

# 4. Check API
Write-Host "`n4. Checking API accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -ErrorAction Stop -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "? API responding on port 8080" -ForegroundColor Green
    }
} catch {
    Write-Host "? API not responding: $($_.Exception.Message)" -ForegroundColor Red
    
    # Check if port is listening
    $listening = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
    if ($listening) {
        Write-Host "  (But something is listening on port 8080)" -ForegroundColor Yellow
    }
}

# 5. Check certificate
Write-Host "`n5. Checking certificate..." -ForegroundColor Yellow
$cert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object {$_.Subject -like "*Pinecrest*"}
if ($cert) {
    Write-Host "? Certificate installed" -ForegroundColor Green
    Write-Host "  Subject: $($cert.Subject)"
} else {
    Write-Host "? Certificate not in Trusted Root (MSIX may show warnings)" -ForegroundColor Yellow
}

Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host "Diagnosis complete. Check above for any ? marks." -ForegroundColor Cyan
```

## Next Steps

Once verified:
1. ? Access Web UI at `http://localhost:8080`
2. ? Configure your Minecraft Bedrock server binaries
3. ? Launch MCBDS Manager desktop app (if installed as MSIX)
4. ? Monitor service via Windows Services panel

## Additional Resources

- [Installation Certificate Guide](CERTIFICATE-INSTALLATION-GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING-GUIDE.md)
- [Build Instructions](build-installer.ps1)

# NSIS Installer - Command Reference

## Copy & Paste Ready Commands

### 1?? INSTALL NSIS (One-time only)

```powershell
# Option A: Automatic (if you have Chocolatey)
choco install nsis

# Option B: Manual download
# Visit: https://nsis.sourceforge.io/
# Download "NSIS Installer" and run
```

---

### 2?? BUILD INSTALLER (Main command)

```powershell
# Navigate to project
cd D:\source\repos\JoshuaBylotas\MCBDSHost

# Run the build script
.\MCBDS.Installer\build-installer.ps1
```

**Expected output:**
```
========================================
MCBDS API Service Installer Build Script
========================================

[1/3] Checking NSIS installation...
? NSIS found

[2/3] Publishing Windows Service...
? Windows Service published

[3/3] Building NSIS installer...
? Installer built successfully

========================================
Build Complete!
========================================

Installer created: MCBDS.API.Service.Installer.exe
```

---

### 3?? BUILD WITH CUSTOM NSIS PATH

If NSIS is installed in a non-standard location:

```powershell
.\MCBDS.Installer\build-installer.ps1 -NsisPath "C:\Your\Custom\Path\makensis.exe"
```

---

### 4?? MANUAL BUILD (If script doesn't work)

#### Step 1: Publish the service
```powershell
dotnet publish MCBDS.WindowsService\MCBDS.WindowsService.csproj `
  -c Release `
  -r win-x64 `
  --self-contained
```

#### Step 2: Build the installer
```powershell
& "C:\Program Files (x86)\NSIS\makensis.exe" "MCBDS.Installer\MCBDSInstaller.nsi"
```

#### Result:
```
MCBDS.API.Service.Installer.exe (in project root)
```

---

### 5?? TEST INSTALLATION

```powershell
# Run installer as Administrator
.\MCBDS.API.Service.Installer.exe

# Or right-click and select "Run as Administrator"
```

---

### 6?? VERIFY SERVICE IS RUNNING

```powershell
# Check service status
Get-Service MCBDSAPIService

# Expected output:
# Status   Name               DisplayName
# ------   ----               -----------
# Running  MCBDSAPIService    MCBDS API Service
```

---

### 7?? VERIFY FIREWALL RULE

```powershell
# Check firewall rule
netsh advfirewall firewall show rule all | findstr MCBDS

# Expected output:
# Rule Name:                            MCBDS API Service (HTTP)
# Direction:                            In
# Action:                               Allow
# ...
```

---

### 8?? TEST API ENDPOINT

```powershell
# Test health endpoint
curl http://localhost:8080/health

# Or using Invoke-WebRequest
Invoke-WebRequest http://localhost:8080/health -UseBasicParsing
```

---

### 9?? SERVICE MANAGEMENT COMMANDS

```powershell
# Start service
net start MCBDSAPIService

# Stop service
net stop MCBDSAPIService

# Restart service
net stop MCBDSAPIService
net start MCBDSAPIService

# View service status
Get-Service MCBDSAPIService

# View service properties
Get-Service MCBDSAPIService | Format-List *
```

---

### ?? UNINSTALL SERVICE

```powershell
# Method 1: Using uninstaller (recommended)
.\MCBDS.API.Service.Installer.exe /S

# Method 2: Manual uninstall
# 1. Open Settings ? Apps ? Apps & features
# 2. Search for "MCBDS API Service"
# 3. Click Uninstall

# Method 3: Command line uninstall
net stop MCBDSAPIService
sc delete MCBDSAPIService
netsh advfirewall firewall delete rule name="MCBDS API Service (HTTP)"
Remove-Item -Path "C:\Program Files\MCBDS API Service" -Recurse
```

---

## ?? TROUBLESHOOTING COMMANDS

### Check Build Status

```powershell
# Check if build was successful
ls -la MCBDS.API.Service.Installer.exe

# Check file size (should be 100+ MB)
(Get-Item MCBDS.API.Service.Installer.exe).Length / 1MB
```

### Check NSIS Installation

```powershell
# Verify NSIS is installed
& "C:\Program Files (x86)\NSIS\makensis.exe" /VERSION

# List installed NSIS location
Get-Command makensis.exe

# or
(Get-ChildItem -Path "C:\Program Files*" -Filter "makensis.exe" -Recurse -ErrorAction SilentlyContinue).FullName
```

### Check Service Logs

```powershell
# View Event Viewer logs
Get-EventLog -LogName Application -Source "MCBDSAPIService" -Newest 10

# Or view application logs
Get-EventLog -LogName Application -Newest 10 | Select-Object TimeGenerated, Source, Message

# View service log file
Get-Content "C:\Program Files\MCBDS API Service\logs\runner.log" -Tail 50

# Follow log in real-time
Get-Content "C:\Program Files\MCBDS API Service\logs\runner.log" -Tail 50 -Wait
```

### Check Port Usage

```powershell
# Find what's using port 8080
netstat -ano | findstr :8080

# More detailed port check
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

# Check all MCBDS-related processes
Get-Process | Where-Object { $_.ProcessName -like "*MCBDS*" }
```

### Check Firewall Rules

```powershell
# Show all firewall rules
netsh advfirewall firewall show rule all

# Show only MCBDS rules
netsh advfirewall firewall show rule all | findstr MCBDS

# Show rules for specific port
netsh advfirewall firewall show rule all | findstr 8080

# Add firewall rule manually
netsh advfirewall firewall add rule `
  name="MCBDS API Service (HTTP)" `
  dir=in `
  action=allow `
  protocol=tcp `
  localport=8080

# Remove firewall rule manually
netsh advfirewall firewall delete rule `
  name="MCBDS API Service (HTTP)"
```

### Check Registry Entries

```powershell
# Check installation registry
Get-ItemProperty "HKLM:\Software\MCBDS\API Service"

# Check Windows uninstall registry
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS API Service"

# List all registry entries
Get-ChildItem "HKLM:\Software\MCBDS" -Recurse
```

---

## ?? DIAGNOSTIC COMMANDS

### Complete Health Check

```powershell
# All-in-one diagnostics
Write-Host "=== Service Status ==="
Get-Service MCBDSAPIService | Format-List *

Write-Host "`n=== Firewall Rules ==="
netsh advfirewall firewall show rule all | findstr MCBDS

Write-Host "`n=== Port Status ==="
netstat -ano | findstr :8080

Write-Host "`n=== API Health Check ==="
try {
    $response = Invoke-WebRequest http://localhost:8080/health -UseBasicParsing
    "? Service is responding on port 8080"
    $response.StatusCode
} catch {
    "? Service is not responding"
    $_.Exception.Message
}

Write-Host "`n=== Recent Logs (last 20 lines) ==="
Get-Content "C:\Program Files\MCBDS API Service\logs\runner.log" -Tail 20

Write-Host "`n=== Service Process Info ==="
Get-Process | Where-Object { $_.ProcessName -like "*MCBDS*" }
```

---

## ?? QUICK WORKFLOWS

### Build and Deploy (5 minutes)

```powershell
# Step 1: Build
cd D:\source\repos\JoshuaBylotas\MCBDSHost
.\MCBDS.Installer\build-installer.ps1

# Step 2: Verify created
ls -la MCBDS.API.Service.Installer.exe

# Step 3: Run installer
.\MCBDS.API.Service.Installer.exe

# Step 4: Wait for installation to complete

# Step 5: Verify
Get-Service MCBDSAPIService
Invoke-WebRequest http://localhost:8080/health -UseBasicParsing
```

### Rebuild and Reinstall

```powershell
# Stop existing service
net stop MCBDSAPIService

# Uninstall
& "C:\Program Files\MCBDS API Service\uninstall.exe" /S

# Rebuild installer
.\MCBDS.Installer\build-installer.ps1

# Reinstall
.\MCBDS.API.Service.Installer.exe /S

# Verify
Get-Service MCBDSAPIService
```

### Clean Rebuild (Start Fresh)

```powershell
# 1. Stop and remove old service
net stop MCBDSAPIService 2>$null
sc delete MCBDSAPIService 2>$null
netsh advfirewall firewall delete rule name="MCBDS API Service (HTTP)" 2>$null

# 2. Clean old installation
Remove-Item -Path "C:\Program Files\MCBDS API Service" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Clean build artifacts
Remove-Item -Path "MCBDS.WindowsService\bin" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "MCBDS.WindowsService\obj" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Build new installer
.\MCBDS.Installer\build-installer.ps1

# 5. Install fresh
.\MCBDS.API.Service.Installer.exe /S

# 6. Verify
Write-Host "Waiting for service to start..."
Start-Sleep 3
Get-Service MCBDSAPIService
```

---

## ?? ENVIRONMENT SETUP

### Verify Prerequisites

```powershell
# Check PowerShell version (5.0 or higher)
$PSVersionTable.PSVersion

# Check .NET SDK
dotnet --version
dotnet --list-sdks

# Check if running as Administrator
if ((whoami /groups) -match "S-1-5-32-544") {
    "? Running as Administrator"
} else {
    "? Not running as Administrator - please restart PowerShell as Admin"
}

# Check NSIS
& "C:\Program Files (x86)\NSIS\makensis.exe" /VERSION
```

### Fix Common Issues

```powershell
# Grant script execution permission (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Check if execution policy is blocking scripts
Get-ExecutionPolicy

# Add current user to Administrators group (if needed)
# Note: This requires admin PowerShell
Add-LocalGroupMember -Group "Administrators" -Member $env:USERNAME
```

---

## ?? BATCH OPERATIONS

### Create Multiple Installers (Different Configs)

```powershell
# Installer 1: Default configuration
.\MCBDS.Installer\build-installer.ps1
Copy-Item "MCBDS.API.Service.Installer.exe" "MCBDS.API.Service.v1.0.1.exe"

# Now manually edit MCBDSInstaller.nsi for different config...
# Then build again
.\MCBDS.Installer\build-installer.ps1
Copy-Item "MCBDS.API.Service.Installer.exe" "MCBDS.API.Service.v1.0.1-CustomPort.exe"
```

---

**Last Updated**: 2024  
**Status**: Ready to Use  
**Test Date**: 2024

---

**?? Tip**: Copy any command above and paste directly into PowerShell (running as Administrator)

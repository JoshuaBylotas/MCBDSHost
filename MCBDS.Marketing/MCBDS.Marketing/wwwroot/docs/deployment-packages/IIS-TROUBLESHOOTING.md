# IIS 500 Error Troubleshooting Guide for MCBDSHost Marketing Site

## ?? Common Causes & Solutions

### 1. **Missing ASP.NET Core Hosting Bundle**

**Problem**: IIS doesn't have the ASP.NET Core Runtime installed.

**Solution**:
```powershell
# Download and install the .NET 10 Hosting Bundle
# Visit: https://dotnet.microsoft.com/download/dotnet/10.0
# Download: "Hosting Bundle" installer

# After installation, restart IIS
iisreset

# Verify installation
dotnet --list-runtimes
# Should show: Microsoft.AspNetCore.App 10.x.x
```

### 2. **Application Pool Configuration**

**Problem**: Wrong application pool settings.

**Solution**:
```powershell
# Open IIS Manager
# Select your site's Application Pool
# Click "Basic Settings"

# Set these values:
# - .NET CLR Version: No Managed Code
# - Managed Pipeline Mode: Integrated
# - Start Mode: AlwaysRunning (optional)

# In Advanced Settings:
# - Enable 32-Bit Applications: False
# - Identity: ApplicationPoolIdentity (or specific user with permissions)
```

### 3. **Enable Detailed Error Messages**

**Update web.config** (already done in the new web.config):
```xml
<aspNetCore processPath="dotnet" 
            arguments=".\MCBDS.Marketing.dll" 
            stdoutLogEnabled="true" 
            stdoutLogFile=".\logs\stdout" 
            hostingModel="inprocess">
  <environmentVariables>
    <environmentVariable name="ASPNETCORE_DETAILEDERRORS" value="true" />
  </environmentVariables>
</aspNetCore>
```

### 4. **Check Application Event Log**

```powershell
# View recent errors in Event Viewer
Get-EventLog -LogName Application -Source "IIS AspNetCore Module V2" -Newest 10 | Format-List

# Or open Event Viewer manually:
# eventvwr.msc ? Windows Logs ? Application
# Filter by: IIS AspNetCore Module V2
```

### 5. **Check stdout Logs**

The web.config is configured to write logs to `.\logs\stdout`.

```powershell
# Navigate to your deployment folder
cd C:\inetpub\wwwroot\mcbdshost-marketing

# Check if logs folder exists
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs"
}

# Grant permissions to the logs folder
icacls "logs" /grant "IIS_IUSRS:(OI)(CI)F" /T

# Check for log files
Get-ChildItem logs\*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### 6. **File Permissions**

**Problem**: IIS doesn't have permission to read files.

**Solution**:
```powershell
# Set permissions on the deployment folder
icacls "C:\inetpub\wwwroot\mcbdshost-marketing" /grant "IIS_IUSRS:(OI)(CI)RX" /T
icacls "C:\inetpub\wwwroot\mcbdshost-marketing" /grant "IUSR:(OI)(CI)RX" /T

# Specific for logs folder (write permission)
icacls "C:\inetpub\wwwroot\mcbdshost-marketing\logs" /grant "IIS_IUSRS:(OI)(CI)F" /T
```

### 7. **Missing DLL Files**

**Problem**: Dependent DLLs not published correctly.

**Solution**:
```powershell
# Rebuild and republish
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Marketing

# Clean previous build
dotnet clean

# Publish with all dependencies
dotnet publish -c Release -o publish --self-contained false

# Copy to IIS
Copy-Item -Path "publish\*" -Destination "C:\inetpub\wwwroot\mcbdshost-marketing" -Recurse -Force

# Restart IIS
iisreset
```

### 8. **Port Conflicts**

**Problem**: Port 80/443 already in use.

**Solution**:
```powershell
# Check what's using port 80
netstat -ano | findstr :80

# If needed, stop conflicting service
Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, DisplayName

# Configure site to use different port temporarily
# In IIS Manager ? Sites ? Your Site ? Bindings
# Add binding for port 8080 (HTTP) for testing
```

---

## ??? Quick Fix Checklist

Run these commands in PowerShell (as Administrator):

```powershell
# 1. Ensure .NET 10 Hosting Bundle is installed
dotnet --list-runtimes

# 2. Create logs directory
$sitePath = "C:\inetpub\wwwroot\mcbdshost-marketing"
New-Item -Path "$sitePath\logs" -ItemType Directory -Force

# 3. Set proper permissions
icacls "$sitePath" /grant "IIS_IUSRS:(OI)(CI)RX" /T
icacls "$sitePath\logs" /grant "IIS_IUSRS:(OI)(CI)F" /T

# 4. Copy updated web.config
Copy-Item -Path "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Marketing\web.config" -Destination "$sitePath\web.config" -Force

# 5. Restart IIS
iisreset

# 6. Test the site
Start-Process "http://localhost"
```

---

## ?? Diagnostic Script

Save this as `diagnose-iis.ps1` and run it:

```powershell
#Requires -RunAsAdministrator

Write-Host "=== IIS Diagnostics for MCBDSHost Marketing ===" -ForegroundColor Cyan

# Check .NET Runtime
Write-Host "`n1. Checking .NET Runtime..." -ForegroundColor Yellow
dotnet --list-runtimes | Where-Object { $_ -like "*AspNetCore*10*" }

# Check IIS Module
Write-Host "`n2. Checking AspNetCoreModuleV2..." -ForegroundColor Yellow
Get-WebGlobalModule | Where-Object { $_.Name -like "*AspNetCore*" }

# Check Application Pool
Write-Host "`n3. Checking Application Pool..." -ForegroundColor Yellow
$appPool = Get-IISAppPool | Where-Object { $_.Name -eq "MCBDSHostMarketing" -or $_.Name -eq "DefaultAppPool" }
if ($appPool) {
    Write-Host "   Pool: $($appPool.Name)" -ForegroundColor Green
    Write-Host "   State: $($appPool.State)" -ForegroundColor Green
    Write-Host "   .NET CLR: $($appPool.ManagedRuntimeVersion)" -ForegroundColor Green
} else {
    Write-Host "   Application pool not found!" -ForegroundColor Red
}

# Check Site
Write-Host "`n4. Checking Website..." -ForegroundColor Yellow
$site = Get-IISSite | Where-Object { $_.Name -like "*marketing*" -or $_.Name -eq "Default Web Site" }
if ($site) {
    Write-Host "   Site: $($site.Name)" -ForegroundColor Green
    Write-Host "   State: $($site.State)" -ForegroundColor Green
    Write-Host "   Physical Path: $($site.Applications['/'].VirtualDirectories['/'].PhysicalPath)" -ForegroundColor Green
}

# Check Files
Write-Host "`n5. Checking Deployment Files..." -ForegroundColor Yellow
$sitePath = "C:\inetpub\wwwroot\mcbdshost-marketing"
if (Test-Path "$sitePath\MCBDS.Marketing.dll") {
    Write-Host "   ? MCBDS.Marketing.dll found" -ForegroundColor Green
} else {
    Write-Host "   ? MCBDS.Marketing.dll NOT found!" -ForegroundColor Red
}

if (Test-Path "$sitePath\web.config") {
    Write-Host "   ? web.config found" -ForegroundColor Green
} else {
    Write-Host "   ? web.config NOT found!" -ForegroundColor Red
}

if (Test-Path "$sitePath\wwwroot") {
    Write-Host "   ? wwwroot folder found" -ForegroundColor Green
    $fileCount = (Get-ChildItem "$sitePath\wwwroot" -Recurse -File).Count
    Write-Host "   Files in wwwroot: $fileCount" -ForegroundColor Green
} else {
    Write-Host "   ? wwwroot folder NOT found!" -ForegroundColor Red
}

# Check Logs
Write-Host "`n6. Checking Logs..." -ForegroundColor Yellow
if (Test-Path "$sitePath\logs") {
    $logFiles = Get-ChildItem "$sitePath\logs\*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    if ($logFiles) {
        Write-Host "   Recent log files:" -ForegroundColor Green
        foreach ($log in $logFiles) {
            Write-Host "   - $($log.Name) ($($log.LastWriteTime))" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No log files found (may indicate permissions issue)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Logs folder doesn't exist. Creating..." -ForegroundColor Yellow
    New-Item -Path "$sitePath\logs" -ItemType Directory -Force | Out-Null
    icacls "$sitePath\logs" /grant "IIS_IUSRS:(OI)(CI)F" /T | Out-Null
}

# Check Event Log
Write-Host "`n7. Checking Event Log (last 5 errors)..." -ForegroundColor Yellow
$events = Get-EventLog -LogName Application -Source "IIS AspNetCore Module V2" -EntryType Error -Newest 5 -ErrorAction SilentlyContinue
if ($events) {
    foreach ($event in $events) {
        Write-Host "   [$($event.TimeGenerated)] $($event.Message.Substring(0, [Math]::Min(100, $event.Message.Length)))..." -ForegroundColor Red
    }
} else {
    Write-Host "   No recent errors in Event Log" -ForegroundColor Green
}

# Check Permissions
Write-Host "`n8. Checking Permissions..." -ForegroundColor Yellow
$acl = Get-Acl "$sitePath"
$hasIISPermissions = $acl.Access | Where-Object { 
    $_.IdentityReference -like "*IIS_IUSRS*" -or $_.IdentityReference -like "*IUSR*" 
}
if ($hasIISPermissions) {
    Write-Host "   ? IIS users have permissions" -ForegroundColor Green
} else {
    Write-Host "   ? Missing IIS user permissions!" -ForegroundColor Red
    Write-Host "   Run: icacls '$sitePath' /grant 'IIS_IUSRS:(OI)(CI)RX' /T" -ForegroundColor Yellow
}

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Cyan
Write-Host "If issues persist, check the stdout logs in: $sitePath\logs\" -ForegroundColor Yellow
```

---

## ?? Deployment Steps (Correct Order)

1. **Build the application**:
```powershell
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Marketing
dotnet publish -c Release -o publish
```

2. **Stop IIS site**:
```powershell
Stop-IISSite -Name "Your Site Name" -Confirm:$false
```

3. **Copy files**:
```powershell
$source = "publish\*"
$dest = "C:\inetpub\wwwroot\mcbdshost-marketing"
Copy-Item -Path $source -Destination $dest -Recurse -Force
```

4. **Copy updated web.config**:
```powershell
Copy-Item -Path "web.config" -Destination "$dest\web.config" -Force
```

5. **Set permissions**:
```powershell
icacls $dest /grant "IIS_IUSRS:(OI)(CI)RX" /T
New-Item -Path "$dest\logs" -ItemType Directory -Force
icacls "$dest\logs" /grant "IIS_IUSRS:(OI)(CI)F" /T
```

6. **Start IIS site**:
```powershell
Start-IISSite -Name "Your Site Name"
```

7. **Test**:
```powershell
Start-Process "http://localhost"
```

---

## ?? Testing Checklist

- [ ] .NET 10 Hosting Bundle installed
- [ ] Application Pool set to "No Managed Code"
- [ ] web.config has stdout logging enabled
- [ ] Logs folder exists with write permissions
- [ ] All files copied to IIS folder
- [ ] IIS_IUSRS has read permissions on site folder
- [ ] Site binding configured (port 80/443)
- [ ] Site started in IIS Manager
- [ ] No errors in Event Viewer
- [ ] Can browse to http://localhost

---

## ?? Still Getting 500 Error?

1. **View the actual error**:
   - Open `C:\inetpub\wwwroot\mcbdshost-marketing\logs\stdout_*.log`
   - Look for the most recent file
   - Check for stack traces or error messages

2. **Enable browser error details**:
   - Add to web.config:
     ```xml
     <aspNetCore ... >
       <environmentVariables>
         <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Development" />
       </environmentVariables>
     </aspNetCore>
     ```
   - Restart IIS
   - Browse site to see detailed error page
   - **Remember to change back to "Production" after debugging!**

3. **Check for missing dependencies**:
   ```powershell
   # Ensure all required runtimes are installed
   dotnet --list-runtimes
   dotnet --list-sdks
   ```

4. **Manual test**:
   ```powershell
   # Try running the app directly
   cd C:\inetpub\wwwroot\mcbdshost-marketing
   dotnet MCBDS.Marketing.dll
   # If it works, the issue is IIS-specific
   ```

---

## ?? Support

If you're still experiencing issues after trying these solutions:

1. Check stdout logs: `C:\inetpub\wwwroot\mcbdshost-marketing\logs\`
2. Check Event Viewer: Application logs with source "IIS AspNetCore Module V2"
3. Run the diagnostic script above
4. Share the error messages for further assistance

**Updated**: December 2024  
**For**: MCBDSHost Marketing Site on IIS

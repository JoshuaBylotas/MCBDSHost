#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy Fixed web.config to IIS

.DESCRIPTION
    Quickly deploy the fixed web.config and updated files to your IIS site.
    Handles stopping/starting IIS, copying files, and testing.

.PARAMETER SitePath
    Physical path of your IIS site (default: C:\inetpub\wwwroot\mcbdshost-marketing)

.PARAMETER SiteName
    IIS site name (default: MCBDSHostMarketing)

.EXAMPLE
    .\deploy-webconfig-fix.ps1
#>

param(
    [string]$SitePath = "C:\inetpub\wwwroot\mcbdshost-marketing",
    [string]$SiteName = "MCBDSHostMarketing"
)

Write-Host @"

?????????????????????????????????????????????????????????????????
?  Deploy Fixed web.config to IIS                              ?
?????????????????????????????????????????????????????????????????

"@ -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host "1. Checking Prerequisites..." -ForegroundColor Yellow
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "   ERROR: Must run as Administrator!" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Running as Administrator" -ForegroundColor Green

if (-not (Test-Path $SitePath)) {
    Write-Host "   ERROR: Site path not found: $SitePath" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Site path exists: $SitePath" -ForegroundColor Green

# Step 2: Stop IIS site
Write-Host "`n2. Stopping IIS Site..." -ForegroundColor Yellow
try {
    Stop-IISSite -Name $SiteName -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "   ? Site stopped" -ForegroundColor Green
} catch {
    Write-Host "   ? Could not stop site (may already be stopped)" -ForegroundColor Yellow
}

# Step 3: Backup old web.config
Write-Host "`n3. Backing Up Old web.config..." -ForegroundColor Yellow
$backupPath = "$SitePath\web.config.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (Test-Path "$SitePath\web.config") {
    Copy-Item -Path "$SitePath\web.config" -Destination $backupPath
    Write-Host "   ? Backup created: $(Split-Path $backupPath -Leaf)" -ForegroundColor Green
}

# Step 4: Copy updated files
Write-Host "`n4. Copying Updated Files..." -ForegroundColor Yellow
$publishPath = "MCBDS.Marketing\publish"
if (-not (Test-Path $publishPath)) {
    Write-Host "   ERROR: Publish folder not found at: $publishPath" -ForegroundColor Red
    Write-Host "   Please run: dotnet publish MCBDS.Marketing -c Release -o MCBDS.Marketing/publish" -ForegroundColor Yellow
    exit 1
}

Copy-Item -Path "$publishPath\*" -Destination $SitePath -Recurse -Force
Write-Host "   ? Files copied successfully" -ForegroundColor Green

# Step 5: Verify web.config
Write-Host "`n5. Verifying web.config..." -ForegroundColor Yellow
if (-not (Test-Path "$SitePath\web.config")) {
    Write-Host "   ERROR: web.config not found after copy!" -ForegroundColor Red
    exit 1
}

# Validate XML
try {
    [xml]$xml = Get-Content "$SitePath\web.config"
    Write-Host "   ? web.config is valid XML" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: web.config is invalid XML!" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Set permissions
Write-Host "`n6. Setting File Permissions..." -ForegroundColor Yellow
icacls $SitePath /grant "IIS_IUSRS:(OI)(CI)RX" /T /Q | Out-Null
Write-Host "   ? IIS_IUSRS permissions set" -ForegroundColor Green

# Create logs directory if needed
$logsPath = "$SitePath\logs"
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}
icacls $logsPath /grant "IIS_IUSRS:(OI)(CI)F" /T /Q | Out-Null
Write-Host "   ? Logs directory ready" -ForegroundColor Green

# Step 7: Start IIS site
Write-Host "`n7. Starting IIS Site..." -ForegroundColor Yellow
Start-IISSite -Name $SiteName
Start-Sleep -Seconds 3

$site = Get-IISSite -Name $SiteName
if ($site.State -eq "Started") {
    Write-Host "   ? Site started successfully" -ForegroundColor Green
} else {
    Write-Host "   ERROR: Site failed to start!" -ForegroundColor Red
    Write-Host "   Check Event Viewer for details" -ForegroundColor Yellow
    exit 1
}

# Step 8: Test connectivity
Write-Host "`n8. Testing Site..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ? Site is responding (HTTP 200)" -ForegroundColor Green
    } else {
        Write-Host "   ? Unexpected response code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ? Site not responding yet (may still be starting)" -ForegroundColor Yellow
    Write-Host "   Try again in a few seconds" -ForegroundColor Gray
}

# Summary
Write-Host @"

?????????????????????????????????????????????????????????????????
?  Deployment Summary                                           ?
?????????????????????????????????????????????????????????????????

Site Name:        $SiteName
Physical Path:    $SitePath
Backup Created:   $(if (Test-Path $backupPath) { Split-Path $backupPath -Leaf } else { "N/A" })
Site Status:      $($site.State)
Files Updated:    Yes
Permissions Set:  Yes

"@ -ForegroundColor Green

Write-Host "? Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test in browser: http://localhost" -ForegroundColor Gray
Write-Host "2. Check for 500 errors (should be none)" -ForegroundColor Gray
Write-Host "3. Verify styles load correctly" -ForegroundColor Gray
Write-Host "4. Check logs if issues: $logsPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Rollback if needed:" -ForegroundColor Yellow
Write-Host "   Copy backup back: Copy-Item '$backupPath' '$SitePath\web.config' -Force" -ForegroundColor Gray
Write-Host ""

#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy MCBDSHost Marketing Site to IIS

.DESCRIPTION
    This script builds, publishes, and deploys the MCBDSHost marketing site to IIS.
    It handles permissions, configuration, and IIS restart automatically.

.PARAMETER SitePath
    The physical path where the site will be deployed (default: C:\inetpub\wwwroot\mcbdshost-marketing)

.PARAMETER SiteName
    The IIS site name (default: MCBDSHostMarketing)

.PARAMETER AppPoolName
    The IIS application pool name (default: MCBDSHostMarketingPool)

.EXAMPLE
    .\deploy-to-iis.ps1
    
.EXAMPLE
    .\deploy-to-iis.ps1 -SitePath "C:\websites\marketing" -SiteName "Marketing"
#>

param(
    [string]$SitePath = "C:\inetpub\wwwroot\mcbdshost-marketing",
    [string]$SiteName = "MCBDSHostMarketing",
    [string]$AppPoolName = "MCBDSHostMarketingPool"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " MCBDSHost Marketing - IIS Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "1. Checking Prerequisites..." -ForegroundColor Yellow

# Check if running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "   ? Must run as Administrator!" -ForegroundColor Red
    exit 1
}

# Check .NET Runtime
$runtimes = dotnet --list-runtimes 2>$null | Where-Object { $_ -like "*AspNetCore*10*" }
if ($runtimes) {
    Write-Host "   ? .NET 10 Runtime found" -ForegroundColor Green
} else {
    Write-Host "   ? .NET 10 Hosting Bundle not found!" -ForegroundColor Red
    Write-Host "   Download from: https://dotnet.microsoft.com/download/dotnet/10.0" -ForegroundColor Yellow
    exit 1
}

# Check IIS Module
$module = Get-WebGlobalModule | Where-Object { $_.Name -eq "AspNetCoreModuleV2" }
if ($module) {
    Write-Host "   ? AspNetCoreModuleV2 installed" -ForegroundColor Green
} else {
    Write-Host "   ? AspNetCoreModuleV2 not found!" -ForegroundColor Red
    Write-Host "   Install .NET Hosting Bundle" -ForegroundColor Yellow
    exit 1
}

# Step 2: Build and Publish
Write-Host "`n2. Building Application..." -ForegroundColor Yellow

$projectPath = Join-Path $PSScriptRoot "MCBDS.Marketing"
Push-Location $projectPath

try {
    # Clean
    Write-Host "   Cleaning previous build..." -ForegroundColor Gray
    dotnet clean --configuration Release | Out-Null
    
    # Publish
    Write-Host "   Publishing..." -ForegroundColor Gray
    $publishPath = Join-Path $projectPath "publish"
    dotnet publish --configuration Release --output $publishPath | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ? Build successful" -ForegroundColor Green
    } else {
        Write-Host "   ? Build failed!" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

# Step 3: Stop IIS Site (if exists)
Write-Host "`n3. Stopping IIS Site..." -ForegroundColor Yellow

$existingSite = Get-IISSite -Name $SiteName -ErrorAction SilentlyContinue
if ($existingSite) {
    Stop-IISSite -Name $SiteName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "   ? Site stopped" -ForegroundColor Green
} else {
    Write-Host "   Site doesn't exist yet (will create)" -ForegroundColor Gray
}

# Step 4: Create/Update Application Pool
Write-Host "`n4. Configuring Application Pool..." -ForegroundColor Yellow

$appPool = Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
if (-not $appPool) {
    New-WebAppPool -Name $AppPoolName | Out-Null
    Write-Host "   ? Application pool created" -ForegroundColor Green
}

# Configure app pool
Import-Module WebAdministration
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name "managedRuntimeVersion" -Value ""
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name "startMode" -Value "AlwaysRunning"
Write-Host "   ? Application pool configured" -ForegroundColor Green

# Step 5: Deploy Files
Write-Host "`n5. Deploying Files..." -ForegroundColor Yellow

# Create site directory
if (-not (Test-Path $SitePath)) {
    New-Item -ItemType Directory -Path $SitePath -Force | Out-Null
}

# Copy files
$publishPath = Join-Path $projectPath "publish"
Copy-Item -Path "$publishPath\*" -Destination $SitePath -Recurse -Force

# Create logs directory
$logsPath = Join-Path $SitePath "logs"
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

Write-Host "   ? Files deployed to: $SitePath" -ForegroundColor Green

# Step 6: Set Permissions
Write-Host "`n6. Setting Permissions..." -ForegroundColor Yellow

icacls $SitePath /grant "IIS_IUSRS:(OI)(CI)RX" /T /Q | Out-Null
icacls $SitePath /grant "IUSR:(OI)(CI)RX" /T /Q | Out-Null
icacls $logsPath /grant "IIS_IUSRS:(OI)(CI)F" /T /Q | Out-Null

Write-Host "   ? Permissions set" -ForegroundColor Green

# Step 7: Create/Update IIS Site
Write-Host "`n7. Configuring IIS Site..." -ForegroundColor Yellow

if (-not $existingSite) {
    # Create new site
    New-IISSite -Name $SiteName `
                -PhysicalPath $SitePath `
                -BindingInformation "*:80:" `
                -Force | Out-Null
    
    # Set application pool
    Set-ItemProperty "IIS:\Sites\$SiteName" -Name "applicationPool" -Value $AppPoolName
    
    Write-Host "   ? Site created" -ForegroundColor Green
} else {
    # Update existing site
    Set-ItemProperty "IIS:\Sites\$SiteName" -Name "physicalPath" -Value $SitePath
    Set-ItemProperty "IIS:\Sites\$SiteName" -Name "applicationPool" -Value $AppPoolName
    
    Write-Host "   ? Site updated" -ForegroundColor Green
}

# Step 8: Start Site
Write-Host "`n8. Starting Site..." -ForegroundColor Yellow

Start-IISSite -Name $SiteName
Start-Sleep -Seconds 2

$site = Get-IISSite -Name $SiteName
if ($site.State -eq "Started") {
    Write-Host "   ? Site started successfully" -ForegroundColor Green
} else {
    Write-Host "   ? Site failed to start!" -ForegroundColor Red
    Write-Host "   Check logs at: $logsPath" -ForegroundColor Yellow
}

# Step 9: Verify Deployment
Write-Host "`n9. Verifying Deployment..." -ForegroundColor Yellow

$dllPath = Join-Path $SitePath "MCBDS.Marketing.dll"
$webConfigPath = Join-Path $SitePath "web.config"
$wwwrootPath = Join-Path $SitePath "wwwroot"

$checks = @(
    @{ Path = $dllPath; Name = "MCBDS.Marketing.dll" },
    @{ Path = $webConfigPath; Name = "web.config" },
    @{ Path = $wwwrootPath; Name = "wwwroot folder" }
)

$allGood = $true
foreach ($check in $checks) {
    if (Test-Path $check.Path) {
        Write-Host "   ? $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "   ? $($check.Name) missing!" -ForegroundColor Red
        $allGood = $false
    }
}

# Summary
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host " Deployment Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Site Name:     $SiteName" -ForegroundColor White
Write-Host "App Pool:      $AppPoolName" -ForegroundColor White
Write-Host "Physical Path: $SitePath" -ForegroundColor White
Write-Host "Site State:    $($site.State)" -ForegroundColor $(if ($site.State -eq "Started") { "Green" } else { "Red" })
Write-Host ""

if ($allGood -and $site.State -eq "Started") {
    Write-Host "? Deployment Successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your site at:" -ForegroundColor Cyan
    Write-Host "   http://localhost" -ForegroundColor White
    Write-Host "   http://$($env:COMPUTERNAME)" -ForegroundColor White
    Write-Host ""
    Write-Host "To add HTTPS binding:" -ForegroundColor Yellow
    Write-Host "   1. Open IIS Manager" -ForegroundColor Gray
    Write-Host "   2. Select site '$SiteName'" -ForegroundColor Gray
    Write-Host "   3. Click 'Bindings' ? 'Add'" -ForegroundColor Gray
    Write-Host "   4. Type: https, Port: 443, SSL Certificate: (your cert)" -ForegroundColor Gray
} else {
    Write-Host "??  Deployment completed with issues!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Check stdout logs: $logsPath" -ForegroundColor Gray
    Write-Host "   2. Check Event Viewer: Application logs" -ForegroundColor Gray
    Write-Host "   3. Run diagnostic: .\diagnose-iis.ps1" -ForegroundColor Gray
    Write-Host "   4. Review: IIS-TROUBLESHOOTING.md" -ForegroundColor Gray
}

Write-Host ""

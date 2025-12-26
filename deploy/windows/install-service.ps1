# MCBDSHost Windows Server Deployment Script
# Run as Administrator

param(
    [string]$InstallPath = "C:\MCBDSHost",
    [string]$ApiPort = "8080",
    [string]$WebUIPort = "5000"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "MCBDSHost Windows Server Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Check for .NET 10 Runtime
Write-Host "`nChecking for .NET 10 Runtime..." -ForegroundColor Yellow
$dotnetVersion = dotnet --list-runtimes | Select-String "Microsoft.AspNetCore.App 10"
if (-not $dotnetVersion) {
    Write-Host ".NET 10 ASP.NET Core Runtime not found. Please install from:" -ForegroundColor Red
    Write-Host "https://dotnet.microsoft.com/download/dotnet/10.0" -ForegroundColor Yellow
    exit 1
}
Write-Host ".NET 10 Runtime found!" -ForegroundColor Green

# Create installation directory
Write-Host "`nCreating installation directory: $InstallPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\api" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\webui" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\logs" | Out-Null

# Get the script's directory (where the solution is)
$SolutionDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (-not (Test-Path "$SolutionDir\MCBDSHost.slnx")) {
    $SolutionDir = Get-Location
}

Write-Host "Solution directory: $SolutionDir" -ForegroundColor Gray

# Build and publish the API
Write-Host "`nBuilding MCBDS.API..." -ForegroundColor Yellow
Push-Location $SolutionDir
dotnet publish "MCBDS.API/MCBDS.API.csproj" -c Release -o "$InstallPath\api" --self-contained false
Pop-Location

# Build and publish the Web UI
Write-Host "`nBuilding MCBDS.ClientUI.Web..." -ForegroundColor Yellow
Push-Location $SolutionDir
dotnet publish "MCBDS.ClientUI/MCBDS.ClientUI.Web/MCBDS.ClientUI.Web.csproj" -c Release -o "$InstallPath\webui" --self-contained false
Pop-Location

# Create appsettings for production
Write-Host "`nConfiguring production settings..." -ForegroundColor Yellow

$apiSettings = @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:$ApiPort"
      }
    }
  }
}
"@
$apiSettings | Out-File -FilePath "$InstallPath\api\appsettings.Production.json" -Encoding UTF8

$webUISettings = @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ApiSettings": {
    "BaseUrl": "http://localhost:$ApiPort"
  },
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:$WebUIPort"
      }
    }
  }
}
"@
$webUISettings | Out-File -FilePath "$InstallPath\webui\appsettings.Production.json" -Encoding UTF8

# Create Windows Services using sc.exe
Write-Host "`nCreating Windows Services..." -ForegroundColor Yellow

# Stop existing services if they exist
sc.exe stop "MCBDSHost-API" 2>$null
sc.exe stop "MCBDSHost-WebUI" 2>$null
sc.exe delete "MCBDSHost-API" 2>$null
sc.exe delete "MCBDSHost-WebUI" 2>$null

Start-Sleep -Seconds 2

# Create API service
sc.exe create "MCBDSHost-API" binPath= "$InstallPath\api\MCBDS.API.exe" start= auto displayname= "MCBDSHost API Server"
sc.exe description "MCBDSHost-API" "Minecraft Bedrock Dedicated Server Host API"

# Create WebUI service
sc.exe create "MCBDSHost-WebUI" binPath= "$InstallPath\webui\MCBDS.ClientUI.Web.exe" start= auto displayname= "MCBDSHost Web UI"
sc.exe description "MCBDSHost-WebUI" "Minecraft Bedrock Dedicated Server Host Web Interface"

# Configure service dependencies (WebUI depends on API)
sc.exe config "MCBDSHost-WebUI" depend= "MCBDSHost-API"

# Configure firewall rules
Write-Host "`nConfiguring Windows Firewall..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "MCBDSHost*" -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "MCBDSHost API HTTP" -Direction Inbound -Protocol TCP -LocalPort $ApiPort -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost WebUI HTTP" -Direction Inbound -Protocol TCP -LocalPort $WebUIPort -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost Minecraft IPv4" -Direction Inbound -Protocol UDP -LocalPort 19132 -Action Allow
New-NetFirewallRule -DisplayName "MCBDSHost Minecraft IPv6" -Direction Inbound -Protocol UDP -LocalPort 19133 -Action Allow

# Start services
Write-Host "`nStarting services..." -ForegroundColor Yellow
sc.exe start "MCBDSHost-API"
Start-Sleep -Seconds 5
sc.exe start "MCBDSHost-WebUI"

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services installed at: $InstallPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Web UI:     http://localhost:$WebUIPort" -ForegroundColor White
Write-Host "  API:        http://localhost:$ApiPort" -ForegroundColor White
Write-Host "  Minecraft:  Connect to port 19132" -ForegroundColor White
Write-Host ""
Write-Host "Service Management:" -ForegroundColor Yellow
Write-Host "  Start:   sc.exe start MCBDSHost-API && sc.exe start MCBDSHost-WebUI" -ForegroundColor Gray
Write-Host "  Stop:    sc.exe stop MCBDSHost-WebUI && sc.exe stop MCBDSHost-API" -ForegroundColor Gray
Write-Host "  Status:  sc.exe query MCBDSHost-API && sc.exe query MCBDSHost-WebUI" -ForegroundColor Gray

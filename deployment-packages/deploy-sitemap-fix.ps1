# ================================================================
# Deploy Sitemap.xml Fix to IIS
# ================================================================
# Purpose: Fix sitemap.xml 404 error by ensuring proper MIME types
#          and file inclusion in publish output
# ================================================================

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Sitemap.xml Fix Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$ProjectPath = "..\MCBDS.Marketing"
$PublishPath = "..\MCBDS.Marketing\bin\Release\net10.0\publish"
$IISPath = "C:\inetpub\wwwroot\mcbdshost-marketing"
$SiteUrl = "https://mcbdshost.com/sitemap.xml"

# Step 1: Clean previous build
Write-Host "[1/6] Cleaning previous build..." -ForegroundColor Yellow
Push-Location $ProjectPath
dotnet clean -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Clean failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "? Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Build the project
Write-Host "[2/6] Building project..." -ForegroundColor Yellow
Push-Location $ProjectPath
dotnet build -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "? Build complete" -ForegroundColor Green
Write-Host ""

# Step 3: Publish the project
Write-Host "[3/6] Publishing project..." -ForegroundColor Yellow
Push-Location $ProjectPath
dotnet publish -c Release -o bin\Release\net10.0\publish
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Publish failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "? Publish complete" -ForegroundColor Green
Write-Host ""

# Step 4: Verify sitemap.xml exists in publish output
Write-Host "[4/6] Verifying sitemap.xml in publish output..." -ForegroundColor Yellow
$SitemapInPublish = Join-Path $PublishPath "wwwroot\sitemap.xml"
if (-not (Test-Path $SitemapInPublish)) {
    Write-Host "? sitemap.xml not found in publish output!" -ForegroundColor Red
    Write-Host "   Expected at: $SitemapInPublish" -ForegroundColor Red
    exit 1
}
Write-Host "? sitemap.xml found in publish output" -ForegroundColor Green
Write-Host ""

# Step 5: Stop IIS site (optional, but recommended)
Write-Host "[5/6] Deploying to IIS..." -ForegroundColor Yellow
$StopSite = Read-Host "Stop IIS site before deployment? (Y/n)"
if ($StopSite -ne "n" -and $StopSite -ne "N") {
    Write-Host "  Stopping IIS site..." -ForegroundColor Yellow
    Stop-WebSite -Name "mcbdshost-marketing" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Copy files to IIS
Write-Host "  Copying files to IIS..." -ForegroundColor Yellow
if (-not (Test-Path $IISPath)) {
    Write-Host "  Creating IIS directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $IISPath -Force | Out-Null
}

Copy-Item -Path "$PublishPath\*" -Destination $IISPath -Recurse -Force

# Verify sitemap.xml was copied
$SitemapInIIS = Join-Path $IISPath "wwwroot\sitemap.xml"
if (-not (Test-Path $SitemapInIIS)) {
    Write-Host "? sitemap.xml not found in IIS directory!" -ForegroundColor Red
    Write-Host "   Expected at: $SitemapInIIS" -ForegroundColor Red
    exit 1
}

# Start IIS site if it was stopped
if ($StopSite -ne "n" -and $StopSite -ne "N") {
    Write-Host "  Starting IIS site..." -ForegroundColor Yellow
    Start-WebSite -Name "mcbdshost-marketing" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "? Deployment complete" -ForegroundColor Green
Write-Host ""

# Step 6: Verify sitemap.xml is accessible
Write-Host "[6/6] Verifying sitemap.xml accessibility..." -ForegroundColor Yellow
Write-Host "  Testing: $SiteUrl" -ForegroundColor Cyan
Start-Sleep -Seconds 3  # Give IIS time to start

try {
    $response = Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "? sitemap.xml is accessible (HTTP 200)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Content preview:" -ForegroundColor Cyan
        Write-Host $response.Content.Substring(0, [Math]::Min(500, $response.Content.Length))
    } else {
        Write-Host "??  Unexpected status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "? Failed to access sitemap.xml" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Check if IIS site is running" -ForegroundColor White
    Write-Host "  2. Verify web.config has .xml MIME type" -ForegroundColor White
    Write-Host "  3. Check IIS logs for errors" -ForegroundColor White
    Write-Host "  4. Verify file exists at: $SitemapInIIS" -ForegroundColor White
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Project:        MCBDS.Marketing" -ForegroundColor White
Write-Host "IIS Path:       $IISPath" -ForegroundColor White
Write-Host "Sitemap URL:    $SiteUrl" -ForegroundColor White
Write-Host "Status:         ? Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test sitemap.xml in browser: $SiteUrl" -ForegroundColor White
Write-Host "  2. Submit to Google Search Console" -ForegroundColor White
Write-Host "  3. Verify in robots.txt: https://mcbdshost.com/robots.txt" -ForegroundColor White
Write-Host ""

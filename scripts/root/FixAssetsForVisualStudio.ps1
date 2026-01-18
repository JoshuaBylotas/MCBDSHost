# Fix assets file before packaging
Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Fixing Assets File for Visual Studio Packaging" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

Write-Host "Removing corrupted assets file..." -ForegroundColor Yellow
Remove-Item "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json" -Force -ErrorAction SilentlyContinue

Write-Host "Restoring with correct context..." -ForegroundColor Yellow
dotnet restore "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" --force --verbosity quiet

Write-Host ""
Write-Host "Verifying assets file..." -ForegroundColor Yellow

$assetsFile = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\project.assets.json"
if (Test-Path $assetsFile) {
    $assets = Get-Content $assetsFile -Raw | ConvertFrom-Json
    $targets = $assets.targets.PSObject.Properties.Name
    
    if ($targets -contains "net10.0") {
        Write-Host "? Assets file has correct target: net10.0" -ForegroundColor Green
        Write-Host ""
        Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
        Write-Host "  Ready for Visual Studio Packaging!" -ForegroundColor Green
        Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Open Visual Studio 2022" -ForegroundColor White
        Write-Host "  2. Right-click 'MCBDS.PublicUI' project" -ForegroundColor White
        Write-Host "  3. Hover over 'Publish'" -ForegroundColor White
        Write-Host "  4. Click 'Create App Packages...'" -ForegroundColor White
        Write-Host "     (NOT just 'Publish')" -ForegroundColor Yellow
        Write-Host "  5. Follow the wizard" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "? Assets file has incorrect targets:" -ForegroundColor Red
        Write-Host "  Found: $targets" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Try running again or contact support." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "? Assets file not found" -ForegroundColor Red
    exit 1
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

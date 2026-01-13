# Restore Project File After Packaging

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "Restoring project file..." -ForegroundColor Yellow

$projectFile = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
$backupFile = "$projectFile.backup"

if (Test-Path $backupFile) {
    Copy-Item $backupFile $projectFile -Force
    Remove-Item $backupFile -Force
    Write-Host "? Project file restored" -ForegroundColor Green
} else {
    Write-Host "??  Backup file not found" -ForegroundColor Yellow
}

Write-Host ""

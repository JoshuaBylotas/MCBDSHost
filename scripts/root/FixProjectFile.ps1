# Emergency Fix - Restore Project File from Backup

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "??????????????????????????????????????????????" -ForegroundColor Yellow
Write-Host "  Emergency Project File Restore" -ForegroundColor Yellow
Write-Host "??????????????????????????????????????????????" -ForegroundColor Yellow
Write-Host ""

$projectFile = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
$backupFile = "$projectFile.backup"

# Check for backup
if (Test-Path $backupFile) {
    Write-Host "Found backup: $backupFile" -ForegroundColor Green
    Write-Host "Restoring..." -ForegroundColor Yellow
    
    Copy-Item $backupFile $projectFile -Force
    Remove-Item $backupFile -Force
    
    Write-Host "? Project file restored from backup" -ForegroundColor Green
} else {
    Write-Host "??  No backup file found at: $backupFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Looking for timestamped backups..." -ForegroundColor Yellow
    
    $backupFiles = Get-ChildItem "MCBDS.PublicUI" -Filter "*.backup.*" | Sort-Object LastWriteTime -Descending
    
    if ($backupFiles) {
        $latestBackup = $backupFiles[0]
        Write-Host "Found: $($latestBackup.Name)" -ForegroundColor Green
        Write-Host "Restoring..." -ForegroundColor Yellow
        
        Copy-Item $latestBackup.FullName $projectFile -Force
        Remove-Item $latestBackup.FullName -Force
        
        Write-Host "? Project file restored from: $($latestBackup.Name)" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "? ERROR: No backup files found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual fix required:" -ForegroundColor Yellow
        Write-Host "1. Open: MCBDS.PublicUI\MCBDS.PublicUI.csproj" -ForegroundColor White
        Write-Host "2. Find the line with invalid XML comment containing '--'" -ForegroundColor White
        Write-Host "3. Either remove the comment or fix it" -ForegroundColor White
        Write-Host ""
        Write-Host "The issue is likely around line 42 with PackageCertificateThumbprint" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

Write-Host ""
Write-Host "Project file should now be valid." -ForegroundColor Green
Write-Host "Try reloading the project in Visual Studio." -ForegroundColor Cyan
Write-Host ""

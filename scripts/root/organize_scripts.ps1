# Script to organize all PS1 and SH scripts into a centralized scripts folder
$rootPath = "D:\source\repos\JoshuaBylotas\MCBDSHost"
$scriptsPath = "$rootPath\scripts"

Write-Host "Script Organization Tool" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Create scripts directory
Write-Host "`nCreating scripts directory..." -ForegroundColor Yellow
New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
Write-Host "[?] Created: $scriptsPath" -ForegroundColor Green

# Find all PS1 and SH files
Write-Host "`nSearching for script files..." -ForegroundColor Yellow
$scriptFiles = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object {
    ($_.Extension -eq ".ps1" -or $_.Extension -eq ".sh") -and
    $_.FullName -notlike "*\obj\*" -and
    $_.FullName -notlike "*\bin\*" -and
    $_.FullName -notlike "*\node_modules\*" -and
    $_.FullName -notlike "*\scripts\*"
}

Write-Host "Found $($scriptFiles.Count) script files to organize" -ForegroundColor White
Write-Host ""

# Track statistics
$movedCount = 0
$errorCount = 0

# Move each script file
foreach ($file in $scriptFiles) {
    try {
        # Calculate relative path from root
        $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
        
        # Determine if file is in root or in a subdirectory
        if ($relativePath.IndexOf('\') -eq -1) {
            # File is in root directory
            $destinationPath = "$scriptsPath\root"
            $destinationFile = "$destinationPath\$($file.Name)"
        }
        else {
            # File is in a subdirectory - preserve structure
            $relativeDir = Split-Path $relativePath -Parent
            $destinationPath = "$scriptsPath\$relativeDir"
            $destinationFile = "$scriptsPath\$relativePath"
        }
        
        # Create destination directory if it doesn't exist
        if (-not (Test-Path $destinationPath)) {
            New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
        }
        
        # Move the file
        Move-Item -Path $file.FullName -Destination $destinationFile -Force
        
        Write-Host "[?] Moved: $relativePath" -ForegroundColor Green
        Write-Host "    To: scripts\$($destinationFile.Replace($scriptsPath, '').TrimStart('\'))" -ForegroundColor Gray
        
        $movedCount++
    }
    catch {
        Write-Host "[?] Error moving: $($file.Name)" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

# Create a README in the scripts folder
Write-Host "`nCreating scripts README..." -ForegroundColor Yellow
$readmeContent = @"
# Scripts Directory

This directory contains all PowerShell (PS1) and Shell (SH) scripts from the MCBDSHost solution, organized to mirror the source directory structure.

## Directory Structure

- **root/** - Scripts that were in the solution root directory
- **[ProjectName]/** - Scripts organized by their source project

## Purpose

All automation, deployment, and utility scripts are centralized here for easy access and maintenance.

## Last Updated

$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Statistics

- Total scripts organized: $movedCount
- Errors during move: $errorCount
"@

Set-Content -Path "$scriptsPath\README.md" -Value $readmeContent -Force
Write-Host "[?] Created README.md" -ForegroundColor Green

# Clean up empty directories in the source tree (optional)
Write-Host "`nCleaning up empty directories..." -ForegroundColor Yellow
$cleanedDirs = 0
try {
    $emptyDirs = Get-ChildItem -Path $rootPath -Recurse -Directory | Where-Object {
        $_.FullName -notlike "*\scripts\*" -and
        $_.FullName -notlike "*\obj\*" -and
        $_.FullName -notlike "*\bin\*" -and
        $_.FullName -notlike "*\node_modules\*" -and
        $_.FullName -notlike "*\.git\*" -and
        @(Get-ChildItem $_.FullName -Force).Count -eq 0
    }
    
    foreach ($dir in $emptyDirs) {
        Remove-Item -Path $dir.FullName -Force -Recurse
        $cleanedDirs++
    }
    
    if ($cleanedDirs -gt 0) {
        Write-Host "[?] Removed $cleanedDirs empty directories" -ForegroundColor Green
    }
}
catch {
    Write-Host "[!] Could not clean all empty directories" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Script Organization Complete" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  Scripts Moved: $movedCount" -ForegroundColor Green
Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Empty Dirs Cleaned: $cleanedDirs" -ForegroundColor Green
Write-Host "`nAll scripts now in: $scriptsPath" -ForegroundColor Cyan

# Verification
Write-Host "`nVerifying organization..." -ForegroundColor Yellow
$remainingScripts = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object {
    ($_.Extension -eq ".ps1" -or $_.Extension -eq ".sh") -and
    $_.FullName -notlike "*\scripts\*" -and
    $_.FullName -notlike "*\obj\*" -and
    $_.FullName -notlike "*\bin\*" -and
    $_.FullName -notlike "*\node_modules\*"
}

if ($remainingScripts.Count -eq 0) {
    Write-Host "[???] SUCCESS! All scripts organized!" -ForegroundColor Green
}
else {
    Write-Host "[!] Warning: Found $($remainingScripts.Count) remaining scripts:" -ForegroundColor Yellow
    $remainingScripts | ForEach-Object {
        Write-Host "    - $($_.FullName.Replace($rootPath, '.'))" -ForegroundColor Yellow
    }
}

Write-Host "`nOperation complete!" -ForegroundColor Green

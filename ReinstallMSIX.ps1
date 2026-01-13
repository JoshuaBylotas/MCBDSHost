# Reinstall MSIX Package - Uninstall old and install new

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Reinstall MCBDS Package" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find and uninstall old versions
Write-Host "Step 1: Checking for existing installations..." -ForegroundColor Yellow
$existingPackages = Get-AppxPackage | Where-Object { 
    $_.Name -like "*MCBDS*" -or $_.Name -like "*MCBDSManager*" 
}

if ($existingPackages) {
    Write-Host ""
    Write-Host "Found existing package(s):" -ForegroundColor Cyan
    foreach ($pkg in $existingPackages) {
        Write-Host "  - $($pkg.Name) v$($pkg.Version)" -ForegroundColor White
        Write-Host "    Publisher: $($pkg.Publisher)" -ForegroundColor DarkGray
        Write-Host "    Package Family Name: $($pkg.PackageFamilyName)" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    Write-Host "Uninstalling old version(s)..." -ForegroundColor Yellow
    $existingPackages | Remove-AppxPackage
    
    if ($?) {
        Write-Host "? Old version(s) uninstalled" -ForegroundColor Green
    } else {
        Write-Host "? Failed to uninstall" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  No existing packages found" -ForegroundColor DarkGray
}
Write-Host ""

# Step 2: Find the newest MSIX package
Write-Host "Step 2: Finding newest MSIX package..." -ForegroundColor Yellow

$msixFiles = Get-ChildItem "AppPackages" -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending

if (-not $msixFiles) {
    Write-Host "? No MSIX packages found in AppPackages folder" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create a package first:" -ForegroundColor Yellow
    Write-Host "  .\CreateMSIXPackage.ps1" -ForegroundColor White
    exit 1
}

$latestMsix = $msixFiles[0]
Write-Host "  Found: $($latestMsix.Name)" -ForegroundColor Green
Write-Host "  Size:  $([math]::Round($latestMsix.Length / 1MB, 2)) MB" -ForegroundColor DarkGray
Write-Host "  Date:  $($latestMsix.LastWriteTime)" -ForegroundColor DarkGray
Write-Host ""

# Step 3: Install new package
Write-Host "Step 3: Installing new package..." -ForegroundColor Yellow
Write-Host ""

try {
    Add-AppxPackage -Path $latestMsix.FullName
    
    if ($?) {
        Write-Host ""
        Write-Host "? Package installed successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Verify installation
        $newPackage = Get-AppxPackage | Where-Object { 
            $_.Name -like "*MCBDS*" -or $_.Name -like "*MCBDSManager*" 
        } | Select-Object -First 1
        
        if ($newPackage) {
            Write-Host "Installed package details:" -ForegroundColor Cyan
            Write-Host "  Name:    $($newPackage.Name)" -ForegroundColor White
            Write-Host "  Version: $($newPackage.Version)" -ForegroundColor White
            Write-Host "  Publisher: $($newPackage.Publisher)" -ForegroundColor White
            Write-Host ""
        }
    }
} catch {
    Write-Host ""
    Write-Host "? Installation failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    
    # Common issues
    Write-Host "Common solutions:" -ForegroundColor Cyan
    Write-Host "  1. Make sure the package is signed with a trusted certificate" -ForegroundColor White
    Write-Host "  2. Install the certificate first if needed" -ForegroundColor White
    Write-Host "  3. Check if Developer Mode is enabled in Windows Settings" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Summary
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Reinstallation Complete" -ForegroundColor Green
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

Write-Host "You can now launch the app from the Start Menu" -ForegroundColor Cyan
Write-Host ""

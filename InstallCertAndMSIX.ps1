# Install Certificate and MSIX Package
# This installs the signing certificate first, then the MSIX package

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Install Certificate and MSIX Package" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "? This script requires Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Restarting as Administrator..." -ForegroundColor Cyan
    Write-Host ""
    
    # Restart as admin
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit -File `"$PSCommandPath`""
    exit
}

Write-Host "? Running as Administrator" -ForegroundColor Green
Write-Host ""

# Step 1: Find the certificate
Write-Host "Step 1: Locating signing certificate..." -ForegroundColor Yellow

$certThumbprint = "B97A80AD152EF3F18075E8F6B31A219112319F2B"

# Look in current user store first
$cert = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue | 
    Where-Object { $_.Thumbprint -eq $certThumbprint }

if (-not $cert) {
    # Try local machine store
    $cert = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | 
        Where-Object { $_.Thumbprint -eq $certThumbprint }
}

if (-not $cert) {
    Write-Host "? Certificate not found in certificate store" -ForegroundColor Red
    Write-Host ""
    Write-Host "Looking for certificate file..." -ForegroundColor Yellow
    
    # Look for .cer or .pfx file
    $certFiles = Get-ChildItem -Path . -Recurse -Include "*.cer","*.pfx" -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -like "*MCBDS*" -or $_.Name -like "*Pinecrest*" } |
        Select-Object -First 1
    
    if ($certFiles) {
        Write-Host "  Found: $($certFiles.FullName)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Installing certificate from file..." -ForegroundColor Cyan
        
        # Import to Trusted Root
        Import-Certificate -FilePath $certFiles.FullName -CertStoreLocation Cert:\LocalMachine\Root
        
        if ($?) {
            Write-Host "? Certificate installed" -ForegroundColor Green
        } else {
            Write-Host "? Failed to install certificate" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "? Certificate file not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "You need to:" -ForegroundColor Yellow
        Write-Host "  1. Export your certificate to a .cer file" -ForegroundColor White
        Write-Host "  2. Run: Import-Certificate -FilePath <cert.cer> -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor White
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "  Found certificate: $($cert.Subject)" -ForegroundColor Green
    Write-Host ""
    
    # Check if already in Trusted Root
    $rootCert = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue | 
        Where-Object { $_.Thumbprint -eq $certThumbprint }
    
    if ($rootCert) {
        Write-Host "? Certificate already trusted" -ForegroundColor Green
    } else {
        Write-Host "Installing certificate to Trusted Root..." -ForegroundColor Cyan
        
        # Export from current location
        $tempCert = "$env:TEMP\MCBDS_Cert.cer"
        Export-Certificate -Cert $cert -FilePath $tempCert -Force | Out-Null
        
        # Import to Trusted Root
        Import-Certificate -FilePath $tempCert -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
        
        # Clean up temp file
        Remove-Item $tempCert -Force -ErrorAction SilentlyContinue
        
        Write-Host "? Certificate installed to Trusted Root" -ForegroundColor Green
    }
}
Write-Host ""

# Step 2: Uninstall old package
Write-Host "Step 2: Removing old package..." -ForegroundColor Yellow

$oldPackages = Get-AppxPackage | Where-Object { 
    $_.Name -like "*MCBDS*" -or $_.Name -like "*MCBDSManager*" 
}

if ($oldPackages) {
    foreach ($pkg in $oldPackages) {
        Write-Host "  Removing: $($pkg.Name) v$($pkg.Version)" -ForegroundColor Cyan
        $pkg | Remove-AppxPackage
    }
    Write-Host "? Old package(s) removed" -ForegroundColor Green
} else {
    Write-Host "  No old packages found" -ForegroundColor DarkGray
}
Write-Host ""

# Step 3: Find and install new MSIX
Write-Host "Step 3: Installing new MSIX package..." -ForegroundColor Yellow

$msixFiles = Get-ChildItem "AppPackages" -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending

if (-not $msixFiles) {
    Write-Host "? No MSIX package found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create a package first:" -ForegroundColor Yellow
    Write-Host "  .\CreateMSIXPackage.ps1" -ForegroundColor White
    exit 1
}

$latestMsix = $msixFiles[0]
Write-Host "  Package: $($latestMsix.Name)" -ForegroundColor Cyan
Write-Host "  Size:    $([math]::Round($latestMsix.Length / 1MB, 2)) MB" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Installing..." -ForegroundColor Cyan

try {
    Add-AppxPackage -Path $latestMsix.FullName
    
    Write-Host ""
    Write-Host "? Package installed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify
    $newPkg = Get-AppxPackage | Where-Object { 
        $_.Name -like "*MCBDS*" -or $_.Name -like "*MCBDSManager*" 
    } | Select-Object -First 1
    
    if ($newPkg) {
        Write-Host "Installed package:" -ForegroundColor Cyan
        Write-Host "  Name:    $($newPkg.Name)" -ForegroundColor White
        Write-Host "  Version: $($newPkg.Version)" -ForegroundColor White
        Write-Host "  Status:  $($newPkg.Status)" -ForegroundColor White
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "? Installation failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    
    # Additional diagnostics
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "  1. Check Event Viewer for details:" -ForegroundColor White
    Write-Host "     Event Viewer ? Applications and Services Logs ? Microsoft ? Windows ? AppXDeployment-Server" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. Enable Developer Mode:" -ForegroundColor White
    Write-Host "     Settings ? Privacy & Security ? For developers ? Developer Mode" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  3. Check certificate is trusted:" -ForegroundColor White
    Write-Host "     certmgr.msc ? Trusted Root Certification Authorities ? Certificates" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

# Summary
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Installation Complete" -ForegroundColor Green
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""
Write-Host "You can now launch 'MCBDS Manager' from the Start Menu" -ForegroundColor Cyan
Write-Host ""

# Pause so window doesn't close if run as admin
if (-not $isAdmin) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

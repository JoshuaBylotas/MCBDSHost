# Diagnose Package Identity and Certificate Issues

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Package Identity Diagnostic" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Read manifest
$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"
[xml]$manifest = Get-Content $manifestPath
$identity = $manifest.Package.Identity

Write-Host "Current Manifest Settings:" -ForegroundColor Yellow
Write-Host "  Identity Name: $($identity.Name)" -ForegroundColor White
Write-Host "  Publisher:     $($identity.Publisher)" -ForegroundColor White
Write-Host "  Version:       $($identity.Version)" -ForegroundColor White
Write-Host ""

# Calculate expected Package Family Name
$identityName = $identity.Name
$publisher = $identity.Publisher

Write-Host "Calculating Package Family Name..." -ForegroundColor Yellow
Write-Host "  Formula: IdentityName + '_' + Hash(Publisher)" -ForegroundColor DarkGray
Write-Host ""

# The hash is calculated by Windows, we can't replicate it exactly,
# but we can check what Windows thinks the PFN should be

# Check if package is already installed
Write-Host "Checking for installed packages..." -ForegroundColor Yellow
$installedPackages = Get-AppxPackage | Where-Object { $_.Name -like "*MCBDSManager*" }

if ($installedPackages) {
    Write-Host ""
    Write-Host "Found installed package(s):" -ForegroundColor Green
    foreach ($pkg in $installedPackages) {
        Write-Host ""
        Write-Host "  Package Full Name:   $($pkg.PackageFullName)" -ForegroundColor Cyan
        Write-Host "  Package Family Name: $($pkg.PackageFamilyName)" -ForegroundColor Cyan
        Write-Host "  Publisher:           $($pkg.Publisher)" -ForegroundColor White
        Write-Host "  Version:             $($pkg.Version)" -ForegroundColor White
        Write-Host "  Install Location:    $($pkg.InstallLocation)" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    # Check if publisher matches
    $installedPublisher = $installedPackages[0].Publisher
    if ($installedPublisher -ne $publisher) {
        Write-Host "? PUBLISHER MISMATCH!" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Manifest Publisher: $publisher" -ForegroundColor Yellow
        Write-Host "  Installed Package:  $installedPublisher" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will cause installation to fail!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Solution:" -ForegroundColor Cyan
        Write-Host "  1. Uninstall the current package:" -ForegroundColor White
        Write-Host "     Get-AppxPackage *MCBDSManager* | Remove-AppxPackage" -ForegroundColor DarkGray
        Write-Host "  2. Then install the new package" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host "  No MCBDS packages currently installed" -ForegroundColor DarkGray
    Write-Host ""
}

# Check certificate store
Write-Host "Checking certificate store..." -ForegroundColor Yellow
$certThumbprint = "B97A80AD152EF3F18075E8F6B31A219112319F2B"

$cert = Get-ChildItem Cert:\CurrentUser\My,Cert:\LocalMachine\My -ErrorAction SilentlyContinue | 
    Where-Object { $_.Thumbprint -eq $certThumbprint } | 
    Select-Object -First 1

if ($cert) {
    Write-Host ""
    Write-Host "Found certificate:" -ForegroundColor Green
    Write-Host "  Subject:    $($cert.Subject)" -ForegroundColor White
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
    Write-Host "  Issuer:     $($cert.Issuer)" -ForegroundColor DarkGray
    Write-Host "  Valid From: $($cert.NotBefore)" -ForegroundColor DarkGray
    Write-Host "  Valid To:   $($cert.NotAfter)" -ForegroundColor DarkGray
    Write-Host ""
    
    # Check if cert subject matches publisher
    if ($cert.Subject -ne $publisher) {
        Write-Host "? Certificate subject doesn't match manifest publisher" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Certificate: $($cert.Subject)" -ForegroundColor White
        Write-Host "  Manifest:    $publisher" -ForegroundColor White
        Write-Host ""
        Write-Host "This is normal for Store-issued certificates" -ForegroundColor DarkGray
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "? Certificate not found in store" -ForegroundColor Yellow
    Write-Host "  Thumbprint: $certThumbprint" -ForegroundColor DarkGray
    Write-Host ""
}

# Check the MSIX package if it exists
Write-Host "Checking created MSIX package..." -ForegroundColor Yellow
$msixFiles = Get-ChildItem "AppPackages" -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($msixFiles) {
    $msixPath = $msixFiles.FullName
    Write-Host ""
    Write-Host "Found package: $msixPath" -ForegroundColor Green
    Write-Host ""
    
    # Try to get package info without installing
    Write-Host "Attempting to read package identity..." -ForegroundColor Cyan
    
    try {
        # Use Get-AppxPackage with -Path to inspect without installing
        $packageInfo = Get-AppxPackage -Path $msixPath -ErrorAction Stop
        
        Write-Host ""
        Write-Host "Package Identity:" -ForegroundColor Green
        Write-Host "  Name:               $($packageInfo.Name)" -ForegroundColor White
        Write-Host "  Publisher:          $($packageInfo.Publisher)" -ForegroundColor White
        Write-Host "  Version:            $($packageInfo.Version)" -ForegroundColor White
        Write-Host "  Package Family Name: $($packageInfo.PackageFamilyName)" -ForegroundColor Cyan
        Write-Host ""
        
        # Compare with expected
        Write-Host "Expected vs Actual:" -ForegroundColor Yellow
        Write-Host "  Expected PFN: 50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w" -ForegroundColor White
        Write-Host "  Actual PFN:   $($packageInfo.PackageFamilyName)" -ForegroundColor White
        Write-Host ""
        
        if ($packageInfo.PackageFamilyName -ne "50677PinecrestConsultants.MCBDSManager_n8ws8gp0q633w") {
            Write-Host "? Package Family Name mismatch!" -ForegroundColor Red
            Write-Host ""
            Write-Host "This means the publisher in the manifest doesn't match" -ForegroundColor Yellow
            Write-Host "what Microsoft Store expects for your app." -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        Write-Host ""
        Write-Host "Could not read package info: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "  No MSIX packages found in AppPackages folder" -ForegroundColor DarkGray
    Write-Host ""
}

# Summary and recommendations
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Recommendations" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

Write-Host "The error you're seeing suggests:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Expected Publisher: CN=<some other value>" -ForegroundColor White
Write-Host "  Your Publisher:     $publisher" -ForegroundColor White
Write-Host ""

Write-Host "Solutions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. If this is a NEW Store submission:" -ForegroundColor Green
Write-Host "   - The current manifest is correct" -ForegroundColor White
Write-Host "   - Submit to Store and let them assign the PFN" -ForegroundColor White
Write-Host ""

Write-Host "2. If UPDATING an existing Store app:" -ForegroundColor Green
Write-Host "   - Download the correct publisher info from Partner Center" -ForegroundColor White
Write-Host "   - Go to: Product Identity section in Partner Center" -ForegroundColor White
Write-Host "   - Copy the correct Publisher value" -ForegroundColor White
Write-Host "   - Update your manifest with that value" -ForegroundColor White
Write-Host ""

Write-Host "3. If testing locally:" -ForegroundColor Green
Write-Host "   - Uninstall any existing versions first:" -ForegroundColor White
Write-Host "     Get-AppxPackage *MCBDSManager* | Remove-AppxPackage" -ForegroundColor DarkGray
Write-Host "   - Then install the new package" -ForegroundColor White
Write-Host ""

Write-Host "To get the correct Publisher from Partner Center:" -ForegroundColor Yellow
Write-Host "  1. Go to: https://partner.microsoft.com/dashboard/" -ForegroundColor Cyan
Write-Host "  2. Select your app: MCBDS Manager" -ForegroundColor Cyan
Write-Host "  3. Go to: Product management ? Product identity" -ForegroundColor Cyan
Write-Host "  4. Copy the 'Publisher' value (should start with CN=)" -ForegroundColor Cyan
Write-Host ""

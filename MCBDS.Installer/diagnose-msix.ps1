# MSIX Installation Diagnostics Script
# Run this script AS ADMINISTRATOR to diagnose MSIX installation issues

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MSIX Installation Diagnostics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check if running as Administrator
Write-Host "`n1. Checking Administrator Privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "   ? Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "   ? NOT running as Administrator - certificate installation will fail!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
}

# 2. Check Certificate Files
Write-Host "`n2. Checking Certificate Files..." -ForegroundColor Yellow
$cerPath = "MCBDS.Installer\CodeSigning.cer"
$pfxPath = "MCBDS.Installer\CodeSigning.pfx"

if (Test-Path $cerPath) {
    Write-Host "   ? CER file exists: $cerPath" -ForegroundColor Green
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
    Write-Host "     Subject: $($cert.Subject)" -ForegroundColor White
    Write-Host "     Issuer: $($cert.Issuer)" -ForegroundColor White
    Write-Host "     Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
    Write-Host "     Valid: $($cert.NotBefore) to $($cert.NotAfter)" -ForegroundColor White
} else {
    Write-Host "   ? CER file NOT found: $cerPath" -ForegroundColor Red
}

if (Test-Path $pfxPath) {
    Write-Host "   ? PFX file exists: $pfxPath" -ForegroundColor Green
} else {
    Write-Host "   ? PFX file NOT found: $pfxPath" -ForegroundColor Red
}

# 3. Check Certificate Stores
Write-Host "`n3. Checking Certificate Stores..." -ForegroundColor Yellow

Write-Host "   CurrentUser\My (Personal):" -ForegroundColor White
$myStore = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -like "*Pinecrest*"}
if ($myStore) {
    foreach ($c in $myStore) {
        Write-Host "     ? $($c.Subject) [Thumbprint: $($c.Thumbprint)]" -ForegroundColor Green
    }
} else {
    Write-Host "     ? No Pinecrest certificates" -ForegroundColor Red
}

Write-Host "   LocalMachine\Root (Trusted Root):" -ForegroundColor White
$rootStore = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Subject -like "*Pinecrest*"}
if ($rootStore) {
    foreach ($c in $rootStore) {
        Write-Host "     ? $($c.Subject) [Thumbprint: $($c.Thumbprint)]" -ForegroundColor Green
    }
} else {
    Write-Host "     ? No Pinecrest certificates" -ForegroundColor Red
}

# 4. Try Manual Certificate Installation
Write-Host "`n4. Attempting Manual Certificate Installation..." -ForegroundColor Yellow
if (Test-Path $cerPath) {
    try {
        $certObj = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        $store.Open("ReadWrite")
        $store.Add($certObj)
        $store.Close()
        Write-Host "   ? Certificate installed to LocalMachine\Root" -ForegroundColor Green
    } catch {
        Write-Host "   ? Failed to install certificate: $($_.Exception.Message)" -ForegroundColor Red
        if (-not $isAdmin) {
            Write-Host "   This requires Administrator privileges!" -ForegroundColor Yellow
        }
    }
}

# 5. Check MSIX File and Signature
Write-Host "`n5. Checking MSIX Package..." -ForegroundColor Yellow
$msixPath = "MCBDS.Installer\MCBDS.PublicUI.msix"
if (Test-Path $msixPath) {
    $msixFile = Get-Item $msixPath
    Write-Host "   ? MSIX exists: $($msixFile.Length) bytes ($([math]::Round($msixFile.Length/1MB, 2)) MB)" -ForegroundColor Green
    
    # Try to get signature
    try {
        $sig = Get-AuthenticodeSignature $msixPath
        Write-Host "   Signature Status: $($sig.Status)" -ForegroundColor $(if ($sig.Status -eq 'Valid') {'Green'} else {'Yellow'})
        if ($sig.SignerCertificate) {
            Write-Host "   Signed By: $($sig.SignerCertificate.Subject)" -ForegroundColor White
            Write-Host "   Cert Thumbprint: $($sig.SignerCertificate.Thumbprint)" -ForegroundColor White
        }
    } catch {
        Write-Host "   ? Could not read signature: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ? MSIX NOT found: $msixPath" -ForegroundColor Red
}

# 6. Try Manual MSIX Installation with Detailed Errors
Write-Host "`n6. Attempting Manual MSIX Installation..." -ForegroundColor Yellow
if (Test-Path $msixPath) {
    Write-Host "   Running: Add-AppxPackage -Path '$msixPath' -Verbose" -ForegroundColor White
    try {
        Add-AppxPackage -Path $msixPath -ForceApplicationShutdown -ErrorAction Stop -Verbose 4>&1 | Out-String | Write-Host
        Write-Host "   ??? MSIX INSTALLED SUCCESSFULLY!" -ForegroundColor Green
    } catch {
        Write-Host "   ? MSIX Installation Failed" -ForegroundColor Red
        Write-Host "   Error Message: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   HRESULT: $($_.Exception.HResult)" -ForegroundColor Red
        
        # Get more details from event log
        Write-Host "`n   Checking Windows Event Log for details..." -ForegroundColor Yellow
        $events = Get-WinEvent -LogName "Microsoft-Windows-AppXDeployment/Operational" -MaxEvents 5 -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated -gt (Get-Date).AddMinutes(-5)}
        if ($events) {
            foreach ($evt in $events) {
                Write-Host "     Event $($evt.Id): $($evt.Message)" -ForegroundColor Yellow
            }
        }
    }
}

# 7. Check Developer Mode
Write-Host "`n7. Checking Developer Mode..." -ForegroundColor Yellow
$devMode = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue
if ($devMode.AllowDevelopmentWithoutDevLicense -eq 1) {
    Write-Host "   ? Developer Mode is ENABLED" -ForegroundColor Green
} else {
    Write-Host "   ? Developer Mode is DISABLED" -ForegroundColor Yellow
    Write-Host "   Enable in: Settings > Update & Security > For Developers" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Diagnostics Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. If certificate is NOT in LocalMachine\Root, run this script as Administrator" -ForegroundColor White
Write-Host "2. If MSIX installation still fails, check the event log details above" -ForegroundColor White
Write-Host "3. Ensure the MSIX signature thumbprint matches the certificate thumbprint" -ForegroundColor White

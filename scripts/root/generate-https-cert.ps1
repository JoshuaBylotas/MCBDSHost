# =============================================================================
# MCBDS API - Self-Signed Certificate Generator (Windows)
# =============================================================================
# This script generates a self-signed SSL certificate for the MCBDS API server.
# Run this script as Administrator before deploying the HTTPS Docker container.
# =============================================================================

param(
    [string]$ServerIP = "",
    [string]$CertPassword = "McbdsApiCert123!",
    [int]$ValidityYears = 5
)

$ErrorActionPreference = "Stop"

# Configuration
$CertDir = ".\certs"
$CertName = "mcbds-api"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  MCBDS API Certificate Generator" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Get server IP if not provided
if ([string]::IsNullOrEmpty($ServerIP)) {
    Write-Host "Enter your server's IP address (or press Enter for localhost only):" -ForegroundColor Yellow
    $ServerIP = Read-Host
    
    if ([string]::IsNullOrEmpty($ServerIP)) {
        $ServerIP = "127.0.0.1"
        Write-Host "Using default: $ServerIP"
    }
}

# Create certs directory
Write-Host ""
Write-Host "Step 1: Creating certificate directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $CertDir -Force | Out-Null
Write-Host "? Created $CertDir" -ForegroundColor Green

# Generate certificate
Write-Host ""
Write-Host "Step 2: Generating self-signed certificate..." -ForegroundColor Yellow

$DnsNames = @("localhost", "mcbds-api", $ServerIP)

$cert = New-SelfSignedCertificate `
    -DnsName $DnsNames `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears($ValidityYears) `
    -FriendlyName "MCBDS API Certificate" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -HashAlgorithm SHA256

Write-Host "? Generated certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Export to PFX
Write-Host ""
Write-Host "Step 3: Exporting to PFX format..." -ForegroundColor Yellow

$securePassword = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
$pfxPath = Join-Path $CertDir "$CertName.pfx"

Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null

Write-Host "? Created PFX file" -ForegroundColor Green

# Export public certificate
Write-Host ""
Write-Host "Step 4: Exporting public certificate..." -ForegroundColor Yellow

$cerPath = Join-Path $CertDir "$CertName.cer"
Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null

Write-Host "? Created CER file" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Certificate Generated Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:"
Write-Host "  $CertDir\$CertName.pfx  - SSL certificate (for Docker)"
Write-Host "  $CertDir\$CertName.cer  - Public certificate"
Write-Host ""
Write-Host "Certificate password: " -NoNewline
Write-Host $CertPassword -ForegroundColor Yellow
Write-Host "Valid for: $ValidityYears years"
Write-Host "Server IP: $ServerIP"
Write-Host "Thumbprint: $($cert.Thumbprint)"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copy files to your Linux server:" -ForegroundColor Cyan
Write-Host "   scp -r .\certs user@your-server:/path/to/MCBDSHost/"
Write-Host ""
Write-Host "2. Start the HTTPS Docker container:" -ForegroundColor Cyan
Write-Host "   docker-compose -f docker-compose.https.yml up -d"
Write-Host ""
Write-Host "3. Test HTTPS connection:" -ForegroundColor Cyan
Write-Host "   curl -k https://localhost:8081/api/runner/status"
Write-Host ""
Write-Host "4. Update PublicUI.Web to use:" -ForegroundColor Cyan
Write-Host "   https://${ServerIP}:8081"
Write-Host ""

# Optional: Trust the certificate locally
Write-Host "Would you like to trust this certificate on this machine? (y/N): " -ForegroundColor Yellow -NoNewline
$trustCert = Read-Host

if ($trustCert -eq 'y' -or $trustCert -eq 'Y') {
    try {
        Import-Certificate -FilePath $cerPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
        Write-Host "? Certificate trusted on this machine" -ForegroundColor Green
    }
    catch {
        Write-Host "? Could not trust certificate (run as Administrator)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

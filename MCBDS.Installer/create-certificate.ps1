# Create Self-Signed Certificate for MSIX Signing
# Run this script as Administrator

param(
    [string]$CertName = "MCBDS Manager Code Signing",
    [string]$Publisher = "CN=Pinecrest Consultants",
    [string]$OutputPath = "MCBDS.Installer\CodeSigning.pfx",
    [string]$Password = ""
)

Write-Host "Creating self-signed certificate for MSIX signing..." -ForegroundColor Cyan

# Generate a strong password if not provided
if ([string]::IsNullOrEmpty($Password)) {
    Add-Type -AssemblyName System.Web
    $Password = [System.Web.Security.Membership]::GeneratePassword(16, 4)
    Write-Host "Generated password: $Password" -ForegroundColor Yellow
    Write-Host "SAVE THIS PASSWORD! You'll need it to sign the MSIX." -ForegroundColor Red
}

$securePassword = ConvertTo-SecureString -String $Password -Force -AsPlainText

# Create the certificate
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $Publisher `
    -KeyUsage DigitalSignature `
    -FriendlyName $CertName `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") `
    -NotAfter (Get-Date).AddYears(3)

Write-Host "? Certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Export to PFX file
$pfxPath = Join-Path (Get-Location) $OutputPath
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
Write-Host "? Certificate exported to: $pfxPath" -ForegroundColor Green

# Also export public key for server installation
$cerPath = $pfxPath -replace '\.pfx$', '.cer'
Export-Certificate -Cert $cert -FilePath $cerPath -Type CERT | Out-Null
Write-Host "? Public certificate exported to: $cerPath" -ForegroundColor Green

# Save password securely
$passwordFile = $pfxPath -replace '\.pfx$', '.password.txt'
$Password | Out-File -FilePath $passwordFile -NoNewline -Encoding UTF8
Write-Host "? Password saved to: $passwordFile" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Certificate Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. The build script will use this certificate to sign the MSIX" -ForegroundColor White
Write-Host "2. On your server, install the certificate to Trusted Root:" -ForegroundColor White
Write-Host "   Right-click $cerPath" -ForegroundColor Gray
Write-Host "   Select 'Install Certificate'" -ForegroundColor Gray
Write-Host "   Choose 'Local Machine'" -ForegroundColor Gray
Write-Host "   Place in 'Trusted Root Certification Authorities'" -ForegroundColor Gray
Write-Host "`n3. Or use PowerShell on the server:" -ForegroundColor White
Write-Host "   Import-Certificate -FilePath '$cerPath' -CertStoreLocation 'Cert:\LocalMachine\Root'" -ForegroundColor Gray

# Prepare MSIX for Microsoft Store Submission

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Prepare MSIX for Microsoft Store" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Find the latest MSIX package
Write-Host "Locating MSIX package..." -ForegroundColor Yellow
$msixFiles = Get-ChildItem "AppPackages" -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending

if (-not $msixFiles) {
    Write-Host "? No MSIX packages found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create a package first:" -ForegroundColor Yellow
    Write-Host "  .\CreateMSIXPackage.ps1" -ForegroundColor White
    exit 1
}

$latestMsix = $msixFiles[0]
Write-Host ""
Write-Host "Found package:" -ForegroundColor Green
Write-Host "  ?? File:    $($latestMsix.Name)" -ForegroundColor White
Write-Host "  ?? Path:    $($latestMsix.DirectoryName)" -ForegroundColor DarkGray
Write-Host "  ?? Size:    $([math]::Round($latestMsix.Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host "  ?? Created: $($latestMsix.LastWriteTime)" -ForegroundColor DarkGray
Write-Host ""

# Read package version from manifest
$manifestPath = "MCBDS.PublicUI\Platforms\Windows\Package.appxmanifest"
[xml]$manifest = Get-Content $manifestPath
$version = $manifest.Package.Identity.Version
$name = $manifest.Package.Identity.Name
$publisher = $manifest.Package.Identity.Publisher

Write-Host "Package Details:" -ForegroundColor Cyan
Write-Host "  Identity: $name" -ForegroundColor White
Write-Host "  Version:  $version" -ForegroundColor White
Write-Host "  Publisher: $publisher" -ForegroundColor DarkGray
Write-Host ""

# Check if package is signed
Write-Host "Checking package signature..." -ForegroundColor Yellow
try {
    $signature = Get-AuthenticodeSignature -FilePath $latestMsix.FullName
    
    if ($signature.Status -eq "Valid") {
        Write-Host "? Package is signed and valid" -ForegroundColor Green
        Write-Host "  Signer: $($signature.SignerCertificate.Subject)" -ForegroundColor DarkGray
    } elseif ($signature.Status -eq "NotSigned") {
        Write-Host "? Package is NOT signed" -ForegroundColor Yellow
        Write-Host "  Microsoft Store requires signed packages" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The Store will re-sign it, but it's better to sign locally first" -ForegroundColor DarkGray
    } else {
        Write-Host "? Package signature status: $($signature.Status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "? Could not verify signature" -ForegroundColor Yellow
}
Write-Host ""

# Create a submission-ready folder
$submissionFolder = "AppPackages\StoreSubmission_$version"
if (Test-Path $submissionFolder) {
    Remove-Item $submissionFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $submissionFolder -Force | Out-Null

# Copy MSIX to submission folder
Write-Host "Preparing submission package..." -ForegroundColor Yellow
Copy-Item $latestMsix.FullName -Destination $submissionFolder
Write-Host "? Package copied to: $submissionFolder" -ForegroundColor Green
Write-Host ""

# Create submission checklist
$checklistPath = Join-Path $submissionFolder "SUBMISSION_CHECKLIST.txt"
$checklist = @"
???????????????????????????????????????????????????
  Microsoft Store Submission Checklist
???????????????????????????????????????????????????

Package Information:
--------------------
File:      $($latestMsix.Name)
Version:   $version
Identity:  $name
Publisher: $publisher
Size:      $([math]::Round($latestMsix.Length / 1MB, 2)) MB

Pre-Submission Checklist:
--------------------------
? Package tested locally (installed and runs correctly)
? All features working as expected
? No crashes or errors
? Screenshots prepared (at least 1, recommended 3-5)
? App description updated
? Privacy policy URL ready (if collecting data)
? Support contact information ready

Microsoft Partner Center Steps:
--------------------------------
1. Go to: https://partner.microsoft.com/dashboard/
2. Sign in with your Microsoft account
3. Navigate to: Apps and games ? All products
4. Find: MCBDS Manager (50677PinecrestConsultants.MCBDSManager)
5. Click on the app to open it

Create New Submission:
----------------------
1. In the app overview, click "Start new submission"
2. Fill in required sections:

   A. Pricing and availability
      - Markets: Select where to distribute
      - Pricing: Free or Paid
      - Visibility: Public, Private, or Hidden

   B. Properties
      - Category: Select appropriate category
      - System requirements: Minimum Windows 10 version

   C. Age ratings
      - Complete the questionnaire

   D. Packages
      - Click "Browse files"
      - Upload: $($latestMsix.Name)
      - Wait for validation (may take a few minutes)
      - Check for any errors/warnings

   E. Store listings
      - Description: Describe your app
      - Screenshots: Upload at least 1 (1366x768 or larger)
      - App tile icon: 300x300 px
      - Additional assets: Optional but recommended

   F. Notes for certification
      - Add any special instructions for testers
      - Login credentials if needed

3. Review all sections
4. Click "Submit to the Store"

After Submission:
-----------------
- Certification usually takes 1-3 days
- You'll receive email updates on status
- Check Partner Center dashboard for progress
- If there are issues, they'll be listed in the submission

Store Listing Assets Needed:
-----------------------------
Required:
  - App description (10-10,000 characters)
  - At least 1 screenshot (1366x768 or larger)
  
Recommended:
  - 3-5 screenshots showing key features
  - Hero image (1920x1080)
  - App tile (300x300)
  - Promotional images (optional)

Privacy Policy:
---------------
If your app:
  - Collects personal information
  - Transmits data over the internet
  - Uses analytics

You MUST provide a privacy policy URL.

Support Information:
--------------------
Provide at least one contact method:
  - Website
  - Email
  - Support page URL

Version Notes:
--------------
This is version $version
Make sure to increment version number for each submission.
Next version should be: $($version.Split('.')[0]).$($version.Split('.')[1]).$($version.Split('.')[2]).$([int]$version.Split('.')[3] + 1)

Package File Location:
----------------------
$($latestMsix.FullName)

Submission Folder:
------------------
$submissionFolder

???????????????????????????????????????????????????
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
???????????????????????????????????????????????????
"@

$checklist | Out-File -FilePath $checklistPath -Encoding UTF8
Write-Host "? Submission checklist created" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "  ? Ready for Microsoft Store Submission" -ForegroundColor Green
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Green
Write-Host ""

Write-Host "Submission package location:" -ForegroundColor Cyan
Write-Host "  $submissionFolder" -ForegroundColor White
Write-Host ""

Write-Host "Files in submission folder:" -ForegroundColor Cyan
Get-ChildItem $submissionFolder | ForEach-Object {
    Write-Host "  • $($_.Name)" -ForegroundColor White
}
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Review the checklist:" -ForegroundColor White
Write-Host "     notepad `"$checklistPath`"" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. Go to Partner Center:" -ForegroundColor White
Write-Host "     https://partner.microsoft.com/dashboard/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Navigate to your app:" -ForegroundColor White
Write-Host "     Apps and games ? All products ? MCBDS Manager" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4. Start new submission" -ForegroundColor White
Write-Host ""
Write-Host "  5. Upload the MSIX file:" -ForegroundColor White
Write-Host "     $($latestMsix.Name)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  6. Complete all required sections" -ForegroundColor White
Write-Host ""
Write-Host "  7. Submit to the Store" -ForegroundColor White
Write-Host ""

Write-Host "Opening checklist in Notepad..." -ForegroundColor Yellow
Start-Process notepad.exe -ArgumentList $checklistPath

Write-Host ""
Write-Host "Opening Partner Center in browser..." -ForegroundColor Yellow
Start-Process "https://partner.microsoft.com/dashboard/"

Write-Host ""
Write-Host "Good luck with your submission! ??" -ForegroundColor Green
Write-Host ""

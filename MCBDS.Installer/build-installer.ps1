# Build and Create NSIS Installer for MCBDS Manager
# This script publishes the Windows Service and Public UI, then builds the NSIS installer

param(
    [string]$Configuration = "Release",
    [string]$NsisPath = "C:\Program Files (x86)\NSIS\makensis.exe",
    [string]$Version = "",
    [switch]$IncrementVersion
)

# Colors for output
$Success = "Green"
$Error = "Red"
$Info = "Cyan"
$Warning = "Yellow"

# Version file for tracking
$VersionFilePath = "MCBDS.Installer\version.txt"

Write-Host "========================================" -ForegroundColor $Info
Write-Host "MCBDS Manager Installer Build Script" -ForegroundColor $Info
Write-Host "========================================" -ForegroundColor $Info

# Determine version
if ($Version -eq "") {
    # Read from version file or default
    if (Test-Path $VersionFilePath) {
        $Version = Get-Content $VersionFilePath -Raw
        $Version = $Version.Trim()
    } else {
        $Version = "1.0.0"
    }
}

# Increment version if requested
if ($IncrementVersion) {
    $VersionParts = $Version.Split('.')
    if ($VersionParts.Length -ge 3) {
        $VersionParts[2] = [int]$VersionParts[2] + 1
        $Version = $VersionParts -join '.'
    } else {
        $Version = "$Version.1"
    }
    Write-Host "Version incremented to: $Version" -ForegroundColor $Warning
}

# Save version for next build
$Version | Out-File -FilePath $VersionFilePath -NoNewline -Encoding UTF8
Write-Host "Building version: $Version" -ForegroundColor $Info

# Setup output directory
$OutputDir = "Publish\$Version"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
Write-Host "Output directory: $OutputDir" -ForegroundColor $Info

# Step 1: Check NSIS installation
Write-Host "`n[1/4] Checking NSIS installation..." -ForegroundColor $Info
if (-not (Test-Path $NsisPath)) {
    Write-Host "ERROR: NSIS not found at $NsisPath" -ForegroundColor $Error
    Write-Host "Please install NSIS from: https://nsis.sourceforge.io/" -ForegroundColor $Error
    Write-Host "Or update the -NsisPath parameter." -ForegroundColor $Error
    exit 1
}
Write-Host "? NSIS found" -ForegroundColor $Success

# Step 2: Publish Windows Service
Write-Host "`n[2/4] Publishing Windows Service..." -ForegroundColor $Info
$ServiceProjectPath = "MCBDS.WindowsService\MCBDS.WindowsService.csproj"

if (-not (Test-Path $ServiceProjectPath)) {
    Write-Host "ERROR: Windows Service project not found at $ServiceProjectPath" -ForegroundColor $Error
    exit 1
}

$PublishOutput = dotnet publish $ServiceProjectPath -c $Configuration -r win-x64 --self-contained -p:Version=$Version 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to publish Windows Service" -ForegroundColor $Error
    Write-Host $PublishOutput
    exit 1
}
Write-Host "? Windows Service published" -ForegroundColor $Success

# Find Visual Studio MSBuild (required for MAUI builds)
Write-Host "`nLocating Visual Studio MSBuild..." -ForegroundColor $Info
$VSMSBuildPaths = @(
    "C:\Program Files\Microsoft Visual Studio\18\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
)

$MSBuildPath = $null
foreach ($path in $VSMSBuildPaths) {
    if (Test-Path $path) {
        $MSBuildPath = $path
        break
    }
}

if ($null -eq $MSBuildPath) {
    Write-Host "ERROR: Visual Studio MSBuild not found" -ForegroundColor $Error
    Write-Host "MAUI builds require Visual Studio's MSBuild" -ForegroundColor $Error
    Write-Host "Please install Visual Studio 2022 or later" -ForegroundColor $Error
    exit 1
}
Write-Host "? MSBuild found: $MSBuildPath" -ForegroundColor $Success

# Step 3: Build PublicUI MAUI App (MSIX package)
Write-Host "`n[3/4] Building PublicUI MAUI App as MSIX package..." -ForegroundColor $Info
$PublicUIProjectPath = "MCBDS.PublicUI\MCBDS.PublicUI.csproj"
$SharedProjectPath = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj"

if (-not (Test-Path $PublicUIProjectPath)) {
    Write-Host "ERROR: PublicUI project not found at $PublicUIProjectPath" -ForegroundColor $Error
    exit 1
}

# Clean previous builds completely
$PublicUIBinDir = "MCBDS.PublicUI\bin\$Configuration"
$PublicUIObjDir = "MCBDS.PublicUI\obj\$Configuration"
$SharedBinDir = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\bin\$Configuration"
$SharedObjDir = "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj"

Write-Host "Cleaning previous build artifacts..." -ForegroundColor $Info
@($PublicUIBinDir, $PublicUIObjDir, $SharedBinDir, $SharedObjDir) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
    }
}

# First restore the shared library project for net10.0
Write-Host "`nRestoring shared library (MCBDS.ClientUI.Shared)..." -ForegroundColor $Info
$SharedRestoreOutput = & dotnet restore $SharedProjectPath 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to restore shared library" -ForegroundColor $Error
    Write-Host $SharedRestoreOutput
    exit 1
}
Write-Host "? Shared library restored" -ForegroundColor $Success

# Now restore the MAUI project
Write-Host "`nRestoring MAUI project packages..." -ForegroundColor $Info
$RestoreOutput = & $MSBuildPath $PublicUIProjectPath `
    /t:Restore `
    /p:Configuration=$Configuration `
    /v:quiet 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Package restore failed for MAUI project" -ForegroundColor $Error
    Write-Host $RestoreOutput
    exit 1
}
Write-Host "? MAUI project packages restored" -ForegroundColor $Success

# Build the MSIX package using Publish target
Write-Host "`nBuilding MSIX package (this may take a few minutes)..." -ForegroundColor $Info
Write-Host "Command: MSBuild /t:Publish with MSIX packaging..." -ForegroundColor $Info

# Get the certificate thumbprint from the store
$certInStore = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*Pinecrest Consultants*" -and $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $certInStore) {
    Write-Host "ERROR: Certificate not found in CurrentUser\My store" -ForegroundColor $Error
    Write-Host "Expected: Certificate with subject containing 'Pinecrest Consultants'" -ForegroundColor $Error
    Write-Host "Run: Get-ChildItem Cert:\CurrentUser\My to see installed certificates" -ForegroundColor $Warning
    exit 1
}

Write-Host "Using certificate for signing:" -ForegroundColor $Info
Write-Host "  Subject: $($certInStore.Subject)" -ForegroundColor $Info
Write-Host "  Thumbprint: $($certInStore.Thumbprint)" -ForegroundColor $Info
Write-Host "  Valid until: $($certInStore.NotAfter)" -ForegroundColor $Info

$PublicUIOutput = & $MSBuildPath $PublicUIProjectPath `
    /t:Publish `
    /p:Configuration=$Configuration `
    /p:TargetFramework=net10.0-windows10.0.19041.0 `
    /p:Platform=x64 `
    /p:RuntimeIdentifier=win-x64 `
    /p:WindowsPackageType=MSIX `
    /p:UapAppxPackageBuildMode=SideloadOnly `
    /p:AppxBundle=Never `
    /p:GenerateAppxPackageOnBuild=true `
    /p:PackageCertificateThumbprint=$($certInStore.Thumbprint) `
    /p:AppxPackageDir="$((Get-Location).Path)\MCBDS.PublicUI\bin\$Configuration\net10.0-windows10.0.19041.0\win-x64\AppPackages\" `
    /p:Version=$Version `
    /v:normal 2>&1

# Check if build succeeded
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Failed to build PublicUI MSIX package" -ForegroundColor $Error
    Write-Host "`nBuild Output:" -ForegroundColor $Error
    $PublicUIOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "? Build completed successfully" -ForegroundColor $Success

# Search for MSIX in multiple possible locations
Write-Host "`nSearching for MSIX package..." -ForegroundColor $Info

$SearchPaths = @(
    "MCBDS.PublicUI\bin\$Configuration\net10.0-windows10.0.19041.0\win-x64\AppPackages",
    "MCBDS.PublicUI\bin\$Configuration\net10.0-windows10.0.19041.0\win-x64",
    "MCBDS.PublicUI\AppPackages",
    "MCBDS.PublicUI\bin\$Configuration\net10.0-windows10.0.19041.0\AppPackages"
)

$MsixPackage = $null
foreach ($searchPath in $SearchPaths) {
    if (Test-Path $searchPath) {
        Write-Host "  Searching in: $searchPath" -ForegroundColor $Info
        $found = Get-ChildItem $searchPath -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -notlike "*_Test_*" -and $_.Name -notlike "*Dependencies*" } | 
            Select-Object -First 1
        
        if ($found) {
            $MsixPackage = $found
            Write-Host "  ? Found MSIX: $($found.Name)" -ForegroundColor $Success
            break
        }
    }
}

if ($null -eq $MsixPackage) {
    Write-Host "`nERROR: MSIX package not found in any expected location" -ForegroundColor $Error
    Write-Host "`nSearched in:" -ForegroundColor $Error
    foreach ($path in $SearchPaths) {
        $fullPath = Join-Path (Get-Location) $path
        $exists = Test-Path $fullPath
        Write-Host "  - $fullPath [$(if($exists){'EXISTS'}else{'NOT FOUND'})]" -ForegroundColor $(if($exists){$Warning}else{$Error})
        
        if ($exists) {
            Write-Host "    Contents:" -ForegroundColor $Info
            Get-ChildItem $fullPath -Recurse | Select-Object FullName, Length | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Info
        }
    }
    
    Write-Host "`nFull build output directory structure:" -ForegroundColor $Error
    $basePath = "MCBDS.PublicUI\bin\$Configuration"
    if (Test-Path $basePath) {
        Get-ChildItem $basePath -Recurse | Select-Object FullName, Length | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Info
    } else {
        Write-Host "  Build output directory not found: $basePath" -ForegroundColor $Error
    }
    
    Write-Host "`nTip: The build might have succeeded but MSIX generation was skipped." -ForegroundColor $Warning
    Write-Host "Check the build output above for warnings about MSIX packaging." -ForegroundColor $Warning
    exit 1
}

Write-Host "`n? PublicUI MSIX found: $($MsixPackage.Name)" -ForegroundColor $Success
Write-Host "  Location: $($MsixPackage.FullName)" -ForegroundColor $Info
Write-Host "  Size: $(($MsixPackage.Length / 1MB).ToString('F2')) MB" -ForegroundColor $Info

# Copy MSIX to installer directory
$InstallerMsixPath = "MCBDS.Installer\MCBDS.PublicUI.msix"
$InstallerMsixFullPath = Join-Path (Get-Location) $InstallerMsixPath
Copy-Item -Path $MsixPackage.FullName -Destination $InstallerMsixPath -Force
Write-Host "? MSIX copied to installer resources" -ForegroundColor $Success

# Check for or create code signing certificate
Write-Host "`nChecking code signing certificate..." -ForegroundColor $Info
$CertPath = "MCBDS.Installer\CodeSigning.pfx"
$CerPath = "MCBDS.Installer\CodeSigning.cer"
$PasswordPath = "MCBDS.Installer\CodeSigning.password.txt"

if (-not (Test-Path $CertPath)) {
    Write-Host "Creating self-signed certificate for MSIX signing..." -ForegroundColor $Info
    
    # Generate certificate password using a modern approach
    $certPassword = -join ((33..126) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    # Ensure we have at least one special character
    $certPassword = $certPassword -replace '^', '!@#$%^&*'[$(Get-Random -Maximum 8)] | Select-Object -First 20
    $certPassword = $certPassword.Substring(0, [Math]::Min(20, $certPassword.Length))
    $certPassword | Out-File -FilePath $PasswordPath -NoNewline -Encoding UTF8
    $securePassword = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
    
    # Create self-signed certificate
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=Pinecrest Consultants" `
        -KeyUsage DigitalSignature `
        -FriendlyName "MCBDS Manager Code Signing" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") `
        -NotAfter (Get-Date).AddYears(3)
    
    # Export to PFX and CER
    Export-PfxCertificate -Cert $cert -FilePath $CertPath -Password $securePassword | Out-Null
    Export-Certificate -Cert $cert -FilePath $CerPath -Type CERT | Out-Null
    
    Write-Host "? Certificate created and exported" -ForegroundColor $Success
} else {
    Write-Host "? Using existing certificate" -ForegroundColor $Success
}

# Verify MSIX was signed during build
Write-Host "`nVerifying MSIX signature..." -ForegroundColor $Info

# Check if the MSIX is signed
$SignToolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe"
)

$SignTool = $SignToolPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($SignTool) {
    $verifyOutput = & $SignTool verify /pa "$InstallerMsixPath" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? MSIX is properly signed" -ForegroundColor $Success
    } else {
        Write-Host "? WARNING: MSIX signature verification failed" -ForegroundColor $Warning
        Write-Host "  This means MSBuild didn't sign the MSIX during build" -ForegroundColor $Warning
        Write-Host "  Users will need Developer Mode enabled to install" -ForegroundColor $Warning
    }
} else {
    Write-Host "? SignTool not found - cannot verify signature" -ForegroundColor $Warning
    Write-Host "  Assuming MSIX was signed by MSBuild during build" -ForegroundColor $Info
}

Write-Host "  MSIX location: $InstallerMsixFullPath" -ForegroundColor $Info
Write-Host "  Certificate (for installer): $CerPath" -ForegroundColor $Info

# Install certificate to trusted root store so Windows trusts the signature
Write-Host "`nInstalling certificate to Trusted Root Certification Authorities..." -ForegroundColor $Info
try {
    Import-Certificate -FilePath $CerPath -CertStoreLocation "Cert:\LocalMachine\Root" -ErrorAction Stop | Out-Null
    Write-Host "? Certificate installed to LocalMachine\Root" -ForegroundColor $Success
} catch {
    # If LocalMachine fails (no admin), try CurrentUser
    try {
        Import-Certificate -FilePath $CerPath -CertStoreLocation "Cert:\CurrentUser\Root" -ErrorAction Stop | Out-Null
        Write-Host "? Certificate installed to CurrentUser\Root" -ForegroundColor $Success
        Write-Host "  Note: For production, run as Administrator to install to LocalMachine\Root" -ForegroundColor $Warning
    } catch {
        Write-Host "ERROR: Failed to install certificate to trusted store" -ForegroundColor $Error
        Write-Host "  The MSIX is signed but not trusted. Windows will warn users." -ForegroundColor $Warning
        Write-Host "  To fix: Run this script as Administrator" -ForegroundColor $Warning
    }
}

# Step 4: Build NSIS Installer
Write-Host "`n[4/4] Building NSIS installer..." -ForegroundColor $Info
$NsiScript = "MCBDS.Installer\MCBDSInstaller.nsi"

if (-not (Test-Path $NsiScript)) {
    Write-Host "ERROR: NSIS script not found at $NsiScript" -ForegroundColor $Error
    exit 1
}

# Build NSIS with version parameter and MSIX path
Write-Host "Compiling NSIS installer with MSIX and certificate..." -ForegroundColor $Info
$CerFullPath = Join-Path (Get-Location) $CerPath
$MsixFullPath = Join-Path (Get-Location) $InstallerMsixPath

Write-Host "  Certificate path: $CerFullPath" -ForegroundColor $Info
Write-Host "  MSIX path: $MsixFullPath" -ForegroundColor $Info

# Verify files exist before building
Write-Host "Verifying files exist..." -ForegroundColor $Info
if (-not (Test-Path $CerFullPath)) {
    Write-Host "ERROR: Certificate file not found at: $CerFullPath" -ForegroundColor $Error
    Write-Host "Expected: $CerFullPath" -ForegroundColor $Error
    exit 1
}
Write-Host "? Certificate file exists" -ForegroundColor $Success

if (-not (Test-Path $MsixFullPath)) {
    Write-Host "ERROR: MSIX file not found at: $MsixFullPath" -ForegroundColor $Error
    Write-Host "Expected: $MsixFullPath" -ForegroundColor $Error
    exit 1
}
Write-Host "? MSIX file exists" -ForegroundColor $Success

Write-Host "Building installer..." -ForegroundColor $Info
$BuildOutput = & $NsisPath /DVERSION=$Version /DMSIX_PATH="$MsixFullPath" /DCERT_PATH="$CerFullPath" $NsiScript 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: NSIS build failed" -ForegroundColor $Error
    Write-Host $BuildOutput
    exit 1
}
Write-Host "? Installer built successfully" -ForegroundColor $Success

# Move installer to versioned output directory
$InstallerName = "MCBDS.Manager.$Version.Installer.exe"
$SourceInstaller = "MCBDS.API.Service.Installer.exe"
$DestInstaller = Join-Path $OutputDir $InstallerName

if (Test-Path $SourceInstaller) {
    Move-Item -Path $SourceInstaller -Destination $DestInstaller -Force
} else {
    Write-Host "ERROR: Installer file not found at $SourceInstaller" -ForegroundColor $Error
    exit 1
}

# Get file size
$FileSize = (Get-Item $DestInstaller).Length
if ($FileSize -lt 5MB) {
    Write-Host "WARNING: Installer is only $(($FileSize / 1MB).ToString('F2')) MB" -ForegroundColor $Warning
}

# Step 5: Show completion message
Write-Host "`n========================================" -ForegroundColor $Info
Write-Host "Build Complete!" -ForegroundColor $Success
Write-Host "========================================" -ForegroundColor $Info
Write-Host "`nVersion: $Version" -ForegroundColor $Success
Write-Host "Installer: $DestInstaller" -ForegroundColor $Success
Write-Host "Size: $(($FileSize / 1MB).ToString('F2')) MB" -ForegroundColor $Info
Write-Host "`n========= IMPORTANT INSTALLATION INSTRUCTIONS ==========" -ForegroundColor $Warning
Write-Host "`nDistribution & Installation:" -ForegroundColor $Info
Write-Host "1. Distribute the installer from: $OutputDir" -ForegroundColor $Info
Write-Host "2. END USERS: Run installer with ADMIN PRIVILEGES" -ForegroundColor $Warning
Write-Host "   -> Right-click installer > 'Run as administrator'" -ForegroundColor $Warning
Write-Host "3. Answer installer questions about configuration" -ForegroundColor $Info
Write-Host "   -> HTTP Port (default: 8080)" -ForegroundColor $Info
Write-Host "   -> Backup frequency (default: 30 minutes)" -ForegroundColor $Info
Write-Host "   -> Maximum backups to keep (default: 30)" -ForegroundColor $Info
Write-Host "`nAfter Installation:" -ForegroundColor $Info
Write-Host "4. Check installation log at:" -ForegroundColor $Warning
Write-Host "   -> C:\Program Files\MCBDS Manager\install.log" -ForegroundColor $Warning
Write-Host "5. Verify service is running:" -ForegroundColor $Info
Write-Host "   -> Press Win+R, type 'services.msc', find 'MCBDSAPIService'" -ForegroundColor $Info
Write-Host "6. Verify certificate installation in install.log" -ForegroundColor $Info
Write-Host "7. Access the API at: http://localhost:8080" -ForegroundColor $Info
Write-Host "`nTroubleshooting:" -ForegroundColor $Warning
Write-Host "- If MSIX fails: Check install.log for certificate installation status" -ForegroundColor $Info
Write-Host "- If JSON error: Check install.log for appsettings.json merge status" -ForegroundColor $Info
Write-Host "- If service won't start: Check for appsettings.json JSON syntax errors" -ForegroundColor $Info
Write-Host "`n========================================================" -ForegroundColor $Info
Write-Host "`nCertificate Status:" -ForegroundColor $Info
Write-Host "- Build machine: Certificate installed to CurrentUser/LocalMachine Root" -ForegroundColor $Success
Write-Host "- Target machines: Certificate installed during installer setup" -ForegroundColor $Success
Write-Host "- Method: certutil.exe with PowerShell fallback" -ForegroundColor $Success
Write-Host "`nTo increment version on next build, use: -IncrementVersion" -ForegroundColor $Info


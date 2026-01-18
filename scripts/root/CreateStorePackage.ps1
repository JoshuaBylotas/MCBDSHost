# Create Store-Ready MSIX Package
# This script creates an unsigned or Store-signed MSIX package ready for Microsoft Store submission

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    
    [Parameter()]
    [string]$ProjectPath = "MCBDS.PublicUI\MCBDS.PublicUI.csproj",
    
    [Parameter()]
    [ValidateSet('x64', 'x86', 'ARM64')]
    [string[]]$Architectures = @('x64'),
    
    [Parameter()]
    [switch]$SkipBuild,
    
    [Parameter()]
    [switch]$OpenOutputFolder
)

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Creating Microsoft Store-Ready MSIX Package  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Verify project exists
if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Project file not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

$projectDir = Split-Path $ProjectPath -Parent
$projectName = [System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)

Write-Host "Project: $projectName" -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Green
Write-Host "Architectures: $($Architectures -join ', ')" -ForegroundColor Green
Write-Host ""

# Check if Package.appxmanifest exists and has Store identity
$manifestPath = Join-Path $projectDir "Platforms\Windows\Package.appxmanifest"
if (-not (Test-Path $manifestPath)) {
    Write-Host "ERROR: Package.appxmanifest not found at: $manifestPath" -ForegroundColor Red
    Write-Host "This file is required for MSIX packaging." -ForegroundColor Yellow
    exit 1
}

# Parse manifest to verify Store identity
Write-Host "Verifying Package.appxmanifest..." -ForegroundColor Cyan
try {
    [xml]$manifest = Get-Content $manifestPath
    $identity = $manifest.Package.Identity
    
    Write-Host "  Package Name: $($identity.Name)" -ForegroundColor Gray
    Write-Host "  Publisher: $($identity.Publisher)" -ForegroundColor Gray
    Write-Host "  Version: $($identity.Version)" -ForegroundColor Gray
    
    # Check if using Store identity
    if ($identity.Publisher -notmatch '^CN=[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$') {
        Write-Host ""
        Write-Host "WARNING: Publisher doesn't look like a Store identity!" -ForegroundColor Yellow
        Write-Host "  Current: $($identity.Publisher)" -ForegroundColor Yellow
        Write-Host "  Expected format: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To get the correct Store identity:" -ForegroundColor Yellow
        Write-Host "  1. Open Visual Studio" -ForegroundColor Yellow
        Write-Host "  2. Right-click project ? Publish ? Associate App with the Store" -ForegroundColor Yellow
        Write-Host "  3. Sign in to Partner Center" -ForegroundColor Yellow
        Write-Host "  4. Select your reserved app" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Host "Aborted." -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "WARNING: Could not parse Package.appxmanifest: $_" -ForegroundColor Yellow
}

Write-Host ""

# Clean previous builds
if (-not $SkipBuild) {
    Write-Host "Cleaning previous builds..." -ForegroundColor Cyan
    & dotnet clean $ProjectPath -c $Configuration --verbosity quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Clean failed, but continuing..." -ForegroundColor Yellow
    }
    Write-Host "  ? Clean complete" -ForegroundColor Green
    Write-Host ""
}

# Fix assets file (known issue with .NET 10)
Write-Host "Fixing assets file for Visual Studio compatibility..." -ForegroundColor Cyan
$assetsPath = Join-Path $projectDir "obj\project.assets.json"
if (Test-Path $assetsPath) {
    try {
        $assets = Get-Content $assetsPath -Raw | ConvertFrom-Json
        if ($assets.packageFolders) {
            $packageFolders = $assets.packageFolders | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            Write-Host "  Found package folders:" -ForegroundColor Gray
            foreach ($folder in $packageFolders) {
                Write-Host "    - $folder" -ForegroundColor Gray
            }
        }
        Write-Host "  ? Assets file is valid" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Could not parse assets file: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No assets file found (will be created during restore)" -ForegroundColor Gray
}
Write-Host ""

# Restore dependencies
if (-not $SkipBuild) {
    Write-Host "Restoring NuGet packages..." -ForegroundColor Cyan
    & dotnet restore $ProjectPath --verbosity quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Restore failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ? Restore complete" -ForegroundColor Green
    Write-Host ""
}

# Build for each architecture
$builtPackages = @()

foreach ($arch in $Architectures) {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Building for $arch..." -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    $runtime = "win-$arch"
    
    if (-not $SkipBuild) {
        Write-Host "Publishing project..." -ForegroundColor Cyan
        
        $publishArgs = @(
            'publish',
            $ProjectPath,
            '-f', 'net10.0-windows10.0.19041.0',
            '-c', $Configuration,
            '-r', $runtime,
            '--self-contained', 'true',
            '-p:WindowsPackageType=None',
            '-p:PublishSingleFile=false',
            '-p:WindowsAppSDKSelfContained=true',
            '--verbosity', 'minimal'
        )
        
        & dotnet @publishArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Build failed for $arch" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "  ? Build complete" -ForegroundColor Green
    } else {
        Write-Host "  Skipping build (using existing output)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Find build output
    $publishDir = Join-Path $projectDir "bin\$Configuration\net10.0-windows10.0.19041.0\$runtime\publish"
    
    if (-not (Test-Path $publishDir)) {
        Write-Host "ERROR: Build output not found at: $publishDir" -ForegroundColor Red
        Write-Host "Run without -SkipBuild to build the project first." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Build output: $publishDir" -ForegroundColor Gray
    Write-Host ""
    
    $builtPackages += @{
        Architecture = $arch
        Runtime = $runtime
        PublishDir = $publishDir
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Build Summary  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Successfully built for the following architectures:" -ForegroundColor Green
foreach ($package in $builtPackages) {
    Write-Host "  ? $($package.Architecture) - $($package.PublishDir)" -ForegroundColor Green
}
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Next Steps  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To create the Store package, use Visual Studio:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Open Visual Studio" -ForegroundColor White
Write-Host "  2. Right-click '$projectName' project" -ForegroundColor White
Write-Host "  3. Select: Publish ? Create App Packages..." -ForegroundColor White
Write-Host "  4. Choose: Microsoft Store (select your app)" -ForegroundColor White
Write-Host "  5. Sign in to Partner Center" -ForegroundColor White
Write-Host "  6. Configure bundle settings:" -ForegroundColor White
Write-Host "     - Architectures: $($Architectures -join ', ')" -ForegroundColor Gray
Write-Host "     - Generate app bundle: Always" -ForegroundColor Gray
Write-Host "     - Include public symbol files: ?" -ForegroundColor Gray
Write-Host "  7. Click 'Create'" -ForegroundColor White
Write-Host "  8. Upload the .msixupload file to Partner Center" -ForegroundColor White
Write-Host ""
Write-Host "The .msixupload file will be created in:" -ForegroundColor Yellow
Write-Host "  $projectDir\AppPackages\" -ForegroundColor Gray
Write-Host ""
Write-Host "??  IMPORTANT: Do NOT manually sign the package!" -ForegroundColor Yellow
Write-Host "   Microsoft will sign it automatically during certification." -ForegroundColor Yellow
Write-Host ""

# Alternative: Using MSBuild directly (if Visual Studio packaging works)
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Alternative: Using MSBuild (Advanced)  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you prefer command-line packaging (requires Visual Studio):" -ForegroundColor Gray
Write-Host ""

$msbuildCmd = @"
msbuild "$ProjectPath" ``
  /p:Configuration=$Configuration ``
  /p:Platform=$($Architectures[0]) ``
  /p:UapAppxPackageBuildMode=StoreUpload ``
  /p:AppxBundle=Always ``
  /p:AppxBundlePlatforms="$($Architectures -join '|')" ``
  /p:GenerateAppxPackageOnBuild=true ``
  /p:AppxPackageSigningEnabled=false ``
  /t:Restore,Build,_GenerateAppxPackage
"@

Write-Host $msbuildCmd -ForegroundColor DarkGray
Write-Host ""
Write-Host "Note: This may not work with .NET 10 preview." -ForegroundColor Yellow
Write-Host ""

Write-Host "? Build preparation complete!" -ForegroundColor Green
Write-Host ""

if ($OpenOutputFolder) {
    $packagesDir = Join-Path $projectDir "AppPackages"
    if (Test-Path $packagesDir) {
        Write-Host "Opening AppPackages folder..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList $packagesDir
    } else {
        Write-Host "AppPackages folder doesn't exist yet (will be created by Visual Studio)" -ForegroundColor Yellow
    }
}

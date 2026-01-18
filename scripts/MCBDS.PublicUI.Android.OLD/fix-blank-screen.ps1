# Complete Fix for Blank Screen - Removes symlinks and copies real files
# Run this script to fix the symbolic link issue once and for all

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  MCBDS.PublicUI.Android - Complete Blank Screen Fix"
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$androidDir = "MCBDS.PublicUI.Android"
$publicuiDir = "MCBDS.PublicUI"

# Step 1: Verify we're in the right directory
if (-not (Test-Path $androidDir)) {
    Write-Host "ERROR: Must run from solution root (MCBDSHost)" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Checking current file types..." -ForegroundColor Yellow
Write-Host ""

$layoutItem = Get-Item "$androidDir\Components\Layout" -ErrorAction SilentlyContinue
$pagesItem = Get-Item "$androidDir\Components\Pages" -ErrorAction SilentlyContinue
$libItem = Get-Item "$androidDir\wwwroot\lib" -ErrorAction SilentlyContinue

if ($layoutItem.LinkType -eq "SymbolicLink") {
    Write-Host "   ? Layout is a SYMLINK (this is the problem!)" -ForegroundColor Red
    $needsFix = $true
} else {
    Write-Host "   ? Layout is a real directory" -ForegroundColor Green
}

if ($pagesItem.LinkType -eq "SymbolicLink") {
    Write-Host "   ? Pages is a SYMLINK (this is the problem!)" -ForegroundColor Red
    $needsFix = $true
} else {
    Write-Host "   ? Pages is a real directory" -ForegroundColor Green
}

if ($libItem.LinkType -eq "SymbolicLink") {
    Write-Host "   ? lib is a SYMLINK (this is the problem!)" -ForegroundColor Red
    $needsFix = $true
} else {
    Write-Host "   ? lib is a real directory" -ForegroundColor Green
}

Write-Host ""

if ($needsFix) {
    Write-Host "Step 2: Removing symbolic links..." -ForegroundColor Yellow
    Write-Host ""
    
    # Remove symlinks with force
    if (Test-Path "$androidDir\Components\Layout") {
        Remove-Item "$androidDir\Components\Layout" -Force -Recurse -ErrorAction Stop
        Write-Host "   ? Removed Layout symlink" -ForegroundColor Green
    }
    
    if (Test-Path "$androidDir\Components\Pages") {
        Remove-Item "$androidDir\Components\Pages" -Force -Recurse -ErrorAction Stop
        Write-Host "   ? Removed Pages symlink" -ForegroundColor Green
    }
    
    if (Test-Path "$androidDir\Components\ServerSwitcher.razor") {
        Remove-Item "$androidDir\Components\ServerSwitcher.razor" -Force -ErrorAction SilentlyContinue
        Remove-Item "$androidDir\Components\ServerSwitcher.razor.css" -Force -ErrorAction SilentlyContinue
        Write-Host "   ? Removed ServerSwitcher files" -ForegroundColor Green
    }
    
    if (Test-Path "$androidDir\wwwroot\lib") {
        Remove-Item "$androidDir\wwwroot\lib" -Force -Recurse -ErrorAction Stop
        Write-Host "   ? Removed lib symlink" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Step 3: Copying real files..." -ForegroundColor Yellow
    Write-Host ""
    
    # Copy actual directories
    Copy-Item -Path "$publicuiDir\Components\Layout" -Destination "$androidDir\Components\Layout" -Recurse -Force
    Write-Host "   ? Copied Layout directory" -ForegroundColor Green
    
    Copy-Item -Path "$publicuiDir\Components\Pages" -Destination "$androidDir\Components\Pages" -Recurse -Force
    Write-Host "   ? Copied Pages directory" -ForegroundColor Green
    
    Copy-Item -Path "$publicuiDir\Components\ServerSwitcher.razor" -Destination "$androidDir\Components\" -Force
    Copy-Item -Path "$publicuiDir\Components\ServerSwitcher.razor.css" -Destination "$androidDir\Components\" -Force
    Write-Host "   ? Copied ServerSwitcher files" -ForegroundColor Green
    
    Copy-Item -Path "$publicuiDir\wwwroot\lib" -Destination "$androidDir\wwwroot\lib" -Recurse -Force
    Write-Host "   ? Copied lib directory" -ForegroundColor Green
    
} else {
    Write-Host "Step 2: Files are already real (not symlinks)" -ForegroundColor Green
    Write-Host "   Skipping copy step..." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 4: Verifying files were copied correctly..." -ForegroundColor Yellow
Write-Host ""

$errors = @()

if (-not (Test-Path "$androidDir\Components\Layout\MainLayout.razor")) {
    $errors += "MainLayout.razor not found"
}
if (-not (Test-Path "$androidDir\Components\Pages\Home.razor")) {
    $errors += "Home.razor not found"
}
if (-not (Test-Path "$androidDir\wwwroot\lib\bootstrap")) {
    $errors += "Bootstrap not found"
}

if ($errors.Count -gt 0) {
    Write-Host "   ? ERRORS found:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "     - $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "The copy failed. Try running as Administrator." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "   ? All required files present" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5: Cleaning build artifacts..." -ForegroundColor Yellow
Write-Host ""

Remove-Item "$androidDir\bin" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$androidDir\obj" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ? Cleaned bin and obj folders" -ForegroundColor Green

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  ? FIX COMPLETE!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files are now REAL (not symlinks) and will be included in the APK." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Rebuild: dotnet build $androidDir -f net10.0-android" -ForegroundColor Gray
Write-Host "  2. Run:     dotnet run $androidDir -f net10.0-android" -ForegroundColor Gray
Write-Host ""
Write-Host "The blank screen should be fixed!" -ForegroundColor Green
Write-Host ""

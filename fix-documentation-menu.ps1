# Script to fix Documentation menu not showing

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host " Documentation Menu Fix Script" -ForegroundColor Cyan  
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify files exist
Write-Host "Step 1: Verifying files exist..." -ForegroundColor Yellow

$files = @(
    "MCBDS.Marketing\Services\DocumentationService.cs",
    "MCBDS.Marketing\Components\Pages\Documentation.razor",
    "MCBDS.Marketing\Components\Pages\DocumentViewer.razor"
)

$allExist = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ? $file" -ForegroundColor Green
    } else {
        Write-Host "  ? $file MISSING!" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host ""
    Write-Host "? Some files are missing! Please create them first." -ForegroundColor Red
    exit 1
}

# Step 2: Verify NavMenu contains Documentation
Write-Host ""
Write-Host "Step 2: Verifying NavMenu..." -ForegroundColor Yellow
$navMenuContent = Get-Content "MCBDS.Marketing\Components\Layout\NavMenu.razor" -Raw
if ($navMenuContent -match "Documentation") {
    Write-Host "  ? NavMenu contains Documentation link" -ForegroundColor Green
} else {
    Write-Host "  ? NavMenu missing Documentation link!" -ForegroundColor Red
    Write-Host "     Add this to NavMenu.razor:" -ForegroundColor Yellow
    Write-Host '     <div class="nav-item px-3">' -ForegroundColor White
    Write-Host '         <NavLink class="nav-link" href="docs">' -ForegroundColor White
    Write-Host '             <span class="bi bi-book-fill" aria-hidden="true"></span> Documentation' -ForegroundColor White
    Write-Host '         </NavLink>' -ForegroundColor White
    Write-Host '     </div>' -ForegroundColor White
}

# Step 3: Count documentation files
Write-Host ""
Write-Host "Step 3: Counting documentation files..." -ForegroundColor Yellow
$docFiles = Get-ChildItem "MCBDS.Marketing\wwwroot\docs" -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
if ($docFiles) {
    Write-Host "  ? Found $($docFiles.Count) documentation files" -ForegroundColor Green
} else {
    Write-Host "  ? No documentation files found in wwwroot\docs!" -ForegroundColor Red
}

# Step 4: Stop any running Marketing instances
Write-Host ""
Write-Host "Step 4: Stopping running Marketing instances..." -ForegroundColor Yellow
$processes = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*dotnet.exe*"
}

if ($processes) {
    Write-Host "  Found $($processes.Count) dotnet process(es)" -ForegroundColor Yellow
    Write-Host "  Attempting to stop Marketing instances..." -ForegroundColor Yellow
    # Note: This is a simple stop - in production you'd want more targeted stopping
    Start-Sleep -Seconds 2
    Write-Host "  ?  Please manually stop the Marketing site in Visual Studio or terminal" -ForegroundColor Cyan
} else {
    Write-Host "  ?  No dotnet processes found running" -ForegroundColor Cyan
}

# Step 5: Clean and Build
Write-Host ""
Write-Host "Step 5: Cleaning and building Marketing project..." -ForegroundColor Yellow

Push-Location "MCBDS.Marketing"

Write-Host "  Cleaning..." -ForegroundColor Cyan
dotnet clean --verbosity quiet

Write-Host "  Restoring packages..." -ForegroundColor Cyan
dotnet restore --verbosity quiet

Write-Host "  Building..." -ForegroundColor Cyan
dotnet build --configuration Debug --no-restore

$buildSuccess = $LASTEXITCODE -eq 0

Pop-Location

if ($buildSuccess) {
    Write-Host "  ? Build successful!" -ForegroundColor Green
} else {
    Write-Host "  ? Build failed! Check errors above." -ForegroundColor Red
    exit 1
}

# Step 6: Final instructions
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host " Next Steps" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Run the Marketing site:" -ForegroundColor Yellow
Write-Host "   cd MCBDS.Marketing" -ForegroundColor White
Write-Host "   dotnet run" -ForegroundColor White
Write-Host ""

Write-Host "2. Open in browser:" -ForegroundColor Yellow
Write-Host "   http://localhost:5000 (or the port shown)" -ForegroundColor White
Write-Host ""

Write-Host "3. Check navigation menu for:" -ForegroundColor Yellow
Write-Host "   ?? Documentation" -ForegroundColor White
Write-Host ""

Write-Host "4. Or navigate directly to:" -ForegroundColor Yellow
Write-Host "   http://localhost:5000/docs" -ForegroundColor White
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "?? Tip: If menu still doesn't appear:" -ForegroundColor Cyan
Write-Host "   - Clear browser cache (Ctrl+Shift+Delete)" -ForegroundColor White
Write-Host "   - Try Incognito/Private mode" -ForegroundColor White
Write-Host "   - Hard refresh (Ctrl+F5)" -ForegroundColor White
Write-Host ""

Write-Host "? Fix script completed!" -ForegroundColor Green

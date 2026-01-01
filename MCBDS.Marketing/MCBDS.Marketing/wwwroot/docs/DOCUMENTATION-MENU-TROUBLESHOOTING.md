# Documentation Menu Not Showing - Troubleshooting Guide

## Issue
The Documentation menu item is not appearing in the Marketing website navigation.

## ? Verification Checklist

### 1. Files Created
- [x] `MCBDS.Marketing/Services/DocumentationService.cs`
- [x] `MCBDS.Marketing/Components/Pages/Documentation.razor`
- [x] `MCBDS.Marketing/Components/Pages/DocumentViewer.razor`
- [x] `MCBDS.Marketing/Components/Layout/NavMenu.razor` (updated)
- [x] `MCBDS.Marketing/Program.cs` (updated)
- [x] `MCBDS.Marketing/wwwroot/docs/` folder with markdown files

### 2. Service Registration
Verify in `Program.cs`:
```csharp
builder.Services.AddScoped<DocumentationService>();
builder.Services.AddHttpClient<DocumentationService>();
```

### 3. Navigation Menu
Check `NavMenu.razor` contains:
```razor
<div class="nav-item px-3">
    <NavLink class="nav-link" href="docs">
        <span class="bi bi-book-fill" aria-hidden="true"></span> Documentation
    </NavLink>
</div>
```

## ?? Solution Steps

### Step 1: Stop the Application
If the Marketing site is currently running, **stop it completely**:
- In Visual Studio: Stop debugging (Shift+F5)
- Or close the console/terminal running the app

### Step 2: Clean and Rebuild
```powershell
# Navigate to Marketing project
cd MCBDS.Marketing

# Clean the project
dotnet clean

# Rebuild
dotnet build
```

### Step 3: Verify Files Are in Output
Check that the Documentation pages are in the build output:
```powershell
# Check if Documentation.razor exists in bin
Get-ChildItem -Path "bin\Debug\net10.0" -Recurse -Filter "Documentation.razor*"

# Check if DocumentViewer.razor exists in bin
Get-ChildItem -Path "bin\Debug\net10.0" -Recurse -Filter "DocumentViewer.razor*"
```

### Step 4: Restart the Application
```powershell
# Run the Marketing site
dotnet run
```

### Step 5: Clear Browser Cache
- Press `Ctrl+Shift+Delete` in your browser
- Or use `Ctrl+F5` to hard refresh the page

### Step 6: Test the Routes Directly
Even if the menu doesn't show, try navigating directly:
- `http://localhost:5000/docs` (Documentation Index)
- `http://localhost:5000/docs/quick-start` (Sample document)

## ?? Diagnostic Commands

### Check if NavMenu.razor was compiled
```powershell
Get-Content "MCBDS.Marketing\Components\Layout\NavMenu.razor" | Select-String "Documentation"
```

### Verify DocumentationService exists
```powershell
Test-Path "MCBDS.Marketing\Services\DocumentationService.cs"
```

### Check documentation files copied
```powershell
Get-ChildItem "MCBDS.Marketing\wwwroot\docs" -Recurse -Filter "*.md" | Measure-Object
```

## ?? Common Issues

### Issue 1: Hot Reload Didn't Apply Changes
**Solution**: Full restart required (not just hot reload)

### Issue 2: Multiple Instances Running
**Solution**: Check Task Manager for multiple `dotnet.exe` processes and kill all Marketing instances

### Issue 3: Browser Cache
**Solution**: Open in Incognito/Private mode or clear browser cache

### Issue 4: Wrong Port/URL
**Solution**: Make sure you're accessing the Marketing site, not the API or PublicUI

### Issue 5: Build Errors
**Solution**: Check Output window for build errors
```powershell
dotnet build MCBDS.Marketing\MCBDS.Marketing.csproj
```

## ? Quick Fix Script

Create and run this PowerShell script:

```powershell
# fix-documentation-menu.ps1

Write-Host "Fixing Documentation Menu..." -ForegroundColor Cyan

# Stop any running instances
Write-Host "1. Stopping running instances..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "dotnet" -and $_.CommandLine -like "*MCBDS.Marketing*"} | Stop-Process -Force

# Navigate to Marketing project
cd MCBDS.Marketing

# Clean
Write-Host "2. Cleaning project..." -ForegroundColor Yellow
dotnet clean

# Restore
Write-Host "3. Restoring packages..." -ForegroundColor Yellow
dotnet restore

# Build
Write-Host "4. Building project..." -ForegroundColor Yellow
dotnet build

# Check for errors
if ($LASTEXITCODE -eq 0) {
    Write-Host "? Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: dotnet run" -ForegroundColor White
    Write-Host "  2. Navigate to: http://localhost:[port]" -ForegroundColor White
    Write-Host "  3. Look for 'Documentation' in the navigation menu" -ForegroundColor White
    Write-Host "  4. Or go directly to: http://localhost:[port]/docs" -ForegroundColor White
} else {
    Write-Host "? Build failed! Check errors above." -ForegroundColor Red
}
```

## ?? Manual Verification

1. **Open the application in browser**
2. **Check navigation menu** (left sidebar or hamburger menu on mobile)
3. **Should see these items:**
   - Home
   - Features
   - Get Started
   - **Documentation** ? Should be here!
   - Contact

## ?? Expected Result

After restart, you should see:
- ? "Documentation" menu item with book icon
- ? Clicking it goes to `/docs` page
- ? Documentation index showing 8 categories
- ? Ability to click and view individual documents

## ?? Still Not Working?

If after following all steps the menu still doesn't appear:

1. **Check browser console** (F12) for JavaScript errors
2. **Check application logs** for startup errors
3. **Verify the Marketing project is running** (not API or PublicUI)
4. **Try accessing `/docs` directly** in the URL bar
5. **Check if other menu items work** (Features, Contact, etc.)

## ?? Alternative: Manual Verification

If you want to verify the files are correct without running:

```powershell
# Verify NavMenu contains Documentation link
Select-String -Path "MCBDS.Marketing\Components\Layout\NavMenu.razor" -Pattern "Documentation"

# Verify Documentation.razor exists
Test-Path "MCBDS.Marketing\Components\Pages\Documentation.razor"

# Verify DocumentViewer.razor exists  
Test-Path "MCBDS.Marketing\Components\Pages\DocumentViewer.razor"

# Verify DocumentationService exists
Test-Path "MCBDS.Marketing\Services\DocumentationService.cs"

# Count documentation files
(Get-ChildItem "MCBDS.Marketing\wwwroot\docs" -Recurse -Filter "*.md").Count
```

All commands should return `True` or positive counts.

---

**Most likely cause**: Application needs a full restart (not hot reload).

**Quick fix**: Stop app completely, run `dotnet clean`, then `dotnet run`.

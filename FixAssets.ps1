# Complete Asset Generation and Build Fix Script for MCBDS.PublicUI

$projectPath = "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.PublicUI"
$assetsPath = Join-Path $projectPath "Platforms\Windows\Assets"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MCBDS.PublicUI Windows Store Fix     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create Assets
Write-Host "1️⃣  Creating Windows Store Assets..." -ForegroundColor Yellow
New-Item -Path $assetsPath -ItemType Directory -Force | Out-Null

$assets = @{
    "Square44x44Logo.png"    = @{ Width = 44;  Height = 44 }
    "Square71x71Logo.png"    = @{ Width = 71;  Height = 71 }
    "Square150x150Logo.png"  = @{ Width = 150; Height = 150 }
    "Square310x310Logo.png"  = @{ Width = 310; Height = 310 }
    "Wide310x150Logo.png"    = @{ Width = 310; Height = 150 }
    "StoreLogo.png"          = @{ Width = 50;  Height = 50 }
    "SplashScreen.png"       = @{ Width = 620; Height = 300 }
}

function New-BrandedImage {
    param([string]$Path, [int]$Width, [int]$Height)
    
    Add-Type -AssemblyName System.Drawing
    
    try {
        $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # MCBDS Purple background
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(81, 43, 212))
        $graphics.FillRectangle($brush, 0, 0, $Width, $Height)
        
        # Add "M" text
        if ($Width -ge 44) {
            $fontSize = [Math]::Max(12, [Math]::Min($Width, $Height) / 2.5)
            $font = New-Object System.Drawing.Font("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold)
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $format = New-Object System.Drawing.StringFormat
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $format.LineAlignment = [System.Drawing.StringAlignment]::Center
            $rect = New-Object System.Drawing.RectangleF(0, 0, $Width, $Height)
            $graphics.DrawString("M", $font, $textBrush, $rect, $format)
            $font.Dispose()
            $textBrush.Dispose()
        }
        
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
        $brush.Dispose()
        return $true
    }
    catch {
        Write-Host "    ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

foreach ($asset in $assets.GetEnumerator() | Sort-Object { $_.Value.Width }) {
    $filePath = Join-Path $assetsPath $asset.Key
    Write-Host "  Creating: $($asset.Key) ($($asset.Value.Width)×$($asset.Value.Height))" -ForegroundColor White
    
    if (New-BrandedImage -Path $filePath -Width $asset.Value.Width -Height $asset.Value.Height) {
        Write-Host "    ✅ Created" -ForegroundColor Green
    }
}

# Step 2: Clean and restore
Write-Host ""
Write-Host "2️⃣  Cleaning solution..." -ForegroundColor Yellow
cd "C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost"
dotnet clean --verbosity quiet 2>$null
dotnet nuget locals all --clear --verbosity quiet 2>$null
Get-ChildItem -Path . -Include bin,obj -Recurse -Directory -ErrorAction SilentlyContinue | 
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ Cleaned" -ForegroundColor Green

# Step 3: Restore
Write-Host ""
Write-Host "3️⃣  Restoring projects..." -ForegroundColor Yellow
cd "$projectPath\..\MCBDS.ClientUI\MCBDS.ClientUI.Shared"
dotnet restore --verbosity quiet
cd $projectPath
dotnet restore --verbosity quiet
Write-Host "   ✅ Restored" -ForegroundColor Green

# Step 4: Build
Write-Host ""
Write-Host "4️⃣  Building for Windows..." -ForegroundColor Yellow
cd $projectPath
dotnet build -f net10.0-windows10.0.19041.0 -c Release --verbosity minimal
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Built successfully" -ForegroundColor Green
} else {
    Write-Host "   ❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ All Done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Visual Studio" -ForegroundColor White
Write-Host "  2. Right-click MCBDS.PublicUI → Publish → Create App Packages..." -ForegroundColor White
Write-Host "  3. Or use command line:" -ForegroundColor White
Write-Host "     dotnet publish -f net10.0-windows10.0.19041.0 -c Release ``" -ForegroundColor DarkGray
Write-Host "       -p:WindowsPackageType=MSIX ``" -ForegroundColor DarkGray
Write-Host "       -p:GenerateAppxPackageOnBuild=true" -ForegroundColor DarkGray
Write-Host ""
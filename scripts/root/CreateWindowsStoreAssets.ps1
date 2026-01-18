# Create Windows Store Assets for MCBDS.PublicUI
# This script generates all required PNG assets for Microsoft Store submission

$projectPath = "MCBDS.PublicUI"
$assetsPath = Join-Path $projectPath "Platforms\Windows\Assets"

Write-Host "Creating Windows Store Assets..." -ForegroundColor Cyan
Write-Host ""

# Ensure Assets directory exists
New-Item -Path $assetsPath -ItemType Directory -Force | Out-Null

# Asset specifications
$assets = @{
    "Square44x44Logo.png"    = @{ Width = 44;  Height = 44;  Desc = "App list icon" }
    "Square71x71Logo.png"    = @{ Width = 71;  Height = 71;  Desc = "Small tile" }
    "Square150x150Logo.png"  = @{ Width = 150; Height = 150; Desc = "Medium tile" }
    "Square310x310Logo.png"  = @{ Width = 310; Height = 310; Desc = "Large tile" }
    "Wide310x150Logo.png"    = @{ Width = 310; Height = 150; Desc = "Wide tile" }
    "StoreLogo.png"          = @{ Width = 50;  Height = 50;  Desc = "Store listing" }
    "SplashScreen.png"       = @{ Width = 620; Height = 300; Desc = "Launch screen" }
}

# Function to create a branded PNG image
function New-BrandedImage {
    param(
        [string]$Path,
        [int]$Width,
        [int]$Height
    )
    
    Add-Type -AssemblyName System.Drawing
    
    try {
        $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
        
        # MCBDS Purple background (#512BD4)
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(81, 43, 212))
        $graphics.FillRectangle($bgBrush, 0, 0, $Width, $Height)
        
        # Add "M" text if size allows
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
        
        # Save as PNG
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $graphics.Dispose()
        $bitmap.Dispose()
        $bgBrush.Dispose()
        
        return $true
    }
    catch {
        Write-Host "  ? Error creating $($Path): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Create each asset
$successCount = 0
$failCount = 0

foreach ($asset in $assets.GetEnumerator() | Sort-Object { $_.Value.Width }) {
    $filePath = Join-Path $assetsPath $asset.Key
    $width = $asset.Value.Width
    $height = $asset.Value.Height
    $desc = $asset.Value.Desc
    
    Write-Host "Creating: " -NoNewline
    Write-Host "$($asset.Key) " -NoNewline -ForegroundColor Cyan
    Write-Host "($width×$height) " -NoNewline -ForegroundColor DarkGray
    Write-Host "- $desc" -ForegroundColor DarkGray
    
    if (New-BrandedImage -Path $filePath -Width $width -Height $height) {
        Write-Host "  ? Success" -ForegroundColor Green
        $successCount++
    }
    else {
        $failCount++
    }
}

Write-Host ""
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "  ? Created: $successCount assets" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  ? Failed: $failCount assets" -ForegroundColor Red
}
Write-Host "  ?? Location: $assetsPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "??  Note: These are placeholder assets with MCBDS branding." -ForegroundColor Yellow
Write-Host "   For production, replace with professionally designed assets." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Update MCBDS.PublicUI.csproj to include these assets" -ForegroundColor White
Write-Host "  2. Rebuild the MSIX package" -ForegroundColor White
Write-Host "  3. Submit to Microsoft Store" -ForegroundColor White

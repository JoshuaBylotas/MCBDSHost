# Create Missing Windows Store Assets for MCBDS.PublicUI
# Generates missing required assets from existing transparent images

$assetsPath = "MCBDS.PublicUI\Platforms\Windows\Assets"

Write-Host "Creating missing Windows Store Assets..." -ForegroundColor Cyan
Write-Host ""

Add-Type -AssemblyName System.Drawing

# Check if we have the base Square44x44Logo to use as source
$sourceFile = Join-Path $assetsPath "Square44x44Logo.transparent.png"
if (-not (Test-Path $sourceFile)) {
    Write-Host "Error: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

# Function to resize and save image maintaining transparency
function Resize-TransparentImage {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [int]$Width,
        [int]$Height
    )
    
    try {
        $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
        $destImage = New-Object System.Drawing.Bitmap $Width, $Height
        $graphics = [System.Drawing.Graphics]::FromImage($destImage)
        
        # High quality settings
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        # Draw with transparency
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.DrawImage($sourceImage, 0, 0, $Width, $Height)
        
        # Save as PNG with transparency
        $destImage.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        $graphics.Dispose()
        $destImage.Dispose()
        $sourceImage.Dispose()
        
        return $true
    }
    catch {
        Write-Host "  ? Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

$missingAssets = @(
    @{ Name = "Square71x71Logo.transparent.png"; Width = 71; Height = 71; Source = "Square44x44Logo.transparent.png" }
    @{ Name = "Wide310x150Logo.transparent.png"; Width = 310; Height = 150; Source = "Square150x150Logo.transparent.png" }
)

$created = 0
foreach ($asset in $missingAssets) {
    $destPath = Join-Path $assetsPath $asset.Name
    $sourcePath = Join-Path $assetsPath $asset.Source
    
    if (Test-Path $destPath) {
        Write-Host "? Already exists: $($asset.Name)" -ForegroundColor Green
        continue
    }
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "? Source not found: $($asset.Source)" -ForegroundColor Red
        continue
    }
    
    Write-Host "Creating: " -NoNewline
    Write-Host "$($asset.Name) " -NoNewline -ForegroundColor Cyan
    Write-Host "($($asset.Width)×$($asset.Height))" -ForegroundColor DarkGray
    
    if (Resize-TransparentImage -SourcePath $sourcePath -DestPath $destPath -Width $asset.Width -Height $asset.Height) {
        Write-Host "  ? Success" -ForegroundColor Green
        $created++
    }
}

Write-Host ""
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "  ? Created: $created asset(s)" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Update Package.appxmanifest to use .transparent.png files" -ForegroundColor Yellow

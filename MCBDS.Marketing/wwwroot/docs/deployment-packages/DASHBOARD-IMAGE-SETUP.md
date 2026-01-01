# Dashboard Image Setup

## ?? Dashboard Screenshot Added

The marketing site now displays a real dashboard preview image on the home page.

---

## ?? Image Location

**Required File Path**: `MCBDS.Marketing/wwwroot/images/dashboard-preview.png`

---

## ??? Image Requirements

### Dimensions
- **Recommended**: 1600×900px (16:9 ratio)
- **Minimum**: 1200×675px
- **Maximum**: 2400×1350px

### Format
- **File Type**: PNG (preferred for crisp UI screenshots)
- **Alternative**: JPG (if file size is a concern)
- **Quality**: High quality (80-90% for JPG)

### Content
The screenshot should show:
- ? MCBDSHost Dashboard (Server Overview)
- ? Real-time statistics visible
- ? Clean, professional appearance
- ? Key features highlighted
- ? Running status indicators

---

## ?? Screenshot Styling

### Existing Screenshot Details
The provided screenshot shows:
- **Title**: "MCBDS Manager" with "Server Overview"
- **Navigation**: Overview, Commands, Server, Backup
- **Server Selection**: "HOMSERVER" dropdown
- **Online Players**: 0/10 indicator
- **Server Stats**: 
  - Bedrock Server (Running, 9h 28m uptime)
  - API Host (Running, 9h 28m uptime)
  - Memory usage graphs
  - CPU & resource metrics

### Perfect for Marketing!
This screenshot demonstrates:
- ? Professional UI design
- ? Real-time monitoring
- ? Multiple server support
- ? Detailed statistics
- ? Running status

---

## ?? Adding the Image

### Step 1: Save the Screenshot
1. Take a high-quality screenshot of the dashboard
2. Crop to show the main content area
3. Save as `dashboard-preview.png`

### Step 2: Place in Directory
```powershell
# Create images directory if it doesn't exist
New-Item -Path "MCBDS.Marketing\wwwroot\images" -ItemType Directory -Force

# Copy your screenshot
Copy-Item -Path "path\to\your\screenshot.png" -Destination "MCBDS.Marketing\wwwroot\images\dashboard-preview.png"
```

### Step 3: Verify
The image should be at:
```
C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Marketing\wwwroot\images\dashboard-preview.png
```

---

## ?? Implementation Details

### Home Page Changes

**Before**:
```html
<div class="dashboard-preview-placeholder">
    <i class="bi bi-window-desktop display-1 text-muted"></i>
    <p class="text-muted mt-3">Dashboard Preview</p>
</div>
```

**After**:
```html
<div class="dashboard-preview">
    <img src="images/dashboard-preview.png" 
         alt="MCBDSHost Dashboard - Server Overview with real-time statistics"
         class="img-fluid rounded shadow-lg"
         style="border: 4px solid rgba(0,0,0,0.2);" />
    <div class="dashboard-badge">
        <i class="bi bi-eye-fill me-2"></i>Live Dashboard Preview
    </div>
</div>
```

### Features
- ? Responsive image (scales on mobile)
- ? Rounded corners
- ? Shadow effect
- ? 4px border (block style)
- ? "Live Dashboard Preview" badge overlay
- ? Hover effect (lifts and scales)
- ? Float-in animation on load

---

## ?? CSS Styling

### Dashboard Preview Container
```css
.dashboard-preview {
    position: relative;
    animation: floatIn 0.8s ease-out;
}
```

### Image Hover Effect
```css
.dashboard-preview:hover img {
    transform: translateY(-8px) scale(1.02);
    box-shadow: 0 12px 24px rgba(0,0,0,0.3) !important;
}
```

### Badge Overlay
```css
.dashboard-badge {
    position: absolute;
    bottom: -15px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--mc-grass-green);
    color: white;
    padding: 0.5rem 1.5rem;
    border-radius: 2rem;
    font-weight: 700;
    text-transform: uppercase;
    box-shadow: 0 4px 0 var(--mc-dark-green), 0 6px 12px rgba(0,0,0,0.3);
    border: 3px solid #000;
}
```

### Float-In Animation
```css
@keyframes floatIn {
    0% {
        opacity: 0;
        transform: translateY(30px);
    }
    100% {
        opacity: 1;
        transform: translateY(0);
    }
}
```

---

## ?? Responsive Behavior

### Desktop (> 1024px)
- Full-size image display
- Side-by-side with hero text
- Hover effects enabled

### Tablet (768px - 1024px)
- Slightly smaller image
- Still side-by-side layout

### Mobile (< 768px)
- Stacked below hero text
- Full-width display
- Smaller badge text
- Touch-friendly (no hover effects)

---

## ?? Benefits

### Marketing Impact
1. **Visual Proof**: Shows actual working product
2. **Professional**: Demonstrates polished UI
3. **Feature Showcase**: Highlights key capabilities
4. **Trust Building**: Real screenshot vs mockup
5. **Engagement**: Users see what they'll get

### SEO Benefits
- **Alt Text**: Descriptive for screen readers
- **Image Optimization**: Fast loading
- **Relevant Content**: Matches page topic

---

## ? Checklist

Before deploying:
- [ ] Screenshot taken at high resolution
- [ ] Image cropped appropriately
- [ ] Saved as `dashboard-preview.png`
- [ ] Placed in `wwwroot/images/` folder
- [ ] Image displays correctly in browser
- [ ] Alt text is descriptive
- [ ] Hover effect works
- [ ] Badge displays correctly
- [ ] Mobile responsive
- [ ] File size optimized (< 500KB)

---

## ?? Image Optimization

### Recommended Tools
- **TinyPNG**: https://tinypng.com (free compression)
- **Squoosh**: https://squoosh.app (advanced options)
- **ImageOptim**: Desktop app for batch processing

### Optimization Tips
1. **Resize** to max 1600px wide
2. **Compress** to reduce file size
3. **Format**: PNG for UI screenshots
4. **Quality**: 85-90% is usually optimal
5. **Target**: < 300KB file size

### PowerShell Optimization (using ImageMagick)
```powershell
# Install ImageMagick
winget install ImageMagick.ImageMagick

# Resize and optimize
magick convert dashboard-preview.png -resize 1600x900 -quality 85 dashboard-preview-optimized.png
```

---

## ?? Expected File Size

| Resolution | Uncompressed | Compressed |
|------------|--------------|------------|
| 1200×675   | ~800KB       | ~200KB     |
| 1600×900   | ~1.4MB       | ~300KB     |
| 2400×1350  | ~3.2MB       | ~600KB     |

**Target**: 200-400KB for optimal loading speed

---

## ?? Deployment

### Build and Deploy
```powershell
# Build marketing site with image
dotnet publish MCBDS.Marketing -c Release -o MCBDS.Marketing/publish

# Image will be included in wwwroot automatically
```

### Verify Image Loads
1. Navigate to home page
2. Check browser DevTools (F12)
3. Network tab ? images/dashboard-preview.png
4. Should load with 200 status
5. Check image displays correctly

---

## ?? Alternative Placements

Consider adding dashboard screenshots to:
- [ ] Features page (different angles)
- [ ] Get Started page (installation preview)
- [ ] Gallery/Screenshots section (new page)
- [ ] Documentation examples

---

## ?? Image Credits

### Screenshot Details
- **Source**: MCBDSHost Web Dashboard
- **Page**: Server Overview
- **Status**: Live production screenshot
- **Date**: Current (real-time stats)

### Usage Rights
- ? Internal marketing materials
- ? Website screenshots
- ? Documentation
- ? Social media promotion
- ? Press materials

---

## ?? Updating the Screenshot

### When to Update
- New features added to dashboard
- UI improvements
- Rebranding changes
- Better quality available
- Seasonal themes

### Update Process
1. Take new screenshot
2. Optimize image
3. Replace existing file (same name)
4. Rebuild marketing site
5. Deploy updated package

---

**Dashboard Image Setup Complete!** ??

Your marketing site now displays a **professional dashboard preview** that:
- ? Shows real product interface
- ? Highlights key features
- ? Builds user trust
- ? Improves engagement
- ? Enhances visual appeal

**Add the screenshot file and rebuild to complete the integration!** ????

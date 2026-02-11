# ?? 3-Step Quick Fix (Do This NOW)

## Step 1: Optimize Hero Image (30 min)

```powershell
# 1. Go to images folder
cd D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Marketing\wwwroot\images

# 2. Check size
Get-Item dashboard-preview.png | Select-Object Length

# 3. If ImageMagick not installed:
choco install imagemagick -y

# 4. Optimize
magick dashboard-preview.png -strip -quality 85 dashboard-preview-opt.png
magick dashboard-preview.png -quality 80 dashboard-preview.webp
```

**Update Home.razor** (line 72-78):
```razor
<picture>
    <source srcset="images/dashboard-preview.webp" type="image/webp">
    <img src="images/dashboard-preview-opt.png" 
         alt="MCBDS Manager Dashboard"
         class="img-fluid rounded shadow-lg"
         width="1200" height="800" fetchpriority="high"
         style="border: 4px solid rgba(0,0,0,0.2);" />
</picture>
```

**Expected: LCP 13.0s ? 3.5s** ?

---

## Step 2: Move Icon CSS (5 min)

**In App.razor:**

Move this line FROM `<head>` (line 48):
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
```

TO end of `<body>` (after line 59):
```html
<body>
    <Routes />
    <script src="@Assets["_framework/blazor.web.js"]"></script>
    <script src="@Assets["lib/bootstrap/dist/js/bootstrap.bundle.min.js"]"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
</body>
```

**Expected: FCP 4.6s ? 3.2s** ?

---

## Step 3: Add Lazy Loading (15 min)

Find ALL images below the hero and add `loading="lazy"`:

**Example - Features Section:**
```razor
<!-- If you have feature images, add loading="lazy" -->
<img src="feature-icon.png" alt="Feature" loading="lazy">
```

**Expected: TBT 1,950ms ? 1,500ms** ?

---

## Test Results

```powershell
# Build
dotnet build MCBDS.Marketing

# Run
dotnet run --project MCBDS.Marketing

# Test: Open http://localhost:7258
# Press F12 ? Lighthouse ? Analyze
```

**Expected Scores:**
- Performance: **70-80** (was 45-55)
- LCP: **~3.5s** (was 13.0s)
- FCP: **~3.0s** (was 4.6s)
- TBT: **~1,500ms** (was 1,950ms)

---

## That's It!

These 3 simple changes should give you **+25-35 points** on Lighthouse.

For 80-90 score, you'll need:
- Self-host Bootstrap Icons
- Purge unused CSS
- More advanced optimizations

But START with these 3 steps first!

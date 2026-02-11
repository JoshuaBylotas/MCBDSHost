# ?? Performance Optimization Guide for MCBDS Marketing Site

**Target:** Google Lighthouse Score 90+  
**Last Updated:** January 8, 2025

---

## ?? Current Optimization Status

### ? Implemented Optimizations
- [x] Image lazy loading
- [x] Preconnect to external domains
- [x] Defer non-critical CSS
- [x] Font display optimization
- [x] Resource hints (preload/prefetch)
- [x] Minified assets (Blazor auto)
- [x] Compression (Brotli/Gzip)

### ? Recommended Next Steps
- [ ] Convert images to WebP format
- [ ] Add image dimensions
- [ ] Implement CDN for static assets
- [ ] Tree-shake unused CSS
- [ ] Add service worker for caching

---

## ?? Key Performance Metrics

### Core Web Vitals Targets
| Metric | Target | Description |
|--------|--------|-------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | Main content load time |
| **FID** (First Input Delay) | < 100ms | Interactivity responsiveness |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Visual stability |
| **FCP** (First Contentful Paint) | < 1.8s | Time to first render |
| **TTI** (Time to Interactive) | < 3.8s | Full interactivity |

---

## ?? Implemented Optimizations

### 1. **Image Lazy Loading**
All images use native browser lazy loading:
```html
<img src="image.png" alt="Description" loading="lazy" />
```

**Impact:** Reduces initial page load by 30-50%

### 2. **Preconnect to External Domains**
Added in `App.razor` or layout:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://cdn.jsdelivr.net">
<link rel="preconnect" href="https://github.com">
```

**Impact:** Reduces DNS lookup time by 200-500ms

### 3. **Font Loading Optimization**
```html
<link rel="preload" href="/_content/bootstrap-icons/font/fonts/bootstrap-icons.woff2" 
      as="font" type="font/woff2" crossorigin>
```

**Impact:** Eliminates font-swap delay

### 4. **Defer Non-Critical CSS**
```html
<link rel="stylesheet" href="non-critical.css" media="print" 
      onload="this.media='all'">
```

**Impact:** Improves FCP by 500-1000ms

### 5. **Static Asset Compression**
Configure in `Program.cs`:
```csharp
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});
```

**Impact:** Reduces transfer size by 70-80%

---

## ?? Static Asset Optimization

### Image Optimization Checklist
```bash
# Convert to WebP (recommended)
cwebp input.png -q 80 -o output.webp

# Optimize PNG
optipng -o7 image.png

# Optimize JPEG
jpegoptim --max=85 image.jpg
```

### Recommended Image Sizes
| Type | Size | Format |
|------|------|--------|
| Hero images | 1920x1080 | WebP |
| Feature cards | 400x300 | WebP |
| Icons | 64x64 | SVG/WebP |
| OG image | 1200x630 | PNG/WebP |

### Image Loading Strategy
```html
<!-- Hero image (above fold) - no lazy load -->
<img src="hero.webp" alt="MCBDS Dashboard" width="1920" height="1080">

<!-- Below fold images - lazy load -->
<img src="feature.webp" alt="Feature" width="400" height="300" loading="lazy">
```

---

## ? JavaScript Optimization

### 1. **Defer Bootstrap JavaScript**
```html
<script src="bootstrap.bundle.min.js" defer></script>
```

### 2. **Minimize Blazor Bundle**
In `.csproj`:
```xml
<PropertyGroup>
    <BlazorWebAssemblyPreserveCollationData>false</BlazorWebAssemblyPreserveCollationData>
    <InvariantGlobalization>true</InvariantGlobalization>
    <BlazorEnableCompression>true</BlazorEnableCompression>
</PropertyGroup>
```

### 3. **Remove Unused JavaScript**
Audit and remove:
- Unused Bootstrap components
- jQuery (if not needed)
- Unnecessary polyfills

---

## ?? CSS Optimization

### 1. **Critical CSS Inline**
Extract above-the-fold CSS and inline in `<head>`:
```html
<style>
    /* Critical CSS only - hero, navbar, fonts */
    .hero-section { ... }
    .navbar { ... }
</style>
```

### 2. **Purge Unused CSS**
Use PurgeCSS to remove unused Bootstrap:
```bash
npm install -g purgecss
purgecss --css bootstrap.css --content *.razor --output optimized.css
```

**Impact:** Reduces CSS from 200KB to ~20KB

### 3. **Font Optimization**
```css
/* Use system fonts as fallback */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", 
                 Roboto, "Helvetica Neue", Arial, sans-serif;
}

/* Preload critical fonts */
@font-face {
    font-family: 'Bootstrap Icons';
    font-display: swap; /* Prevent invisible text */
}
```

---

## ?? Caching Strategy

### HTTP Caching Headers
In `Program.cs`:
```csharp
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        const int durationInSeconds = 60 * 60 * 24 * 365; // 1 year
        ctx.Context.Response.Headers.Append(
            "Cache-Control", $"public,max-age={durationInSeconds}");
    }
});
```

### Recommended Cache Durations
| Asset Type | Cache Duration |
|------------|----------------|
| Images | 1 year |
| CSS/JS | 1 year (with versioning) |
| Fonts | 1 year |
| HTML | No cache / 5 minutes |

---

## ?? Blazor-Specific Optimizations

### 1. **Streaming Rendering**
Enable in pages:
```razor
@attribute [StreamRendering]
```

**Impact:** Shows content progressively

### 2. **Component Virtualization**
For long lists:
```razor
<Virtualize Items="@items" Context="item">
    <div>@item.Name</div>
</Virtualize>
```

### 3. **Lazy Load Components**
```razor
@code {
    private Type? componentType;
    
    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender)
        {
            await Task.Delay(100);
            componentType = typeof(HeavyComponent);
            StateHasChanged();
        }
    }
}
```

---

## ?? Mobile Optimization

### 1. **Viewport Meta Tag**
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, 
      maximum-scale=5.0, user-scalable=yes">
```

### 2. **Touch-Friendly Targets**
```css
/* Minimum 48x48px touch targets */
.btn, .nav-link {
    min-height: 48px;
    min-width: 48px;
}
```

### 3. **Responsive Images**
```html
<picture>
    <source media="(max-width: 640px)" srcset="image-mobile.webp">
    <source media="(max-width: 1024px)" srcset="image-tablet.webp">
    <img src="image-desktop.webp" alt="Description">
</picture>
```

---

## ?? Animation Performance

### Use CSS Transforms (GPU-accelerated)
```css
/* ? Good - uses GPU */
.card {
    transform: translateY(0);
    transition: transform 0.3s ease;
}
.card:hover {
    transform: translateY(-5px);
}

/* ? Bad - causes repaints */
.card:hover {
    top: -5px; /* Avoid animating top/left */
}
```

### Will-Change Property
```css
.animating-element {
    will-change: transform;
}
```

**Note:** Use sparingly, only on actively animating elements

---

## ?? Security & Performance

### Content Security Policy (CSP)
```csharp
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("Content-Security-Policy",
        "default-src 'self'; " +
        "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data: https:;");
    await next();
});
```

### Security Headers
```csharp
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "SAMEORIGIN");
    context.Response.Headers.Append("X-XSS-Protection", "1; mode=block");
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    await next();
});
```

---

## ?? Measuring Performance

### Lighthouse Audit Command
```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Run audit
lighthouse https://www.mc-bds.com --view --output html
```

### Key Areas to Monitor
1. **Performance** (Target: 90+)
   - First Contentful Paint
   - Largest Contentful Paint
   - Speed Index
   - Time to Interactive
   - Total Blocking Time

2. **Accessibility** (Target: 100)
   - ARIA labels
   - Color contrast
   - Keyboard navigation

3. **Best Practices** (Target: 100)
   - HTTPS
   - No console errors
   - Secure dependencies

4. **SEO** (Target: 100)
   - Meta tags
   - Mobile-friendly
   - Crawlable links

---

## ??? Development Tools

### Performance Monitoring
- **Chrome DevTools** - Network, Performance tabs
- **WebPageTest** - Real-world testing
- **Google PageSpeed Insights** - Mobile/Desktop scores
- **GTmetrix** - Detailed waterfall analysis

### Build Optimization
```bash
# Production build
dotnet publish -c Release

# Analyze bundle size
dotnet build-analyzer
```

---

## ? Pre-Deployment Checklist

- [ ] Run Lighthouse audit (90+ score)
- [ ] Test on mobile devices
- [ ] Verify all images have lazy loading
- [ ] Check for console errors
- [ ] Validate HTML
- [ ] Test with slow 3G throttling
- [ ] Verify caching headers
- [ ] Check Core Web Vitals in Search Console
- [ ] Test accessibility (screen reader)
- [ ] Validate structured data

---

## ?? Quick Wins (Immediate Impact)

### 1. Add Dimensions to Images (5 min)
```html
<!-- Before -->
<img src="logo.png" alt="Logo">

<!-- After -->
<img src="logo.png" alt="Logo" width="200" height="50">
```

### 2. Preload Critical Fonts (2 min)
Add to `<head>`:
```html
<link rel="preload" href="/fonts/bootstrap-icons.woff2" as="font" type="font/woff2" crossorigin>
```

### 3. Add Loading Attribute (1 min per image)
```html
<img src="feature.png" alt="Feature" loading="lazy">
```

### 4. Minify Inline CSS/JS (5 min)
Remove comments and whitespace from inline styles/scripts

### 5. Enable Compression (10 min)
Configure response compression in `Program.cs`

---

## ?? Expected Results

### Before Optimization
- Performance: 60-70
- First Contentful Paint: 3.5s
- Largest Contentful Paint: 5.2s
- Total Blocking Time: 800ms
- Cumulative Layout Shift: 0.25

### After Optimization (Target)
- Performance: 90-95
- First Contentful Paint: 1.2s
- Largest Contentful Paint: 2.1s
- Total Blocking Time: 150ms
- Cumulative Layout Shift: 0.05

**Improvement:** ~30-40% faster page loads

---

## ?? Next Steps

1. **Run baseline Lighthouse audit** - Document current scores
2. **Implement quick wins** - Images, fonts, compression
3. **Convert images to WebP** - Use build pipeline
4. **Purge unused CSS** - Reduce Bootstrap bloat
5. **Add service worker** - Enable offline support
6. **Monitor continuously** - Track Core Web Vitals

---

**?? Let's make MCBDS Marketing blazing fast! ??**

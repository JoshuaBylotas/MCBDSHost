# MCBDS Manager - SEO Checklist & Configuration

**Last Updated:** January 8, 2025  
**Site URL:** https://www.mc-bds.com

## ? Core SEO Files Updated

### 1. Sitemap (sitemap.xml)
- ? **Location:** `/wwwroot/sitemap.xml`
- ? **Referenced in robots.txt:** Yes
- ? **Updated:** January 8, 2025
- ? **Current Pages:**
  - `/` (Home - Priority: 1.0)
  - `/features` (Features - Priority: 0.9)
  - `/get-started` (Getting Started - Priority: 0.95)
  - `/installer` (Installer Download - Priority: 0.9)
  - `/installer-guide` (Detailed Guide - Priority: 0.85)
  - `/compatibility` (Compatibility - Priority: 0.8)
  - `/docs` + documentation pages
  - `/contact` (Contact - Priority: 0.7)

### 2. Robots.txt
- ? **Location:** `/wwwroot/robots.txt`
- ? **Configuration:**
  - Allows all search engines
  - Disallows: `/Error`, `/not-found`, `/bin/`, `/obj/`, `/_framework/`, `/logs/`
  - Sitemap URL: https://www.mc-bds.com/sitemap.xml
  - Crawl-delay: 1 second

### 3. Meta Tags (Per Page)
All pages include:
- ? `<title>` tag with descriptive text
- ? `<meta name="description">` (unique per page)
- ? `<meta name="keywords">` (relevant to page)
- ? `<link rel="canonical">` (correct URLs)

---

## ?? SEO Components

### SeoHead Component
**Location:** `/Components/Shared/SeoHead.razor`

Provides:
- Primary meta tags (title, description, keywords)
- Open Graph tags (Facebook)
- Twitter Card tags
- Canonical URLs
- Structured Data (JSON-LD) support

**Default Keywords:** `minecraft, bedrock, server, management, windows service, blazor, maui, mcbds, dedicated server, monitoring, automation, pack management, player allowlist, backup, restore`

---

## ?? Page-Specific SEO

### Home Page (/)
- **Title:** MCBDS Manager - Professional Minecraft Bedrock Server Management
- **Focus Keywords:** minecraft bedrock server, server management, windows service, pack management
- **Structured Data:** Organization + SoftwareApplication schemas

### Features Page (/features)
- **Title:** Features - MCBDS Manager Server Management Platform
- **Focus Keywords:** server features, monitoring, command console, backups, pack management
- **Highlights:** Real-time monitoring, Smart console, Pack management, Player allowlist, Multi-server, HTTPS support

### Get Started (/get-started)
- **Title:** Get Started - MCBDS Manager Installation Guide
- **Focus Keywords:** installation, windows service installer, quick setup
- **Priority:** High (0.95) - primary conversion page

### Installer (/installer)
- **Title:** Download MCBDS Manager v1.1 - Windows Service Installer
- **Focus Keywords:** download, installer, windows service, v1.1
- **Priority:** High (0.9) - download page
- **Direct Link:** GitHub release

### Installer Guide (/installer-guide)
- **Title:** MCBDS Windows Installer - Quick Setup Guide
- **Focus Keywords:** installation guide, setup, configuration, screenshots
- **Priority:** Medium-High (0.85)

### Compatibility (/compatibility)
- **Title:** Version Compatibility Guide - MCBDS Manager
- **Focus Keywords:** compatibility, versions, minecraft bedrock versions
- **Priority:** Medium (0.8)

---

## ?? SEO Best Practices Implemented

### ? Technical SEO
- [x] Valid XML sitemap
- [x] Robots.txt properly configured
- [x] Canonical URLs on all pages
- [x] Mobile-responsive design (Bootstrap)
- [x] Fast page load (Blazor SSR + Static assets)
- [x] HTTPS support (via configuration)
- [x] Structured data (JSON-LD)

### ? On-Page SEO
- [x] Unique title tags per page
- [x] Unique meta descriptions per page
- [x] Proper heading hierarchy (H1 ? H6)
- [x] Alt text for images (where applicable)
- [x] Internal linking structure
- [x] Clear call-to-action buttons
- [x] Breadcrumb navigation (in docs)

### ? Content SEO
- [x] Keyword-rich content
- [x] Focus on user intent (informational, transactional)
- [x] Regular content updates (lastmod in sitemap)
- [x] Clear value propositions
- [x] Feature benefits highlighted

### ? Social Media SEO
- [x] Open Graph tags (Facebook)
- [x] Twitter Card tags
- [x] Social sharing enabled
- [x] OG images configured

---

## ?? SEO Priority Actions

### High Priority ? (Completed)
1. ? Update sitemap.xml with current pages
2. ? Remove Docker references from keywords
3. ? Add Windows Service to keywords
4. ? Add pack management, player allowlist to keywords
5. ? Fix duplicate /installer route
6. ? Update page priorities in sitemap
7. ? Update lastmod dates

### Medium Priority (Recommended)
1. ? Submit sitemap to Google Search Console
2. ? Submit sitemap to Bing Webmaster Tools
3. ? Create and upload OG image (`/images/og-image.png`)
4. ? Add schema.org WebSite markup with search action
5. ? Implement FAQ schema on documentation pages
6. ? Add breadcrumb schema to all pages
7. ? Monitor Core Web Vitals

### Low Priority (Future)
1. ? Create video content for YouTube
2. ? Add blog section for tutorials
3. ? Implement customer reviews/testimonials schema
4. ? Create infographics for features
5. ? Add changelog page for SEO benefits

---

## ?? SEO Monitoring

### Tools to Use
- **Google Search Console:** Track indexing, rankings, CTR
- **Bing Webmaster Tools:** Bing search visibility
- **Google Analytics:** Traffic, user behavior
- **PageSpeed Insights:** Performance monitoring
- **Lighthouse:** Overall site quality

### Key Metrics to Track
- Organic search traffic
- Keyword rankings
- Click-through rate (CTR)
- Bounce rate
- Average session duration
- Pages per session
- Core Web Vitals (LCP, FID, CLS)

---

## ?? Important URLs

### Internal Links
- Home: https://www.mc-bds.com/
- Get Started: https://www.mc-bds.com/get-started
- Download: https://www.mc-bds.com/installer
- Features: https://www.mc-bds.com/features
- Compatibility: https://www.mc-bds.com/compatibility
- Docs: https://www.mc-bds.com/docs

### External Links
- GitHub Repository: https://github.com/JoshuaBylotas/MCBDSHost
- GitHub Releases: https://github.com/JoshuaBylotas/MCBDSHost/releases
- GitHub Issues: https://github.com/JoshuaBylotas/MCBDSHost/issues
- Minecraft Bedrock Server: https://www.minecraft.net/en-us/download/server/bedrock

---

## ?? Content Guidelines

### Writing for SEO
1. **Focus Keywords:** Use naturally, don't stuff
2. **User Intent:** Answer user questions clearly
3. **Readability:** Short paragraphs, bullet points, clear headers
4. **CTAs:** Clear calls-to-action on every page
5. **Internal Links:** Link to related content naturally

### Keyword Strategy
**Primary Keywords:**
- minecraft bedrock server manager
- bedrock server management
- minecraft server hosting tool
- bedrock dedicated server software

**Secondary Keywords:**
- pack management minecraft bedrock
- player allowlist minecraft
- minecraft server backup tool
- bedrock server monitoring
- windows service minecraft

**Long-tail Keywords:**
- how to manage minecraft bedrock server
- best minecraft bedrock server management tool
- minecraft bedrock dedicated server windows
- automate minecraft bedrock server backups

---

## ? Next Steps

1. **Submit sitemap** to Google Search Console
2. **Upload OG image** to `/wwwroot/images/og-image.png`
3. **Test all pages** with Lighthouse
4. **Monitor rankings** for target keywords
5. **Create content calendar** for blog posts
6. **Build backlinks** through community engagement

---

## ?? Support

For SEO-related questions or improvements, open an issue on GitHub:
https://github.com/JoshuaBylotas/MCBDSHost/issues

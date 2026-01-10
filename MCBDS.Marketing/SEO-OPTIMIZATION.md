# SEO Optimization Guide - MCBDS.Marketing

This document outlines the SEO optimization implemented for the MCBDSHost marketing website.

## Overview

The MCBDS.Marketing project has been optimized for search engines with comprehensive SEO best practices including:

- ? Meta tags and Open Graph data
- ? Structured data (JSON-LD)
- ? XML sitemap
- ? Robots.txt configuration
- ? Semantic HTML structure
- ? Page-specific SEO components
- ? Canonical URLs
- ? Security headers

---

## 1. Meta Tags & Open Graph

### Global Meta Tags (App.razor)

All pages include these base meta tags:

```html
<meta name="description" content="..." />
<meta name="keywords" content="..." />
<meta name="author" content="MCBDSHost" />
<meta name="theme-color" content="#0d6efd" />
<meta name="robots" content="index, follow" />
```

### Open Graph Tags

For social media sharing:

```html
<meta property="og:type" content="website" />
<meta property="og:url" content="https://www.mc-bds.com/" />
<meta property="og:title" content="..." />
<meta property="og:description" content="..." />
<meta property="og:image" content="https://www.mc-bds.com/images/og-image.png" />
```

### Twitter Cards

Optimized for Twitter sharing:

```html
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="..." />
<meta name="twitter:description" content="..." />
<meta name="twitter:image" content="..." />
```

---

## 2. Structured Data (JSON-LD)

### StructuredDataService

Located at: `Services/StructuredDataService.cs`

Provides methods to generate schema.org structured data:

#### Organization Data
```csharp
GetOrganizationData()
```
- Used on the home page
- Defines organization identity
- Includes contact information
- Links to social media

#### Software Application Data
```csharp
GetSoftwareApplicationData()
```
- Describes MCBDSHost as software
- Lists features and requirements
- Includes pricing (free)
- Download information

#### HowTo Data
```csharp
GetHowToData(name, description, steps)
```
- Used on installation guides
- Step-by-step instructions
- Improves Google search results

#### FAQ Data
```csharp
GetFAQPageData(faqs)
```
- For FAQ pages
- Question/answer format
- Featured snippets in search

#### Breadcrumb Data
```csharp
GetBreadcrumbData(breadcrumbs)
```
- Navigation hierarchy
- Better search result display

---

## 3. Page-Specific SEO

### Home Page (`Pages/Home.razor`)

**Keywords:**
- minecraft bedrock server
- minecraft server management
- mcbds
- bedrock dedicated server
- server monitoring

**Structured Data:**
- Organization schema
- Software Application schema

**Content Optimization:**
- H1: "Manage Your Minecraft Bedrock Server Like a Pro"
- Descriptive feature cards
- Clear CTAs
- Image alt text

### Features Page (`Pages/Features.razor`)

**Keywords:**
- minecraft server features
- server monitoring
- command console
- automated backups

**Content:**
- Detailed feature descriptions
- Organized by category
- Visual icons for scanning
- Benefit-focused copy

### Get Started Page (`Pages/GetStarted.razor`)

**Keywords:**
- mcbdshost installation
- minecraft server setup
- docker deployment
- windows server minecraft

**Structured Data:**
- HowTo schema for installation steps

**Content:**
- Step-by-step guides
- Code examples
- Platform-specific instructions
- System requirements

---

## 4. XML Sitemap

### Location
`wwwroot/sitemap.xml`

### Structure
```xml
<url>
  <loc>https://www.mc-bds.com/</loc>
  <lastmod>2025-01-07</lastmod>
  <changefreq>weekly</changefreq>
  <priority>1.0</priority>
</url>
```

### Priority Guidelines
- **1.0**: Homepage
- **0.9**: Main sections (Features, Get Started, Docs)
- **0.8**: Important documentation
- **0.7**: Standard documentation
- **0.6**: Reference documentation
- **0.5**: Technical/internal pages

### Change Frequency
- **weekly**: Homepage, Get Started
- **monthly**: Features, main documentation
- **yearly**: Technical reference

### Maintenance
Update `<lastmod>` dates when content changes:
```bash
# Current format: YYYY-MM-DD
<lastmod>2025-01-07</lastmod>
```

---

## 5. Robots.txt

### Location
`wwwroot/robots.txt`

### Configuration

**Allowed:**
```
User-agent: *
Allow: /
```

**Disallowed:**
```
Disallow: /Error
Disallow: /not-found
Disallow: /bin/
Disallow: /obj/
Disallow: /_framework/
Disallow: /logs/
```

**Sitemap Reference:**
```
Sitemap: https://www.mc-bds.com/sitemap.xml
```

**Crawl Delay:**
```
Crawl-delay: 1
```

---

## 6. SeoHead Component

### Location
`Components/Shared/SeoHead.razor`

### Usage

```razor
<SeoHead 
    Title="Custom Page Title"
    Description="Custom description"
    Keywords="custom, keywords"
    ImageUrl="https://example.com/image.png"
    StructuredData="@jsonLdData" />
```

### Parameters

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| Title | string | No | MCBDSHost - Professional Minecraft... |
| Description | string | No | Professional web-based management... |
| Keywords | string | No | minecraft, bedrock, server... |
| Author | string | No | MCBDSHost |
| Robots | string | No | index, follow |
| OgType | string | No | website |
| ImageUrl | string | No | /images/og-image.png |
| StructuredData | string | No | null |

---

## 7. Security Headers

### Implemented in Program.cs

```csharp
context.Response.Headers["X-Content-Type-Options"] = "nosniff";
context.Response.Headers["X-Frame-Options"] = "SAMEORIGIN";
context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
context.Response.Headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()";
```

**Benefits:**
- Prevents MIME type sniffing
- Protects against clickjacking
- Controls referrer information
- Restricts sensitive permissions

---

## 8. Image Optimization

### Requirements

Create these images in `wwwroot/images/`:

| Image | Size | Purpose |
|-------|------|---------|
| og-image.png | 1200×630 | Open Graph/Twitter |
| logo.png | 512×512 | Organization logo |
| dashboard-preview.png | 1920×1080 | Feature showcase |

### Best Practices

- Use PNG for logos/screenshots
- Use WebP for photos (with PNG fallback)
- Compress images (TinyPNG, Squoosh)
- Include alt text for all images
- Use responsive images where appropriate

---

## 9. Content Best Practices

### Title Tags
- Keep under 60 characters
- Include primary keyword
- Make compelling and descriptive
- Format: "Page Name - MCBDSHost"

### Meta Descriptions
- 150-160 characters
- Include target keywords naturally
- Add call-to-action
- Unique for each page

### Headings Structure
- One H1 per page
- Hierarchical (H1 ? H2 ? H3)
- Include keywords naturally
- Descriptive and clear

### Internal Linking
- Link related pages
- Use descriptive anchor text
- Create hub pages (Documentation)
- Breadcrumb navigation

### Content Quality
- Original, valuable content
- Solve user problems
- Use clear language
- Regular updates

---

## 10. Performance Optimization

### Implemented

- Static asset optimization
- Blazor SSR for fast initial load
- Lazy loading components
- Minimal external dependencies
- Compressed CSS/JS

### To Monitor

- Core Web Vitals (LCP, FID, CLS)
- Time to First Byte (TTFB)
- First Contentful Paint (FCP)
- Speed Index

### Tools

- Google PageSpeed Insights
- Lighthouse
- WebPageTest
- GTmetrix

---

## 11. Analytics & Monitoring

### Google Search Console

1. Verify ownership
2. Submit sitemap
3. Monitor:
   - Index coverage
   - Search performance
   - Mobile usability
   - Core Web Vitals

### Google Analytics (Optional)

Track:
- Page views
- User behavior
- Conversion goals
- Traffic sources

Add tracking code to `App.razor`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

---

## 12. SEO Checklist

### Pre-Launch

- [ ] All pages have unique titles
- [ ] All pages have unique meta descriptions
- [ ] All images have alt text
- [ ] Sitemap.xml is accessible
- [ ] Robots.txt is configured
- [ ] Canonical URLs are set
- [ ] 404 page exists and is helpful
- [ ] HTTPS is enforced
- [ ] Mobile responsive
- [ ] Page load time < 3 seconds

### Post-Launch

- [ ] Submit sitemap to Google Search Console
- [ ] Submit sitemap to Bing Webmaster Tools
- [ ] Set up Google Analytics (optional)
- [ ] Monitor for crawl errors
- [ ] Check mobile usability
- [ ] Monitor Core Web Vitals
- [ ] Track keyword rankings
- [ ] Build quality backlinks

### Ongoing Maintenance

- [ ] Update content regularly
- [ ] Fix broken links
- [ ] Update sitemap.xml dates
- [ ] Monitor search performance
- [ ] Add new content
- [ ] Improve existing content
- [ ] Monitor competitors

---

## 13. Keyword Strategy

### Primary Keywords

1. **minecraft bedrock server management**
2. **mcbds**
3. **bedrock dedicated server**
4. **minecraft server monitoring**
5. **docker minecraft server**

### Secondary Keywords

- minecraft server control panel
- bedrock server automation
- minecraft backup solution
- server command console
- minecraft server dashboard

### Long-Tail Keywords

- how to manage minecraft bedrock dedicated server
- best minecraft bedrock server management tool
- docker compose minecraft bedrock server
- automated minecraft server backups
- minecraft bedrock server with web interface

---

## 14. Common SEO Issues & Fixes

### Issue: Duplicate Content

**Cause:** Multiple URLs for same content

**Fix:**
```razor
<link rel="canonical" href="https://www.mc-bds.com/page" />
```

### Issue: Slow Page Load

**Cause:** Large images, unoptimized assets

**Fix:**
- Compress images
- Enable caching
- Use CDN for static assets
- Minimize JavaScript

### Issue: Poor Mobile Experience

**Cause:** Not responsive, small text

**Fix:**
- Use Bootstrap responsive classes
- Test on real devices
- Use viewport meta tag
- Ensure touch targets are large enough

### Issue: Missing Structured Data

**Cause:** No JSON-LD markup

**Fix:**
```razor
@inject StructuredDataService StructuredData

<script type="application/ld+json">
    @((MarkupString)StructuredData.GetOrganizationData())
</script>
```

---

## 15. Resources

### Official Documentation

- [Google SEO Starter Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide)
- [Schema.org](https://schema.org/)
- [Open Graph Protocol](https://ogp.me/)
- [Google Search Console](https://search.google.com/search-console)

### Tools

- **SEO Analysis:** Moz, Ahrefs, SEMrush
- **Technical SEO:** Screaming Frog, Sitebulb
- **Performance:** Lighthouse, PageSpeed Insights
- **Keywords:** Google Keyword Planner, Ubersuggest

### Testing

- [Google Rich Results Test](https://search.google.com/test/rich-results)
- [Google Mobile-Friendly Test](https://search.google.com/test/mobile-friendly)
- [Schema Markup Validator](https://validator.schema.org/)

---

## 16. Future Enhancements

### Planned Improvements

1. **Blog Section**
   - Tutorial articles
   - Update announcements
   - Best practices guides

2. **Video Content**
   - Installation tutorials
   - Feature demonstrations
   - YouTube SEO

3. **Multilingual Support**
   - hreflang tags
   - Translated content
   - Regional targeting

4. **Enhanced Structured Data**
   - Video schema
   - Article schema
   - Review schema

5. **Local SEO** (if applicable)
   - Local business schema
   - Google My Business
   - Location pages

---

## Contact

For SEO-related questions or suggestions:
- GitHub: https://github.com/JoshuaBylotas/MCBDSHost
- Website: https://www.mc-bds.com
- Email: support@mc-bds.com

---

**Document Version:** 1.0  
**Last Updated:** January 7, 2025  
**Project:** MCBDS.Marketing  
**Target:** .NET 10 / Blazor

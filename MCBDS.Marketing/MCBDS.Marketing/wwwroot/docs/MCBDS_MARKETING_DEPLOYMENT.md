# MCBDSHost Marketing Website - Deployment Guide

## ? PACKAGES READY FOR DEPLOYMENT!

Production-ready deployment packages have been created in the `deployment-packages/` folder with **NO source code included**.

---

## ?? Available Packages

### Package 1: mcbdshost-marketing-static.zip (4.31 MB)
**For Static Web Hosting (RECOMMENDED)**

**What's included:**
- ? Compiled HTML, CSS, JavaScript
- ? Bootstrap 5 framework
- ? Bootstrap Icons
- ? All static assets
- ? NO source code
- ? NO project files
- ? NO development artifacts

**Best for:**
- GitHub Pages, Netlify, Vercel
- Fastest deployment (drag & drop)
- Free hosting available
- Global CDN distribution
- Automatic HTTPS

### Package 2: mcbdshost-marketing-full.zip (4.45 MB)
**For ASP.NET Core Hosting**

**What's included:**
- ? Complete .NET 10 application (compiled)
- ? All required DLLs
- ? Runtime configuration
- ? NO source code
- ? NO project files

**Best for:**
- IIS (Windows Server)
- Docker containers
- Azure App Service
- Linux with Kestrel

---

## ?? QUICK START (3 Options)

### Option 1: Netlify (EASIEST - 2 Steps)

```bash
# 1. Extract the static package
unzip deployment-packages/mcbdshost-marketing-static.zip -d marketing-site

# 2. Deploy
# Go to https://app.netlify.com/drop
# Drag the 'marketing-site' folder
# Done! Instant URL provided
```

**Time:** 2 minutes | **Cost:** FREE

---

### Option 2: GitHub Pages (3 Commands)

```bash
# 1. Extract
unzip deployment-packages/mcbdshost-marketing-static.zip -d gh-pages

# 2. Initialize and push
cd gh-pages
git init
git add .
git commit -m "Deploy MCBDSHost marketing site"
git branch -M gh-pages
git remote add origin https://github.com/yourusername/mcbdshost-marketing.git
git push -u origin gh-pages

# 3. Enable in GitHub
# Go to repository Settings ? Pages
# Select 'gh-pages' branch
# Save
```

**Time:** 5 minutes | **Cost:** FREE

---

### Option 3: Vercel (1 Command)

```bash
# Extract and deploy
unzip deployment-packages/mcbdshost-marketing-static.zip -d vercel-deploy
vercel --prod vercel-deploy
```

**Time:** 2 minutes | **Cost:** FREE

---

## ?? Complete Documentation

All documentation is included in the `deployment-packages/` folder:

### 1. **README.md** - Start here!
- Package overview
- Quick start guides
- Platform comparisons

### 2. **DEPLOYMENT-GUIDE.md** - Detailed instructions
- Step-by-step for 7+ platforms
- Configuration guides
- Troubleshooting
- Performance optimization
- SSL setup
- Custom domains

### 3. **MANIFEST.txt** - Package information
- Build details
- Contents list
- System requirements
- Verification checklist

### 4. **PACKAGE-SUMMARY.md** - Executive summary
- Deployment recommendations
- Cost comparisons
- Performance expectations
- Success criteria

---

## ?? Recommended Deployment

**For this marketing website, we recommend:**

1. **Package:** `mcbdshost-marketing-static.zip`
2. **Platform:** Netlify, Vercel, or GitHub Pages
3. **Time:** 2-5 minutes
4. **Cost:** $0 (FREE!)
5. **Performance:** Excellent (global CDN)

**Why static hosting?**
- ? Marketing sites don't need servers
- ? Faster page loads
- ? Free hosting widely available
- ? Global CDN included
- ? Automatic HTTPS
- ? Zero maintenance

---

## ?? Package Contents Summary

### Static Package (mcbdshost-marketing-static.zip)
```
wwwroot/
??? index.html                 # Main entry point
??? _framework/                # Blazor framework
??? css/
?   ??? bootstrap/            # Bootstrap 5
?   ??? app.css              # Base styles
?   ??? marketing.css        # Custom marketing styles
??? lib/
?   ??? bootstrap/           # Bootstrap JS
??? pages/                   # Pre-rendered pages
    ??? features/
    ??? get-started/
```

### Full Package (mcbdshost-marketing-full.zip)
```
publish/
??? MCBDS.Marketing.dll       # Main application
??? wwwroot/                  # Static assets
??? web.config                # IIS configuration
??? appsettings.json          # Runtime config
??? [framework files]         # .NET runtime DLLs
```

---

## ? Verification Checklist

After deploying, verify:

- [ ] Home page loads (/)
- [ ] Features page accessible (/features)  
- [ ] Get Started page accessible (/get-started)
- [ ] Navigation menu works
- [ ] All internal links function
- [ ] GitHub links open correctly
- [ ] Bootstrap icons display
- [ ] Responsive on mobile
- [ ] Footer shows properly
- [ ] No console errors
- [ ] Page loads < 3 seconds
- [ ] HTTPS enabled (production)

---

## ?? Hosting Cost Comparison

| Platform | Type | Cost | Features |
|----------|------|------|----------|
| **Netlify** | Static | FREE | 100GB bandwidth, CDN, HTTPS |
| **Vercel** | Static | FREE | Unlimited bandwidth, Edge network |
| **GitHub Pages** | Static | FREE | 100GB bandwidth, Custom domains |
| **Cloudflare Pages** | Static | FREE | Unlimited bandwidth, CDN |
| **Azure Static Web Apps** | Static | FREE | First 100GB bandwidth |
| **Azure App Service** | Server | ~$13/mo | Full .NET hosting |
| **Digital Ocean** | Server | ~$5/mo | VPS hosting |

**Recommendation:** Use free static hosting!

---

## ??? Deployment Tools

### For Static Hosting
- **Required:** None (just upload files)
- **Optional:** 
  - Git (for GitHub Pages)
  - Netlify CLI (for CI/CD)
  - Vercel CLI (for CLI deployment)

### For Server Hosting
- **Required:** 
  - .NET 10 Runtime
  - SSH/FTP client or Docker
- **Optional:**
  - nginx (reverse proxy)
  - Let's Encrypt (SSL)

---

## ?? Performance Expectations

### Static Hosting (Recommended)
- **Initial load:** < 2 seconds worldwide
- **CDN caching:** Edge locations globally
- **Uptime:** 99.9%+
- **Scalability:** Automatic (CDN)

### Server Hosting
- **Initial load:** 2-4 seconds
- **Caching:** Depends on configuration
- **Uptime:** Server-dependent
- **Scalability:** Manual scaling needed

---

## ?? Advanced Configurations

### Custom Domain

**Static Hosting:**
1. Add CNAME record: `www.yourdomain.com` ? `your-host.netlify.app`
2. Configure in hosting provider dashboard
3. HTTPS automatically configured

**Server Hosting:**
1. Update DNS A record to server IP
2. Configure SSL certificate
3. Update server configuration

### SSL/HTTPS

**Static Hosts:** 
- ? Automatic (Netlify, Vercel, GitHub Pages)
- ? Let's Encrypt integration
- ? Certificate renewal automatic

**Server Hosting:**
```bash
# Linux with Let's Encrypt
sudo certbot --nginx -d marketing.yourdomain.com
```

---

## ?? Troubleshooting

### Common Issues

**Problem:** 404 errors on page navigation
**Solution:** Configure hosting for SPA routing or use hash routing

**Problem:** CSS/JS not loading
**Solution:** Check base href in index.html matches deployment path

**Problem:** Application won't start (server hosting)
**Solution:** 
- Verify .NET 10 runtime installed
- Check application logs
- Ensure correct file permissions

---

## ?? Support Resources

### Documentation
- `deployment-packages/README.md` - Quick reference
- `deployment-packages/DEPLOYMENT-GUIDE.md` - Full guide
- `deployment-packages/MANIFEST.txt` - Package details

### Online Help
- **GitHub Repository:** https://github.com/JoshuaBylotas/MCBDSHost
- **Issues:** https://github.com/JoshuaBylotas/MCBDSHost/issues
- **Discussions:** https://github.com/JoshuaBylotas/MCBDSHost/discussions

---

## ?? Updating the Deployment

When you need to update:

1. Get updated source from repository
2. Rebuild: `dotnet publish MCBDS.Marketing -c Release`
3. Re-create packages: `Compress-Archive ...`
4. Deploy updated package
5. Verify deployment

**Typical update time:** 5-10 minutes

---

## ?? You're Ready to Deploy!

Everything you need is in the `deployment-packages/` folder:

? **Production-ready packages** (no source code)
? **Multiple deployment options** (static & server)
? **Complete documentation** (4 reference files)
? **Quick start guides** (2-5 minute deploys)
? **Free hosting options** ($0 cost)

---

## ?? Next Steps

1. **Navigate to** `deployment-packages/` folder
2. **Read** `README.md` for quick overview
3. **Choose** deployment method (Netlify recommended)
4. **Extract** appropriate ZIP file
5. **Deploy** following the guide
6. **Verify** using checklist above
7. **Share** your deployed URL!

---

**Pick your platform and deploy in minutes!** ??

For detailed platform-specific instructions, see:
- `deployment-packages/DEPLOYMENT-GUIDE.md`
- `deployment-packages/PACKAGE-SUMMARY.md`

**Happy deploying!** ??

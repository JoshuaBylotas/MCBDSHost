# MCBDSHost Marketing Website - Deployment Packages

**Production-ready packages with NO source code**

## ?? What's Included

### 1. `mcbdshost-marketing-static.zip` 
**? For static web hosting (RECOMMENDED)**
- Pure HTML, CSS, JavaScript files
- No server required
- Deploy to: GitHub Pages, Netlify, Vercel, Cloudflare Pages
- **Fastest and easiest deployment**

### 2. `mcbdshost-marketing-full.zip`
**? For ASP.NET Core hosting**
- Complete .NET 10 application
- Requires .NET 10 runtime on server
- Deploy to: IIS, Docker, Azure App Service, Linux

### 3. Documentation
- `DEPLOYMENT-GUIDE.md` - Complete deployment instructions
- `MANIFEST.txt` - Package information and checklist
- `README.md` - This file

## ?? Quick Start (3 Steps)

### For Static Hosting (GitHub Pages Example)

```bash
# 1. Extract the static package
unzip mcbdshost-marketing-static.zip -d website

# 2. Commit to GitHub
cd website
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/mcbdshost-marketing.git
git push -u origin main

# 3. Enable GitHub Pages in repository settings
# Settings ? Pages ? Source: main branch ? Save
```

**That's it!** Your site will be live at `https://yourusername.github.io/mcbdshost-marketing/`

### For Netlify (Even Easier!)

1. Go to https://app.netlify.com/drop
2. Extract `mcbdshost-marketing-static.zip`
3. Drag the folder to Netlify
4. **Done!** Instant URL provided

## ?? Full Documentation

See `DEPLOYMENT-GUIDE.md` for:
- Step-by-step guides for all platforms
- Docker deployment
- IIS configuration
- Linux server setup
- Custom domain configuration
- SSL/HTTPS setup
- Troubleshooting

## ? What You Get

### Pages
- **Home** - Hero section, features overview, CTA
- **Features** - Detailed feature showcase
- **Get Started** - Installation guides

### Design
- Fully responsive (mobile, tablet, desktop)
- Bootstrap 5 framework
- Bootstrap Icons
- Custom gradients and animations
- Professional styling

### SEO
- Meta tags included
- Semantic HTML
- Optimized for search engines
- Fast loading times

## ?? Recommended: Static Hosting

We recommend using the **static package** because:
- ? **Free hosting** available (GitHub Pages, Netlify, Vercel)
- ? **No server** maintenance
- ? **Global CDN** - Fast worldwide
- ? **Automatic HTTPS** - Secure by default
- ? **Zero configuration** - Just upload files
- ? **Instant deploys** - Updates in seconds

## ?? System Requirements

### Static Hosting
- **None!** Just upload the files

### Server Hosting
- .NET 10 Runtime (ASP.NET Core)
- Windows Server 2019+ or Linux
- 512 MB RAM minimum
- 100 MB disk space

## ?? Security

These packages contain:
- ? Compiled code only (no source)
- ? Production configuration
- ? No secrets or API keys
- ? Safe for public deployment

## ?? Performance

- Optimized static assets
- Compressed files
- Minimal dependencies
- Fast page loads (< 3 seconds)

## ?? Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS, Android)

## ?? Support

- **Full Guide**: `DEPLOYMENT-GUIDE.md`
- **GitHub**: https://github.com/JoshuaBylotas/MCBDSHost
- **Issues**: https://github.com/JoshuaBylotas/MCBDSHost/issues

## ?? License

MIT License - See source repository for details

---

## Platform-Specific Quick Links

### Static Hosting

**GitHub Pages**: Extract ? Push ? Enable Pages
- Free for public repos
- Custom domains supported
- Automatic HTTPS

**Netlify**: Drag & drop at https://app.netlify.com/drop
- Instant deployment
- Free tier available
- Custom domains with DNS

**Vercel**: `vercel --prod extracted-folder`
- Edge network
- Instant rollbacks
- Free hobby tier

### Server Hosting

**Docker**: 
```bash
# Build from full package
docker build -t marketing .
docker run -p 80:8080 marketing
```

**IIS**: Extract ? Create App Pool ? Create Site
- Windows Server 2019+
- Requires .NET 10 Hosting Bundle

**Linux**: Extract ? systemd service ? nginx reverse proxy
- Ubuntu 20.04+
- systemd for service management

---

## ?? Next Steps

1. **Choose** your deployment method (static recommended)
2. **Read** `DEPLOYMENT-GUIDE.md` for your platform
3. **Extract** the appropriate ZIP file
4. **Deploy** following the guide
5. **Verify** using the checklist in MANIFEST.txt

**Questions?** Check the deployment guide or open an issue on GitHub!

---

**Ready to deploy?** Start with the static package for the easiest experience! ??

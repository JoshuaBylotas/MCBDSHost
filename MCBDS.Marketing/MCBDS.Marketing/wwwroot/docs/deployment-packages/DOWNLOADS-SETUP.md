# MCBDSHost Marketing Site - Downloads Setup

## ?? Download Files Location

The marketing site now references download packages that should be hosted at:

### Expected URLs:
- **Windows Package**: `/downloads/mcbdshost-windows.zip`
- **Linux Package**: `/downloads/mcbdshost-linux.zip`

## ?? Setup Instructions

### For Static Hosting (Netlify, Vercel, GitHub Pages)

1. **Create downloads folder** in your deployed site:
   ```
   wwwroot/
   ??? downloads/
       ??? mcbdshost-windows.zip
       ??? mcbdshost-linux.zip
   ```

2. **Prepare the packages**:
   - Create `mcbdshost-windows.zip` containing:
     - `docker-compose.windows.yml`
     - Configuration files
     - Deployment scripts
     - README with instructions
   
   - Create `mcbdshost-linux.zip` containing:
     - `docker-compose.linux.yml`
     - Configuration files
     - Deployment scripts
     - README with instructions

3. **Upload to hosting**:
   ```bash
   # For Netlify
   mkdir -p site/downloads
   cp mcbdshost-windows.zip site/downloads/
   cp mcbdshost-linux.zip site/downloads/
   netlify deploy --prod --dir=site
   ```

### For Server Hosting (IIS, nginx)

1. **Create downloads directory**:
   ```powershell
   # Windows/IIS
   New-Item -Path "C:\inetpub\wwwroot\marketing\downloads" -ItemType Directory
   
   # Linux/nginx
   mkdir -p /var/www/marketing/downloads
   ```

2. **Copy packages**:
   ```powershell
   # Windows
   Copy-Item mcbdshost-*.zip C:\inetpub\wwwroot\marketing\downloads\
   
   # Linux
   cp mcbdshost-*.zip /var/www/marketing/downloads/
   ```

3. **Set permissions** (Linux only):
   ```bash
   chmod 644 /var/www/marketing/downloads/*.zip
   ```

## ?? Package Contents

### mcbdshost-windows.zip should include:
```
mcbdshost-windows/
??? docker-compose.windows.yml
??? README.md
??? .env.example
??? scripts/
    ??? setup.ps1
    ??? start.ps1
```

### mcbdshost-linux.zip should include:
```
mcbdshost-linux/
??? docker-compose.linux.yml
??? README.md
??? .env.example
??? scripts/
    ??? setup.sh
    ??? start.sh
```

## ?? Creating the Download Packages

### Option 1: From Repository
```bash
# Clone repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Create Windows package
zip -r mcbdshost-windows.zip docker-compose.windows.yml README.md

# Create Linux package
zip -r mcbdshost-linux.zip docker-compose.linux.yml README.md
```

### Option 2: Automated Script
```powershell
# Windows PowerShell
$files = @(
    "docker-compose.windows.yml",
    "README.md",
    ".env.example"
)

Compress-Archive -Path $files -DestinationPath "mcbdshost-windows.zip" -Force
```

## ?? Alternative: GitHub Releases

If you prefer to use GitHub Releases instead:

1. **Update Get Started page** to use GitHub releases URL:
   ```html
   <a href="https://github.com/JoshuaBylotas/MCBDSHost/releases/latest/download/mcbdshost-windows.zip">
   ```

2. **Create release** on GitHub with attachments:
   - Go to repository ? Releases ? New Release
   - Upload `mcbdshost-windows.zip` and `mcbdshost-linux.zip`
   - Publish release

3. **Automatic URL**: GitHub will provide permanent download links

## ? Verification

After deployment, verify downloads work:

1. Visit your marketing site
2. Go to "Get Started" page
3. Click "Download for Windows"
4. Verify file downloads correctly
5. Extract and verify contents

## ?? Download Analytics

To track downloads:

### Google Analytics (Static Sites)
```html
<a href="/downloads/mcbdshost-windows.zip" 
   onclick="gtag('event', 'download', {'file_name': 'mcbdshost-windows.zip'});">
```

### Server Logs (nginx)
```nginx
location /downloads/ {
    alias /var/www/marketing/downloads/;
    log_format downloads '$remote_addr - $time_local "$request"';
    access_log /var/log/nginx/downloads.log downloads;
}
```

## ?? Updating Packages

When you update MCBDSHost:

1. **Create new packages** with updated files
2. **Replace old packages** in downloads folder
3. **No code changes needed** - URLs remain the same
4. **Users get latest** version automatically

## ?? Current Status

? Marketing site references `/downloads/` URLs
? Instructions updated to use marketing site
? Minecraft download instructions point to official site
? **TODO**: Create and upload actual download packages

## ?? Next Steps

1. **Create the download packages**:
   ```bash
   # Prepare mcbdshost-windows.zip
   # Prepare mcbdshost-linux.zip
   ```

2. **Deploy marketing site** with packages:
   ```bash
   # Upload to hosting provider
   netlify deploy --prod
   ```

3. **Test downloads**:
   - Visit live site
   - Test both download links
   - Verify package contents

4. **Update documentation**:
   - Add version numbers
   - Update changelog
   - Notify users

---

**Important**: The marketing site is ready, but you'll need to create and upload the actual download packages before the links will work!

# MCBDSHost Marketing Website - Deployment Packages

## ?? Package Contents

This folder contains production-ready deployment packages for the MCBDSHost marketing website.

### Package 1: mcbdshost-marketing-static.zip
**For Static Web Hosting (Recommended)**
- **Contents**: wwwroot folder contents only (HTML, CSS, JS, assets)
- **Use with**: 
  - GitHub Pages
  - Netlify
  - Vercel
  - Azure Static Web Apps
  - AWS S3 + CloudFront
  - Any CDN or static file hosting
- **No server required**: Pure static files
- **Best for**: Fast loading, global CDN distribution, minimal cost

### Package 2: mcbdshost-marketing-full.zip
**For ASP.NET Core Hosting**
- **Contents**: Complete published application with .NET 10 runtime files
- **Use with**:
  - IIS (Windows Server)
  - Docker containers
  - Azure App Service
  - Linux with Kestrel
  - Any ASP.NET Core compatible host
- **Requires**: .NET 10 runtime on target server
- **Best for**: Full control, server-side features, existing .NET infrastructure

---

## ?? Quick Deployment Guides

### Option 1: GitHub Pages (Free & Easy)

1. **Extract static package**:
   ```powershell
   Expand-Archive mcbdshost-marketing-static.zip -DestinationPath gh-pages
   ```

2. **Commit to docs folder or gh-pages branch**:
   ```bash
   git checkout -b gh-pages
   cp -r gh-pages/* .
   git add .
   git commit -m "Deploy marketing site"
   git push origin gh-pages
   ```

3. **Enable in GitHub**:
   - Go to repository Settings > Pages
   - Select gh-pages branch
   - Save

4. **Access**: `https://yourusername.github.io/MCBDSHost/`

---

### Option 2: Netlify (Instant Deploy)

**Method A: Drag & Drop**
1. Extract `mcbdshost-marketing-static.zip`
2. Go to https://app.netlify.com/drop
3. Drag the extracted folder
4. Done! Instant URL provided

**Method B: CLI**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Extract package
Expand-Archive mcbdshost-marketing-static.zip -DestinationPath netlify-deploy

# Deploy
netlify deploy --prod --dir=netlify-deploy
```

**Custom Domain**: Configure in Netlify dashboard

---

### Option 3: Vercel (Next-Gen Hosting)

```bash
# Install Vercel CLI
npm install -g vercel

# Extract package
Expand-Archive mcbdshost-marketing-static.zip -DestinationPath vercel-deploy

# Deploy
vercel --prod vercel-deploy
```

**Features**: Automatic HTTPS, global CDN, instant rollbacks

---

### Option 4: Azure Static Web Apps (Microsoft)

**Using Azure Portal:**
1. Create new Static Web App resource
2. Choose "Custom" deployment
3. Upload extracted files via FTP or Kudu

**Using Azure CLI:**
```bash
# Login
az login

# Create static web app
az staticwebapp create \
  --name mcbdshost-marketing \
  --resource-group myResourceGroup \
  --location "East US 2"

# Deploy (extract zip first)
az staticwebapp deploy \
  --name mcbdshost-marketing \
  --source ./extracted-folder
```

---

### Option 5: IIS (Windows Server)

For `mcbdshost-marketing-full.zip`:

1. **Install Prerequisites**:
   - .NET 10 Hosting Bundle: https://dotnet.microsoft.com/download/dotnet/10.0
   - IIS with ASP.NET Core module

2. **Extract package**:
   ```powershell
   Expand-Archive mcbdshost-marketing-full.zip -DestinationPath C:\inetpub\wwwroot\marketing
   ```

3. **Create IIS Site**:
   ```powershell
   # Create App Pool
   New-WebAppPool -Name "MCBDSHostMarketing" -Force
   Set-ItemProperty IIS:\AppPools\MCBDSHostMarketing managedRuntimeVersion ""
   
   # Create Website
   New-Website -Name "MCBDSHost Marketing" `
               -PhysicalPath "C:\inetpub\wwwroot\marketing" `
               -ApplicationPool "MCBDSHostMarketing" `
               -Port 80
   ```

4. **Configure Firewall**:
   ```powershell
   New-NetFirewallRule -DisplayName "MCBDSHost Marketing" `
                       -Direction Inbound `
                       -LocalPort 80 `
                       -Protocol TCP `
                       -Action Allow
   ```

5. **Browse**: http://your-server-ip/

---

### Option 6: Docker (Universal)

Create `Dockerfile` next to extracted full package:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY . .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MCBDS.Marketing.dll"]
```

**Build and Run**:
```bash
# Extract full package
Expand-Archive mcbdshost-marketing-full.zip -DestinationPath docker-build

# Copy Dockerfile
cp Dockerfile docker-build/

# Build
docker build -t mcbdshost-marketing docker-build/

# Run
docker run -d -p 80:8080 --name marketing mcbdshost-marketing

# View logs
docker logs -f marketing
```

**Docker Compose** (`docker-compose.yml`):
```yaml
version: '3.8'
services:
  marketing:
    image: mcbdshost-marketing
    ports:
      - "80:8080"
    restart: unless-stopped
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
```

---

### Option 7: Linux with Kestrel

For `mcbdshost-marketing-full.zip`:

1. **Install .NET 10 Runtime**:
   ```bash
   wget https://dot.net/v1/dotnet-install.sh
   chmod +x dotnet-install.sh
   ./dotnet-install.sh --runtime aspnetcore --version 10.0
   ```

2. **Extract and Setup**:
   ```bash
   mkdir -p /var/www/marketing
   unzip mcbdshost-marketing-full.zip -d /var/www/marketing
   chmod +x /var/www/marketing/MCBDS.Marketing
   ```

3. **Create systemd Service** (`/etc/systemd/system/mcbds-marketing.service`):
   ```ini
   [Unit]
   Description=MCBDSHost Marketing Website
   After=network.target

   [Service]
   WorkingDirectory=/var/www/marketing
   ExecStart=/usr/local/bin/dotnet /var/www/marketing/MCBDS.Marketing.dll
   Restart=always
   RestartSec=10
   KillSignal=SIGINT
   SyslogIdentifier=mcbds-marketing
   User=www-data
   Environment=ASPNETCORE_ENVIRONMENT=Production
   Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

   [Install]
   WantedBy=multi-user.target
   ```

4. **Enable and Start**:
   ```bash
   sudo systemctl enable mcbds-marketing
   sudo systemctl start mcbds-marketing
   sudo systemctl status mcbds-marketing
   ```

5. **Setup Nginx Reverse Proxy** (`/etc/nginx/sites-available/marketing`):
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection keep-alive;
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

   Enable:
   ```bash
   sudo ln -s /etc/nginx/sites-available/marketing /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

---

## ?? Configuration

### Custom Domain

**Static Hosting (GitHub Pages/Netlify/Vercel)**:
1. Add CNAME record: `marketing.yourdomain.com` ? `your-host.com`
2. Configure in hosting provider dashboard
3. Enable HTTPS (automatic on most platforms)

**Server Hosting**:
1. Update DNS A record to point to server IP
2. Configure SSL certificate (Let's Encrypt recommended)
3. Update server configuration with domain name

### SSL/HTTPS

**Static Hosts**: Automatic (GitHub Pages, Netlify, Vercel, Azure)

**IIS**: Use Let's Encrypt with win-acme or import certificate

**Linux**: Use Certbot
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d marketing.yourdomain.com
```

---

## ? Post-Deployment Checklist

After deploying, verify:

- [ ] Home page loads correctly
- [ ] Navigation menu works (Home, Features, Get Started)
- [ ] All internal links function properly
- [ ] External links (GitHub) open in new tab
- [ ] Bootstrap icons display correctly
- [ ] Responsive design works on mobile
- [ ] Footer displays properly
- [ ] Custom CSS styling applied
- [ ] No console errors in browser
- [ ] Page loads under 3 seconds

---

## ?? Performance Optimization

### Static Hosting
- ? Already optimized (static files)
- ? Use CDN for global distribution
- ? Enable gzip compression (hosting provider)
- ? Set caching headers

### Server Hosting
Add to `Program.cs` or `Startup.cs`:

```csharp
// Response compression
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
});

// Response caching
builder.Services.AddResponseCaching();

app.UseResponseCompression();
app.UseResponseCaching();

// Static file caching
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.Append(
            "Cache-Control", $"public, max-age=31536000");
    }
});
```

---

## ?? Monitoring & Analytics

### Add Google Analytics

Edit `MCBDS.Marketing/Components/App.razor`:

```html
<head>
    <!-- Existing head content -->
    
    <!-- Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
    <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-XXXXXXXXXX');
    </script>
</head>
```

### Health Monitoring

For server hosting, monitor:
- Application uptime
- Response times
- Error rates
- Memory usage
- CPU usage

Tools: Application Insights, New Relic, Datadog

---

## ?? Troubleshooting

### Static Hosting Issues

**Problem**: 404 on navigation
**Solution**: Configure hosting for SPA routing or use hash routing

**Problem**: CSS not loading
**Solution**: Check base href in index.html matches deployment path

### Server Hosting Issues

**Problem**: Application won't start
**Solution**: 
- Verify .NET 10 runtime installed
- Check application logs
- Ensure proper file permissions

**Problem**: 500 Error
**Solution**:
- Check `web.config` (IIS)
- Review application logs
- Verify environment variables

---

## ?? Support

Need help deploying?

- **Documentation**: See README.md in package
- **GitHub Issues**: https://github.com/JoshuaBylotas/MCBDSHost/issues
- **Discussions**: https://github.com/JoshuaBylotas/MCBDSHost/discussions

---

## ?? Package Information

- **Build Date**: Generated from published output
- **.NET Version**: 10.0
- **Framework**: Blazor Server
- **License**: MIT
- **Source**: https://github.com/JoshuaBylotas/MCBDSHost

---

## ?? Recommended Deployment

**For most users**: Use **Static Hosting** (mcbdshost-marketing-static.zip)
- Faster loading
- Free hosting available
- Global CDN
- Automatic HTTPS
- No server maintenance

**Platforms**: Netlify, Vercel, or GitHub Pages

---

## ?? Updating the Site

To deploy an update:

1. Get new package from repository
2. Extract new version
3. Replace existing files
4. Clear CDN cache (if applicable)
5. Verify deployment

**Zero-downtime**: Most platforms support blue-green deployments

---

**Ready to deploy? Choose your platform and follow the guide above!** ??

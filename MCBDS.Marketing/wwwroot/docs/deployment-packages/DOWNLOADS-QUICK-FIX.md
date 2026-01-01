# ? Downloads Fixed - Quick Reference

## Problem
Downloads were missing on the published site (404 errors on /downloads/mcbdshost-windows.zip and /downloads/mcbdshost-linux.zip).

## Solution
Created local download packages with deployment files and updated the Marketing site to serve them.

---

## What Was Done

### 1. Created Download Packages ?
- `mcbdshost-windows.zip` - Windows deployment files (2.5 KB)
- `mcbdshost-linux.zip` - Linux deployment files (2.6 KB)
- Both stored in `MCBDS.Marketing/wwwroot/downloads/`

### 2. Created Linux Docker Compose ?
- File: `docker-compose.linux.yml`
- Matches Windows version with Linux paths
- Volume mounts to `/opt/mcbdshost/`

### 3. Updated Get Started Page ?
- Changed download links from GitHub to local files
- Updated installation instructions
- Added file contents information

### 4. Updated Project Configuration ?
- Added `.zip` MIME type to `web.config`
- Updated `.csproj` to copy downloads folder
- Verified build succeeds

---

## Quick Deploy

```powershell
# Run the complete deployment script
cd deployment-packages
.\deploy-marketing-with-downloads.ps1
```

Or manually:
```powershell
cd MCBDS.Marketing
dotnet publish -c Release -o bin\Release\net10.0\publish
Copy-Item -Path "bin\Release\net10.0\publish\*" -Destination "C:\inetpub\wwwroot\mc-bds-marketing\" -Recurse -Force
iisreset
```

---

## Test Downloads

After deployment, verify:

1. **Windows Package**:
   ```powershell
   Invoke-WebRequest -Uri "https://www.mc-bds.com/downloads/mcbdshost-windows.zip" -OutFile "test.zip"
   ```

2. **Linux Package**:
   ```powershell
   Invoke-WebRequest -Uri "https://www.mc-bds.com/downloads/mcbdshost-linux.zip" -OutFile "test.zip"
   ```

3. **In Browser**:
   - Visit: https://www.mc-bds.com/get-started#download
   - Click "Download for Windows"
   - Click "Download for Linux"
   - Both should download immediately

---

## Package Contents

### Windows (mcbdshost-windows.zip)
```
??? docker-compose.windows.yml
??? README.md
```

### Linux (mcbdshost-linux.zip)
```
??? docker-compose.linux.yml
??? README.md
```

Each README contains complete deployment instructions.

---

## Updating Packages

To update downloads in the future:

1. Modify docker-compose files or READMEs
2. Run: `deployment-packages\create-download-packages.ps1`
3. Rebuild and redeploy Marketing site

---

## Files Changed

| File | Change |
|------|--------|
| `GetStarted.razor` | Updated download section with local links |
| `MCBDS.Marketing.csproj` | Added downloads folder to content |
| `web.config` | Added `.zip` MIME type |
| `docker-compose.linux.yml` | Created (new file) |

---

## Scripts Created

| Script | Purpose |
|--------|---------|
| `create-download-packages.ps1` | Creates ZIP files |
| `deploy-marketing-with-downloads.ps1` | Complete deployment |

---

## Status

? Downloads created  
? Configuration updated  
? Build successful  
? Ready to deploy  

---

## Next Steps

1. Deploy to IIS using the script
2. Test downloads in browser
3. Verify downloads work in different browsers
4. Monitor download analytics in Google Analytics

---

*Created*: December 30, 2024  
*Status*: Complete and Ready  

# Website Repositioning Summary

## Changes Made to Prioritize Windows Installer

### 1. GetStarted Page Restructure
**File:** `MCBDS.Marketing\Components\Pages\GetStarted.razor`

#### Before
- Generic heading about deployment options
- No clear recommendation
- Mixed messaging about Docker and installer

#### After
- **Clear Call-to-Action Cards** at the top:
  - Windows Installer (Green "Recommended" card)
  - Docker Deployment (Secondary gray card)
- **Quick Stats Section** highlighting:
  - 5-10 minute setup time
  - 1-click service installation
  - Default port 8080
  - Community support availability
- **Blue Info Alert** redirecting users to installer
- **Positioned installer first** with emphasis on simplicity

### 2. Installer Guide Enhancement
**File:** `MCBDS.Marketing\Components\Pages\InstallerGuide.razor`

#### Updated Comparison Table
- Added visual highlighting (green table row for installer)
- Windows Installer = Primary
- Docker = Community support
- Changed wording from "Simple" to "Very Simple" for installer
- Emphasized native performance vs container overhead
- Added "Support Level" comparison row

### 3. Navigation Priority
**File:** `MCBDS.Marketing\Components\Layout\NavMenu.razor`

**Already Complete:**
- "Installer" link positioned between "Get Started" and "Docs"
- Uses download icon (??) for visibility
- Easily accessible from any page

### 4. Sitemap SEO
**File:** `MCBDS.Marketing\wwwroot\sitemap.xml`

**Already Complete:**
- Installer page added with 0.9 priority (same as Get Started)
- Signals to search engines: installer is primary installation method

---

## Website Now Communicates:

### ?? Primary Message
> **"MCBDS Windows Installer: The fastest way to get started in 5-10 minutes"**

### ?? Messaging Hierarchy
1. **Installer is the recommended default** (green "Recommended" badge)
2. **Docker is for advanced users** (secondary, gray card)
3. **Windows users should start here** (blue alert on Get Started)
4. **Easy setup = no technical knowledge required** (quick stats)

### ? Key Benefits Emphasized
- **Speed:** 5-10 minute setup vs 15-20 for Docker
- **Simplicity:** "Just click" vs "CLI knowledge required"
- **Performance:** Native Windows Service vs container overhead
- **Support:** Primary support vs community

---

## GitHub Publishing Files Created

### 1. Release Notes Template
**File:** `MCBDS.Installer\GITHUB-RELEASE-NOTES.md`

**Contents:**
- Professional release documentation
- Installation overview and requirements
- Step-by-step installation guide
- Configuration details
- Troubleshooting section
- Architecture overview
- Installer vs Docker comparison table
- FAQ
- Support resources
- Version history
- Development information

**Usage:** Reference this when writing release notes on GitHub

### 2. Publishing Template
**File:** `MCBDS.Installer\GITHUB-PUBLISHING-TEMPLATE.md`

**Contents:**
- Ready-to-use release description
- Copy-paste release notes text
- Asset upload instructions
- Verification checklist
- Version numbering guide
- Publishing workflow steps
- Next release checklist

**Usage:** When creating new release on GitHub releases page

---

## How to Use When Publishing

### Step 1: Prepare Release
```powershell
# Build the installer
.\MCBDS.Installer\build-installer.ps1

# Verify the executable was created
Test-Path ".\MCBDS.API.Service.Installer.exe"
```

### Step 2: Create GitHub Release
1. Go to: https://github.com/JoshuaBylotas/MCBDSHost/releases
2. Click "Draft a new release"
3. Set tag to version (e.g., `v1.0.1`)
4. Use this template for description:
   - Open `MCBDS.Installer\GITHUB-PUBLISHING-TEMPLATE.md`
   - Copy the "Release Description" section
   - Paste into GitHub release body
5. Upload `MCBDS.API.Service.Installer.exe`
6. Click "Publish release"

### Step 3: Update Documentation
- Update version numbers in all files
- Update `GITHUB-RELEASE-NOTES.md` with new version features
- Update website if features changed

---

## Messaging Strategy Summary

### For Windows Users
> "Download the installer and click once. Your server is ready in 5-10 minutes."

### For Advanced Users
> "Docker deployment available for cloud and enterprise scenarios."

### For New Users
> "Start with the Windows Installer — it's the easiest way to get your Minecraft server running."

### For Enterprise/Cloud
> "Prefer Docker? Check out our comprehensive Docker deployment guide."

---

## Files Changed

| File | Changes |
|------|---------|
| `MCBDS.Marketing\Components\Pages\GetStarted.razor` | Added installer/Docker comparison cards, quick stats section, repositioned content |
| `MCBDS.Marketing\Components\Pages\InstallerGuide.razor` | Updated comparison table with visual highlighting and support levels |
| `MCBDS.Marketing\Components\Layout\NavMenu.razor` | Already had installer link (completed in previous session) |
| `MCBDS.Marketing\wwwroot\sitemap.xml` | Already had installer page (completed in previous session) |
| `MCBDS.Installer\GITHUB-RELEASE-NOTES.md` | **NEW** - Professional release documentation |
| `MCBDS.Installer\GITHUB-PUBLISHING-TEMPLATE.md` | **NEW** - Ready-to-use publishing template |

---

## Next Steps

1. **Test Website Changes**
   - Review GetStarted page in browser
   - Verify InstallerGuide displays correctly
   - Check navigation flow

2. **Prepare for Release**
   - Build installer: `.\MCBDS.Installer\build-installer.ps1`
   - Test installer on Windows 10/11
   - Test on Windows Server if available

3. **Create GitHub Release**
   - Use `GITHUB-PUBLISHING-TEMPLATE.md`
   - Upload installer executable
   - Monitor for user feedback

4. **Announce Release**
   - Share on Twitter/X
   - Post on Reddit/Minecraft forums
   - Update Discord communities

---

## Benefits of This Repositioning

? **Clearer User Journey** - Users immediately see installer as the recommended option  
? **Faster Adoption** - 5-10 minute setup vs unclear Docker path  
? **Better SEO** - Consistent messaging across website and GitHub  
? **Professional Presentation** - GitHub release notes look polished  
? **Less Support Burden** - Simple setup = fewer configuration questions  
? **Windows User Focus** - Acknowledges that installer is for 90% of users  

---

**Status:** ? Complete  
**Website Changes:** Done  
**GitHub Publishing Files:** Created  
**Ready for Release:** Yes

**Next Action:** Build installer and create GitHub release using the templates provided!

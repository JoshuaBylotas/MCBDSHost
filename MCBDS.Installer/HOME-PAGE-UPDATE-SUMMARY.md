# Home Page Update Summary

## Changes Made

### 1. Release Announcement Badge
**Location:** Hero section (top of home page)

**Added:** Green success alert banner showing:
- "Latest Release: API v1.0.1 Now Available"
- Link to GitHub release: https://github.com/JoshuaBylotas/MCBDSHost/releases/tag/API-v1
- Feature highlight: "Windows installer with automatic backups and web dashboard"
- Dismissible (users can close it)

**Position:** Appears above the main heading for maximum visibility

### 2. Updated Hero CTA
**Changed:** Primary call-to-action button
- **Before:** "Explore Features"
- **After:** "Download Windows Installer"
- **Link:** Points to `/installer` page
- **Icon:** Download icon (??)

**Why:** Prioritizes the newly released installer as the primary action

### 3. Coming Soon Section
**Location:** New section between Features and Technology Stack

**Features:**

#### Windows Desktop App Card
- **Timeline:** Q1 2025
- **Headline:** "Windows Desktop App"
- **Features Listed:**
  - System Tray Integration
  - Desktop Notifications
  - Offline Support
  - One-Click Access
- **Call-to-Action:** Link to contact page for notifications

#### Android Play Store Card
- **Timeline:** Q2 2025
- **Headline:** "Android Play Store"
- **Features Listed:**
  - Google Play Store Distribution
  - Push Notifications
  - Home Screen Widgets
  - Offline Command Queue
- **Call-to-Action:** Placeholder for Google Play pre-registration

#### Additional Planned Features
Grid showing 6 more upcoming features:
1. **HTTPS Support** - Full HTTPS and SSL/TLS certificate support
2. **Cloud Backups** - AWS S3, Google Cloud Storage, or Azure Blob
3. **Advanced Analytics** - Performance metrics and player statistics
4. **Multi-Server Management** - Manage multiple servers from one dashboard
5. **Plugin System** - Community plugins and extensions support
6. **Discord Integration** - Discord bot for notifications and remote management

#### Newsletter Subscription CTA
- "Want to be notified about new releases?"
- Button: "Subscribe to Updates" ? Links to contact page

---

## Visual Design

### Color Scheme
- **Windows Desktop App:** Primary blue (border-primary)
- **Android Play Store:** Success green (border-success)
- **Planned Features:** Info blue icons

### Layout
- Responsive grid layout (2 columns on desktop, 1 on mobile)
- Card-based design with borders for visual separation
- Consistent spacing and typography

### Icons Used
- `bi-window` - Windows Desktop App
- `bi-android2` - Android Play Store
- `bi-shield-check` - HTTPS
- `bi-cloud-check` - Cloud Backups
- `bi-graph-up` - Analytics
- `bi-people-fill` - Multi-Server
- `bi-plug` - Plugins
- `bi-discord` - Discord

---

## GitHub Release Link

**Release URL:** https://github.com/JoshuaBylotas/MCBDSHost/releases/tag/API-v1

This link is:
- Prominently displayed in hero section
- Easy for users to click through
- Opens in new tab (target="_blank" with noopener for security)
- Points directly to the release page

---

## File Modified

**File:** `MCBDS.Marketing\Components\Pages\Home.razor`

**Sections Updated:**
1. Hero Section (added badge + updated CTA)
2. Added new "Coming Soon" section (full new content)

---

## How This Helps

? **Increased Visibility** - Release announcement front and center on home page  
? **Better Conversion** - Primary CTA points to the newly available installer  
? **Feature Roadmap** - Users can see what's coming (Windows & Android apps)  
? **Community Engagement** - Newsletter signup for notifications  
? **Professional Appearance** - Well-designed cards with clear timelines  

---

## Next Steps (Manual)

To complete the release promotion:

1. **Create GitHub Release**
   - Go to: https://github.com/JoshuaBylotas/MCBDSHost/releases
   - Click "Draft a new release"
   - Tag: `API-v1` (or `API-v1.0.1`)
   - Use `GITHUB-PUBLISHING-TEMPLATE.md` for description
   - Upload `MCBDS.API.Service.Installer.exe`
   - Publish

2. **Test the Links**
   - Visit https://www.mc-bds.com
   - Click release link - should go to GitHub release
   - Click "Download Windows Installer" - should go to /installer page
   - Click "Subscribe to Updates" - should go to /contact page

3. **Social Media Announcements**
   - Twitter/X
   - Reddit (r/Minecraft)
   - Discord communities
   - MinecraftForums

4. **Future App Releases**
   - Q1 2025: Release Windows Desktop App (update Coming Soon card to "Released")
   - Q2 2025: Release Android Play Store app (update Coming Soon card to link to Google Play)

---

## Content Strategy

The home page now communicates:

1. **What:** Professional Minecraft server management tool
2. **Latest:** API v1.0.1 is available now with Windows installer
3. **When:** Download it today from the installer page
4. **Future:** Windows desktop and Android apps coming Q1-Q2 2025
5. **Roadmap:** Other features planned for future releases

This creates urgency for the current release while building excitement for upcoming apps.

---

**Status:** ? Complete  
**Last Updated:** January 2025  
**Ready for:** Publishing to GitHub and announcing on social media

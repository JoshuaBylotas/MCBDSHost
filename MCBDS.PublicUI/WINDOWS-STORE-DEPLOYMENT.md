# Windows Store Deployment Guide - MCBDS.PublicUI

Complete instructions for deploying the MCBDS.PublicUI .NET MAUI application to the Microsoft Store.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Configure Project for Store](#step-1-configure-your-app-for-store-submission)
3. [Step 2: Create Package Manifest](#step-2-create-and-configure-packageappxmanifest)
4. [Step 3: Prepare App Icons](#step-3-create-required-app-icons)
5. [Step 4: Register with Partner Center](#step-4-reserve-your-app-name-in-partner-center)
6. [Step 5: Update Identity](#step-5-update-identity-from-partner-center)
7. [Step 6: Associate with Store](#step-6-associate-your-app-with-the-store)
8. [Step 7: Create MSIX Package](#step-7-create-the-msix-package-for-store-submission)
9. [Step 8: Test Package](#step-8-test-your-package-before-submission)
10. [Step 9: Submit to Store](#step-9-submit-to-the-microsoft-store)
11. [Step 10: Monitor Certification](#step-10-monitor-certification-process)
12. [Post-Publication](#step-11-post-publication)
13. [Troubleshooting](#common-issues-and-solutions)
14. [Resources](#additional-resources)

---

## Prerequisites

Before you begin, ensure you have:

- ? **Windows 11** or **Windows 10** (version 1809 or later) with latest updates
- ? **Visual Studio 2026** (already installed)
- ? **Windows App SDK** (included with Visual Studio)
- ? **.NET 10 SDK** (already configured in your project)
- ? **Microsoft Partner Center Account**
  - Register at: https://partner.microsoft.com/dashboard
  - One-time registration fee: **$19 USD** for individuals
  - Business accounts may have different requirements

### Verify Your Environment

```powershell
# Check .NET version
dotnet --version

# Verify Windows SDK installation
Get-WindowsSDK

# Check MAUI workload
dotnet workload list
```

---

## Step 1: Configure Your App for Store Submission

Update your `MCBDS.PublicUI.csproj` file with Store-ready properties:

```xml
<PropertyGroup>
    <TargetFrameworks>net10.0-android;net10.0-ios;net10.0-maccatalyst</TargetFrameworks>
    <TargetFrameworks Condition="$([MSBuild]::IsOSPlatform('windows'))">$(TargetFrameworks);net10.0-windows10.0.19041.0</TargetFrameworks>

    <OutputType>Exe</OutputType>
    <RootNamespace>MCBDS.PublicUI</RootNamespace>
    <UseMaui>true</UseMaui>
    <SingleProject>true</SingleProject>
    <ImplicitUsings>enable</ImplicitUsings>
    <EnableDefaultCssItems>false</EnableDefaultCssItems>
    <Nullable>enable</Nullable>

    <!-- Display name -->
    <ApplicationTitle>MCBDS Manager</ApplicationTitle>

    <!-- App Identifier - MUST be unique in the Store -->
    <ApplicationId>com.mcbds.publicui</ApplicationId>

    <!-- Versions -->
    <ApplicationDisplayVersion>1.0.0</ApplicationDisplayVersion>
    <ApplicationVersion>1</ApplicationVersion>

    <!-- Windows Store Configuration -->
    <WindowsPackageType>MSIX</WindowsPackageType>
    <GenerateAppInstallerFile>False</GenerateAppInstallerFile>
    <AppxPackageSigningEnabled>True</AppxPackageSigningEnabled>
    <PackageCertificateKeyFile>MCBDS.PublicUI_TemporaryKey.pfx</PackageCertificateKeyFile>
    
    <!-- Windows Specific Properties -->
    <WindowsAppSDKSelfContained Condition="'$(IsUnpackaged)' != 'true'">true</WindowsAppSDKSelfContained>
    
    <!-- Platform Versions -->
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'ios'">15.0</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'maccatalyst'">15.0</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'android'">24.0</SupportedOSPlatformVersion>
    <SupportedOSPlatformVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'">10.0.17763.0</SupportedOSPlatformVersion>
    <TargetPlatformMinVersion Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'windows'">10.0.17763.0</TargetPlatformMinVersion>
</PropertyGroup>
```

### Key Properties Explained

| Property | Purpose |
|----------|---------|
| `WindowsPackageType` | Set to `MSIX` for Store deployment |
| `ApplicationId` | Unique identifier (reverse domain notation) |
| `ApplicationDisplayVersion` | User-facing version (1.0.0) |
| `ApplicationVersion` | Build number (increment for each submission) |
| `AppxPackageSigningEnabled` | Required for Store submission |
| `WindowsAppSDKSelfContained` | Bundles runtime for reliability |

---

## Step 2: Create and Configure Package.appxmanifest

Create the file at `Platforms/Windows/Package.appxmanifest`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:mp="http://schemas.microsoft.com/appx/2014/phone"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
  IgnorableNamespaces="uap rescap">

  <Identity Name="YourPublisherID.MCBDSManager" 
            Publisher="CN=YourPublisherName" 
            Version="1.0.0.0" />

  <mp:PhoneIdentity PhoneProductId="YOUR-GUID-HERE" PhonePublisherId="00000000-0000-0000-0000-000000000000"/>

  <Properties>
    <DisplayName>MCBDS Manager</DisplayName>
    <PublisherDisplayName>Your Company Name</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19041.0" />
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19041.0" />
  </Dependencies>

  <Resources>
    <Resource Language="x-generate"/>
  </Resources>

  <Applications>
    <Application Id="App" Executable="$targetnametoken$.exe" EntryPoint="$targetentrypoint$">
      <uap:VisualElements
        DisplayName="MCBDS Manager"
        Description="MCBDS Manager Application"
        BackgroundColor="transparent"
        Square150x150Logo="Assets\Square150x150Logo.png"
        Square44x44Logo="Assets\Square44x44Logo.png">
        <uap:DefaultTile Wide310x150Logo="Assets\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Assets\SplashScreen.png" />
      </uap:VisualElements>
    </Application>
  </Applications>

  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <Capability Name="internetClient" />
  </Capabilities>
</Package>
```

> **Note**: The `Identity`, `Publisher`, and `PublisherDisplayName` values will be replaced automatically when you associate your app with the Store in Step 6.

---

## Step 3: Create Required App Icons

You need these image assets in `Platforms/Windows/Assets/`:

### Required Assets

| Asset | Dimensions | Purpose |
|-------|------------|---------|
| **Square44x44Logo.png** | 44×44 px | App list icon |
| **Square150x150Logo.png** | 150×150 px | Medium tile |
| **Wide310x150Logo.png** | 310×150 px | Wide tile |
| **StoreLogo.png** | 50×50 px | Store listing |
| **SplashScreen.png** | 620×300 px | Launch screen |

### Optional Assets (Recommended)

| Asset | Dimensions | Purpose |
|-------|------------|---------|
| **LargeTile.png** | 310×310 px | Large tile |
| **SmallTile.png** | 71×71 px | Small tile |

### Asset Creation Tips

1. **Use high-quality, transparent PNG files**
2. **Maintain consistent branding** across all assets
3. **Test on both light and dark themes**
4. **Use your existing app icon** from `Resources\AppIcon\appicon.svg` as a starting point
5. **Consider using the Visual Assets Generator** in Visual Studio:
   - Right-click project ? **Add** ? **New Item** ? **Visual Assets**

### Creating Assets from Existing Icon

```powershell
# If you have ImageMagick installed
magick convert Resources\AppIcon\appicon.svg -resize 44x44 Platforms\Windows\Assets\Square44x44Logo.png
magick convert Resources\AppIcon\appicon.svg -resize 150x150 Platforms\Windows\Assets\Square150x150Logo.png
magick convert Resources\AppIcon\appicon.svg -resize 50x50 Platforms\Windows\Assets\StoreLogo.png
```

---

## Step 4: Reserve Your App Name in Partner Center

### Register for Partner Center

1. Go to **https://partner.microsoft.com/dashboard**
2. Sign in with your Microsoft account
3. Complete registration:
   - **Individual**: $19 USD one-time fee
   - **Company**: $99 USD one-time fee
4. Verify your account (may take 24-48 hours)

### Reserve Your App Name

1. In Partner Center, click **Apps and games**
2. Click **+ New product**
3. Select **MSIX or PWA app**
4. Enter your app name: **"MCBDS Manager"** (or your preferred name)
5. Click **Reserve product name**
6. Note the confirmation - you have **3 months** to submit

### Important Notes

- App names must be unique across the Store
- You can reserve multiple names for the same app
- Reserved names can be changed before first submission
- After submission, name changes require a new submission

---

## Step 5: Update Identity from Partner Center

After reserving your app name, you need to copy identity values to your manifest.

### Get Identity Values

1. In Partner Center, navigate to your app
2. Go to **Product management** ? **Product identity**
3. Copy these exact values:

```
Package/Identity/Name: 12345YourPublisher.MCBDSManager
Package/Identity/Publisher: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Package/Properties/PublisherDisplayName: Your Company Name
Package/Applications/Application/Id: App
```

### Update Package.appxmanifest

Replace the placeholder values in your `Package.appxmanifest`:

```xml
<Identity Name="12345YourPublisher.MCBDSManager" 
          Publisher="CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" 
          Version="1.0.0.0" />

<Properties>
  <DisplayName>MCBDS Manager</DisplayName>
  <PublisherDisplayName>Your Company Name</PublisherDisplayName>
  <Logo>Assets\StoreLogo.png</Logo>
</Properties>
```

> **Important**: These values MUST match exactly what Partner Center provides, or your submission will be rejected.

---

## Step 6: Associate Your App with the Store

Visual Studio can automatically update your manifest with the correct identity values.

### Using Visual Studio

1. In **Solution Explorer**, right-click the **MCBDS.PublicUI** project
2. Select **Publish** ? **Create App Packages...**
3. In the wizard, choose **Microsoft Store as a new app name**
4. Click **Next**
5. Sign in with your **Partner Center credentials**
6. Select your reserved app name from the dropdown
7. Click **Associate**

Visual Studio will:
- ? Update `Package.appxmanifest` with correct identity
- ? Download your app certificate
- ? Configure package signing

### Verify Association

Check that `Package.appxmanifest` now contains your actual Partner Center values:

```xml
<Identity Name="12345YourActualPublisher.MCBDSManager" 
          Publisher="CN=YOUR-ACTUAL-GUID" 
          Version="1.0.0.0" />
```

---

## Step 7: Create the MSIX Package for Store Submission

You have two options for creating your Store package:

### Option A: Using Visual Studio (Recommended)

1. Right-click **MCBDS.PublicUI** project
2. Select **Publish** ? **Create App Packages...**
3. Choose **Microsoft Store as [your app name]**
4. Click **Next**
5. Configure package settings:

   **Version Information:**
   - Version: `1.0.0.0` (increment for updates)

   **Select and Configure Packages:**
   - ? **x64** (Required - 64-bit Windows)
   - ? **x86** (Recommended - 32-bit Windows)
   - ? **ARM64** (Recommended - ARM devices)

   **Bundle Options:**
   - Generate app bundle: **Always**
   - Include public symbol files: ? (for crash analysis)

6. Click **Create**
7. Wait for build to complete (5-15 minutes)
8. The `.msixupload` file will be in:
   ```
   MCBDS.PublicUI\AppPackages\MCBDS.PublicUI_1.0.0.0\
   ```

### Option B: Using Command Line

```powershell
# Navigate to project directory
cd C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.PublicUI

# Clean previous builds
dotnet clean -c Release

# Restore dependencies
dotnet restore

# Build MSIX package for Store (single architecture)
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:RuntimeIdentifierOverride=win10-x64 `
  -p:WindowsPackageType=MSIX `
  -p:WindowsAppSDKSelfContained=true `
  -p:GenerateAppxPackageOnBuild=true `
  -p:AppxPackageSigningEnabled=true
```

### Multi-Architecture Build (Advanced)

For maximum compatibility, build for all architectures:

```powershell
# Requires MSBuild (included with Visual Studio)
msbuild MCBDS.PublicUI.csproj `
  /p:Configuration=Release `
  /p:UapAppxPackageBuildMode=StoreUpload `
  /p:AppxBundle=Always `
  /p:AppxBundlePlatforms="x86|x64|ARM64" `
  /p:GenerateAppxPackageOnBuild=true
```

### Package Output

After successful build, you'll find:

```
AppPackages/
??? MCBDS.PublicUI_1.0.0.0/
    ??? MCBDS.PublicUI_1.0.0.0_x64.msix
    ??? MCBDS.PublicUI_1.0.0.0_x86.msix
    ??? MCBDS.PublicUI_1.0.0.0_ARM64.msix
    ??? MCBDS.PublicUI_1.0.0.0_x64_x86_ARM64_bundle.msixupload  ? Upload this
    ??? MCBDS.PublicUI_1.0.0.0_x64_x86_ARM64_bundle.msixbundle
```

> **Submit the `.msixupload` file** to Partner Center, not the individual `.msix` files.

---

## Step 8: Test Your Package Before Submission

### Install Windows App Certification Kit (WACK)

WACK is included with the Windows SDK:

```powershell
# Check if WACK is installed
$wackPath = "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe"
if (Test-Path $wackPath) {
    Write-Host "WACK is installed" -ForegroundColor Green
} else {
    Write-Host "Install Windows SDK to get WACK" -ForegroundColor Yellow
}
```

### Run Certification Tests

#### Option A: Visual Studio Integration

1. When creating app packages (Step 7), enable:
   - ? **"Validate package using Windows App Certification Kit"**
2. Tests run automatically after build
3. Review the HTML report that opens

#### Option B: Command Line

```powershell
# Run WACK tests
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" test `
  -appxpackagepath "AppPackages\MCBDS.PublicUI_1.0.0.0\MCBDS.PublicUI_1.0.0.0_x64.msix" `
  -reportoutputpath "certification-report.xml"
```

### Common Test Categories

| Test | Purpose | Common Issues |
|------|---------|---------------|
| **App manifest compliance** | Validates manifest structure | Missing capabilities, invalid IDs |
| **Windows security features** | Checks security requirements | Missing code signing |
| **Supported APIs** | Ensures API compatibility | Unsupported Windows APIs |
| **App resource usage** | Performance validation | Excessive memory, slow launch |
| **Performance tests** | Launch time, resource cleanup | Long startup times |

### Local Testing

Before submitting, test the MSIX package locally:

```powershell
# Install package locally
Add-AppxPackage -Path "AppPackages\MCBDS.PublicUI_1.0.0.0\MCBDS.PublicUI_1.0.0.0_x64.msix"

# Launch the app
Start-Process shell:AppsFolder\$(
  (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
)!App

# Uninstall after testing
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage
```

---

## Step 9: Submit to the Microsoft Store

### Start Your Submission

1. Go to **https://partner.microsoft.com/dashboard**
2. Select your app: **MCBDS Manager**
3. Click **Start your submission**

### Complete Required Sections

#### 1?? **Pricing and Availability**

**Markets:**
- Select all markets, or specific regions
- Consider localization requirements

**Pricing:**
- Free (recommended for first release)
- Paid ($0.99 - $999.99)
- Free with in-app purchases

**Visibility:**
- **Public Store** - Anyone can find and download
- **Private Audience** - Limited to specific people
- **Hidden in Store** - Available only via direct link

**Schedule:**
- Publish as soon as possible (automatic)
- Publish on specific date (manual)

**Example Configuration:**
```
Markets: All markets
Base price: Free
Discoverability: Make this product available and discoverable in the Store
Publish: As soon as possible after certification
```

#### 2?? **Properties**

**Category:** Choose the most appropriate
- Productivity
- Utilities & tools
- Developer tools
- Business
- Education

**System Requirements:**
```
Minimum:
- OS: Windows 10 version 1809 (Build 17763) or higher
- RAM: 4 GB
- Disk: 500 MB available space

Recommended:
- OS: Windows 11
- RAM: 8 GB
- Disk: 1 GB available space
```

**Additional Properties:**
- Product declarations (privacy policy URL)
- Display mode preferences
- Support information

#### 3?? **Age Ratings**

Complete the **IARC questionnaire**:

Sample questions:
- Does your app contain violence?
- Does it include in-app purchases?
- Does it collect personal information?
- Does it include social features?

> The system will automatically assign appropriate age ratings for all markets.

#### 4?? **Packages**

1. Click **Upload packages**
2. Drag and drop your `.msixupload` file
3. Wait for **validation** (2-5 minutes)
4. Verify **Device family availability** shows:
   - ? Desktop
5. Review **Package details**:
   - Version: 1.0.0.0
   - Architecture: x64, x86, ARM64

#### 5?? **Store Listings**

**Description** (minimum 200 characters):
```
MCBDS Manager is a powerful tool for managing your Minecraft Bedrock Dedicated Server (MCBDS). 

Features:
• Easy server configuration and management
• Real-time monitoring
• Automated backups
• User-friendly interface
• Cross-platform support

Perfect for server administrators who want a streamlined management experience.
```

**Screenshots** (Required - at least 1):
- Recommended size: **1920×1080** or **2560×1440**
- Maximum 10 screenshots
- Capture key features and UI
- Use Windows Snipping Tool or Snip & Sketch

**App Tile Icon** (Required):
- **1:1 aspect ratio** (e.g., 1920×1920)
- PNG format
- Used in promotional materials

**Search Terms** (up to 7):
```
minecraft, server, management, bedrock, admin, hosting, mcbds
```

**Privacy Policy URL** (Required if you collect data):
```
https://www.mc-bds.com/privacy-policy
```

**Additional Store Listing Information:**
- **Copyright and trademark info**
- **Additional license terms**
- **App features** (select relevant features)
- **Website URL**: https://www.mc-bds.com
- **Support contact**: support@mc-bds.com

**Promotional Images** (Optional but recommended):
- 16:9 Super hero art (1920×1080)
- 2:3 Poster art (1000×1500)
- 9:16 Box art (1080×1920)

#### 6?? **Notes for Certification**

Help testers understand your app:

```
Test Account (if required):
- Username: tester@mcbds.com
- Password: [Provide secure test credentials]

Testing Instructions:
1. Launch the application
2. The app requires a Docker environment for full functionality
3. Main UI and configuration features can be tested without Docker
4. For server management features, Docker Desktop should be installed

Known Limitations:
- Requires Docker Desktop for full server management features
- Internet connection required for updates

Special Notes:
- First-time setup may take 2-3 minutes
- Test on both Windows 10 and Windows 11 if possible
```

### Review and Submit

1. Review all sections (green checkmarks required)
2. Click **Submit to the Store**
3. Confirm submission

---

## Step 10: Monitor Certification Process

### Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| **Pre-processing** | 15 mins - 1 hour | Package validation |
| **Security tests** | 1-4 hours | Malware scanning, security checks |
| **Technical compliance** | 2-6 hours | WACK tests, API compatibility |
| **Content compliance** | 4-24 hours | Manual review of content, metadata |
| **Release** | 1-3 hours | Publishing to Store |
| **Total** | **24-72 hours** | Full certification process |

### Check Status

1. Go to **Partner Center** ? **Your App**
2. View **Submission progress**:
   - ?? **In progress** - Being reviewed
   - ?? **In the Store** - Published
   - ?? **Failed** - Issues found

### Notifications

You'll receive emails for:
- Certification started
- Certification passed
- Certification failed (with details)
- App published

### If Certification Fails

1. Check **Certification report** in Partner Center
2. Common failure reasons:
   - Crashes during testing
   - Missing privacy policy
   - Inappropriate content
   - API compatibility issues
   - Performance problems
3. Fix issues
4. Increment version number
5. Resubmit

---

## Step 11: Post-Publication

### App is Live! ??

Once certified and published:

**Store URL:**
```
https://www.microsoft.com/store/apps/[YOUR-APP-ID]
```

Find your app ID in Partner Center under **Product identity**.

### Monitor Performance

**Analytics in Partner Center:**
- **Acquisitions**: Downloads and purchases
- **Usage**: Daily active users, engagement
- **Health**: Crashes, errors, feedback
- **Reviews**: User ratings and reviews
- **Conversions**: Trial to paid conversions (if applicable)

### Respond to Reviews

1. Navigate to **Engagement** ? **Reviews**
2. Respond to user feedback
3. Best practices:
   - Thank users for positive reviews
   - Address issues in negative reviews professionally
   - Provide solutions or workarounds
   - Invite users to contact support

### Publishing Updates

When you need to release an update:

1. **Increment version number** in `MCBDS.PublicUI.csproj`:
   ```xml
   <ApplicationDisplayVersion>1.1.0</ApplicationDisplayVersion>
   <ApplicationVersion>2</ApplicationVersion>
   ```

2. Update `Package.appxmanifest`:
   ```xml
   <Identity Name="..." Publisher="..." Version="1.1.0.0" />
   ```

3. **Rebuild MSIX package** (Step 7)
4. **Start new submission** in Partner Center
5. Upload new `.msixupload` file
6. Update **Store listing** (e.g., "What's new")
7. **Submit for certification**

### Gradual Rollout (Optional)

Control update distribution:
- 10% of users ? Monitor for issues
- 50% of users ? After 24 hours
- 100% of users ? After 48 hours

Configure in Partner Center under **Package rollout**.

### Promote Your App

**Marketing channels:**
- ?? Add download badge to your website (https://www.mc-bds.com)
- ?? Share on social media
- ?? Email existing users
- ?? Write a blog post/release announcement
- ?? Create video tutorials

**Microsoft Store Badge:**
```html
<a href="https://www.microsoft.com/store/apps/[YOUR-APP-ID]">
  <img src="https://developer.microsoft.com/store/badges/images/English_get-it-from-MS.png" 
       alt="Get it from Microsoft" />
</a>
```

---

## Common Issues and Solutions

### Issue 1: Certificate Errors

**Problem:** `Package failed signature validation`

**Solutions:**
```powershell
# Remove old certificate
Remove-Item MCBDS.PublicUI_TemporaryKey.pfx -ErrorAction SilentlyContinue

# Recreate in Visual Studio:
# 1. Right-click project ? Properties
# 2. Package ? Choose Certificate ? Create Test Certificate
# 3. Provide a password
```

### Issue 2: Package Validation Fails

**Problem:** `Package could not be opened`

**Solutions:**
- Ensure all required assets are present in `Platforms/Windows/Assets/`
- Verify `Package.appxmanifest` XML is valid
- Check that file references in manifest match actual files
- Run WACK tests locally to identify specific issues

```powershell
# Validate manifest XML
[xml]$manifest = Get-Content "Platforms\Windows\Package.appxmanifest"
$manifest.Package.Identity.Name  # Should output valid name
```

### Issue 3: Version Conflicts

**Problem:** `Version already exists`

**Solutions:**
- You cannot re-submit the same version number
- Increment `ApplicationVersion` in `.csproj`:
  ```xml
  <ApplicationVersion>2</ApplicationVersion>
  ```
- Update manifest version:
  ```xml
  <Identity Version="1.0.1.0" />
  ```

### Issue 4: Missing Assets

**Problem:** `Asset not found: Square150x150Logo.png`

**Solutions:**
```powershell
# Check asset files exist
Get-ChildItem "Platforms\Windows\Assets\"

# Verify manifest references
[xml]$manifest = Get-Content "Platforms\Windows\Package.appxmanifest"
$manifest.Package.Applications.Application.VisualElements
```

All referenced assets MUST exist:
- Square44x44Logo.png
- Square150x150Logo.png
- Wide310x150Logo.png
- StoreLogo.png
- SplashScreen.png

### Issue 5: Publisher ID Mismatch

**Problem:** `Publisher in manifest does not match reserved app`

**Solutions:**
- Publisher value MUST exactly match Partner Center
- Re-associate app with Store (Step 6)
- Manually copy values from Partner Center ? Product identity
- Do not modify the `Publisher` attribute manually

### Issue 6: Crashes During Certification

**Problem:** `App crashed during launch testing`

**Solutions:**
- Test the MSIX package locally before submission
- Review crash logs in `Event Viewer`:
  ```powershell
  Get-WinEvent -LogName Application | Where-Object {$_.Message -like "*MCBDS*"}
  ```
- Check for missing dependencies
- Ensure `WindowsAppSDKSelfContained` is set to `true`
- Add error handling for first-run scenarios

### Issue 7: Build Errors on Windows Target

**Problem:** `The command "GenerateAppxManifest" failed`

**Solutions:**
```powershell
# Clean solution
dotnet clean -c Release

# Clear NuGet cache
dotnet nuget locals all --clear

# Restore packages
dotnet restore

# Rebuild
dotnet build -f net10.0-windows10.0.19041.0 -c Release
```

### Issue 8: Icon Not Showing in Store

**Problem:** Store shows placeholder icon

**Solutions:**
- Ensure `StoreLogo.png` is exactly **50×50 pixels**
- Use PNG format with transparency
- Check file is included in project:
  ```xml
  <Content Include="Platforms\Windows\Assets\StoreLogo.png" />
  ```
- Clear cache and wait 24 hours for Store to update

### Issue 9: Privacy Policy Required

**Problem:** `Privacy policy URL is required`

**Solutions:**
- Create privacy policy page on your website
- Add to Store listing in Partner Center
- Template: https://www.freeprivacypolicy.com/
- Even "free" apps need privacy policies if they:
  - Access internet
  - Collect telemetry
  - Use third-party services

### Issue 10: Age Rating Issues

**Problem:** `Age rating questionnaire incomplete`

**Solutions:**
- Complete all IARC questions honestly
- Common issues:
  - Forgot to answer a question
  - Selected inappropriate category
  - Content doesn't match description
- Age rating affects app visibility in family accounts

---

## Additional Resources

### Official Documentation

| Resource | URL |
|----------|-----|
| **.NET MAUI Windows Publishing** | https://learn.microsoft.com/dotnet/maui/windows/deployment/publish-cli |
| **Partner Center Guide** | https://learn.microsoft.com/windows/apps/publish/ |
| **MSIX Packaging** | https://learn.microsoft.com/windows/msix/ |
| **Windows App Certification** | https://learn.microsoft.com/windows/apps/publish/store-policies |
| **App Package Requirements** | https://learn.microsoft.com/windows/uwp/packaging/ |

### Community & Support

| Resource | Description |
|----------|-------------|
| **Microsoft Q&A** | https://learn.microsoft.com/answers/tags/295/windows-store |
| **.NET MAUI GitHub** | https://github.com/dotnet/maui |
| **Stack Overflow** | Tag: `windows-store` or `maui` |
| **Partner Center Support** | Available in Partner Center dashboard |

### Tools

| Tool | Purpose | URL |
|------|---------|-----|
| **Windows App Certification Kit** | Pre-submission testing | Included with Windows SDK |
| **App Installer** | Test MSIX packages locally | Included with Windows |
| **Visual Studio AppCenter** | Crash analytics | https://appcenter.ms |
| **Partner Center API** | Automate submissions | https://learn.microsoft.com/windows/uwp/monetize/create-and-manage-submissions-using-windows-store-services |

### Video Tutorials

- **Publishing to Microsoft Store**: https://www.youtube.com/results?search_query=publish+maui+windows+store
- **MSIX Packaging**: https://www.youtube.com/results?search_query=msix+packaging+tutorial
- **Partner Center Setup**: https://www.youtube.com/results?search_query=microsoft+partner+center+tutorial

### Sample Apps

Review open-source .NET MAUI apps published to Store:
- https://github.com/topics/dotnet-maui
- https://github.com/jsuarezruiz/awesome-dotnet-maui

---

## Quick Reference: Command Cheat Sheet

```powershell
# Build for Windows
dotnet build -f net10.0-windows10.0.19041.0 -c Release

# Publish for Windows (self-contained)
dotnet publish -f net10.0-windows10.0.19041.0 -c Release --self-contained

# Create MSIX package
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true

# Install package locally for testing
Add-AppxPackage -Path "path\to\package.msix"

# Uninstall package
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"} | Remove-AppxPackage

# Run WACK tests
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" test `
  -appxpackagepath "path\to\package.msix" `
  -reportoutputpath "report.xml"

# Check installed packages
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
```

---

## Checklist: Pre-Submission

Before submitting to the Store, verify:

### Project Configuration
- [ ] `WindowsPackageType` set to `MSIX`
- [ ] `ApplicationId` is unique and follows reverse domain notation
- [ ] `ApplicationDisplayVersion` and `ApplicationVersion` set correctly
- [ ] `AppxPackageSigningEnabled` is `True`
- [ ] Certificate file exists in project

### Package Manifest
- [ ] `Package.appxmanifest` exists in `Platforms/Windows/`
- [ ] Identity values match Partner Center exactly
- [ ] All asset references are correct
- [ ] Capabilities section includes required permissions

### Assets
- [ ] Square44x44Logo.png (44×44)
- [ ] Square150x150Logo.png (150×150)
- [ ] Wide310x150Logo.png (310×150)
- [ ] StoreLogo.png (50×50)
- [ ] SplashScreen.png (620×300)
- [ ] All assets are PNG format
- [ ] Assets have transparent backgrounds

### Partner Center
- [ ] Account created and verified
- [ ] App name reserved
- [ ] Identity values copied to manifest
- [ ] App associated with Store in Visual Studio

### Package Testing
- [ ] MSIX package builds successfully
- [ ] WACK tests pass
- [ ] Package installs locally without errors
- [ ] App launches and runs correctly
- [ ] No crashes or errors during testing

### Store Listing
- [ ] Description written (minimum 200 characters)
- [ ] At least 1 screenshot (1920×1080 or higher)
- [ ] App tile icon uploaded (1:1 ratio)
- [ ] Search terms defined (up to 7)
- [ ] Privacy policy URL provided (if applicable)
- [ ] Category selected
- [ ] Age rating questionnaire completed
- [ ] Pricing and availability configured

### Final Steps
- [ ] Version number incremented for updates
- [ ] Notes for certification written
- [ ] Test credentials provided (if needed)
- [ ] All submission sections have green checkmarks
- [ ] Ready to submit!

---

## Maintenance Schedule

### Regular Tasks

**Weekly:**
- Monitor crash reports in Partner Center
- Respond to user reviews
- Check analytics for unusual patterns

**Monthly:**
- Review app performance metrics
- Plan feature updates based on feedback
- Update dependencies and packages

**Quarterly:**
- Major version updates
- Review and update Store listing
- Refresh screenshots if UI changes

**Annually:**
- Renew certificates if needed
- Review compliance with new Store policies
- Major feature releases

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | [Submission Date] | Initial Store release |
| 1.0.1 | TBD | Bug fixes, performance improvements |
| 1.1.0 | TBD | New features |

---

## Contact & Support

**For deployment issues:**
- GitHub: https://github.com/JoshuaBylotas/MCBDSHost
- Website: https://www.mc-bds.com
- Email: support@mc-bds.com

**For Store-specific questions:**
- Partner Center Support (available in dashboard)
- Microsoft Q&A: https://learn.microsoft.com/answers/

---

## Appendix: Windows Store Policies Summary

### Content Policies

Your app MUST:
- ? Provide unique, creative value
- ? Work as described
- ? Be stable and responsive
- ? Respect user privacy
- ? Display appropriate content
- ? Have a valid privacy policy (if applicable)

Your app MUST NOT:
- ? Contain malware or viruses
- ? Mislead users
- ? Infringe on intellectual property
- ? Include inappropriate content
- ? Violate laws or regulations
- ? Harm user devices

### Technical Policies

- Apps must launch within 30 seconds
- Must not crash during certification testing
- Must handle errors gracefully
- Must work on all selected device families
- Must pass Windows App Certification Kit tests

### Metadata Policies

- Accurate descriptions and screenshots
- No misleading claims
- Appropriate age ratings
- Valid publisher information
- Working support contact

**Full Store Policies:** https://learn.microsoft.com/windows/apps/publish/store-policies

---

## Document Version

**Version:** 1.0  
**Created:** January 7, 2025  
**Author:** GitHub Copilot  
**Project:** MCBDS.PublicUI  
**Target:** .NET 10 / .NET MAUI  

---

**Good luck with your Windows Store submission! ??**

For questions or issues, refer to the [Common Issues and Solutions](#common-issues-and-solutions) section or consult the [Additional Resources](#additional-resources).

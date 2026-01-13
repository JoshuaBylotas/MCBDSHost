# Microsoft Store Assets Setup - MCBDS.PublicUI

## ? Completed Setup

### Assets Created and Configured

All required Windows Store assets have been successfully configured with transparent backgrounds:

| Asset | Size | Purpose | Status |
|-------|------|---------|--------|
| Square44x44Logo.transparent.png | 44×44 | App list icon | ? |
| Square71x71Logo.transparent.png | 71×71 | Small tile | ? |
| Square150x150Logo.transparent.png | 150×150 | Medium tile | ? |
| Square310x310Logo.transparent.png | 310×310 | Large tile | ? |
| Wide310x150Logo.transparent.png | 310×150 | Wide tile | ? |
| StoreLogo.transparent.png | 50×50 | Store listing | ? |
| SplashScreen.transparent.png | 620×300 | Launch screen (100% scale) | ? |
| SplashScreen.transparent.scale-125.png | 775×375 | Launch screen (125% scale) | ? |
| SplashScreen.transparent.scale-150.png | 930×450 | Launch screen (150% scale) | ? |
| SplashScreen.transparent.scale-200.png | 1240×600 | Launch screen (200% scale) | ? |
| SplashScreen.transparent.scale-400.png | 2480×1200 | Launch screen (400% scale) | ? |

### Files Updated

1. **Package.appxmanifest** - Updated all asset references to use new transparent PNGs
2. **MCBDS.PublicUI.csproj** - Updated Content includes with all new assets
3. **Old assets** - Moved to `Platforms/Windows/Assets/OLD/` directory

## ?? Ready for Microsoft Store Submission

Your app is now configured with proper transparent PNG assets for Microsoft Store submission.

### Current Package Information

- **Package Name**: MCBDS Manager
- **Publisher**: Pinecrest Consultants
- **Identity**: 50677PinecrestConsultants.MCBDSManager
- **Version**: 1.0.6.0
- **Certificate Thumbprint**: B97A80AD152EF3F18075E8F6B31A219112319F2B

## ?? Next Steps for Store Submission

### 1. Create MSIX Package

Right-click on `MCBDS.PublicUI` project in Visual Studio:
- Select **Publish** ? **Create App Packages**
- Choose **Microsoft Store** as distribution method
- Follow the wizard to create the MSIX package

### 2. Test the Package Locally

Before submitting, test the MSIX package:
```powershell
# Install the package locally
Add-AppxPackage -Path "path\to\your\package.msix"

# Launch and test the app
# Verify all assets display correctly

# Uninstall when done testing
Get-AppxPackage *MCBDSManager* | Remove-AppxPackage
```

### 3. Microsoft Partner Center Submission

1. Go to [Microsoft Partner Center](https://partner.microsoft.com/dashboard)
2. Navigate to your app submission
3. Upload the new MSIX package
4. Update store listing if needed
5. Submit for certification

### 4. Additional Store Listing Assets (Required)

You'll also need to prepare these for the Store listing page:
- **Screenshots**: At least 1 screenshot (1366×768 or larger)
- **Store logos**: 
  - 300×300 Store logo
  - 1240×600 Promotional banner (optional)
- **App description**: Compelling description for users
- **Privacy policy URL**: If your app collects data
- **Support contact information**

## ?? Notes

- All assets use transparent backgrounds for better visual integration
- Multiple splash screen scales ensure crisp display on all DPI settings
- Assets follow Microsoft Store naming conventions
- Build verified successful with all assets properly included

## ?? Troubleshooting

If you need to regenerate any missing assets:
```powershell
.\CreateMissingStoreAssets.ps1
```

## ? Asset Quality Tips

- Consider having a designer create high-quality versions for production
- Ensure your logo is clearly visible at small sizes (44×44)
- Test on different backgrounds to ensure visibility
- Follow [Microsoft Store icon design guidelines](https://learn.microsoft.com/windows/apps/design/style/iconography/app-icon-design)

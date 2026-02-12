# MSIX Code Signing Certificate Installation Guide

## Overview
The MCBDS Manager installer now properly installs the code signing certificate to the target machine's **Trusted Root Certification Authorities** store. This ensures that Windows recognizes the MSIX package signature as trusted and installs it without security warnings.

## How It Works

### Build Process (build-installer.ps1)
1. **Creates a self-signed certificate** for code signing
2. **Signs the MSIX package** with this certificate
3. **Embeds the certificate (.cer file)** in the installer
4. **Installs the certificate locally** (on the build machine)

### Installation Process (MCBDSInstaller.nsi)
When users run the installer on their machines:

1. **Extracts the certificate** from the installer to temp directory
2. **Installs certificate to LocalMachine\Root** using `certutil.exe`
   - This is the primary method (no PowerShell required)
   - Makes the certificate trusted system-wide for all users
3. **Falls back to PowerShell method** if certutil fails
4. **Installs the MSIX package** (which is now trusted)
5. **Cleans up temporary files**

## Requirements

### For Building the Installer
- PowerShell 5.1+ (Windows 10/11 default)
- Visual Studio 2022+ with NSIS installed
- Run as Administrator (recommended for system-wide certificate installation)

### For Installing on Target Machines
- **MUST RUN AS ADMINISTRATOR** - This is critical for certificate installation to work
- Windows 10 (Build 19041) or later
- User account with administrator privileges

## Important Notes

?? **CRITICAL**: The installer MUST be run with Administrator privileges on the target machine for the code signing certificate to be installed to the trusted root store.

### What Happens if Run Without Admin
- Certificate installation will fail silently
- MSIX installation may fail with security warnings
- Users will see "Unknown Publisher" or security prompts

### What Happens if Run With Admin
- ? Certificate is installed to LocalMachine\Root (trusted for all users)
- ? MSIX installs without warnings
- ? Clean, seamless installation experience

## Building the Installer

```powershell
# Standard build
.\MCBDS.Installer\build-installer.ps1

# Build with version increment
.\MCBDS.Installer\build-installer.ps1 -IncrementVersion

# Build with custom version
.\MCBDS.Installer\build-installer.ps1 -Version 2.1.0
```

### Recommended
```powershell
# Run as Administrator for best results
# Then run the build script
```

## Testing the Certificate Installation

After building, you can verify the installer includes the certificate:

```powershell
# Extract the installer to check its contents
# The certificate should be: MCBDS.Installer\CodeSigning.cer
# The MSIX should be: MCBDS.Installer\MCBDS.PublicUI.msix

# Both are embedded in the NSIS installer
```

## User Installation Instructions

Users should:

1. **Right-click** the installer: `MCBDS.Manager.X.X.X.Installer.exe`
2. **Select "Run as administrator"**
3. **Click "Yes"** when prompted by UAC (User Account Control)
4. **Follow the setup wizard**
5. **Do NOT cancel** during the certificate installation step
6. Once complete, the MSIX will install without warnings

## Troubleshooting

### "Unknown Publisher" or Security Warning During MSIX Installation
- **Cause**: Installer was not run as Administrator
- **Solution**: Uninstall and reinstall with Administrator privileges

### "Code signing certificate installed, but MSIX still shows warnings"
- **Cause**: Certificate may be in CurrentUser store instead of LocalMachine
- **Solution**: Run the installer as Administrator from a fresh installation

### "Certificate installation failed" in installer logs
- **Cause**: System policy blocks certificate installation
- **Solution**: Check Windows certificate policies or try on a machine without group policy restrictions

## Architecture Details

### Certificate Storage Locations

**Desired (production):**
- `Cert:\LocalMachine\Root` - System-wide trust (requires Admin)
- Affects all users on the machine
- Persists across user sessions

**Fallback (if admin fails):**
- `Cert:\CurrentUser\Root` - User-specific trust
- Only affects current user
- Not recommended for production installers

### Methods Used for Installation

1. **Primary**: `certutil.exe -addstore -f "Root"`
   - Built-in Windows utility
   - Works without PowerShell execution policy changes
   - Requires Admin privileges

2. **Fallback**: PowerShell `Import-Certificate`
   - More flexible but requires PowerShell
   - Still requires Admin privileges
   - Used only if certutil fails

## Self-Signed Certificate Details

- **Subject**: CN=Pinecrest Consultants
- **Valid for**: 3 years from creation
- **Key Usage**: Code Signing
- **Stored in**: MCBDS.Installer folder
  - `CodeSigning.pfx` - Private key (password protected)
  - `CodeSigning.cer` - Public certificate
  - `CodeSigning.password.txt` - PFX password (do NOT share)

?? **Security Note**: The certificate files are stored locally. For production use with distribution, consider using a proper code signing certificate from a trusted Certificate Authority.

## Files Involved

- `MCBDS.Installer\build-installer.ps1` - Build script
- `MCBDS.Installer\MCBDSInstaller.nsi` - NSIS installer script
- `MCBDS.Installer\CodeSigning.pfx` - Private key (created on first build)
- `MCBDS.Installer\CodeSigning.cer` - Public certificate (embedded in installer)
- `MCBDS.Installer\CodeSigning.password.txt` - Password (created on first build)
- `MCBDS.Installer\MCBDS.PublicUI.msix` - MSIX package (embedded in installer)

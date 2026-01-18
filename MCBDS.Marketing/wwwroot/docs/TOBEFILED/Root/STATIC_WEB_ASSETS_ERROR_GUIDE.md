# Static Web Assets Build Error - Resolution Guide

## Problem

When publishing MCBDS.PublicUI in Release mode, you may encounter:

```
Error: Manifest file at 'obj\Release\net10.0\staticwebassets.build.json' not found.
```

## Root Cause

The error occurs because:

1. **MCBDS.PublicUI** references **MCBDS.ClientUI.Shared** (a Razor class library)
2. Razor class libraries generate static web assets manifests during build
3. When publishing in Release mode, MSBuild looks for the manifest from the referenced project
4. If the referenced project hasn't been built in Release mode yet, the manifest doesn't exist

## Solution

### Automatic Solution (Recommended)

Use the provided build script that ensures dependencies are built in the correct order:

```powershell
# Build only
.\BuildAndPublish.ps1 -Configuration Release

# Build and create MSIX package
.\BuildAndPublish.ps1 -Configuration Release -CreatePackage

# Build for specific runtime
.\BuildAndPublish.ps1 -Configuration Release -RuntimeIdentifier win-x86 -CreatePackage
```

### Manual Solution

If you need to build manually:

1. **First, build the shared library:**
   ```powershell
   dotnet build MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj -c Release
   ```

2. **Then build the main project:**
   ```powershell
   dotnet build MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release -f net10.0-windows10.0.19041.0
   ```

3. **Finally, publish:**
   ```powershell
   dotnet publish MCBDS.PublicUI\MCBDS.PublicUI.csproj -c Release -f net10.0-windows10.0.19041.0 -r win-x64
   ```

### Visual Studio Solution

When using Visual Studio:

1. **Build Solution** (Ctrl+Shift+B) - This builds all projects in the correct order
2. **Then Publish** - Right-click MCBDS.PublicUI ? Publish

?? **Do NOT publish directly without building first**

## Project Configuration Updates

The following changes have been made to prevent this issue:

### 1. MCBDS.PublicUI.csproj

Updated project reference to ensure proper asset inclusion:

```xml
<ItemGroup>
    <ProjectReference Include="..\MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj">
        <ReferenceOutputAssembly>true</ReferenceOutputAssembly>
        <IncludeAssets>all</IncludeAssets>
    </ProjectReference>
</ItemGroup>
```

### 2. BuildAndPublish.ps1

Created automated build script that:
- Cleans previous builds
- Restores NuGet packages
- Builds dependencies first (MCBDS.ClientUI.Shared)
- Verifies static web assets manifest creation
- Builds main project
- Optionally creates MSIX package

## Build Order Requirements

When building for Microsoft Store submission:

```
1. MCBDS.ClientUI.Shared (Debug or Release)
   ? Creates staticwebassets.build.json
2. MCBDS.PublicUI (Same configuration)
   ? References manifest from step 1
3. Publish/Package (Same configuration)
   ? Creates MSIX package
```

## Verification

To verify the manifest exists:

```powershell
# Check Release manifest
Test-Path "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\Release\net10.0\staticwebassets.build.json"

# Check Debug manifest
Test-Path "MCBDS.ClientUI\MCBDS.ClientUI.Shared\obj\Debug\net10.0\staticwebassets.build.json"
```

## Why This Happens

Static web assets are:
- CSS files
- JavaScript files
- Images
- Other web content from Blazor/Razor class libraries

The manifest file (`staticwebassets.build.json`) tells MSBuild:
- What assets exist
- Where they're located
- How to include them in the consuming project

Without this manifest, the build system doesn't know how to properly include these assets in the final package.

## Prevention

Always use the build script or follow the manual build order when:
- Switching between Debug and Release configurations
- After cleaning the solution
- After pulling changes that affect MCBDS.ClientUI.Shared
- Before creating store submission packages

## Quick Reference

| Command | Purpose |
|---------|---------|
| `.\BuildAndPublish.ps1` | Build in Release mode |
| `.\BuildAndPublish.ps1 -CreatePackage` | Build and create MSIX |
| `.\BuildAndPublish.ps1 -Configuration Debug` | Build in Debug mode |
| `.\BuildAndPublish.ps1 -RuntimeIdentifier win-x86` | Build for specific runtime |
| `.\BuildAndPublish.ps1 -SkipBuild -CreatePackage` | Package only (if already built) |

## Additional Resources

- [Microsoft Store Submission Guide](MICROSOFT_STORE_ASSETS_SETUP.md)
- [Static Web Assets Documentation](https://learn.microsoft.com/aspnet/core/razor-pages/ui-class)
- [.NET MAUI Windows Packaging](https://learn.microsoft.com/dotnet/maui/windows/deployment/overview)

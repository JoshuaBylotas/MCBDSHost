# 3-STEP FIX

## Step 1: Disable Signing
```powershell
.\PrepareForVisualStudioPackaging.ps1
```

## Step 2: Visual Studio
1. Open Visual Studio 2026
2. Right-click MCBDS.PublicUI
3. Publish ? Create App Packages
4. Microsoft Store ? MCBDS Manager
5. x64, x86, ARM64 ? Create

## Step 3: Restore & Upload
```powershell
.\RestoreProjectFile.ps1
```

Upload `.msixupload` to Partner Center

---

## Why?
- .NET 10 preview = no NuGet runtime packages
- Must use Visual Studio
- But need signing disabled first
- Then Microsoft signs at Store

? **Identity mismatch fixed!**

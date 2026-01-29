# ? Add NSIS Project to Solution

## What You Now Have

A **custom .csproj project file** that shows all NSIS installer files in Solution Explorer without requiring WiX Toolset!

---

## How to Add to Solution

### Step 1: Open Solution in Visual Studio

```
1. Open MCBDSHost.slnx
2. Right-click on Solution name
3. Select "Add" ? "Existing Project"
```

### Step 2: Select the Project File

```
1. Navigate to: MCBDS.Installer\
2. Select: MCBDS.Installer.csproj
3. Click "Open"
```

### Step 3: Done! ?

```
Solution Explorer now shows:
?? MCBDS.API
?? MCBDS.ClientUI.Shared
?? MCBDS.ClientUI.Web
?? MCBDS.Marketing
?? MCBDS.PublicUI
?? MCBDS.WindowsService
?? MCBDSHost.AppHost
?? MCBDSHost.ServiceDefaults
?? MCBDS.Installer ? (Now visible!)
   ?? MCBDSInstaller.nsi
   ?? build-installer.ps1
   ?? 00-START-HERE.md
   ?? QUICK-REFERENCE.md
   ?? ... (all other files)
```

---

## Features of This Project

? **Shows all NSIS files** in Solution Explorer  
? **No external dependencies** - doesn't require WiX, NSIS, or any special tools  
? **Can edit files directly** - right-click any file and edit  
? **Custom build target** - Building the project runs the PowerShell script  
? **Clean integration** - Works like a normal project in the solution  

---

## How to Use

### View Files
```
Solution Explorer
  ?? MCBDS.Installer
     ?? MCBDSInstaller.nsi (right-click to edit)
     ?? build-installer.ps1 (right-click to edit)
     ?? ... (all docs visible and editable)
```

### Build Installer
```
Option 1: Right-click project ? Build
Option 2: Right-click project ? Build (runs PowerShell script)
Option 3: PowerShell: .\MCBDS.Installer\build-installer.ps1
```

### Edit Files
```
Solution Explorer
  ?? MCBDS.Installer
     ?? MCBDSInstaller.nsi (double-click to edit in VS)
     ?? build-installer.ps1 (double-click to edit in VS)
     ?? ... (all files editable)
```

---

## Project Details

### What the .csproj Does

```xml
<ItemGroup>
  <!-- Lists all NSIS and documentation files -->
  <!-- Makes them visible in Solution Explorer -->
</ItemGroup>

<Target Name="BuildInstaller">
  <!-- When you build this project, it runs: -->
  <!-- .\MCBDS.Installer\build-installer.ps1 -->
</Target>
```

### Benefits

| Feature | Benefit |
|---------|---------|
| **Shows in Solution Explorer** | Easy to find and edit all installer files |
| **No external tools needed** | Works without WiX, NSIS SDK, or special software |
| **Integrates with VS** | Double-click files to edit, right-click for context menu |
| **Custom build target** | Building project creates installer automatically |
| **Clean organization** | All installer files grouped together |

---

## What This Solves

### Before (No Project) ?
```
Solution Explorer
?? MCBDS.API
?? ...
?? MCBDS.WindowsService
?? (MCBDS.Installer folder not visible!)

You had to:
- Open file explorer to find installer files
- Use PowerShell to build
- Can't see installer files in VS
```

### After (With Project) ?
```
Solution Explorer
?? MCBDS.API
?? ...
?? MCBDS.WindowsService
?? MCBDS.Installer (visible and organized!)
   ?? MCBDSInstaller.nsi
   ?? build-installer.ps1
   ?? ... (all files visible)

Now you can:
- See all installer files in Solution Explorer
- Double-click to edit files
- Right-click for context menu
- Build from within Visual Studio
```

---

## Complete Steps

### Step 1: Remove Old WiX Project
```
Solution Explorer
  ?? Right-click MCBDS.Installer (old WiX project)
     ?? Select "Remove"
```

### Step 2: Delete Old Files
```powershell
cd "D:\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.Installer"
Remove-Item "MCBDS.Installer.wixproj" -Force
Remove-Item "Product.wxs" -Force
```

### Step 3: Add New Project
```
Solution Explorer
  ?? Right-click Solution name
     ?? Select "Add" ? "Existing Project"
        ?? Select: MCBDS.Installer\MCBDS.Installer.csproj
```

### Step 4: Done! ?
```
All installer files now visible in Solution Explorer
```

---

## File Organization in Project

The project includes all important files:

```
MCBDS.Installer (Project)
?? Installer Files
?  ?? MCBDSInstaller.nsi
?  ?? build-installer.ps1
?
?? Quick Start
?  ?? 00-START-HERE.md
?  ?? QUICK-REFERENCE.md
?
?? Configuration
?  ?? INSTALLER-CONFIGURATION-GUIDE.md
?  ?? CONFIGURATION-QUICK-START.md
?  ?? ... (configuration docs)
?
?? Setup & Reference
?  ?? INSTALLER-SETUP-GUIDE.md
?  ?? NSIS-README.md
?  ?? ... (setup docs)
?
?? Architecture & Reference
   ?? ARCHITECTURE.md
   ?? COMMANDS-REFERENCE.md
   ?? ... (reference docs)
```

---

## Building the Installer from Visual Studio

### Option 1: Right-Click Project Build
```
Solution Explorer
  ?? Right-click MCBDS.Installer
     ?? "Build"
     
Output: MCBDS.API.Service.Installer.exe
```

### Option 2: Build Menu
```
Build ? Build MCBDS.Installer

Output: MCBDS.API.Service.Installer.exe
```

### Option 3: PowerShell (Still Works)
```powershell
.\MCBDS.Installer\build-installer.ps1

Output: MCBDS.API.Service.Installer.exe
```

---

## Frequently Asked Questions

**Q: Do I need NSIS SDK or WiX installed?**  
A: No! This project just organizes files. The actual build script handles everything.

**Q: Can I edit the .nsi file in Visual Studio?**  
A: Yes! Double-click it in Solution Explorer. VS will open it for editing (basic text editor).

**Q: What happens when I build this project?**  
A: It runs the PowerShell build script which creates the installer.

**Q: Will this interfere with other projects?**  
A: No! It's completely independent and just organizes files.

**Q: Can I remove this project later?**  
A: Yes, right-click and "Remove" (keeps the files on disk).

---

## Summary

| Before | After |
|--------|-------|
| ? NSIS files hidden from Solution Explorer | ? All files visible in Solution Explorer |
| ? Can't edit files from VS | ? Double-click any file to edit |
| ? Must use PowerShell to build | ? Can build from Visual Studio |
| ? Files scattered | ? Files organized in project |
| ? No WiX needed (but missing project) | ? No WiX needed (with organized project) |

---

## Quick Checklist

- [ ] Created `MCBDS.Installer.csproj` (? Already done for you!)
- [ ] Removed old WiX project from solution
- [ ] Deleted old WiX files (Product.wxs, old .wixproj)
- [ ] Added new MCBDS.Installer.csproj to solution
- [ ] Verify all files show in Solution Explorer
- [ ] Test building the project

---

## Status

? **Project file created**: MCBDS.Installer.csproj  
? **Ready to add to solution**: Yes  
? **All files included**: Yes  
? **No external dependencies**: Correct  
? **Build target configured**: Yes  

?? **Ready to use! Just add it to your solution.**

---

**Next Step**: Add `MCBDS.Installer.csproj` to your solution in Visual Studio!

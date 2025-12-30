#!/usr/bin/env python3
"""
Diagnostic script for MCBDS.PublicUI.Android
Checks if setup was completed correctly
"""

import os
from pathlib import Path

def check_setup():
    """Check if all required files and directories exist."""
    
    script_dir = Path(__file__).parent
    solution_root = script_dir.parent
    android_dir = solution_root / "MCBDS.PublicUI.Android"
    publicui_dir = solution_root / "MCBDS.PublicUI"
    
    print()
    print("=" * 70)
    print("MCBDS.PublicUI.Android - Setup Diagnostic")
    print("=" * 70)
    print()
    
    # Check basic paths
    print("?? Checking directories...")
    print(f"   Solution Root: {solution_root}")
    print(f"   ? Exists" if solution_root.exists() else "   ? MISSING")
    print()
    
    print(f"   Android Project: {android_dir}")
    print(f"   ? Exists" if android_dir.exists() else "   ? MISSING")
    print()
    
    print(f"   PublicUI Project: {publicui_dir}")
    print(f"   ? Exists" if publicui_dir.exists() else "   ? MISSING")
    print()
    
    # Check required components
    print("?? Checking required components...")
    print()
    
    required_components = [
        ("Components/Layout", android_dir / "Components" / "Layout"),
        ("Components/Pages", android_dir / "Components" / "Pages"),
        ("Components/ServerSwitcher.razor", android_dir / "Components" / "ServerSwitcher.razor"),
        ("Components/ServerSwitcher.razor.css", android_dir / "Components" / "ServerSwitcher.razor.css"),
        ("Components/_Imports.razor", android_dir / "Components" / "_Imports.razor"),
        ("Components/Routes.razor", android_dir / "Components" / "Routes.razor"),
        ("wwwroot/lib", android_dir / "wwwroot" / "lib"),
        ("wwwroot/index.html", android_dir / "wwwroot" / "index.html"),
        ("wwwroot/app.css", android_dir / "wwwroot" / "app.css"),
    ]
    
    missing = []
    for name, path in required_components:
        status = "?" if path.exists() else "?"
        print(f"   [{status}] {name}")
        if not path.exists():
            missing.append(name)
    
    print()
    
    if missing:
        print("??  SETUP NOT COMPLETE")
        print()
        print("Missing components:")
        for item in missing:
            print(f"   - {item}")
        print()
        print("SOLUTION:")
        print("-" * 70)
        print()
        print("Run one of the setup scripts from the solution root:")
        print()
        print("Option 1 (Python - Recommended):")
        print("  python MCBDS.PublicUI.Android/setup-links.py")
        print()
        print("Option 2 (PowerShell - Windows, needs Admin):")
        print("  .\MCBDS.PublicUI.Android\setup-links.ps1")
        print()
        print("Option 3 (Batch - Windows, needs Admin):")
        print("  MCBDS.PublicUI.Android\setup-links.bat")
        print()
        print("Option 4 (Manual Copy - No Admin Required):")
        print("  See MCBDS.PublicUI.Android\SETUP.md for instructions")
        print()
        return False
    else:
        print("? SETUP COMPLETE")
        print()
        print("All required components are in place.")
        print("You can now build and run the Android app:")
        print()
        print("  dotnet build MCBDS.PublicUI.Android -f net10.0-android")
        print("  dotnet run MCBDS.PublicUI.Android -f net10.0-android")
        print()
        return True

if __name__ == "__main__":
    success = check_setup()
    exit(0 if success else 1)

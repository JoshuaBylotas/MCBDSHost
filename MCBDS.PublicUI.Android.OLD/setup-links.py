#!/usr/bin/env python3
"""
Setup script for MCBDS.PublicUI.Android
Copies shared components from MCBDS.PublicUI to MCBDS.PublicUI.Android
"""

import os
import shutil
import sys
from pathlib import Path

def copy_directory_tree(source, dest):
    """Copy directory tree from source to dest, creating as needed."""
    source_path = Path(source)
    dest_path = Path(dest)
    
    if not source_path.exists():
        print(f"  [ERROR] Source not found: {source}")
        return False
    
    dest_path.mkdir(parents=True, exist_ok=True)
    
    try:
        for item in source_path.rglob("*"):
            if item.is_file():
                relative_path = item.relative_to(source_path)
                target_file = dest_path / relative_path
                target_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, target_file)
        
        print(f"  [OK] Copied {source_path.name}")
        return True
    except Exception as e:
        print(f"  [ERROR] Failed to copy: {e}")
        return False

def main():
    # Get script directory (should be in MCBDS.PublicUI.Android)
    script_dir = Path(__file__).parent
    
    # Navigate to solution root
    solution_root = script_dir.parent
    publicui_dir = solution_root / "MCBDS.PublicUI"
    android_dir = solution_root / "MCBDS.PublicUI.Android"
    
    print()
    print("Setting up MCBDS.PublicUI.Android...")
    print()
    print(f"Solution Root: {solution_root}")
    print(f"PublicUI Project: {publicui_dir}")
    print(f"Android Project: {android_dir}")
    print()
    
    # Verify paths
    if not publicui_dir.exists():
        print(f"[ERROR] MCBDS.PublicUI not found at: {publicui_dir}")
        sys.exit(1)
    
    # Create Components directory structure
    print("Copying components...")
    components_pairs = [
        (publicui_dir / "Components" / "Layout", android_dir / "Components" / "Layout"),
        (publicui_dir / "Components" / "Pages", android_dir / "Components" / "Pages"),
    ]
    
    for source, dest in components_pairs:
        copy_directory_tree(source, dest)
    
    # Copy individual component files
    print("Copying component files...")
    component_files = [
        "ServerSwitcher.razor",
        "ServerSwitcher.razor.css",
    ]
    
    for filename in component_files:
        source_file = publicui_dir / "Components" / filename
        dest_file = android_dir / "Components" / filename
        
        if source_file.exists():
            shutil.copy2(source_file, dest_file)
            print(f"  [OK] Copied {filename}")
        else:
            print(f"  [ERROR] File not found: {filename}")
    
    # Copy wwwroot/lib
    print("Copying wwwroot/lib...")
    copy_directory_tree(publicui_dir / "wwwroot" / "lib", android_dir / "wwwroot" / "lib")
    
    print()
    print("Setup complete!")
    print()
    print("Next steps:")
    print("1. Build the project: dotnet build MCBDS.PublicUI.Android/MCBDS.PublicUI.Android.csproj -f net10.0-android")
    print("2. Test on Android device/emulator: dotnet run MCBDS.PublicUI.Android -f net10.0-android")
    print()

if __name__ == "__main__":
    main()

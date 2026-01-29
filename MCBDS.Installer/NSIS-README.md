# MCBDS API Windows Service Installer (NSIS)

This project creates a Windows installer (.exe) using NSIS (Nullsoft Scriptable Install System) that installs the MCBDS API as a Windows Service.

## Features

- ? **Windows Service**: Automatically installs and starts as a Windows Service
- ? **HTTP Port 8080**: Configured for local/network access
- ? **Automatic Firewall Rule**: Opens port 8080 in Windows Firewall (TCP)
- ? **Service Management**: Full integration with Windows Services (services.msc)
- ? **Self-Contained**: Includes .NET 10 runtime (no separate installation required)
- ? **Free**: Uses NSIS - completely free and open-source
- ? **Lightweight**: Installer is under 100MB
- ? **Clean Uninstall**: Removes service, firewall rules, and all files on uninstall

## Prerequisites

### Required Software

1. **NSIS (Nullsoft Scriptable Install System)**
   - Download from: https://nsis.sourceforge.io/
   - Install to default location: `C:\Program Files (x86)\NSIS\`
   - Or custom location (update -NsisPath parameter in build script)

2. **.NET 10 SDK**
   - Download from: https://dotnet.microsoft.com/download
   - Required for publishing the Windows Service

3. **Windows Admin Privileges**
   - Required to build and run the installer

### Optional but Recommended

- **Visual Studio 2022 or Visual Studio Code** - for editing .nsi files
- **NSIS Syntax Highlighter** - Visual Studio extension (search "NSIS" in Extensions)

## Quick Start

### Automated Build (Recommended)

1. **Install NSIS** from https://nsis.sourceforge.io/
2. **Open PowerShell as Administrator**
3. **Navigate to the solution directory**
4. **Run the build script**:
   ```powershell
   .\MCBDS.Installer\build-installer.ps1
   ```

The script will:
- Publish the Windows Service
- Build the NSIS installer
- Create `MCBDS.API.Service.Installer.exe`

### Manual Build Steps

1. **Publish the Windows Service**:
   ```powershell
   dotnet publish MCBDS.WindowsService\MCBDS.WindowsService.csproj -c Release -r win-x64 --self-contained
   ```

2. **Build the Installer**:
   ```powershell
   & "C:\Program Files (x86)\NSIS\makensis.exe" "MCBDS.Installer\MCBDSInstaller.nsi"
   ```

3. **The installer will be created as**: `MCBDS.API.Service.Installer.exe`

## Installation

### For Users

1. **Download** `MCBDS.API.Service.Installer.exe`
2. **Run as Administrator** (right-click ? Run as Administrator)
3. **Follow the installation wizard**
4. **Choose installation directory** (default: `C:\Program Files\MCBDS API Service`)
5. **Complete installation**

The installer will:
- Extract all files to the installation directory
- Create subdirectories: `Binaries`, `logs`, `backups`
- Install as Windows Service named "MCBDSAPIService"
- Add firewall rule for port 8080
- **Start the service immediately**

### Service Management

**Start/Stop Service**:
```powershell
# Start
net start MCBDSAPIService

# Stop
net stop MCBDSAPIService
```

**Via Services.msc**:
1. Press `Win + R`
2. Type `services.msc` and press Enter
3. Find "MCBDS API Service"
4. Right-click to start, stop, or disable

## Uninstallation

### Via Control Panel (Recommended)

1. Open **Settings** ? **Apps** ? **Apps & features**
2. Search for "MCBDS API Service"
3. Click and select "Uninstall"
4. Follow the uninstallation wizard

The uninstaller will:
- Stop the Windows Service
- Remove the service registration
- Delete the firewall rule
- Remove all installed files and directories

### Manual Uninstall

```powershell
# Stop the service
net stop MCBDSAPIService

# Uninstall the service
sc delete MCBDSAPIService

# Remove firewall rule
netsh advfirewall firewall delete rule name="MCBDS API Service (HTTP)"

# Delete the installation directory
Remove-Item -Path "C:\Program Files\MCBDS API Service" -Recurse
```

## Configuration

### Service Configuration File

Located at: `C:\Program Files\MCBDS API Service\appsettings.json`

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "Urls": "http://0.0.0.0:8080",
  "Runner": {
    "ExePath": "Binaries\\bedrock_server.exe",
    "LogFilePath": "logs\\runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "backups",
    "MaxBackupsToKeep": 30
  }
}
```

### Minecraft Server Binary

1. Download Minecraft Bedrock Server for Windows
2. Extract `bedrock_server.exe` to: `C:\Program Files\MCBDS API Service\Binaries\`
3. The service will automatically detect and run it

### Firewall Configuration

The installer automatically adds a firewall rule:
- **Port**: 8080 (TCP)
- **Direction**: Inbound
- **Action**: Allow
- **Program**: MCBDS.WindowsService.exe

To modify manually:
```powershell
# Add custom firewall rule
netsh advfirewall firewall add rule name="MCBDS Custom" dir=in action=allow protocol=tcp localport=8080

# Remove rule
netsh advfirewall firewall delete rule name="MCBDS API Service (HTTP)"

# List all rules
netsh advfirewall firewall show rule all
```

## Accessing the Service

### Local Network

- **API Endpoint**: `http://localhost:8080`
- **Find your IP**: Open Command Prompt and run `ipconfig`
- **Remote Access**: `http://<your-ip>:8080`

### Example Requests

```powershell
# Check service health
curl http://localhost:8080/health

# Get server status
curl http://localhost:8080/api/server/status
```

## Troubleshooting

### Service Won't Start

**Check the service status**:
```powershell
Get-Service MCBDSAPIService
```

**Check logs**:
- Service logs: Event Viewer ? Windows Logs ? Application
- Application logs: `C:\Program Files\MCBDS API Service\logs\`

**Restart the service**:
```powershell
net stop MCBDSAPIService
net start MCBDSAPIService
```

### Port 8080 Already in Use

**Find what's using port 8080**:
```powershell
netstat -ano | findstr :8080
```

**Change the port in appsettings.json** and restart the service.

### Installer Won't Run

- Run as Administrator
- Check that NSIS is installed
- Ensure .NET 10 runtime is available

## Customizing the Installer

### Modify Installation Directory

Edit `MCBDSInstaller.nsi`:
```nsi
InstallDir "$PROGRAMFILES64\MCBDS API Service"
```

### Change Service Display Name

Edit `MCBDSInstaller.nsi`:
```nsi
DetailPrint "Installing Windows Service..."
ExecWait '"$INSTDIR\MCBDS.WindowsService.exe" install'
```

And update in `Program.cs`:
```csharp
options.ServiceName = "MCBDS API Service";
```

### Add Additional Directories

Edit `MCBDSInstaller.nsi`:
```nsi
CreateDirectory "$INSTDIR\data"
CreateDirectory "$INSTDIR\config"
```

## Support

For issues:
1. Check the logs in the installation directory
2. Review Windows Event Viewer for service errors
3. Ensure Windows Service is running: `net start MCBDSAPIService`
4. Check firewall settings allow port 8080

## License

This installer uses NSIS, which is open-source under the zlib license.

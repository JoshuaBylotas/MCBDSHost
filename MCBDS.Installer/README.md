# MCBDS API Windows Service Installer

This project creates a Windows installer (.msi) that installs the MCBDS API as a Windows Service.

## Features

- **Windows Service**: Runs automatically on system startup
- **HTTP Port 8080**: Configured for local/network access (no HTTPS certificate required)
- **Automatic Firewall Rule**: Opens port 8080 in Windows Firewall
- **Service Management**: Integrates with Windows Services (services.msc)
- **Self-Contained**: Includes .NET 10 runtime (no separate .NET installation required)

## Building the Installer

### Prerequisites

1. **WiX Toolset v5**: Install from https://wixtoolset.org/
2. **.NET 10 SDK**: Install from https://dotnet.microsoft.com/download

### Build Steps

1. **Publish the Windows Service**:
   ```powershell
   dotnet publish MCBDS.WindowsService/MCBDS.WindowsService.csproj -c Release -r win-x64 --self-contained
   ```

2. **Build the Installer**:
   ```powershell
   dotnet build MCBDS.Installer/MCBDS.Installer.wixproj -c Release
   ```

3. **Locate the MSI**: 
   The installer will be in `MCBDS.Installer\bin\Release\MCBDS.Installer.msi`

## Installation

1. **Run the MSI** as Administrator
2. Follow the installation wizard
3. The service will be installed to: `C:\Program Files\MCBDS API Service\`
4. The service starts automatically after installation

## Post-Installation

### Place Minecraft Bedrock Server Binary

Copy your Minecraft Bedrock server files to:
```
C:\Program Files\MCBDS API Service\Binaries\
```

The main executable should be at:
```
C:\Program Files\MCBDS API Service\Binaries\bedrock_server.exe
```

### Service Management

**Start/Stop Service**:
```powershell
# Stop
net stop MCBDSAPIService

# Start
net start MCBDSAPIService

# Restart
net stop MCBDSAPIService && net start MCBDSAPIService
```

**View Service Status**:
```powershell
Get-Service MCBDSAPIService
```

**View Service in GUI**:
- Press `Win + R`, type `services.msc`, press Enter
- Find "MCBDS API Service" in the list

### Connecting to the API

The API is accessible at:
- **Local machine**: `http://localhost:8080`
- **Network**: `http://<your-ip>:8080`

Test the health endpoint:
```powershell
curl http://localhost:8080/health
```

### Logs and Backups

- **Logs**: `C:\Program Files\MCBDS API Service\logs\`
- **Backups**: `C:\Program Files\MCBDS API Service\backups\`
- **Server Files**: `C:\Program Files\MCBDS API Service\Binaries\`

### Configuration

Edit `appsettings.json` in the installation directory:
```json
{
  "Runner": {
    "ExePath": "Binaries\\bedrock_server.exe"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "MaxBackupsToKeep": 30
  }
}
```

After changing configuration, restart the service.

## Uninstallation

1. Use Windows "Add or Remove Programs"
2. Find "MCBDS API Service" and click Uninstall
3. The service will be stopped and removed
4. Installation files will be deleted (backups and world data will remain)

## Troubleshooting

### Service Won't Start

1. Check Event Viewer: `eventvwr.msc` ? Windows Logs ? Application
2. Verify bedrock_server.exe exists in Binaries folder
3. Check service account has read/write permissions to installation folder

### Can't Connect to API

1. Verify service is running: `Get-Service MCBDSAPIService`
2. Check firewall rule exists: `Get-NetFirewallRule -DisplayName "MCBDS API Service (HTTP)"`
3. Test locally first: `curl http://localhost:8080/health`

### Port 8080 Already in Use

Edit `appsettings.json` and change the "Urls" setting:
```json
{
  "Urls": "http://0.0.0.0:9090"
}
```

Then update the firewall rule manually or use a different port.

## Development Notes

- The service runs under the `LocalSystem` account
- Service name: `MCBDSAPIService`
- Display name: `MCBDS API Service`
- Startup type: Automatic

## Building from Source

```powershell
# Clone the repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Publish the service
dotnet publish MCBDS.WindowsService -c Release -r win-x64 --self-contained

# Build the installer (requires WiX Toolset)
dotnet build MCBDS.Installer -c Release
```

## License

Same as the main MCBDS Host project.

# Launch MCBDS Manager Web UI
# This script starts the web server and opens the browser

$ErrorActionPreference = "Stop"

# Get installation directory from registry
$InstallDir = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MCBDS Manager" -Name "InstallDir" -ErrorAction SilentlyContinue).InstallDir

if (-not $InstallDir) {
    $InstallDir = "$env:ProgramFiles\MCBDS Manager"
}

$WebUIExe = Join-Path $InstallDir "WebUI\MCBDS.ClientUI.Web.exe"

if (-not (Test-Path $WebUIExe)) {
    [System.Windows.Forms.MessageBox]::Show("MCBDS Manager Web UI not found at: $WebUIExe", "MCBDS Manager", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Check if already running
$existing = Get-Process -Name "MCBDS.ClientUI.Web" -ErrorAction SilentlyContinue
if ($existing) {
    # Already running - just open browser
    Start-Process "http://localhost:5000"
    exit 0
}

# Start Web UI in background
Start-Process -FilePath $WebUIExe -WindowStyle Hidden

# Wait for server to start
Start-Sleep -Seconds 2

# Open browser
Start-Process "http://localhost:5000"

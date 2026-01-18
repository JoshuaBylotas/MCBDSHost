#!/bin/bash
# MCBDSHost Linux Server Deployment Script
# Run as root or with sudo

set -e

INSTALL_PATH="${1:-/opt/mcbdshost}"
API_PORT="${2:-8080}"
WEBUI_PORT="${3:-5000}"
SERVICE_USER="mcbdshost"

echo "============================================"
echo "MCBDSHost Linux Server Deployment"
echo "============================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Check for .NET 10
echo ""
echo "Checking for .NET 10 Runtime..."
if ! dotnet --list-runtimes | grep -q "Microsoft.AspNetCore.App 10"; then
    echo ".NET 10 ASP.NET Core Runtime not found."
    echo "Installing .NET 10..."
    
    # Detect distribution
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        apt-get update
        apt-get install -y aspnetcore-runtime-10.0
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora
        dnf install -y aspnetcore-runtime-10.0
    else
        echo "Unsupported distribution. Please install .NET 10 manually:"
        echo "https://dotnet.microsoft.com/download/dotnet/10.0"
        exit 1
    fi
fi
echo ".NET 10 Runtime found!"

# Create service user
echo ""
echo "Creating service user: $SERVICE_USER"
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

# Create installation directories
echo ""
echo "Creating installation directory: $INSTALL_PATH"
mkdir -p "$INSTALL_PATH/api"
mkdir -p "$INSTALL_PATH/webui"
mkdir -p "$INSTALL_PATH/logs"
mkdir -p "$INSTALL_PATH/data/worlds"
mkdir -p "$INSTALL_PATH/data/backups"

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -f "$SOLUTION_DIR/MCBDSHost.slnx" ]; then
    SOLUTION_DIR="$(pwd)"
fi

echo "Solution directory: $SOLUTION_DIR"

# Build and publish the API
echo ""
echo "Building MCBDS.API..."
cd "$SOLUTION_DIR"
dotnet publish "MCBDS.API/MCBDS.API.csproj" -c Release -o "$INSTALL_PATH/api" --self-contained false

# Build and publish the Web UI
echo ""
echo "Building MCBDS.ClientUI.Web..."
dotnet publish "MCBDS.ClientUI/MCBDS.ClientUI.Web/MCBDS.ClientUI.Web.csproj" -c Release -o "$INSTALL_PATH/webui" --self-contained false

# Create production configuration for API
echo ""
echo "Configuring production settings..."

cat > "$INSTALL_PATH/api/appsettings.Production.json" << EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:$API_PORT"
      }
    }
  }
}
EOF

# Create production configuration for Web UI
cat > "$INSTALL_PATH/webui/appsettings.Production.json" << EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ApiSettings": {
    "BaseUrl": "http://localhost:$API_PORT"
  },
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:$WEBUI_PORT"
      }
    }
  }
}
EOF

# Set ownership
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_PATH"

# Create systemd service for API
echo ""
echo "Creating systemd services..."

cat > /etc/systemd/system/mcbdshost-api.service << EOF
[Unit]
Description=MCBDSHost API Server
Documentation=https://github.com/JoshuaBylotas/MCBDSHost
After=network.target

[Service]
Type=notify
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_PATH/api
ExecStart=/usr/bin/dotnet $INSTALL_PATH/api/MCBDS.API.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=mcbdshost-api
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Web UI
cat > /etc/systemd/system/mcbdshost-webui.service << EOF
[Unit]
Description=MCBDSHost Web UI
Documentation=https://github.com/JoshuaBylotas/MCBDSHost
After=network.target mcbdshost-api.service
Requires=mcbdshost-api.service

[Service]
Type=notify
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_PATH/webui
ExecStart=/usr/bin/dotnet $INSTALL_PATH/webui/MCBDS.ClientUI.Web.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=mcbdshost-webui
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo ""
    echo "Configuring UFW firewall..."
    ufw allow $API_PORT/tcp comment 'MCBDSHost API'
    ufw allow $WEBUI_PORT/tcp comment 'MCBDSHost WebUI'
    ufw allow 19132/udp comment 'Minecraft Bedrock IPv4'
    ufw allow 19133/udp comment 'Minecraft Bedrock IPv6'
fi

# Configure firewall (if firewalld is installed)
if command -v firewall-cmd &> /dev/null; then
    echo ""
    echo "Configuring firewalld..."
    firewall-cmd --permanent --add-port=$API_PORT/tcp
    firewall-cmd --permanent --add-port=$WEBUI_PORT/tcp
    firewall-cmd --permanent --add-port=19132/udp
    firewall-cmd --permanent --add-port=19133/udp
    firewall-cmd --reload
fi

# Enable and start services
echo ""
echo "Starting services..."
systemctl enable mcbdshost-api
systemctl enable mcbdshost-webui
systemctl start mcbdshost-api
sleep 5
systemctl start mcbdshost-webui

echo ""
echo "============================================"
echo "Deployment Complete!"
echo "============================================"
echo ""
echo "Services installed at: $INSTALL_PATH"
echo ""
echo "Access URLs:"
echo "  Web UI:     http://localhost:$WEBUI_PORT"
echo "  API:        http://localhost:$API_PORT"
echo "  Minecraft:  Connect to port 19132"
echo ""
echo "Service Management:"
echo "  Status:  systemctl status mcbdshost-api mcbdshost-webui"
echo "  Start:   systemctl start mcbdshost-api mcbdshost-webui"
echo "  Stop:    systemctl stop mcbdshost-webui mcbdshost-api"
echo "  Logs:    journalctl -u mcbdshost-api -f"
echo "           journalctl -u mcbdshost-webui -f"

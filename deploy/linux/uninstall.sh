#!/bin/bash
# MCBDSHost Uninstall Script
# Run as root or with sudo

set -e

INSTALL_PATH="${1:-/opt/mcbdshost}"
SERVICE_USER="mcbdshost"

echo "============================================"
echo "MCBDSHost Uninstall"
echo "============================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo ""
read -p "This will remove MCBDSHost and all data. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop and disable services
echo ""
echo "Stopping services..."
systemctl stop mcbdshost-webui 2>/dev/null || true
systemctl stop mcbdshost-api 2>/dev/null || true
systemctl disable mcbdshost-webui 2>/dev/null || true
systemctl disable mcbdshost-api 2>/dev/null || true

# Remove service files
echo "Removing service files..."
rm -f /etc/systemd/system/mcbdshost-api.service
rm -f /etc/systemd/system/mcbdshost-webui.service
systemctl daemon-reload

# Remove installation directory
echo "Removing installation directory..."
rm -rf "$INSTALL_PATH"

# Remove user (optional)
read -p "Remove service user '$SERVICE_USER'? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    userdel "$SERVICE_USER" 2>/dev/null || true
fi

echo ""
echo "============================================"
echo "Uninstall Complete!"
echo "============================================"

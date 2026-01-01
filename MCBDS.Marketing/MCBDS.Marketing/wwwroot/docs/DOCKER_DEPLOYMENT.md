# Docker Deployment Guide

This guide explains how to build and run the MCBDSHost solution as Docker containers.

## Overview

The solution consists of the following containerized services:

| Service | Description | Port |
|---------|-------------|------|
| `mcbds-api` | Minecraft Bedrock Dedicated Server API | 8080 (HTTP), 19132/udp, 19133/udp |
| `mcbds-clientui-web` | Blazor Web UI for server management | 5000 |

> **Note:** The MAUI apps (`MCBDS.PublicUI` and `MCBDS.ClientUI`) cannot be containerized as they run on mobile/desktop devices.

## Linux Server Deployment

### Option 1: Docker Compose (Recommended)

#### Install Docker on Ubuntu/Debian

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Logout and login again, then verify
docker --version

# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

#### Install Docker on RHEL/CentOS/Fedora

```bash
# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER
```

#### Deploy the Application

```bash
# Clone the repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Build and start all containers
docker compose up --build -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### Option 2: Systemd Services (No Docker)

Use the provided installation script:

```bash
# Clone the repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Make the script executable
chmod +x deploy/linux/install.sh

# Run the installation (as root)
sudo ./deploy/linux/install.sh

# Or with custom paths/ports
sudo ./deploy/linux/install.sh /opt/mcbdshost 8080 5000
```

#### Manage Services

```bash
# Check status
systemctl status mcbdshost-api mcbdshost-webui

# View logs
journalctl -u mcbdshost-api -f
journalctl -u mcbdshost-webui -f

# Restart services
sudo systemctl restart mcbdshost-api mcbdshost-webui

# Stop services
sudo systemctl stop mcbdshost-webui mcbdshost-api
```

#### Uninstall

```bash
chmod +x deploy/linux/uninstall.sh
sudo ./deploy/linux/uninstall.sh
```

## Windows Server Deployment

See `deploy/windows/install-service.ps1` for Windows deployment.

```powershell
# Run as Administrator
.\deploy\windows\install-service.ps1
```

## Prerequisites

- Docker Desktop or Docker Engine installed
- Docker Compose v2.0+

## Quick Start

### Build and Run All Services

```bash
# Build and start all containers
docker compose up --build

# Run in detached mode (background)
docker compose up --build -d
```

### Access the Services

- **Web UI**: http://localhost:5000
- **API**: http://localhost:8080
- **API Health Check**: http://localhost:8080/health
- **Minecraft Server**: Connect via `localhost:19132`

## Development

For development with hot reload and debug configuration:

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml up --build
```

## Production Deployment

### Build Production Images

```bash
# Build with production configuration
docker-compose build

# Tag images for registry
docker tag mcbdshost-mcbds-api:latest your-registry/mcbds-api:v1.0
docker tag mcbdshost-mcbds-clientui-web:latest your-registry/mcbds-clientui-web:v1.0

# Push to registry
docker push your-registry/mcbds-api:v1.0
docker push your-registry/mcbds-clientui-web:v1.0
```

### Environment Variables

#### mcbds-api

| Variable | Description | Default |
|----------|-------------|---------|
| `ASPNETCORE_ENVIRONMENT` | Runtime environment | `Production` |
| `ASPNETCORE_HTTP_PORTS` | HTTP port | `8080` |

#### mcbds-clientui-web

| Variable | Description | Default |
|----------|-------------|---------|
| `ASPNETCORE_ENVIRONMENT` | Runtime environment | `Production` |
| `ApiSettings__BaseUrl` | URL of the API service | `http://mcbds-api:8080` |

## Persistent Data

The following Docker volumes are used to persist data:

- `mcbds-worlds` - Minecraft world data
- `mcbds-config` - Server configuration files

### Backup Volumes

```bash
# Backup worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar czf /backup/worlds-backup.tar.gz /data

# Restore worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar xzf /backup/worlds-backup.tar.gz -C /
```

## Individual Container Commands

### Build Individual Images

```bash
# Build API image
docker build -t mcbds-api -f MCBDS.API/Dockerfile .

# Build Web UI image
docker build -t mcbds-clientui-web -f MCBDS.ClientUI/MCBDS.ClientUI.Web/Dockerfile .
```

### Run Individual Containers

```bash
# Run API
docker run -d -p 8080:8080 -p 19132:19132/udp -p 19133:19133/udp --name mcbds-api mcbds-api

# Run Web UI (after API is running)
docker run -d -p 5000:8080 -e ApiSettings__BaseUrl=http://host.docker.internal:8080 --name mcbds-clientui-web mcbds-clientui-web
```

## Troubleshooting

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mcbds-api
```

### Shell Access

```bash
# Access API container shell
docker-compose exec mcbds-api /bin/bash

# Access Web UI container shell
docker-compose exec mcbds-clientui-web /bin/bash
```

### Rebuild Without Cache

```bash
docker-compose build --no-cache
docker-compose up
```

## Stopping Services

```bash
# Stop and remove containers
docker-compose down

# Stop, remove containers, and delete volumes (WARNING: deletes world data!)
docker-compose down -v

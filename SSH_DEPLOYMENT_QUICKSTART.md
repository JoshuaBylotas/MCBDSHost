# SSH Deployment Quick Start Guide

## ? Problem Solved
The large bedrock-server binary files have been removed from Git history. Your repository is now ready to push to GitHub without errors.

## ?? Deploy to Linux Server via SSH

### Step 1: Connect to Your Server
```bash
ssh username@your-server-ip
```

### Step 2: Install Docker (One-Time Setup)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Log out and back in
exit
```

### Step 3: Clone and Deploy
```bash
# Reconnect to server
ssh username@your-server-ip

# Clone your repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# Download Minecraft Bedrock Server (REQUIRED)
cd MCBDS.API/bedrock-server
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.44.01.zip
unzip bedrock-server-*.zip
chmod +x bedrock_server
cd ../..

# Build and start containers
docker compose up --build -d
```

### Step 4: Configure Firewall
```bash
# Allow required ports
sudo ufw allow 5000/tcp   # WebUI
sudo ufw allow 8080/tcp   # API
sudo ufw allow 19132/udp  # Minecraft IPv4
sudo ufw allow 19133/udp  # Minecraft IPv6
sudo ufw allow 22/tcp     # SSH (important!)
sudo ufw enable
```

### Step 5: Access Your Services
- **Web UI**: http://your-server-ip:5000
- **API**: http://your-server-ip:8080
- **Minecraft Server**: your-server-ip:19132

## ?? Management Commands

### View Logs
```bash
docker compose logs -f                  # All services
docker compose logs -f mcbds-api        # API only
docker compose logs -f mcbds-clientui-web  # Web UI only
```

### Restart Services
```bash
docker compose restart
```

### Stop Services
```bash
docker compose down
```

### Update Deployment
```bash
cd ~/MCBDSHost
git pull origin master
docker compose down
docker compose up --build -d
```

### Backup World Data
```bash
docker run --rm \
  -v mcbdshost-mcbds-worlds:/data \
  -v ~/backups:/backup \
  alpine tar czf /backup/worlds-$(date +%Y%m%d-%H%M%S).tar.gz /data
```

## ?? Important Notes

1. **Bedrock Server Files Not Included**: You must download them separately (see Step 3)
2. **Firewall**: Ensure ports 5000, 8080, 19132, and 19133 are open
3. **SSH Access**: Always keep port 22 open to maintain SSH access
4. **Docker Volumes**: World data persists in Docker volumes `mcbdshost-mcbds-worlds`

## ?? Troubleshooting

### Container won't start
```bash
docker compose ps            # Check status
docker compose logs -f       # View errors
```

### Port already in use
```bash
sudo lsof -i :5000           # Check what's using port 5000
sudo lsof -i :8080           # Check what's using port 8080
```

### Reset everything
```bash
docker compose down -v       # WARNING: Deletes all data including worlds!
docker compose up --build -d
```

## ?? Full Documentation

See `DOCKER_DEPLOYMENT.md` for complete deployment options including:
- Systemd service installation (no Docker)
- Windows Server deployment
- Production configuration
- Volume management
- Security best practices

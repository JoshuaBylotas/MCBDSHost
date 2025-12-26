# SSH Deployment Quick Start Guide

## ? Problem Solved
The large bedrock-server binary files have been removed from Git history. Your repository is now ready to push to GitHub without errors.

## ?? GitHub Authentication (Required First)

GitHub no longer accepts passwords for Git operations. You need a **Personal Access Token**.

### Option 1: Use Personal Access Token (Quick)

1. **Create Token**: Go to https://github.com/settings/tokens
2. Click **"Generate new token"** ? **"Generate new token (classic)"**
3. Settings:
   - Name: `Linux Server Deployment`
   - Expiration: `90 days` (or custom)
   - Scopes: ? **repo** (Full control of private repositories)
4. Click **"Generate token"**
5. **COPY THE TOKEN** - you won't see it again!

6. **Clone with token**:
```bash
# When prompted for username: JoshuaBylotas
# When prompted for password: paste your token
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
```

### Option 2: Use SSH Keys (Most Secure - Recommended)

```bash
# Generate SSH key on your server
ssh-keygen -t ed25519 -C "your-email@example.com"
# Press Enter 3 times (default location, no passphrase)

# Display public key
cat ~/.ssh/id_ed25519.pub
```

1. Copy the entire output
2. Go to https://github.com/settings/keys
3. Click **"New SSH key"**
4. Title: `Linux Server`
5. Paste the key and click **"Add SSH key"**

6. **Clone with SSH**:
```bash
git clone git@github.com:JoshuaBylotas/MCBDSHost.git
```

### Option 3: Make Repository Public (No Auth Required)

If this is open-source:
1. Go to https://github.com/JoshuaBylotas/MCBDSHost/settings
2. Scroll to "Danger Zone" ? "Change visibility"
3. Click "Make public"

Then clone without authentication:
```bash
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
```

---

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

# Clone your repository (use ONE of the methods from GitHub Authentication section above)
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
# OR
git clone git@github.com:JoshuaBylotas/MCBDSHost.git

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
5. **GitHub Token**: Store your Personal Access Token securely - it's like a password!

## ?? Troubleshooting

### Authentication Failed (403 Error)
```bash
# Your Personal Access Token needs 'repo' scope
# Create a new token at: https://github.com/settings/tokens
# Make sure to check the 'repo' checkbox when creating it
```

### Permission Denied - Docker Socket Error
```bash
# After adding user to docker group, you MUST log out and back in
exit

# Then reconnect to your server
ssh username@your-server-ip

# Verify you're in the docker group
groups

# You should see 'docker' in the list
# Now try again
cd ~/MCBDSHost
docker compose up --build -d
```

**Alternative quick fix (without logging out):**
```bash
# Use newgrp to activate the docker group in current session
newgrp docker

# Now run docker compose
cd ~/MCBDSHost
docker compose up --build -d
```

**If still having issues, run with sudo (temporary solution):**
```bash
sudo docker compose up --build -d
```

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

---Token
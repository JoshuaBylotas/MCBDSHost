# Raspberry Pi Deployment Guide

## Important: ARM Architecture Considerations

Raspberry Pi uses **ARM64** architecture, not x86_64. The standard Minecraft Bedrock Dedicated Server from Minecraft.net is **NOT compatible** with Raspberry Pi.

## Solution Options

### Option 1: Use Docker with ARM64 Images (Recommended)

The Dockerfile has been updated to use ARM64-compatible .NET images. However, you'll need an ARM-compatible Minecraft server.

#### Using Box64 to Run x86_64 Server on ARM

```bash
# Install Box64 on Raspberry Pi
sudo apt update
sudo apt install -y cmake git build-essential

# Clone and build Box64
git clone https://github.com/ptitSeb/box64
cd box64
mkdir build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
sudo make install

# Download x86_64 Bedrock Server
cd ~/MCBDSHost/MCBDS.API/bedrock-server
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.44.01.zip
unzip bedrock-server-*.zip

# Update the executable path to use Box64
# Edit appsettings.json:
# "ExePath": "box64 /app/Binaries/bedrock_server"
```

### Option 2: Use PocketMine-MP (Pure PHP - Native ARM Support)

PocketMine-MP is a Minecraft Bedrock server written in PHP that runs natively on ARM:

```bash
# Install dependencies
sudo apt update
sudo apt install -y php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl unzip

# Download PocketMine-MP
cd ~/MCBDSHost/MCBDS.API/bedrock-server
wget https://github.com/pmmp/PocketMine-MP/releases/download/5.11.2/PocketMine-MP.phar
chmod +x PocketMine-MP.phar

# Update appsettings.json:
# "ExePath": "php /app/Binaries/PocketMine-MP.phar"
```

### Option 3: Use Nukkit (Java - Native ARM Support)

Nukkit is a Java-based Minecraft Bedrock server:

```bash
# Install Java
sudo apt update
sudo apt install -y openjdk-17-jre-headless

# Download Nukkit
cd ~/MCBDSHost/MCBDS.API/bedrock-server
wget https://ci.opencollab.dev/job/NukkitX/job/Nukkit/job/master/lastSuccessfulBuild/artifact/target/nukkit-1.0-SNAPSHOT.jar
mv nukkit-1.0-SNAPSHOT.jar nukkit.jar

# Update appsettings.json:
# "ExePath": "java -jar /app/Binaries/nukkit.jar"
```

## Recommended Approach for Raspberry Pi

**Use Box64 with the official Bedrock server** for best compatibility:

### Complete Setup Instructions

```bash
# 1. On your Raspberry Pi, install Box64
sudo apt update
sudo apt install -y cmake git build-essential
git clone https://github.com/ptitSeb/box64
cd box64
mkdir build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
sudo make install
cd ~

# 2. Clone repository
git clone https://github.com/JoshuaBylotas/MCBDSHost.git
cd MCBDSHost

# 3. Download Bedrock Server (x86_64 version)
cd MCBDS.API/bedrock-server
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.44.01.zip
unzip bedrock-server-*.zip
chmod +x bedrock_server
cd ../..

# 4. Update configuration for Box64
cat > MCBDS.API/appsettings.Production.json << 'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Runner": {
    "ExePath": "box64",
    "Arguments": "/app/Binaries/bedrock_server",
    "LogFilePath": "/app/logs/runner.log"
  },
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "/app/backups",
    "MaxBackupsToKeep": 30
  }
}
EOF

# 5. Install Docker (ARM64 version)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt-get install docker-compose-plugin

# 6. Log out and back in, then build
newgrp docker
docker compose build --no-cache
docker compose up -d
```

## Performance Considerations

- **Raspberry Pi 4 (4GB+ RAM)**: Can run small servers (2-5 players)
- **Raspberry Pi 5**: Better performance, can handle 5-10 players
- **Raspberry Pi 3 or older**: May struggle with performance

## Troubleshooting

### Error: "Exec format error"
This means you're trying to run x86_64 binary on ARM without Box64.

**Solution**: Install Box64 or use a native ARM server (PocketMine-MP/Nukkit)

### Performance Issues
- Lower `view-distance` in `server.properties` to 4-6 chunks
- Reduce `max-players` to 5 or fewer
- Ensure adequate cooling for Raspberry Pi
- Use a fast SD card or USB SSD

### Memory Issues
```bash
# Check available memory
free -h

# If low, add swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Alternative: Run Without Docker (Native)

If Docker performance is poor on Raspberry Pi:

```bash
# Use the systemd installation script
cd ~/MCBDSHost
chmod +x deploy/linux/install.sh
sudo ./deploy/linux/install.sh

# But first, install Box64 and update the config to use it
```

## Recommended Configuration

For best performance on Raspberry Pi, edit `server.properties`:

```properties
view-distance=4
tick-distance=4
max-players=5
simulation-distance=4
server-authoritative-movement=server-auth-with-rewind
server-authoritative-block-breaking=true
```

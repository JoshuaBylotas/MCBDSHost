# ?? Quick Start: Update Your Running Docker Deployment

## The Fastest Way to Update

### Linux/Mac (One Command)
```bash
cd /path/to/MCBDSHost && ./update-deployment.sh --force
```

### Windows (One Command)
```powershell
cd C:\path\to\MCBDSHost; .\Update-Deployment.ps1 -Force
```

That's it! The script will:
1. ? Back up your worlds and config
2. ? Pull latest code from GitHub
3. ? Rebuild Docker containers
4. ? Restart services
5. ? Verify everything is healthy

---

## What You Need

- Access to the server (SSH, RDP, or physical)
- Git repository cloned at `/path/to/MCBDSHost`
- Docker and Docker Compose installed
- Running containers from previous deployment

---

## Step-by-Step (If You Prefer)

### 1?? Connect to Your Server

**Linux:**
```bash
ssh username@your-server-ip
```

**Windows:**
- Use Remote Desktop Connection
- Connect to your server

### 2?? Navigate to Repository

```bash
cd /path/to/MCBDSHost
```

Common locations:
- `/home/username/MCBDSHost` (Linux)
- `C:\Users\username\MCBDSHost` (Windows)
- `/opt/MCBDSHost` (Linux server)

### 3?? Run Update Script

**With prompts (safer):**
```bash
./update-deployment.sh          # Linux/Mac
.\Update-Deployment.ps1          # Windows
```

**Without prompts (faster):**
```bash
./update-deployment.sh --force   # Linux/Mac
.\Update-Deployment.ps1 -Force   # Windows
```

### 4?? Verify It Worked

```bash
# Check containers are running
docker compose ps

# Test API health
curl http://localhost:8080/health

# View logs
docker compose logs --tail=50
```

---

## Alternative: Manual 3-Step Update

If you want full control:

```bash
# Step 1: Pull latest code
git pull origin master

# Step 2: Rebuild and restart
docker compose down
docker compose up -d --build

# Step 3: Verify
docker compose ps
curl http://localhost:8080/health
```

---

## What If Something Goes Wrong?

### View Logs
```bash
docker compose logs -f
```

### Rollback
```bash
# Stop containers
docker compose down

# Go back to previous version
git log --oneline
git checkout <previous-commit-hash>

# Rebuild
docker compose up -d --build
```

### Restore Backup
```bash
# Find your backup
ls -lh backups/

# Restore worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar xzf /backup/worlds-backup-YYYYMMDD.tar.gz -C /
```

---

## Understanding the Update Process

### What Gets Updated ?
- API code (MCBDS.API)
- Web UI code (MCBDS.ClientUI.Web)
- Dependencies and packages
- Docker images

### What Stays Safe ?
- World saves (in Docker volumes)
- Player data
- Configuration changes you made
- Backup files

### Downtime
- Typical: 30-60 seconds
- Depends on: Server speed, image size, internet connection

---

## Troubleshooting

### "Script not found"
```bash
# Make script executable
chmod +x update-deployment.sh
```

### "Permission denied"
```bash
# Run with sudo if needed
sudo ./update-deployment.sh --force
```

### "Git has local changes"
```bash
# Stash changes first
git stash
./update-deployment.sh --force
```

### "Port already in use"
```bash
# Something else is using the ports
docker compose down
# Wait 10 seconds
docker compose up -d
```

### "Cannot connect to Docker"
```bash
# Start Docker service
sudo systemctl start docker      # Linux
# Or start Docker Desktop (Windows/Mac)
```

---

## Pro Tips

### Schedule Automatic Updates

**Linux (Cron):**
```bash
# Edit crontab
crontab -e

# Add daily update at 3 AM
0 3 * * * cd /path/to/MCBDSHost && ./update-deployment.sh --force >> /var/log/mcbdshost-update.log 2>&1
```

**Windows (Task Scheduler):**
```powershell
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File C:\path\to\MCBDSHost\Update-Deployment.ps1 -Force'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "MCBDSHost Update"
```

### Check for Updates Without Installing
```bash
git fetch origin master
git log HEAD..origin/master --oneline
```

### Update Logs
All updates are logged to: `update-YYYYMMDD-HHMMSS.log`

```bash
# View latest update log
cat update-*.log | tail -100
```

---

## More Help

- **Full Guide**: [UPDATE_DEPLOYMENT.md](UPDATE_DEPLOYMENT.md)
- **Docker Guide**: [DOCKER_DEPLOYMENT.md](MCBDS.Marketing/wwwroot/docs/DOCKER_DEPLOYMENT.md)
- **Quick Reference**: [QUICK_UPDATE_GUIDE.md](QUICK_UPDATE_GUIDE.md)

---

## Support

If you need help:
1. Check the logs: `docker compose logs`
2. Check update log: `cat update-*.log`
3. Open an issue on GitHub with logs attached
4. Join our community Discord (if available)

---

**Remember**: Always back up before updating! The scripts do this automatically, but manual backups never hurt.

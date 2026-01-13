# Quick Reference: Update Docker Deployment

## One-Line Updates

### Linux/Mac
```bash
cd /path/to/MCBDSHost && ./update-deployment.sh --force
```

### Windows (PowerShell)
```powershell
cd C:\path\to\MCBDSHost; .\Update-Deployment.ps1 -Force
```

---

## Update Scripts

Two automated scripts are provided:

| Script | Platform | Location |
|--------|----------|----------|
| `update-deployment.sh` | Linux/Mac | Root of repository |
| `Update-Deployment.ps1` | Windows | Root of repository |

### Features

? Automatic backup of worlds and configuration  
? Git pull from origin/master  
? Docker container rebuild  
? Health checks  
? Rollback capability  
? Logging of all operations  

### Usage

#### Linux/Mac

```bash
# Standard update (with prompts)
./update-deployment.sh

# Forced update (no prompts)
./update-deployment.sh --force

# Update without backup (not recommended)
./update-deployment.sh --force --no-backup

# Show help
./update-deployment.sh --help
```

#### Windows

```powershell
# Standard update (with prompts)
.\Update-Deployment.ps1

# Forced update (no prompts)
.\Update-Deployment.ps1 -Force

# Update without backup (not recommended)
.\Update-Deployment.ps1 -Force -NoBackup

# Show help
Get-Help .\Update-Deployment.ps1 -Full
```

---

## Manual Update (3 Steps)

If you prefer manual control:

```bash
# 1. Pull latest code
git pull origin master

# 2. Rebuild and restart containers
docker compose down && docker compose up -d --build

# 3. Verify
docker compose ps && curl http://localhost:8080/health
```

---

## What Gets Updated

When you run the update scripts:

1. **API Code** - All changes to MCBDS.API
2. **Web UI** - All changes to MCBDS.ClientUI.Web
3. **Dependencies** - Updated NuGet packages
4. **Docker Images** - Rebuilt with latest code
5. **Configuration** - New appsettings (merged with existing)

### What Persists (Not Lost)

? World saves (stored in Docker volumes)  
? Backups (stored in Docker volumes)  
? Server configuration (appsettings.json changes)  
? Player data  

---

## Before You Update

### Check What's New

```bash
# View commits since your last update
git fetch origin master
git log HEAD..origin/master --oneline

# See detailed changes
git diff HEAD..origin/master
```

### Verify Current Status

```bash
# Check running containers
docker compose ps

# Check logs for errors
docker compose logs --tail=50

# Test API health
curl http://localhost:8080/health
```

---

## After Update

### Verify Everything Works

```bash
# 1. Check container status
docker compose ps

# 2. Check API health
curl http://localhost:8080/health

# 3. Check recent logs
docker compose logs --tail=50

# 4. Test Minecraft connection
# Connect using your Minecraft client to localhost:19132
```

### Common Post-Update Tasks

```bash
# View API logs
docker compose logs -f mcbds-api

# View Web UI logs
docker compose logs -f mcbds-clientui-web

# Restart specific service
docker compose restart mcbds-api

# Access container shell
docker compose exec mcbds-api bash
```

---

## Troubleshooting

### Update Failed

```bash
# View update log
cat update-*.log

# Check Docker logs
docker compose logs

# Rollback to previous version
git log --oneline
git checkout <previous-commit-hash>
docker compose down && docker compose up -d --build
```

### Containers Won't Start

```bash
# Rebuild without cache
docker compose build --no-cache

# Remove old containers and images
docker compose down -v
docker system prune -a

# Rebuild from scratch
docker compose up -d --build
```

### Port Conflicts

```bash
# Find what's using the port
sudo lsof -i :8080
# Or on Windows: netstat -ano | findstr :8080

# Change ports in docker-compose.yml
# Or stop the conflicting process
```

---

## Scheduled Updates

### Cron (Linux)

```bash
# Edit crontab
crontab -e

# Add line for daily 3 AM update
0 3 * * * cd /path/to/MCBDSHost && ./update-deployment.sh --force >> /var/log/mcbdshost-update.log 2>&1
```

### Task Scheduler (Windows)

```powershell
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File C:\path\to\MCBDSHost\Update-Deployment.ps1 -Force'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "MCBDSHost Update"
```

---

## Backup Management

### Manual Backup Before Update

```bash
# Backup worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar czf /backup/worlds-backup-$(date +%Y%m%d).tar.gz /data

# Backup config
docker run --rm -v mcbds-config:/data -v $(pwd):/backup alpine tar czf /backup/config-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore from Backup

```bash
# Restore worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar xzf /backup/worlds-backup-YYYYMMDD.tar.gz -C /

# Restore config
docker run --rm -v mcbds-config:/data -v $(pwd):/backup alpine tar xzf /backup/config-backup-YYYYMMDD.tar.gz -C /
```

---

## Getting Help

- **Detailed Guide**: See `UPDATE_DEPLOYMENT.md`
- **Docker Guide**: See `MCBDS.Marketing/wwwroot/docs/DOCKER_DEPLOYMENT.md`
- **Logs**: Check `update-*.log` files in the repository root
- **Docker Logs**: Run `docker compose logs -f`

---

## Emergency Rollback

If something goes wrong:

```bash
# 1. Stop containers
docker compose down

# 2. Revert code
git log --oneline
git reset --hard <last-working-commit>

# 3. Restore backup (if needed)
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar xzf /backup/worlds-backup-YYYYMMDD.tar.gz -C /

# 4. Rebuild and start
docker compose up -d --build
```

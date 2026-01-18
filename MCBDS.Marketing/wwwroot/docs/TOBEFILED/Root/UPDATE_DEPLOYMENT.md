# How to Update API Code on Running Docker Deployment

This guide explains how to update your running Docker deployment with the latest code from GitHub.

## Quick Update Commands

### For Linux Server (Docker Compose)

```bash
# Navigate to your deployment directory
cd /path/to/MCBDSHost

# Run the update script
./update-deployment.sh
```

### For Windows Server (Docker Compose)

```powershell
# Navigate to your deployment directory
cd C:\path\to\MCBDSHost

# Run the update script
.\Update-Deployment.ps1
```

---

## Manual Update Steps

If you prefer to update manually or troubleshoot issues, follow these steps:

### Linux Server Manual Update

```bash
# 1. Navigate to your deployment directory
cd /path/to/MCBDSHost

# 2. Pull the latest code from GitHub
git pull origin master

# 3. Stop the running containers
docker compose down

# 4. Rebuild the containers with the new code
docker compose build --no-cache

# 5. Start the updated containers
docker compose up -d

# 6. Verify the containers are running
docker compose ps

# 7. View logs to ensure everything started correctly
docker compose logs -f
```

### Windows Server Manual Update

```powershell
# 1. Navigate to your deployment directory
cd C:\path\to\MCBDSHost

# 2. Pull the latest code from GitHub
git pull origin master

# 3. Stop the running containers
docker compose down

# 4. Rebuild the containers with the new code
docker compose build --no-cache

# 5. Start the updated containers
docker compose up -d

# 6. Verify the containers are running
docker compose ps

# 7. View logs to ensure everything started correctly
docker compose logs -f
```

---

## Zero-Downtime Update (Advanced)

For production environments where you need minimal downtime:

### Using Blue-Green Deployment

```bash
# 1. Pull latest code
git pull origin master

# 2. Build new images with a version tag
docker compose build
docker tag mcbdshost-mcbds-api:latest mcbdshost-mcbds-api:new
docker tag mcbdshost-mcbds-clientui-web:latest mcbdshost-mcbds-clientui-web:new

# 3. Start new containers alongside old ones (using different ports temporarily)
# Modify docker-compose.yml to use different ports, then:
docker compose -p mcbdshost-new up -d

# 4. Test the new deployment
curl http://localhost:8081/health  # Assuming you mapped to 8081

# 5. Switch traffic to new containers
# Update your reverse proxy/load balancer to point to new ports

# 6. Stop old containers
docker compose -p mcbdshost down

# 7. Update ports back to normal and restart
docker compose up -d
```

---

## Important Notes

### Before Updating

1. **Backup Your Data** - World saves, configurations, and backups are stored in Docker volumes. Create a backup before updating:

```bash
# Backup worlds
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar czf /backup/worlds-backup-$(date +%Y%m%d).tar.gz /data

# Backup config
docker run --rm -v mcbds-config:/data -v $(pwd):/backup alpine tar czf /backup/config-backup-$(date +%Y%m%d).tar.gz /data
```

2. **Check for Breaking Changes** - Review the commit history or release notes for any breaking changes:

```bash
git log --oneline origin/master..HEAD
```

3. **Notify Users** - If you have active players, notify them before taking the server down.

### After Updating

1. **Verify Health** - Check that the API is responding:

```bash
curl http://localhost:8080/health
```

2. **Test Minecraft Connection** - Try connecting to the Minecraft server to ensure it's working.

3. **Check Logs** - Monitor logs for any errors:

```bash
docker compose logs -f mcbds-api
```

---

## Troubleshooting

### Issue: Git Pull Fails with Local Changes

```bash
# Stash your local changes
git stash

# Pull the latest code
git pull origin master

# Optionally reapply your changes
git stash pop
```

### Issue: Container Won't Start After Update

```bash
# View detailed logs
docker compose logs mcbds-api

# Check container status
docker compose ps

# Try rebuilding without cache
docker compose build --no-cache mcbds-api
docker compose up -d mcbds-api
```

### Issue: "Port Already in Use"

```bash
# Find what's using the port
sudo lsof -i :8080

# Or on Windows
netstat -ano | findstr :8080

# Stop the conflicting process or use different ports in docker-compose.yml
```

### Issue: Database/Config Migration Needed

If the update includes database schema changes or configuration updates:

```bash
# Run migrations (if applicable)
docker compose exec mcbds-api dotnet ef database update

# Check appsettings.json for new required configuration
```

---

## Rollback Procedure

If the update causes issues, you can rollback:

```bash
# 1. Stop the containers
docker compose down

# 2. Revert to previous code version
git log --oneline  # Find the commit hash you want to revert to
git checkout <previous-commit-hash>

# 3. Rebuild and restart
docker compose build --no-cache
docker compose up -d

# 4. Optionally restore data from backup
docker run --rm -v mcbds-worlds:/data -v $(pwd):/backup alpine tar xzf /backup/worlds-backup-YYYYMMDD.tar.gz -C /
```

---

## Automated Update Scheduling

### Linux (Cron Job)

```bash
# Edit crontab
crontab -e

# Add this line to update daily at 3 AM
0 3 * * * cd /path/to/MCBDSHost && ./update-deployment.sh >> /var/log/mcbdshost-update.log 2>&1
```

### Windows (Task Scheduler)

```powershell
# Create a scheduled task
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File C:\path\to\MCBDSHost\Update-Deployment.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "MCBDSHost Update" -Description "Update MCBDSHost deployment daily"
```

---

## Support

If you encounter issues during the update process:

1. Check the logs: `docker compose logs -f`
2. Review the GitHub repository for recent issues
3. Restore from backup if necessary
4. Contact support with log files and error messages

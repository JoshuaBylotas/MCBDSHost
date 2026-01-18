# Backup Service Quick Start

## Setup (5 Minutes)

### 1. Configure Backup Settings

Edit `appsettings.json`:

```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\Backups\\Minecraft",
    "MaxBackupsToKeep": 10
  }
}
```

### 2. Create Backup Directory

```powershell
# Windows
mkdir C:\Backups\Minecraft

# Linux/Docker
mkdir -p /backups/minecraft
```

### 3. Start the API

The backup service starts automatically when the API starts.

```bash
dotnet run --project MCBDS.API
```

## Verify It's Working

### Check Logs

Look for these messages in the console:

```
[BackupHostedService] BackupHostedService started
[BackupHostedService] Backup directory: C:\Backups\Minecraft
[BackupHostedService] Backup frequency set to 30 minutes
```

### Wait for First Backup

After the configured frequency (e.g., 30 minutes), you'll see:

```
[BackupHostedService] Starting backup process...
[BackupHostedService] Backup completed. Copied 42 files to C:\Backups\Minecraft\backup_2025-01-15_14-30-00
```

## Test Backup Manually

### List Existing Backups

```http
GET http://localhost:5000/api/backup/list
```

### Check Configuration

```http
GET http://localhost:5000/api/backup/config
```

## Common Settings

### Every 15 Minutes (Frequent)
```json
"FrequencyMinutes": 15
```

### Every Hour
```json
"FrequencyMinutes": 60
```

### Every 2 Hours
```json
"FrequencyMinutes": 120
```

### Keep More Backups
```json
"MaxBackupsToKeep": 20
```

### Keep All Backups (No Deletion)
```json
"MaxBackupsToKeep": 0
```

## Backup Directory Examples

### Windows
```json
"BackupDirectory": "C:\\Backups\\Minecraft"
"BackupDirectory": "D:\\ServerBackups\\MCBDS"
```

### Linux
```json
"BackupDirectory": "/var/backups/minecraft"
"BackupDirectory": "/home/user/backups"
```

### Docker
```json
"BackupDirectory": "/backups"
```

Then mount a volume:
```yaml
volumes:
  - ./backups:/backups
```

## Troubleshooting

### Service Not Starting

**Check logs for:**
```
"Backup directory not configured"
"Invalid backup frequency"
```

**Solution:** Verify appsettings.json has valid Backup section.

### Backups Not Creating

**Check:**
1. Directory exists and has write permissions
2. Server is running (backups need the Bedrock server)
3. Wait for the full frequency duration
4. Check disk space

### Finding Backups

Backups are timestamped folders:
```
backup_2025-01-15_14-30-00/
backup_2025-01-15_15-00-00/
backup_2025-01-15_15-30-00/
```

Format: `backup_YYYY-MM-DD_HH-mm-ss`

## Backup File Structure

Each backup contains:
```
backup_2025-01-15_14-30-00/
??? level/
?   ??? db/              (LevelDB files)
?   ??? level.dat        (World data)
?   ??? level.dat_old    (Previous world data)
?   ??? levelname.txt    (World name)
```

## Restoring from Backup

1. Stop the Bedrock server
2. Navigate to the server's worlds directory
3. Backup the current world (just in case)
4. Copy files from backup directory to worlds/Bedrock level/
5. Restart the server

```powershell
# Example restoration (Windows)
Stop-Service BedrockServer
Copy-Item "C:\Backups\Minecraft\backup_2025-01-15_14-30-00\level\*" -Destination "C:\BedrockServer\worlds\Bedrock level\" -Recurse -Force
Start-Service BedrockServer
```

## Integration with UI

The PublicUI has a Backup Settings page that stores settings locally. To keep them in sync:

1. **Option A**: Manually update both locations
2. **Option B**: Add API endpoint to update appsettings.json (future enhancement)
3. **Option C**: Use environment variables for Docker deployments

## Production Checklist

- [ ] Backup directory created with proper permissions
- [ ] FrequencyMinutes set appropriately for server size
- [ ] MaxBackupsToKeep configured for available disk space
- [ ] Tested backup and restore process
- [ ] Monitoring/alerts configured for backup failures
- [ ] Disk space monitoring enabled
- [ ] Backup directory on separate disk (recommended)

## Quick Reference

| Action | Command/URL |
|--------|-------------|
| View configuration | `GET /api/backup/config` |
| List backups | `GET /api/backup/list` |
| Delete backup | `DELETE /api/backup/{name}` |
| Check logs | View API console output |
| Force backup | Restart API (triggers after 30s + frequency) |

## Need Help?

Check the full documentation: `BACKUP_SERVICE_DOCUMENTATION.md`

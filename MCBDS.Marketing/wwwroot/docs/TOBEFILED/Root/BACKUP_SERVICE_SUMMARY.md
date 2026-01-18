# Backup Service Implementation Summary

## ? What Was Created

### Core Components

1. **BackupConfiguration Model** (`MCBDS.API\Models\BackupConfiguration.cs`)
   - `FrequencyMinutes` - Backup interval
   - `BackupDirectory` - Where backups are stored
   - `MaxBackupsToKeep` - Retention policy

2. **BackupHostedService** (`MCBDS.API\Background\BackupHostedService.cs`)
   - Background service running on a timer
   - Executes Minecraft backup commands
   - Parses file lists from server responses
   - Copies files to timestamped directories
   - Manages backup retention

3. **BackupController** (`MCBDS.API\Controllers\BackupController.cs`)
   - `GET /api/backup/config` - View configuration
   - `GET /api/backup/list` - List all backups
   - `DELETE /api/backup/{name}` - Delete specific backup

### Configuration

4. **appsettings.json** - Updated with backup settings
5. **Program.cs** - Registered services in DI container

### Documentation

6. **BACKUP_SERVICE_DOCUMENTATION.md** - Complete technical documentation
7. **BACKUP_QUICK_START.md** - Quick setup guide

## ?? Backup Process Flow

```
Timer Triggers
    ?
Send "save hold"
    ?
Wait 2 seconds
    ?
Send "save query"
    ?
Parse file list from response
    ?
Create timestamped backup directory
    ?
Copy each file
    ?
Send "save resume"
    ?
Clean up old backups
    ?
Wait for next interval
```

## ?? Minecraft Commands Used

1. **`save hold`** - Pauses world saving
   ```
   Response: [INFO] Saving...
   ```

2. **`save query`** - Lists files to backup
   ```
   Response: [INFO] Data saved. Files are now ready to be copied.
   Bedrock level/db/000011.ldb:455, Bedrock level/db/CURRENT:16, ...
   ```

3. **`save resume`** - Resumes world saving
   ```
   Response: [INFO] Changes to the world are resumed.
   ```

## ?? Default Configuration

```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\Backups\\Minecraft",
    "MaxBackupsToKeep": 10
  }
}
```

## ?? Backup Structure

```
C:\Backups\Minecraft\
??? backup_2025-01-15_14-00-00\
?   ??? level\
?       ??? db\
?       ?   ??? 000011.ldb
?       ?   ??? CURRENT
?       ?   ??? MANIFEST-000053
?       ??? level.dat
?       ??? level.dat_old
?       ??? levelname.txt
??? backup_2025-01-15_14-30-00\
??? backup_2025-01-15_15-00-00\
```

## ?? Features

? **Automatic Scheduled Backups**
- Runs every N minutes (configurable)
- Starts 30 seconds after server starts
- No manual intervention needed

? **Data Consistency**
- Uses Minecraft's official backup commands
- Ensures data integrity during backup
- Automatically resumes saving after backup

? **File Management**
- Timestamped backup directories
- Preserves directory structure
- Automatic cleanup of old backups

? **API Management**
- List all backups with size/date
- Delete individual backups
- View current configuration

? **Robust Error Handling**
- Comprehensive logging
- Graceful failure recovery
- Automatic save resume on errors

## ?? Getting Started

### Quick Setup

1. Edit `appsettings.json`:
   ```json
   "BackupDirectory": "C:\\Backups\\Minecraft"
   ```

2. Create the directory:
   ```bash
   mkdir C:\Backups\Minecraft
   ```

3. Run the API:
   ```bash
   dotnet run --project MCBDS.API
   ```

4. Verify in logs:
   ```
   [BackupHostedService] BackupHostedService started
   [BackupHostedService] Backup frequency set to 30 minutes
   ```

### Test API Endpoints

```bash
# List backups
curl http://localhost:5000/api/backup/list

# View config
curl http://localhost:5000/api/backup/config

# Delete backup
curl -X DELETE http://localhost:5000/api/backup/backup_2025-01-15_14-00-00
```

## ?? Monitoring

### Log Messages

**Successful Backup:**
```
[BackupHostedService] Starting backup process...
[BackupHostedService] Sending 'save hold' command...
[BackupHostedService] Sending 'save query' command...
[BackupHostedService] Created backup directory: C:\Backups\Minecraft\backup_2025-01-15_14-30-00
[BackupHostedService] Backup completed. Copied 42 files to ...
[BackupHostedService] World saving resumed
[BackupHostedService] Cleaned up 3 old backup(s)
```

**Service Disabled:**
```
[BackupHostedService] Backup directory not configured. Backup service will not run.
```

## ?? Common Issues

### Backups Not Running

- Check `BackupDirectory` is set in appsettings.json
- Verify directory exists and has write permissions
- Ensure `FrequencyMinutes` >= 1

### Files Not Copied

- Verify Bedrock server is running
- Check server responds to commands
- Ensure sufficient disk space

### Old Backups Not Deleted

- Check `MaxBackupsToKeep` setting
- Set to 0 to keep all backups
- Verify directory permissions

## ?? Future Enhancements

Potential additions:
- Manual backup trigger endpoint
- Backup compression (ZIP files)
- Cloud storage integration
- Backup restoration API
- Email/webhook notifications
- Backup integrity verification
- Pre-restart automatic backup

## ?? Documentation Files

1. **BACKUP_SERVICE_DOCUMENTATION.md** - Full technical docs
2. **BACKUP_QUICK_START.md** - Quick setup guide
3. **This file** - Implementation summary

## ? Testing Checklist

- [x] Service builds successfully
- [ ] Service starts without errors
- [ ] First backup completes successfully
- [ ] Files are copied correctly
- [ ] Old backups are cleaned up
- [ ] API endpoints return correct data
- [ ] Backup restoration works
- [ ] Service handles server restart
- [ ] Disk space monitoring in place

## ?? Status

**Build Status:** ? Successful

**Services Registered:**
- ? BackupConfiguration (Options)
- ? BackupHostedService (Background Service)
- ? BackupController (API Endpoints)

**Ready for Testing:** Yes

## ?? Summary

The automatic backup service is fully implemented and integrated with the MCBDS.API. It uses the official Minecraft Bedrock commands (`save hold`, `save query`, `save resume`) to perform consistent backups at configurable intervals. The service includes robust error handling, automatic cleanup, and API management endpoints.

Simply configure the backup directory and frequency in `appsettings.json`, and the service will automatically handle all backups!

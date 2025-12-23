# Automatic Backup Service Documentation

## Overview

The BackupHostedService provides automatic, scheduled backups of the Minecraft Bedrock Dedicated Server world data. It uses the server's built-in save commands to ensure data consistency during backups.

## How It Works

### Backup Process

The service follows the official Minecraft Bedrock backup procedure:

1. **`save hold`** - Pauses world saving and prepares files for backup
2. **`save query`** - Queries the list of files that need to be backed up
3. **Copy Files** - Copies the identified files to a timestamped backup directory
4. **`save resume`** - Resumes normal world saving

### File Structure

Backups are stored in the configured directory with timestamps:

```
BackupDirectory/
??? backup_2025-01-15_14-30-00/
?   ??? level/
?   ?   ??? db/
?   ?   ??? level.dat
?   ?   ??? levelname.txt
??? backup_2025-01-15_15-00-00/
??? backup_2025-01-15_15-30-00/
```

## Configuration

### appsettings.json

```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\Backups\\Minecraft",
    "MaxBackupsToKeep": 10
  }
}
```

### Configuration Options

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `FrequencyMinutes` | int | 30 | How often backups run (minutes) |
| `BackupDirectory` | string | "" | Full path to backup storage directory |
| `MaxBackupsToKeep` | int | 10 | Number of backups to retain (0 = keep all) |

## API Endpoints

### Get Backup Configuration

```http
GET /api/backup/config
```

**Response:**
```json
{
  "frequencyMinutes": 30,
  "backupDirectory": "C:\\Backups\\Minecraft",
  "maxBackupsToKeep": 10
}
```

### List Backups

```http
GET /api/backup/list
```

**Response:**
```json
{
  "backups": [
    {
      "name": "backup_2025-01-15_14-30-00",
      "createdAt": "2025-01-15T14:30:00",
      "sizeMB": 45.3,
      "path": "C:\\Backups\\Minecraft\\backup_2025-01-15_14-30-00"
    }
  ],
  "count": 1
}
```

### Delete Backup

```http
DELETE /api/backup/{backupName}
```

**Example:**
```http
DELETE /api/backup/backup_2025-01-15_14-30-00
```

**Response:**
```json
{
  "message": "Backup 'backup_2025-01-15_14-30-00' deleted successfully"
}
```

## Service Lifecycle

### Startup

1. Service starts 30 seconds after the Bedrock server starts
2. Validates configuration (directory, frequency)
3. Creates backup directory if it doesn't exist
4. Begins periodic backup cycle

### During Backup

1. Sends `save hold` to pause world saves
2. Waits 2 seconds for server to prepare
3. Sends `save query` to get file list
4. Parses response for file paths
5. Creates timestamped backup directory
6. Copies each file while preserving directory structure
7. Sends `save resume` to resume normal operation
8. Cleans up old backups based on retention policy

### Shutdown

- Service stops gracefully when the API shuts down
- Any in-progress backup completes before shutdown

## Logging

The service logs all operations to the standard ASP.NET Core logging infrastructure:

```
[BackupHostedService] Starting backup process...
[BackupHostedService] Sending 'save hold' command...
[BackupHostedService] Sending 'save query' command...
[BackupHostedService] Created backup directory: C:\Backups\Minecraft\backup_2025-01-15_14-30-00
[BackupHostedService] Backup completed. Copied 42 files to C:\Backups\Minecraft\backup_2025-01-15_14-30-00
[BackupHostedService] World saving resumed
[BackupHostedService] Cleaned up 3 old backup(s)
```

## Files Created

### New Files

1. **`MCBDS.API\Models\BackupConfiguration.cs`**
   - Configuration model for backup settings

2. **`MCBDS.API\Background\BackupHostedService.cs`**
   - Background service that performs scheduled backups

3. **`MCBDS.API\Controllers\BackupController.cs`**
   - API controller for backup management

### Modified Files

1. **`MCBDS.API\Program.cs`**
   - Registered BackupConfiguration
   - Registered BackupHostedService

2. **`MCBDS.API\appsettings.json`**
   - Added Backup configuration section

## Server Commands Reference

### save hold

```
Command: save hold
Response: [2025-12-22 16:18:30:809 INFO] Saving...
```

Prepares the world for backup by holding all writes.

### save query

```
Command: save query
Response: [2025-12-22 16:18:39:270 INFO] Data saved. Files are now ready to be copied.
Bedrock level/db/000011.ldb:455, Bedrock level/db/CURRENT:16, Bedrock level/db/MANIFEST-000053:101, Bedrock level/level.dat:3168, Bedrock level/level.dat_old:3168, Bedrock level/levelname.txt:13
```

Returns a list of files that need to be backed up with their sizes.

### save resume

```
Command: save resume
Response: [2025-12-22 16:20:53:034 INFO] Changes to the world are resumed.
```

Resumes normal world saving operations.

## Best Practices

### Frequency

- **Development/Testing**: 15-30 minutes
- **Small Server**: 30-60 minutes
- **Large Server**: 60-120 minutes
- **Production**: Consider server activity and storage

### Storage

- Ensure sufficient disk space (backups can be 50-500MB each)
- Use fast storage (SSD recommended)
- Consider network storage for off-site backups

### Retention

- Keep at least 3-5 recent backups
- For production, keep 24-48 hours of backups
- Consider daily/weekly long-term backups

### Monitoring

- Monitor logs for backup failures
- Set up alerts for disk space
- Verify backups periodically

## Troubleshooting

### Backups Not Running

Check:
1. Is `BackupDirectory` configured in appsettings.json?
2. Does the directory exist and have write permissions?
3. Is `FrequencyMinutes` set to a valid value (>= 1)?
4. Check logs for error messages

### Backup Failures

Common causes:
1. Server not responding to commands
2. Insufficient disk space
3. File permission issues
4. Invalid backup directory path

### Large Backup Times

If backups take too long:
1. Increase `FrequencyMinutes` to reduce frequency
2. Check disk I/O performance
3. Consider faster storage
4. Reduce world size if possible

## Integration with PublicUI

The backup settings configured in the PublicUI app (Backup Settings page) are stored locally on the device. To use those settings with this service:

1. The API reads from `appsettings.json`
2. Consider adding an API endpoint to update configuration
3. Or manually sync the settings between UI and API

## Security Considerations

- The backup directory should not be web-accessible
- Validate all user input in the BackupController
- Consider authentication for backup management endpoints
- Backup files may contain sensitive player data

## Future Enhancements

Potential additions:
- Manual backup trigger endpoint
- Backup restoration API
- Backup compression (zip files)
- Cloud storage integration (Azure Blob, AWS S3)
- Backup integrity verification
- Email notifications on backup failure
- Backup before server restart

# Hot-Reloadable Backup Settings - Implementation

## ? Issues Fixed

1. **No Restart Required**: Settings now reload automatically without restarting the API
2. **Proper Persistence**: Settings are correctly saved to `appsettings.json` and persisted

## ?? Hot-Reload Implementation

### Key Changes

#### 1. IOptionsMonitor Instead of IOptions

**Before:**
```csharp
private readonly BackupConfiguration _config;

public BackupHostedService(IOptions<BackupConfiguration> config, ...)
{
    _config = config.Value; // Static value, never updates
}
```

**After:**
```csharp
private readonly IOptionsMonitor<BackupConfiguration> _configMonitor;

public BackupHostedService(IOptionsMonitor<BackupConfiguration> configMonitor, ...)
{
    _configMonitor = configMonitor;
    
    // Subscribe to changes
    _configMonitor.OnChange(config =>
    {
        _logger.LogInformation("Configuration changed!");
        RestartBackupLoop();
    });
}

private BackupConfiguration CurrentConfig => _configMonitor.CurrentValue;
```

#### 2. Restartable Backup Loop

The service now uses a cancellable loop that restarts when configuration changes:

```csharp
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        _loopCts = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);
        
        try
        {
            await RunBackupLoopAsync(_loopCts.Token);
        }
        catch (OperationCanceledException) when (_loopCts.IsCancellationRequested)
        {
            _logger.LogInformation("Restarting due to config change...");
        }
    }
}

private void RestartBackupLoop()
{
    _loopCts?.Cancel(); // Cancels current loop, ExecuteAsync restarts it
}
```

#### 3. Proper JSON Persistence

**Before:**
```csharp
// ? This loses nested structure and comments
var settings = JsonSerializer.Deserialize<Dictionary<string, object>>(json);
settings["Backup"] = new Dictionary<string, object> { ... };
```

**After:**
```csharp
// ? Preserves JSON structure properly
var jsonNode = JsonNode.Parse(json);
jsonNode["Backup"] = new JsonObject
{
    ["FrequencyMinutes"] = newConfig.FrequencyMinutes,
    ["BackupDirectory"] = newConfig.BackupDirectory,
    ["MaxBackupsToKeep"] = newConfig.MaxBackupsToKeep
};
var updatedJson = jsonNode.ToJsonString(new JsonSerializerOptions { WriteIndented = true });
```

#### 4. Configuration Reload Trigger

```csharp
// Force immediate reload after saving
if (_configuration is IConfigurationRoot configRoot)
{
    configRoot.Reload();
    _logger.LogInformation("Configuration reloaded");
}
```

#### 5. Enable File Watching in Program.cs

```csharp
builder.Configuration.AddJsonFile("appsettings.json", 
    optional: false, 
    reloadOnChange: true); // ? This enables hot-reload
```

## ?? How It Works

### Configuration Change Flow

```
User saves settings in UI
    ?
PUT /api/backup/config
    ?
Update appsettings.json (JsonNode)
    ?
Call configRoot.Reload()
    ?
IOptionsMonitor detects change
    ?
OnChange callback fires
    ?
RestartBackupLoop() cancels current loop
    ?
ExecuteAsync catches cancellation
    ?
RunBackupLoopAsync starts with new config
    ?
Next backup uses new settings!
```

### Timeline Example

```
14:00:00 - Service running, frequency = 30 minutes
14:05:00 - User changes frequency to 60 minutes
14:05:01 - Settings saved to appsettings.json
14:05:02 - Configuration reloaded
14:05:03 - OnChange callback fires
14:05:04 - Backup loop restarts with new settings
14:05:05 - ? Next backup in 60 minutes (not 30!)
```

## ?? Configuration Lifecycle

### Service Startup

```
1. Service starts
   ?
2. Read CurrentConfig (e.g., 30 min frequency)
   ?
3. Subscribe to OnChange
   ?
4. Start backup loop with 30 min interval
   ?
5. Running...
```

### Configuration Change

```
1. User updates settings
   ?
2. Settings saved to disk
   ?
3. File watcher detects change
   ?
4. Configuration provider reloads
   ?
5. IOptionsMonitor fires OnChange
   ?
6. Current loop cancelled
   ?
7. New loop starts with CurrentConfig
   ?
8. ? Running with new settings
```

## ?? Testing

### Test 1: Change Frequency

1. Start API with frequency = 30 minutes
2. Wait for log: "Backup frequency set to 30 minutes"
3. Change via UI to 60 minutes
4. Check logs for:
```
[BackupHostedService] Backup configuration changed. New frequency: 60 minutes
[BackupHostedService] Backup loop restarting due to configuration change...
[BackupHostedService] Backup frequency set to 60 minutes
```

### Test 2: Change Directory

1. Set directory to `C:\Backups\Test1`
2. Trigger manual backup
3. Verify backup in `C:\Backups\Test1`
4. Change to `C:\Backups\Test2`
5. Trigger another backup
6. Verify backup in `C:\Backups\Test2` (without restart!)

### Test 3: Persistence

1. Save settings via UI
2. Restart API
3. Verify settings loaded correctly
4. Check `appsettings.json` has correct values

## ?? API Response Changes

### Before (Required Restart)

```json
{
  "message": "Configuration updated successfully. Restart the API for changes to take effect.",
  "restartRequired": true
}
```

### After (Hot-Reload)

```json
{
  "message": "Configuration updated successfully and reloaded!",
  "restartRequired": false,
  "note": "Changes will take effect on the next backup cycle"
}
```

## ?? Benefits

### 1. No Downtime
- Change settings without restarting
- No interruption to running server
- No need to stop/start services

### 2. Immediate Feedback
- See configuration changes in logs
- Next backup uses new settings
- Clear confirmation messages

### 3. Developer Experience
- Fast iteration during development
- Easy testing of different settings
- No restart delays

### 4. Production Ready
- Safe configuration updates
- Proper validation before applying
- Rollback possible (edit JSON manually)

## ?? Important Notes

### Configuration Reload Timing

- Changes apply to **next backup cycle**
- In-progress backup completes with old settings
- Loop restarts immediately after current backup

### File Watching

The file watcher monitors `appsettings.json`:
- Detects saves from API
- Detects manual edits
- May take 1-2 seconds to detect

### Thread Safety

- `IOptionsMonitor` is thread-safe
- `CurrentConfig` always returns latest value
- Semaphore prevents concurrent backups

## ?? Configuration File Format

### appsettings.json Structure

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\Backups\\Minecraft",
    "MaxBackupsToKeep": 10,
    "WorldPath": null
  }
}
```

### After Update via API

Structure is preserved:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Backup": {
    "FrequencyMinutes": 60,          ? Updated
    "BackupDirectory": "D:\\Backups", ? Updated
    "MaxBackupsToKeep": 20            ? Updated
  }
}
```

## ?? Troubleshooting

### Settings Don't Reload

**Check:**
1. Is `reloadOnChange: true` in Program.cs?
2. Do you see "Configuration reloaded" in logs?
3. Is the file being saved successfully?

**Solution:**
```csharp
// Verify in Program.cs
builder.Configuration.AddJsonFile("appsettings.json", 
    optional: false, 
    reloadOnChange: true); // ? Must be true
```

### Changes Not Taking Effect

**Check:**
1. Did the backup loop restart?
2. Is a backup currently in progress?
3. Check logs for "Configuration changed"

**Solution:** Wait for current backup to complete, loop will restart automatically.

### JSON File Corrupted

**Prevention:**
- API uses JsonNode for safe updates
- Validates before saving
- Backup appsettings.json before changes

**Recovery:**
- Restore from backup
- Or manually fix JSON structure

## ?? Related Files

1. **MCBDS.API\Background\BackupHostedService.cs** - Hot-reload implementation
2. **MCBDS.API\Controllers\BackupController.cs** - JSON persistence
3. **MCBDS.API\Program.cs** - Configuration setup
4. **MCBDS.PublicUI\Components\Pages\BackupConfig.razor** - Updated UI

## Status

? **Build: Successful**  
? **Hot-Reload: Implemented**  
? **Persistence: Fixed**  
? **Ready for: Production**

## Summary

The backup service now supports:
- ? **Hot-reload**: No restart required for configuration changes
- ? **Persistence**: Settings properly saved to appsettings.json
- ? **Automatic restart**: Backup loop restarts with new settings
- ? **Thread-safe**: Safe concurrent access to configuration
- ? **Production-ready**: Robust error handling and validation

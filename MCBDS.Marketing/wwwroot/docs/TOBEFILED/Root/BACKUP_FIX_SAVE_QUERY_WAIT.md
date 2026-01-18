# Backup Process Fix - Wait for save query Response

## ? Issue Fixed

The backup process now **properly waits for the `save query` command to return** with the file list before starting the file copy process.

## ?? Problem

Previously, the backup service would:
1. Send "save hold"
2. Wait 2 seconds
3. Send "save query" 
4. **Immediately start copying files** without waiting for the response

This was incorrect because `save query` is asynchronous and needs time to return the file list.

## ? Solution Implemented

The updated `BackupHostedService` now follows the correct flow:

### Correct Backup Sequence

```
1. Send "save hold"
   ?
2. Wait 3 seconds (for save hold to complete)
   ?
3. Send "save query"
   ?
4. ? WAIT for response (up to 10 seconds)
   - Poll log every 500ms
   - Look for "Files are now ready to be copied" OR "Data saved"
   ?
5. ? Confirm files are ready
   ?
6. Parse file list from response
   ?
7. Copy files (ONLY after confirmation)
   ?
8. Send "save resume"
```

### Key Changes

#### 1. **Response Waiting Loop**

```csharp
// Wait for "Files are now ready to be copied" message with timeout
var maxWaitTime = TimeSpan.FromSeconds(10);
var waitInterval = TimeSpan.FromMilliseconds(500);
var elapsedTime = TimeSpan.Zero;
bool filesReady = false;

while (elapsedTime < maxWaitTime && !cancellationToken.IsCancellationRequested)
{
    await Task.Delay(waitInterval, cancellationToken);
    elapsedTime += waitInterval;

    var currentLog = _runnerService.GetLog();
    
    // Check if we got the "Files are now ready to be copied" message
    if (currentLog.Contains("Files are now ready to be copied", StringComparison.OrdinalIgnoreCase) ||
        currentLog.Contains("Data saved", StringComparison.OrdinalIgnoreCase))
    {
        filesReady = true;
        _logger.LogInformation("Received confirmation that files are ready to be copied");
        break;
    }
}
```

#### 2. **Timeout Protection**

```csharp
if (!filesReady)
{
    _logger.LogError("Timeout waiting for 'save query' response. Files may not be ready.");
    await ResumeWorldSaving();
    return;  // Abort backup
}
```

#### 3. **File Copy ONLY After Confirmation**

```csharp
// Step 3: Parse file list from server response - ONLY proceed if we have the list
var filesToBackup = ParseFileList();

if (filesToBackup.Count == 0)
{
    _logger.LogWarning("No files identified for backup from save query response");
    await ResumeWorldSaving();
    return;  // Abort backup
}

_logger.LogInformation("Identified {Count} files to backup", filesToBackup.Count);

// Step 4: Create backup directory...
// Step 5: Copy files - ONLY after save query has returned the file list
```

## ?? Backup Flow Diagram

```
???????????????????????????????????????
? Start Backup                        ?
???????????????????????????????????????
             ?
             ?
???????????????????????????????????????
? Send "save hold"                    ?
? Server pauses world saving          ?
???????????????????????????????????????
             ?
             ? Wait 3 seconds
???????????????????????????????????????
? Send "save query"                   ?
? Request file list                   ?
???????????????????????????????????????
             ?
             ?
    ??????????????????????
    ? Wait for Response  ? ???? Poll every 500ms
    ? (max 10 seconds)   ?      (up to 10 seconds)
    ??????????????????????
             ?
             ?
   ???????????????????????
   ? Files Ready?        ?
   ???????????????????????
         ?       ?
    Yes  ?       ?  No (timeout)
         ?       ?
         ?       ?
??????????????  ??????????????????
?Parse Files ?  ? Log Error      ?
?List        ?  ? Resume Saving  ?
??????????????  ? Abort Backup   ?
      ?         ??????????????????
      ?
???????????????
? Files > 0?  ?
???????????????
      ?   ?
 Yes  ?   ?  No
      ?   ?
      ?   ?
??????????????????????
? Create Backup Dir  ?
? Copy Files         ?
? Resume Saving      ?
? Cleanup Old        ?
??????????????????????
```

## ?? Safety Features

1. **Timeout Protection**: 10-second maximum wait for response
2. **Cancellation Support**: Respects cancellation tokens
3. **Validation**: Checks for file list before copying
4. **Always Resume**: Guarantees "save resume" is called
5. **Error Logging**: Detailed logging at each step

## ?? Log Output Example

### Successful Backup

```
[BackupHostedService] Starting backup process...
[BackupHostedService] Sending 'save hold' command...
[BackupHostedService] Waiting for save hold to complete...
[BackupHostedService] Sending 'save query' command and waiting for response...
[BackupHostedService] Received confirmation that files are ready to be copied
[BackupHostedService] Identified 42 files to backup
[BackupHostedService] Created backup directory: C:\Backups\Minecraft\backup_2025-01-15_14-30-00
[BackupHostedService] Starting file copy from: C:\BedrockServer\worlds\Bedrock level
[BackupHostedService] Backup completed. Copied 42 files, 0 failed to C:\Backups\Minecraft\backup_2025-01-15_14-30-00
[BackupHostedService] Sending 'save resume' command...
[BackupHostedService] World saving resumed
[BackupHostedService] Cleaned up 3 old backup(s)
```

### Timeout Scenario

```
[BackupHostedService] Starting backup process...
[BackupHostedService] Sending 'save hold' command...
[BackupHostedService] Waiting for save hold to complete...
[BackupHostedService] Sending 'save query' command and waiting for response...
[BackupHostedService] Timeout waiting for 'save query' response. Files may not be ready.
[BackupHostedService] Sending 'save resume' command...
[BackupHostedService] World saving resumed
```

## ? Benefits

1. **Data Integrity**: Files are only copied when confirmed ready
2. **Reliability**: Handles server delays and timeouts
3. **Safety**: Never copies files before they're ready
4. **Traceability**: Clear logging of each step
5. **Robustness**: Proper error handling and recovery

## ?? Testing

To verify the fix works:

1. Start the API with backup configured
2. Trigger a manual backup via UI
3. Check logs for:
   - "Waiting for response" message
   - "Received confirmation" message  
   - File count before copying
4. Verify backup folder contains all files

## ?? References

- **Minecraft Bedrock Commands**: Official backup procedure
  - `save hold` - Prepare for backup
  - `save query` - Get file list (asynchronous!)
  - `save resume` - Resume normal operation

## Status

? **Build: Successful**  
? **Fix: Implemented**  
? **Ready for: Testing and Production**

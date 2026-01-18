# World Path Configuration Fix

## ? Issue Fixed

The `GetBedrockWorldPath()` method now correctly determines the world directory based on the location of `bedrock_server.exe` instead of the API assembly location.

##  Problem

Previously, the code was using:
```csharp
var bedrockPath = Path.GetDirectoryName(_runnerService.GetType().Assembly.Location) ?? string.Empty;
return Path.Combine(bedrockPath, "worlds", "Bedrock level");
```

This was incorrect because:
- The assembly location is where the API DLL is located
- `bedrock_server.exe` is in a completely different directory
- The world files are relative to `bedrock_server.exe`, not the API

## ? Solution

The code now uses a three-tier approach to find the world directory:

### Priority 1: Explicit Configuration

```json
{
  "Backup": {
    "WorldPath": "C:\\Binaries\\BDS1.12.124.2\\worlds\\Bedrock level"
  }
}
```

If `WorldPath` is explicitly configured, it will be used directly.

### Priority 2: Derive from Runner:ExePath (Default)

```json
{
  "Runner": {
    "ExePath": "c:\\Binaries\\BDS1.12.124.2\\Bedrock_server.exe"
  }
}
```

The service will:
1. Read `Runner:ExePath` configuration
2. Get the directory containing `bedrock_server.exe`
3. Append `worlds\Bedrock level` to that path

**Example:**
```
ExePath:  c:\Binaries\BDS1.12.124.2\Bedrock_server.exe
          ? Get directory
BedrockDir: c:\Binaries\BDS1.12.124.2\
          ? Append worlds path
WorldPath:  c:\Binaries\BDS1.12.124.2\worlds\Bedrock level\
```

### Priority 3: Assembly Location Fallback

If neither of the above are configured, falls back to assembly location (legacy behavior).

## ?? Implementation

```csharp
private string GetBedrockWorldPath()
{
    // Option 1: Use configured world path if provided
    if (!string.IsNullOrWhiteSpace(_config.WorldPath))
    {
        return _config.WorldPath;
    }

    // Option 2: Derive from Runner:ExePath configuration
    var exePath = _configuration["Runner:ExePath"];
    if (!string.IsNullOrWhiteSpace(exePath))
    {
        // Get the directory containing bedrock_server.exe
        var bedrockServerDir = Path.GetDirectoryName(exePath);
        if (!string.IsNullOrEmpty(bedrockServerDir))
        {
            // World is typically in "worlds/Bedrock level" subdirectory
            return Path.Combine(bedrockServerDir, "worlds", "Bedrock level");
        }
    }

    // Option 3: Fallback to assembly location (less reliable)
    var assemblyLocation = Path.GetDirectoryName(typeof(BackupHostedService).Assembly.Location) ?? string.Empty;
    return Path.Combine(assemblyLocation, "worlds", "Bedrock level");
}
```

## ?? Directory Structure

### Typical Bedrock Server Layout

```
C:\Binaries\BDS1.12.124.2\
??? bedrock_server.exe          ? Runner:ExePath points here
??? bedrock_server.pdb
??? worlds\
?   ??? Bedrock level\          ? This is what we need
?       ??? db\
?       ??? level.dat
?       ??? level.dat_old
?       ??? levelname.txt
??? behavior_packs\
??? resource_packs\
??? ...
```

### Backup Service Resolution

```
Configuration:
  Runner:ExePath = "C:\Binaries\BDS1.12.124.2\bedrock_server.exe"

Resolution Process:
1. Path.GetDirectoryName(exePath)
   ? "C:\Binaries\BDS1.12.124.2"

2. Path.Combine(dir, "worlds", "Bedrock level")
   ? "C:\Binaries\BDS1.12.124.2\worlds\Bedrock level"

3. ? Correct world path!
```

## ?? Configuration Options

### Option A: Auto-Detection (Recommended)

```json
{
  "Runner": {
    "ExePath": "c:\\Binaries\\BDS1.12.124.2\\Bedrock_server.exe"
  },
  "Backup": {
    "WorldPath": null  // or omit this line
  }
}
```

World path will be automatically determined from ExePath.

### Option B: Explicit Path

```json
{
  "Backup": {
    "WorldPath": "C:\\Binaries\\BDS1.12.124.2\\worlds\\Bedrock level"
  }
}
```

Useful for:
- Non-standard world locations
- Multiple world support
- Custom server setups

### Option C: Docker/Container

```json
{
  "Runner": {
    "ExePath": "/bedrock/bedrock_server"
  },
  "Backup": {
    "WorldPath": null
  }
}
```

Will resolve to: `/bedrock/worlds/Bedrock level`

## ?? Logging

The service now logs the resolved world path on startup:

### Successful Resolution

```
[BackupHostedService] Backup directory: C:\Backups\Minecraft
[BackupHostedService] World directory: C:\Binaries\BDS1.12.124.2\worlds\Bedrock level
[BackupHostedService] Backup frequency set to 30 minutes
```

### Warning if Directory Doesn't Exist

```
[BackupHostedService] World directory does not exist: C:\Binaries\BDS1.12.124.2\worlds\Bedrock level. Waiting for it to be created...
```

This is normal on first run before the world is generated.

## ?? Testing

### Verify World Path Resolution

1. Check your `appsettings.Development.json` for `Runner:ExePath`
2. Start the API
3. Look for log message: "World directory: ..."
4. Verify the path is correct

### Manual Test

```powershell
# Check if world directory exists
$exePath = "c:\Binaries\BDS1.12.124.2\Bedrock_server.exe"
$bedrockDir = Split-Path $exePath
$worldPath = Join-Path $bedrockDir "worlds\Bedrock level"
Test-Path $worldPath
```

## ?? Configuration Priority

```
???????????????????????????????
? 1. Backup:WorldPath         ? ? Highest Priority
?    (if explicitly set)      ?
???????????????????????????????
           ? Not set? ?
???????????????????????????????
? 2. Runner:ExePath           ? ? Recommended
?    + "worlds/Bedrock level" ?
???????????????????????????????
           ? Not set? ?
???????????????????????????????
? 3. Assembly Location        ? ? Fallback
?    + "worlds/Bedrock level" ?
???????????????????????????????
```

## ? Benefits

1. **Correctness**: Finds world files in the actual bedrock server directory
2. **Flexibility**: Supports explicit configuration when needed
3. **Simplicity**: Works automatically in most cases
4. **Reliability**: Multiple fallback options
5. **Visibility**: Logs resolved path for verification

## ?? Migration

If you previously had issues with backups not finding files:

1. Verify `Runner:ExePath` is correctly configured
2. Restart the API
3. Check logs for resolved world path
4. Trigger a manual backup to verify it works

No configuration changes needed if `Runner:ExePath` was already correct!

## Status

? **Build: Successful**  
? **Fix: Implemented**  
? **Configuration: Enhanced**  
? **Ready for: Production**

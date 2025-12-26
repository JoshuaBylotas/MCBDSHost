# Settings Not Persisting - Fix and Debugging

## ? Issue

Settings reset to defaults when navigating away and returning to the Backup Settings page.

## ?? Root Cause Analysis

The PublicUI loads settings from the API correctly, but there may be issues with:
1. **Component lifecycle** - Settings might not reload when revisiting the page
2. **API response** - Settings might not be saving to appsettings.json correctly
3. **Caching** - Blazor might be caching the component state

## ? Fixes Implemented

### 1. Added Console Logging

```csharp
Console.WriteLine($"[BackupConfig] OnInitializedAsync at {DateTime.Now:HH:mm:ss}");
Console.WriteLine($"[BackupConfig] Loaded: Freq={frequencyMinutes}, Dir={backupDirectory}");
Console.WriteLine($"[BackupConfig] Saving: Freq={frequencyMinutes}, Dir={backupDirectory}");
```

**Purpose**: Track when settings are loaded and what values are being used.

### 2. Added "Last Loaded" Timestamp

```razor
<small class="text-muted">Last loaded: @lastLoadTime.ToString("HH:mm:ss")</small>
```

**Purpose**: Visual confirmation that settings were loaded and when.

### 3. Reload After Save

```csharp
if (success)
{
    SetStatus($"? {message}\n\nSettings saved successfully!", "alert-success");
    await Task.Delay(500);
    await LoadSettings(); // ? Reload to confirm save
}
```

**Purpose**: Immediately reflect saved values in the UI.

### 4. Clear Status on Reload

```csharp
statusMessage = string.Empty; // Clear any previous messages
```

**Purpose**: Don't show stale messages when reloading.

## ?? Debugging Steps

### Step 1: Check Console Logs

Open the browser developer console (F12) and look for messages:

```
[BackupConfig] OnInitializedAsync at 14:30:45
[BackupConfig] LoadSettings called
[BackupConfig] Loaded: Freq=30, Dir=C:\Backups\Minecraft, Max=10
```

**What to check:**
- Is `OnInitializedAsync` called when you visit the page?
- Are the loaded values correct?
- Do values change when you navigate away and back?

### Step 2: Verify API Response

1. Open browser Developer Tools (F12)
2. Go to Network tab
3. Navigate to Backup Settings
4. Look for request to `/api/backup/config`
5. Check the response:

```json
{
  "frequencyMinutes": 30,
  "backupDirectory": "C:\\Backups\\Minecraft",
  "maxBackupsToKeep": 10
}
```

**What to check:**
- Is the API returning the values you saved?
- Are the values correct in the response?

### Step 3: Check appsettings.json

Open `MCBDS.API\appsettings.json` and verify:

```json
{
  "Backup": {
    "FrequencyMinutes": 30,
    "BackupDirectory": "C:\\Backups\\Minecraft",
    "MaxBackupsToKeep": 10
  }
}
```

**What to check:**
- Are your saved values actually in the file?
- Is the JSON structure correct?
- Are values persisting after API restart?

### Step 4: Test Save Operation

1. Open Backup Settings
2. Change frequency to 60
3. Click "Save Settings"
4. Open browser console
5. Look for:

```
[BackupConfig] Saving: Freq=60, Dir=C:\Backups\Minecraft, Max=10
[BackupConfig] Save successful
[BackupConfig] LoadSettings called
[BackupConfig] Loaded: Freq=60, Dir=C:\Backups\Minecraft, Max=10
```

**What to check:**
- Did the save succeed?
- Did the reload happen?
- Are the reloaded values correct?

### Step 5: Test Navigation

1. Save settings (e.g., freq=60)
2. Navigate to Home
3. Navigate back to Backup Settings
4. Check console for:

```
[BackupConfig] OnInitializedAsync at 14:31:20
[BackupConfig] LoadSettings called
[BackupConfig] Loaded: Freq=60, Dir=C:\Backups\Minecraft, Max=10
```

**What to check:**
- Did `OnInitializedAsync` run again?
- Are the loaded values still 60?
- Or did they reset to 30?

## ?? Common Issues and Solutions

### Issue 1: Values Reset to Defaults

**Symptom**: Settings show 30, "C:\Backups\Minecraft", 10 every time

**Possible Causes:**
1. API not saving to appsettings.json
2. API reading from wrong file
3. File permissions issue

**Solution:**
Check API logs for:
```
[BackupController] Backup configuration updated
```

If missing, the save might be failing. Check:
- File permissions on appsettings.json
- API has write access to the directory
- No antivirus blocking file writes

### Issue 2: API Returns Null

**Symptom**: Console shows `[BackupConfig] API returned null`

**Possible Causes:**
1. API not running
2. Wrong API URL in MauiProgram.cs
3. CORS issue
4. Network error

**Solution:**
Check `MCBDS.PublicUI\MauiProgram.cs`:
```csharp
client.BaseAddress = new Uri("https://localhost:7123"); // ? Correct URL?
```

Verify API is running at that URL.

### Issue 3: Values Load Once But Not Again

**Symptom**: First load shows correct values, but after navigation they reset

**Possible Causes:**
1. Blazor caching component
2. API returning cached response
3. Hot-reload not working

**Solution:**
Add cache-busting to API call:
```csharp
var config = await ApiService.GetBackupConfigAsync();
// Or with timestamp:
var config = await ApiService.GetBackupConfigAsync($"?t={DateTime.Now.Ticks}");
```

### Issue 4: Save Succeeds But Values Don't Persist

**Symptom**: Save shows success, but values reset after restart

**Possible Causes:**
1. API saving to wrong appsettings.json
2. File being overwritten
3. Configuration not reloading

**Solution:**
Check which appsettings.json is being modified:
```
C:\Users\joshua\source\repos\JoshuaBylotas\MCBDSHost\MCBDS.API\appsettings.json
```

Verify this is the file the API is reading from.

## ?? Expected vs Actual Behavior

### Expected Behavior

```
1. Open Backup Settings
   ? Load from API: freq=30
   ? Display: 30 minutes
   
2. Change to 60, click Save
   ? Save to API
   ? API updates appsettings.json
   ? Reload from API: freq=60
   ? Display: 60 minutes
   
3. Navigate to Home
   
4. Navigate back to Backup Settings
   ? Load from API: freq=60
   ? Display: 60 minutes ?
```

### Actual Behavior (if bugged)

```
1. Open Backup Settings
   ? Load from API: freq=30
   ? Display: 30 minutes
   
2. Change to 60, click Save
   ? Save to API
   ? Reload from API: freq=60
   ? Display: 60 minutes
   
3. Navigate to Home
   
4. Navigate back to Backup Settings
   ? Load from API: freq=30 ?
   ? Display: 30 minutes ?
```

## ?? Quick Test

Run this test to verify the fix:

```
1. Open PublicUI
2. Go to Backup Settings
3. Note "Last loaded" timestamp
4. Change frequency from 30 to 99
5. Click "Save Settings"
6. Wait for success message
7. Note "Last loaded" timestamp (should update)
8. Verify display shows 99
9. Navigate to Home
10. Navigate back to Backup Settings
11. Check "Last loaded" timestamp (should be new)
12. Verify display still shows 99 ?
```

If step 12 shows 30 instead of 99, the issue persists.

## ?? Additional Debugging

### Enable Detailed API Logging

In `MCBDS.API\appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "MCBDS.API.Controllers.BackupController": "Trace"
    }
  }
}
```

This will show every API call and response.

### Add Breakpoint

In `BackupConfig.razor`, add breakpoint at:

```csharp
protected override async Task OnInitializedAsync()
{
    Console.WriteLine(...); // ? Breakpoint here
```

Step through and inspect:
- `config` object from API
- `frequencyMinutes`, `backupDirectory`, `maxBackupsToKeep` values

## ?? Summary

The fix adds:
1. **Console logging** for visibility
2. **Last loaded timestamp** for confirmation
3. **Reload after save** to ensure UI updates
4. **Clear status messages** to avoid confusion

If the issue persists after these changes, use the debugging steps above to identify the root cause.

## Status

? **Build: Successful**  
? **Logging: Added**  
? **Timestamp: Added**  
? **Auto-reload: Implemented**  
?? **Ready for: Testing**

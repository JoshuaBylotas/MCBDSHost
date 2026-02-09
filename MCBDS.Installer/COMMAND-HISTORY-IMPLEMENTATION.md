# Command History Feature - Implementation Guide

## Overview
This feature adds persistent command history tracking to the MCBDS Commands page. Every command sent to the server is recorded in a JSON file with timestamp, success status, and error messages.

## Files Created

### 1. CommandHistory.cs
**Location:** `MCBDS.ClientUI\MCBDS.ClientUI.Shared\Models\CommandHistory.cs`

**Purpose:** Data models for command history entries and history container

**Key Classes:**
- `CommandHistoryEntry` - Single command record with:
  - Command (string)
  - Timestamp (DateTime)
  - Success (bool)
  - ErrorMessage (string?)
- `CommandHistory` - Container with:
  - Entries (List<CommandHistoryEntry>)
  - MaxEntries (int) - defaults to 100

### 2. CommandHistoryService.cs
**Location:** `MCBDS.ClientUI\MCBDS.ClientUI.Shared\Services\CommandHistoryService.cs`

**Purpose:** Service to manage reading/writing command history to JSON file

**Key Methods:**
- `GetHistory(int count)` - Get most recent commands
- `SearchHistory(string query)` - Search command history
- `AddCommandAsync(string command, bool success, string? errorMessage)` - Add new command
- `ClearHistoryAsync()` - Clear all history
- `GetCommandStats()` - Get top 10 most used commands
- `GetSuccessRate()` - Get success percentage

**Storage Location:**
- File: `command-history.json`
- Directory: `FileSystem.Current.AppDataDirectory` (MAUI app data folder)

---

## Manual Setup Required

### Step 1: Register Service in MauiProgram.cs

**File:** `MCBDS.PublicUI\MauiProgram.cs`

**Add this code after the BackupSettingsService registration (around line 104):**

```csharp
// Register CommandHistoryService with MAUI AppDataDirectory
builder.Services.AddSingleton<CommandHistoryService>(sp => 
{
	try
	{
		var appDataDir = FileSystem.Current.AppDataDirectory;
		CrashLogger.LogInfo($"Creating CommandHistoryService with directory: {appDataDir}");
		return new CommandHistoryService(appDataDir);
	}
	catch (Exception ex)
	{
		CrashLogger.LogError("Failed to create CommandHistoryService", ex);
		throw;
	}
});
```

### Step 2: Update Commands.razor

**File:** `MCBDS.PublicUI\Components\Pages\Commands.razor`

#### A. Add Service Injection (at top of @code section)

```csharp
@inject CommandHistoryService HistoryService
```

#### B. Update SendCommand Method

Find the `SendCommand` method (around line 670) and update it to record history:

```csharp
private async Task SendCommand()
{
    if (string.IsNullOrWhiteSpace(commandInput))
    {
        SetStatus("Please enter a command", "alert-warning");
        return;
    }

    isProcessing = true;
    statusMessage = string.Empty;
    connectionError = null;
    StateHasChanged();

    var result = await ApiService.SendLineAsync(commandInput);
    
    if (result.Success)
    {
        // Record successful command
        await HistoryService.AddCommandAsync(commandInput, true);
        
        SetStatus($"Command sent: {commandInput}", "alert-success");
        
        // If it was a "list" command, refresh to update player list
        if (commandInput.Trim().ToLower() == "list")
        {
            await Task.Delay(1000); // Wait for server to respond
        }
        
        commandInput = string.Empty;
        selectedCommand = null;
        await Task.Delay(500);
        await RefreshLog();
    }
    else
    {
        // Record failed command
        await HistoryService.AddCommandAsync(commandInput, false, result.ErrorMessage);
        
        if (result.ErrorType == ApiErrorType.ConnectionFailed)
        {
            connectionError = result.ErrorMessage;
        }
        SetStatus(result.ErrorMessage ?? "Failed to send command", "alert-danger");
    }
    
    isProcessing = false;
    StateHasChanged();
}
```

#### C. Add Command History UI Section

Add this section to the Commands.razor page (after the command input section, before the log):

```razor
<!-- Command History Section -->
<div class="command-history-section mt-4">
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
                <i class="bi bi-clock-history me-2"></i>Command History
            </h5>
            <div>
                <button class="btn btn-sm btn-outline-secondary me-2" @onclick="RefreshHistory">
                    <i class="bi bi-arrow-clockwise me-1"></i>Refresh
                </button>
                <button class="btn btn-sm btn-outline-danger" @onclick="ClearHistory">
                    <i class="bi bi-trash me-1"></i>Clear
                </button>
            </div>
        </div>
        <div class="card-body">
            <!-- Search -->
            <input type="text" 
                   class="form-control mb-3" 
                   @bind="historySearchQuery" 
                   @bind:event="oninput"
                   @bind:after="SearchHistory"
                   placeholder="Search command history..." />

            <!-- Stats -->
            <div class="row mb-3">
                <div class="col-md-6">
                    <div class="alert alert-info mb-0">
                        <i class="bi bi-graph-up me-2"></i>
                        <strong>Success Rate:</strong> @historySuccessRate%
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="alert alert-secondary mb-0">
                        <i class="bi bi-list-ol me-2"></i>
                        <strong>Total Commands:</strong> @historyEntries.Count
                    </div>
                </div>
            </div>

            <!-- Most Used Commands -->
            @if (mostUsedCommands.Any())
            {
                <div class="mb-3">
                    <h6><i class="bi bi-bar-chart me-2"></i>Most Used Commands</h6>
                    <div class="d-flex flex-wrap gap-2">
                        @foreach (var cmd in mostUsedCommands.Take(5))
                        {
                            <span class="badge bg-primary">
                                @cmd.Key <span class="badge bg-light text-dark ms-1">@cmd.Value</span>
                            </span>
                        }
                    </div>
                </div>
            }

            <!-- History List -->
            <div class="history-list">
                @if (historyEntries.Any())
                {
                    @foreach (var entry in historyEntries)
                    {
                        <div class="history-entry @(entry.Success ? "success" : "failed")">
                            <div class="d-flex justify-content-between align-items-start">
                                <div class="flex-grow-1">
                                    <code class="command-text" @onclick="@(() => UseHistoryCommand(entry.Command))">
                                        @entry.Command
                                    </code>
                                    @if (!entry.Success && !string.IsNullOrEmpty(entry.ErrorMessage))
                                    {
                                        <div class="text-danger small mt-1">
                                            <i class="bi bi-exclamation-triangle me-1"></i>@entry.ErrorMessage
                                        </div>
                                    }
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    @if (entry.Success)
                                    {
                                        <span class="badge bg-success">Success</span>
                                    }
                                    else
                                    {
                                        <span class="badge bg-danger">Failed</span>
                                    }
                                    <small class="text-muted">@entry.Timestamp.ToLocalTime().ToString("g")</small>
                                </div>
                            </div>
                        </div>
                    }
                }
                else
                {
                    <div class="text-center text-muted py-4">
                        <i class="bi bi-inbox display-4 d-block mb-2"></i>
                        No command history yet
                    </div>
                }
            </div>
        </div>
    </div>
</div>
```

#### D. Add Code-Behind Methods

Add these fields and methods to the `@code` section:

```csharp
// Command History fields
private string historySearchQuery = string.Empty;
private List<CommandHistoryEntry> historyEntries = new();
private Dictionary<string, int> mostUsedCommands = new();
private int historySuccessRate = 100;

protected override async Task OnInitializedAsync()
{
    await RefreshLog();
    await RefreshHistory();
    
    // Auto-refresh log every 3 seconds
    autoRefreshTimer = new System.Threading.Timer(async _ =>
    {
        await InvokeAsync(async () =>
        {
            if (!isProcessing && !isLoadingLog)
            {
                await RefreshLog();
            }
        });
    }, null, TimeSpan.FromSeconds(3), TimeSpan.FromSeconds(3));
}

private async Task RefreshHistory()
{
    historyEntries = HistoryService.GetHistory(50);
    mostUsedCommands = HistoryService.GetCommandStats();
    historySuccessRate = HistoryService.GetSuccessRate();
    StateHasChanged();
}

private void SearchHistory()
{
    historyEntries = string.IsNullOrWhiteSpace(historySearchQuery) 
        ? HistoryService.GetHistory(50)
        : HistoryService.SearchHistory(historySearchQuery);
    StateHasChanged();
}

private async Task ClearHistory()
{
    if (await JSRuntime.InvokeAsync<bool>("confirm", "Are you sure you want to clear all command history?"))
    {
        await HistoryService.ClearHistoryAsync();
        await RefreshHistory();
    }
}

private void UseHistoryCommand(string command)
{
    commandInput = command;
    selectedCommand = BedrockCommands.GetCommand(command.Split(' ')[0]);
    StateHasChanged();
}
```

### Step 3: Add CSS Styles

**File:** `MCBDS.PublicUI\Components\Pages\Commands.razor.css`

Add these styles:

```css
/* Command History Styles */
.command-history-section {
    margin-bottom: 1rem;
}

.history-list {
    max-height: 400px;
    overflow-y: auto;
}

.history-entry {
    padding: 0.75rem;
    border-bottom: 1px solid #dee2e6;
    transition: background-color 0.2s;
}

.history-entry:hover {
    background-color: #f8f9fa;
}

.history-entry.success {
    border-left: 3px solid #198754;
}

.history-entry.failed {
    border-left: 3px solid #dc3545;
}

.history-entry .command-text {
    cursor: pointer;
    font-family: 'Courier New', monospace;
    font-size: 0.9rem;
    color: #0066cc;
}

.history-entry .command-text:hover {
    text-decoration: underline;
}

.history-entry:last-child {
    border-bottom: none;
}
```

---

## Features

### ? Automatic Recording
- Every command sent is automatically recorded
- Success/failure status tracked
- Error messages saved for failed commands

### ? Persistent Storage
- Stored in JSON file in app data directory
- Survives app restarts
- Maximum 100 entries (configurable)

### ? Search & Filter
- Search through command history
- Real-time filtering as you type

### ? Statistics
- Success rate percentage
- Total command count
- Top 5 most used commands

### ? Quick Reuse
- Click any historical command to use it again
- Saves typing for repeated commands

### ? Clear History
- Clear all history with confirmation dialog
- Fresh start when needed

---

## File Storage Location

### Android
```
/data/data/com.mcbds.publicui/files/command-history.json
```

### Windows
```
C:\Users\<username>\AppData\Local\MCBDS.PublicUI\command-history.json
```

### iOS
```
/var/mobile/Containers/Data/Application/<GUID>/Library/command-history.json
```

---

## JSON Format Example

```json
{
  "Entries": [
    {
      "Command": "list",
      "Timestamp": "2025-01-08T10:30:45.123Z",
      "Success": true,
      "ErrorMessage": null
    },
    {
      "Command": "give @a diamond 64",
      "Timestamp": "2025-01-08T10:31:12.456Z",
      "Success": true,
      "ErrorMessage": null
    },
    {
      "Command": "tp Player1 0 100 0",
      "Timestamp": "2025-01-08T10:32:00.789Z",
      "Success": false,
      "ErrorMessage": "Player not found"
    }
  ],
  "MaxEntries": 100
}
```

---

## Testing

1. **Send Commands**: Execute various commands through the Commands page
2. **Refresh Page**: Close and reopen app to verify persistence
3. **Search**: Test search functionality with different queries
4. **Clear**: Test clear history with confirmation
5. **Reuse**: Click historical commands to populate input field

---

## Future Enhancements

- Export history to CSV/JSON
- Import/share command histories
- Command favorites/pinning
- Command templates with placeholders
- History grouping by session

---

**Status:** Ready for implementation  
**Estimated Time:** 15-20 minutes  
**Last Updated:** January 2025

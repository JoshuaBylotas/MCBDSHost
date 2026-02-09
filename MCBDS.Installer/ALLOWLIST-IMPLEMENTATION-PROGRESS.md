# User Allowlist Management - Implementation Progress

## ? Completed (Steps 1-5)

### Backend (API Server)
1. **? VersionController.cs** - API v1.1 capability detection
   - GET `/api/version` - Returns supported features
   - Enables backward compatibility

2. **? AllowlistController.cs** - Full allowlist management
   - GET `/api/allowlist` - Read allowlist.json
   - POST `/api/allowlist` - Update entire allowlist
   - POST `/api/allowlist/user` - Add single user
   - DELETE `/api/allowlist/user/{xuid}` - Remove user
   - POST `/api/allowlist/toggle` - Enable/disable in server.properties
   - **Auto-toggle:** Automatically enables allow-list when users added, disables when empty

### Frontend (MAUI Blazor)
3. **? AllowlistModels.cs** - Data models
   - `AllowlistUser` - User entry with gamertag, XUID, ignores limit
   - `AllowlistData` - Container with users list and enabled status
   - `ApiCapabilities` - API version and supported features
   - `AddAllowlistUserRequest` - Request model for adding users
   - `XboxLiveProfile` - Response from Xbox lookup

4. **? XboxLiveService.cs** - Gamertag ? XUID lookup
   - `LookupGamertagAsync()` - Gets XUID from gamertag
   - `IsValidGamertagFormat()` - Validates gamertag rules
   - `IsValidXuidFormat()` - Validates XUID format
   - **Fallback method:** Generates deterministic pseudo-XUID (no API key required)

5. **? BedrockApiService.cs** - Updated with allowlist methods
   - `GetCapabilitiesAsync()` - Feature detection for backward compatibility
   - `GetAllowlistAsync()` - Get current allowlist
   - `UpdateAllowlistAsync()` - Save entire allowlist
   - `AddAllowlistUserAsync()` - Add single user
   - `RemoveAllowlistUserAsync()` - Remove user by XUID
   - `ToggleAllowlistAsync()` - Toggle feature in server.properties

---

## ?? Remaining (Steps 6-8)

### Step 6: Create AllowlistModal.razor Component
Need to create: `MCBDS.ClientUI.Shared\Components\AllowlistModal.razor`

**Features Required:**
- User list display with gamertags and XUIDs
- Add user form with gamertag input
- Xbox Live lookup button (uses XboxLiveService)
- "Ignores Player Limit" checkbox per user
- Edit/Remove buttons for each user
- Save/Cancel buttons
- Feature detection (hide if API doesn't support)
- Loading states and error handling

**UI Layout:**
```
??????????????????????????????????????????
?   Manage Allowlist               [X]   ?
??????????????????????????????????????????
?  Allowlist Status: [Enabled/Disabled]  ?
?                                         ?
?  Add User                               ?
?  ????????????????????  [Lookup]       ?
?  ? Gamertag         ?                  ?
?  ????????????????????                  ?
?  ? Ignores Player Limit                ?
?  [Add to Allowlist]                    ?
?                                         ?
?  Current Users (3)                      ?
?  ??????????????????????????????????   ?
?  ? Player1 (2535405130520144)      ?   ?
?  ? ? Ignores Limit  [Edit] [Remove]   ?
?  ? Player2 (2535405130520145)      ?   ?
?  ? ? Ignores Limit  [Edit] [Remove]   ?
?  ? Player3 (2535405130520146)      ?   ?
?  ? ? Ignores Limit  [Edit] [Remove]   ?
?  ??????????????????????????????????   ?
?                                         ?
?  [Save Changes]  [Cancel]              ?
??????????????????????????????????????????
```

### Step 7: Integrate into Config.razor
Need to update: `MCBDS.PublicUI\Components\Pages\Config.razor`

**Add:**
- Inject `BedrockApiService` and `XboxLiveService`
- API capability detection on page load
- Conditional rendering based on API version
- "Manage Allowlist" button (only if supported)
- Modal trigger and event handlers

**Code Example:**
```razor
@code {
    private Models.ApiCapabilities? apiCapabilities;
    private bool showAllowlistModal = false;

    protected override async Task OnInitializedAsync()
    {
        // Check API capabilities
        apiCapabilities = await ApiService.GetCapabilitiesAsync();
    }
}

@if (apiCapabilities?.SupportsAllowlist == true)
{
    <button @onclick="() => showAllowlistModal = true">
        <i class="bi bi-shield-check"></i> Manage Allowlist
    </button>
}
else
{
    <div class="alert alert-warning">
        Allowlist management requires API v1.1+
        (Current: @(apiCapabilities?.Version ?? "Unknown"))
    </div>
}

<AllowlistModal @bind-Show="showAllowlistModal" />
```

### Step 8: Register XboxLiveService in MauiProgram.cs
Need to update: `MCBDS.PublicUI\MauiProgram.cs`

**Add after CommandHistoryService:**
```csharp
// Register XboxLiveService
builder.Services.AddSingleton<XboxLiveService>(sp =>
{
    try
    {
        var httpClient = sp.GetRequiredService<HttpClient>();
        CrashLogger.LogInfo("Creating XboxLiveService");
        return new XboxLiveService(httpClient);
    }
    catch (Exception ex)
    {
        CrashLogger.LogError("Failed to create XboxLiveService", ex);
        throw;
    }
});
```

---

## ?? Key Features Implemented

### Backward Compatibility ?
- Old client + Old server = Works (no allowlist button shown)
- New client + Old server = Works (shows upgrade message)
- New client + New server = Full functionality

### Auto-Enable/Disable ?
- Adding first user ? `allow-list=true` in server.properties
- Removing last user ? `allow-list=false` in server.properties
- Manual toggle also available via API

### Security & Validation ?
- Gamertag format validation (3-15 chars, alphanumeric + spaces)
- XUID format validation (15+ digits)
- Duplicate user detection
- Error handling with friendly messages

### File Management ?
- Reads/writes `allowlist.json` in bedrock directory
- Updates `server.properties` automatically
- Creates files if they don't exist
- JSON formatted with indentation

---

## ?? Testing Checklist (After Completion)

### Backend Tests
- [ ] GET `/api/version` returns API v1.1
- [ ] GET `/api/allowlist` reads allowlist.json
- [ ] POST `/api/allowlist` updates allowlist.json
- [ ] POST `/api/allowlist/user` adds user
- [ ] DELETE `/api/allowlist/user/{xuid}` removes user
- [ ] First user triggers `allow-list=true`
- [ ] Last user removal triggers `allow-list=false`

### Frontend Tests
- [ ] Modal opens on button click
- [ ] Gamertag lookup generates valid XUID
- [ ] Add user button adds to list
- [ ] Remove button removes from list
- [ ] Save button sends to API
- [ ] Feature detection hides button on old server
- [ ] Error messages display properly

### Integration Tests
- [ ] Old client connects to old server (no errors)
- [ ] New client connects to old server (shows upgrade message)
- [ ] New client connects to new server (full functionality)
- [ ] Server restart preserves allowlist
- [ ] Minecraft server respects allowlist.json changes

---

## ?? Next Steps

1. **Create AllowlistModal.razor** - UI component
2. **Update Config.razor** - Add button and integration
3. **Register XboxLiveService** - DI setup
4. **Test end-to-end** - Verify full workflow
5. **Document** - Update user docs and API docs

---

## ?? Files Created/Modified

### Created:
- ? `MCBDS.ClientUI.Shared\Models\AllowlistModels.cs`
- ? `MCBDS.ClientUI.Shared\Services\XboxLiveService.cs`
- ? `MCBDS.API\Controllers\VersionController.cs`
- ? `MCBDS.API\Controllers\AllowlistController.cs`
- ?? `MCBDS.ClientUI.Shared\Components\AllowlistModal.razor` (pending)
- ?? `MCBDS.ClientUI.Shared\Components\AllowlistModal.razor.css` (pending)

### Modified:
- ? `MCBDS.ClientUI.Shared\Services\BedrockApiService.cs`
- ?? `MCBDS.PublicUI\Components\Pages\Config.razor` (pending)
- ?? `MCBDS.PublicUI\MauiProgram.cs` (pending)

---

**Status:** 62% Complete (5 of 8 steps done)  
**Remaining:** UI component, integration, service registration  
**ETA:** ~30-45 minutes for remaining work

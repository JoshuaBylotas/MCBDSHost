# PublicUI.Web Server Configuration Fix

## Problem
The "Add Server" functionality in PublicUI.Web was not working properly because the `ServerConfigService` was using file system operations (`File.ReadAllText`, `File.WriteAllText`) which are not available in WebAssembly/browser environments.

## Solution
Created a web-specific implementation that uses browser `localStorage` for persistence.

---

## Changes Made

### 1. Created Interface: `IServerConfigService`
**File**: `MCBDS.ClientUI/MCBDS.ClientUI.Shared/Services/IServerConfigService.cs`

Defines the contract for server configuration services, allowing different implementations for different platforms:
- MAUI/Desktop: Uses file system
- Web/Blazor WebAssembly: Uses browser localStorage

### 2. Created Web Implementation: `WebServerConfigService`
**File**: `MCBDS.PublicUI.Web/Services/WebServerConfigService.cs`

Web-specific implementation that:
- Uses `IJSRuntime` to access browser `localStorage`
- Stores configuration as JSON under key `mcbds_server_config`
- Persists across browser sessions
- Works in Blazor WebAssembly environment

### 3. Updated `ServerConfigService`
**File**: `MCBDS.ClientUI/MCBDS.ClientUI.Shared/Services/ServerConfigService.cs`

Updated to implement `IServerConfigService` interface (for MAUI/desktop apps).

### 4. Updated `BedrockApiService`
**File**: `MCBDS.ClientUI/MCBDS.ClientUI.Shared/Services/BedrockApiService.cs`

Updated to use `IServerConfigService` interface instead of concrete `ServerConfigService`.

### 5. Updated `Program.cs`
**File**: `MCBDS.PublicUI.Web/Program.cs`

Updated service registration:
```csharp
// Register WebServerConfigService - uses browser localStorage
builder.Services.AddSingleton<WebServerConfigService>();

// Register interface pointing to web implementation
builder.Services.AddSingleton<IServerConfigService>(sp => 
    sp.GetRequiredService<WebServerConfigService>());

// Register BedrockApiService with interface
builder.Services.AddSingleton<BedrockApiService>(sp =>
{
    var client = sp.GetRequiredService<HttpClient>();
    var serverConfig = sp.GetRequiredService<IServerConfigService>();
    return new BedrockApiService(client, serverConfig);
});
```

### 6. Updated `ServerSwitcher.razor`
**File**: `MCBDS.PublicUI.Web/Components/ServerSwitcher.razor`

Updated to inject `IServerConfigService` interface instead of concrete type.

---

## How It Works

### Storage Mechanism
- **Key**: `mcbds_server_config`
- **Format**: JSON
- **Location**: Browser localStorage

### Example Stored Data
```json
{
  "CurrentServerUrl": "http://192.168.1.100:8080",
  "SavedServers": [
    { "Name": "Local Development", "Url": "http://localhost:8080" },
    { "Name": "Home Server", "Url": "http://192.168.1.100:8080" }
  ]
}
```

### Data Persistence
- ? Survives page refreshes
- ? Survives browser restarts
- ? Per-origin storage (isolated per domain)
- ? Does NOT sync across devices (use server-side storage for that)

---

## Testing

### Add a New Server
1. Open PublicUI.Web in browser
2. Click the server dropdown
3. Select "+ Add New Server..."
4. Enter server name and URL
5. Click the checkmark button
6. Server should be added and selected

### Verify Persistence
1. Add a server as above
2. Refresh the page (F5)
3. The added server should still be in the dropdown
4. Close and reopen the browser
5. The server should still be there

### View Stored Data
Open browser DevTools (F12) ? Application ? Local Storage:
- Look for `mcbds_server_config` key
- Should contain JSON with your server configuration

---

## Architecture

```
???????????????????????????????????????????????????????????????
?                    IServerConfigService                      ?
?  (Interface - defines contract for server config)           ?
???????????????????????????????????????????????????????????????
                       ?
       ?????????????????????????????????
       ?                               ?
???????????????               ???????????????????
?ServerConfig ?               ?WebServerConfig  ?
?Service      ?               ?Service          ?
???????????????               ???????????????????
? File System ?               ? localStorage    ?
? (MAUI/      ?               ? (Blazor WASM)   ?
?  Desktop)   ?               ?                 ?
???????????????               ???????????????????
```

---

## Files Changed

| File | Change |
|------|--------|
| `IServerConfigService.cs` | **NEW** - Interface definition |
| `WebServerConfigService.cs` | **NEW** - Browser localStorage implementation |
| `ServerConfigService.cs` | Updated to implement interface |
| `BedrockApiService.cs` | Updated to use interface |
| `Program.cs` | Updated service registration |
| `ServerSwitcher.razor` | Updated to inject interface |

---

## Status
? **Build Successful**  
? **Ready for Testing**

The server configuration will now persist correctly in the browser's localStorage.

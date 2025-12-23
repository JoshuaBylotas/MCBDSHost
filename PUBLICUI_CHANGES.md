# PublicUI Navigation Changes

## Changes Made

### 1. Navigation Menu Updated
**File:** `MCBDS.PublicUI\Components\Layout\NavMenu.razor`

- ? Renamed "Home" ? "Overview"
- ? Removed "Weather" tab
- ? Added "Commands" tab with terminal icon

### 2. Home Page Updated
**File:** `MCBDS.PublicUI\Components\Pages\Home.razor`

- ? Changed page title from "Hello, world!" to "Overview"
- ? Added descriptive welcome content
- ? Added navigation guide for users

### 3. Commands Page Created
**File:** `MCBDS.PublicUI\Components\Pages\Commands.razor`

New page with full functionality:
- ? Send commands to Minecraft server
- ? View real-time server log (auto-refreshes every 3 seconds)
- ? Restart server button
- ? Status messages with color coding
- ? Enter key support for sending commands
- ? Loading indicators for all actions

### 4. Weather Page Removed
**File:** `MCBDS.PublicUI\Components\Pages\Weather.razor`

- ? Deleted (no longer needed)

## Navigation Structure

```
MCBDS.PublicUI
??? ?? Overview (/)
??? ? Counter (/counter)
??? ?? Commands (/commands)
```

## Features in Commands Page

1. **Command Input**
   - Text input with Enter key support
   - Send button with loading state
   - Status messages (success/error/warning)

2. **Server Log Viewer**
   - Real-time log display (400px scrollable area)
   - Auto-refresh every 3 seconds
   - Manual refresh button
   - Dark theme for better readability

3. **Server Management**
   - Restart server button
   - Status feedback for all operations

## How to Test

1. Start the AppHost (to run the API)
2. Note the API URL from Aspire Dashboard
3. Update the URL in `MCBDS.PublicUI\MauiProgram.cs` if needed
4. Run MCBDS.PublicUI
5. Navigate to Commands tab
6. Try sending commands like:
   - `list` - List players
   - `say Hello World` - Broadcast message
   - `help` - Show available commands

## Integration

The Commands page uses the shared `BedrockApiService` from:
`MCBDS.ClientUI.Shared\Services\BedrockApiService.cs`

This service connects to the Aspire-orchestrated API endpoints:
- `GET /api/runner/log` - Get server log
- `POST /api/runner/send` - Send command
- `POST /api/runner/restart` - Restart server

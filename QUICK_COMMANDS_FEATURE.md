# Quick Commands Feature

## Overview
Added a Quick Commands section to the PublicUI Commands page with convenient one-click buttons for common server configuration tasks.

## New Features

### Quick Commands Section
Located at the top of the Commands page, this section provides instant access to popular server settings without needing to manually type commands.

### Available Quick Commands

#### 1. **Enable Coordinates** 
- **Button**: Green "Enable Coordinates" button with location icon
- **Command**: `gamerule showCoordinates true`
- **Effect**: Displays coordinates (X, Y, Z) in the game HUD for all players
- **Use Case**: Helpful for players to navigate, share locations, and find their way home

#### 2. **Enable 1-Player Sleep**
- **Button**: Blue "Enable 1-Player Sleep" button with moon icon
- **Command**: `gamerule playersSleepingPercentage 1`
- **Effect**: Allows a single player to sleep through the night (instead of requiring all players)
- **Use Case**: Prevents night cycles from interrupting gameplay when players are scattered

## User Interface

### Visual Design
- **Gradient Background**: Purple gradient (667eea ? 764ba2) for visual distinction
- **Icon Support**: Bootstrap icons for better visual communication
- **Responsive Layout**: Buttons adapt to screen size on mobile devices
- **Hover Effects**: Buttons lift and cast shadow on hover for better interactivity
- **Loading States**: Buttons disable and show spinner while command executes

### Layout
```
??????????????????????????????????????????????
?  ? Quick Commands                          ?
?  ???????????????????? ???????????????????? ?
?  ? ?? Enable       ? ? ?? Enable        ? ?
?  ?  Coordinates    ? ?  1-Player Sleep  ? ?
?  ???????????????????? ???????????????????? ?
??????????????????????????????????????????????
```

## Technical Implementation

### Files Modified

#### 1. `MCBDS.PublicUI/Components/Pages/Commands.razor`
Added:
- Quick Commands HTML section with two buttons
- `EnableCoordinates()` method - sends `gamerule showCoordinates true`
- `EnableOnePlayerSleep()` method - sends `gamerule playersSleepingPercentage 1`
- `SendQuickCommand()` helper method - executes command and shows feedback

#### 2. `MCBDS.PublicUI/Components/Pages/Commands.razor.css`
Added:
- `.quick-commands-section` - gradient background and padding
- Button hover animations (translateY with shadow)
- Responsive styles for mobile devices
- Color schemes for success (green) and info (blue) buttons

### Code Structure

```csharp
private async Task EnableCoordinates()
{
    await SendQuickCommand("gamerule showCoordinates true", "Coordinates enabled for all players");
}

private async Task EnableOnePlayerSleep()
{
    await SendQuickCommand("gamerule playersSleepingPercentage 1", "One-player sleep enabled");
}

private async Task SendQuickCommand(string command, string successMessage)
{
    // Execute command via API
    // Show success/error feedback
    // Refresh server log
}
```

## Benefits

### For Players
- ? Quick access to common settings
- ? No need to remember command syntax
- ? Visual feedback for command execution
- ? Mobile-friendly interface

### For Server Admins
- ? Reduce typing errors
- ? Standardized common configurations
- ? Faster server setup
- ? Easy to add more quick commands in future

## Future Enhancement Ideas

Additional quick commands that could be added:
- **Set Day**: `time set day`
- **Clear Weather**: `weather clear`
- **Keep Inventory**: `gamerule keepInventory true`
- **PvP Toggle**: `gamerule pvp true/false`
- **Set Difficulty**: `difficulty easy/normal/hard`
- **Fire Spread Off**: `gamerule doFireTick false`
- **Mob Griefing Off**: `gamerule mobGriefing false`

## Testing

### Tested Scenarios
- ? Click "Enable Coordinates" - executes command successfully
- ? Click "Enable 1-Player Sleep" - executes command successfully
- ? Buttons disable during command execution
- ? Success/error messages display correctly
- ? Server log refreshes after command
- ? Works on desktop and mobile layouts
- ? Build compiles successfully

### How to Test
1. Launch MCBDS.PublicUI app
2. Navigate to Commands page
3. Click "Enable Coordinates" button
4. Verify success message appears
5. Check server log shows gamerule command
6. Join Minecraft server and verify coordinates display in HUD
7. Repeat for "Enable 1-Player Sleep" button
8. Test sleeping with single player to verify it works

## Platform Support

| Platform | Supported | Tested |
|----------|-----------|--------|
| Windows | ? | ? |
| Android | ? | ? |
| iOS | ? | ?? |
| macOS | ? | ?? |

*Note: iOS and macOS should work but require testing on those platforms*

## API Integration

Uses existing `BedrockApiService` endpoints:
- `POST /api/runner/send` - Sends command to Minecraft server
- `GET /api/runner/log` - Retrieves updated server log

## User Experience Flow

```
1. User clicks "Enable Coordinates" button
   ?
2. Button shows loading spinner and disables
   ?
3. Command sent to API: gamerule showCoordinates true
   ?
4. API forwards command to Minecraft server
   ?
5. Success message displays: "Coordinates enabled for all players"
   ?
6. Server log auto-refreshes to show command execution
   ?
7. Players see coordinates in game HUD
```

## Accessibility

- ? Keyboard accessible (tab navigation)
- ? ARIA labels for screen readers
- ? High contrast colors
- ? Tooltip hints on hover
- ? Clear visual feedback

## Performance

- ? Instant button response
- ? No page reload required
- ? Async command execution (non-blocking)
- ? Automatic log refresh after command

## Version Info

- **Added**: 2025-01-XX
- **Platform**: .NET MAUI (net10.0)
- **Component**: MCBDS.PublicUI
- **Build Status**: ? Successful

## Related Documentation

- [Command IntelliSense](COMMAND_INTELLISENSE.md)
- [PublicUI Changes](PUBLICUI_CHANGES.md)
- [Game Rules Documentation](https://minecraft.wiki/w/Game_rule)

---

**Note**: This feature is part of the ongoing improvements to make server administration more user-friendly and accessible on mobile devices.

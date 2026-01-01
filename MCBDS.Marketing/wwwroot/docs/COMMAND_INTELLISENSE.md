# Minecraft Bedrock Server Command IntelliSense

IntelliSense support has been added to the Commands page for both MCBDS.PublicUI and MCBDS.PublicUI.Android with **real-time player tracking**.

## Features

### ?? Player Tracking (NEW!)
- **Automatic player detection** - Tracks players as they join/leave
- **Live player suggestions** - Shows only currently online players
- **Smart context detection** - Player names appear when typing player-targeting commands
- **Real-time updates** - Player list updates automatically with server log
- **Overview page display** - See all online players at a glance on the home page

### Autocomplete Dropdown
- Real-time command suggestions as you type
- Shows command name, category, syntax, and description
- Navigate with arrow keys, select with Tab/Enter
- Ctrl+Space to manually trigger

### Player Name Suggestions
- Shows online players when typing commands that accept player names
- Commands like `kick`, `ban`, `tp`, `give`, `gamemode`, etc.
- Green "Online" badge for active players
- Displays player count in dropdown header

### Inline Command Help
- Parameter details (required/optional)
- Type information
- Possible values for enums
- Clickable examples

### Command Reference Browser
- 40+ Minecraft Bedrock commands
- Organized by category
- Searchable
- Quick insertion

### Overview Page Player List (NEW!)
- **Prominent display** - Player list shown at the top of Overview page
- **Visual indicators** - Pulsing green dot for each online player
- **Player count** - Shows current/maximum players
- **Auto-refresh** - Updates every 5 seconds with status refresh
- **Responsive grid** - Adapts to screen size
- **Interactive cards** - Hover effects on each player badge
- **Empty state** - Shows helpful message when no players are online

## How Player Tracking Works

The system parses the server log in real-time to detect:

1. **Player Joins**: `Player connected: PlayerName, xuid: ...`
2. **Player Leaves**: `Player disconnected: PlayerName, xuid: ...`
3. **List Command**: `There are X out of maximum Y players online: Player1, Player2, ...`

### Smart Parameter Detection

When you type a command, the system checks if the current parameter accepts player names:
- **Commands with player parameters**: kick, ban, op, deop, give, clear, effect, xp, tp, teleport, gamemode, title, etc.
- **Shows player suggestions**: Only when typing the player name portion
- **Keyboard navigation**: Arrow keys to select, Tab/Enter to insert

### Example Usage

```
Type: kick <space>
Result: Shows dropdown with all online players

Type: kick St
Result: Filters to players starting with "St" (e.g., Steve, Steve123)

Select: Use arrow keys or mouse, press Tab/Enter
Result: "kick Steve " (ready for optional reason parameter)
```

## Keyboard Shortcuts
- **Ctrl+Space** - Show suggestions
- **?/?** - Navigate command or player suggestions
- **Tab/Enter** - Select suggestion
- **Esc** - Close suggestions
- **Enter** - Send command

## Benefits

- ? **No typos** - Select player names from list instead of typing
- ? **See who's online** - Know exactly which players are connected
- ? **Faster commands** - No need to type full player names
- ? **Context-aware** - Suggestions appear only when relevant
- ? **Always current** - Updates automatically as players join/leave
- ? **Overview at a glance** - See all players on home page
- ? **Visual feedback** - Pulsing indicators show live player status
- ? **Mobile friendly** - Works seamlessly on both desktop and Android

## Files Modified/Created

### New Files
- `MCBDS.PublicUI/Components/PlayerTracker.cs` - Player tracking service (NEW)
- `MCBDS.PublicUI/Components/BedrockCommands.cs` - Command database
- `MCBDS.PublicUI.Android/Components/PlayerTracker.cs` - Android version (NEW)
- `MCBDS.PublicUI.Android/Components/BedrockCommands.cs` - Android version

### Updated Files
- `MCBDS.PublicUI/Components/Pages/Commands.razor` - IntelliSense + Player tracking UI
- `MCBDS.PublicUI/Components/Pages/Commands.razor.css` - Styling for player dropdown
- `MCBDS.PublicUI/Components/Pages/Home.razor` - Overview page with player list (NEW)
- `MCBDS.PublicUI/Components/Pages/Home.razor.css` - Player list styling (NEW)
- `MCBDS.PublicUI.Android/Components/Pages/Commands.razor` - Android version
- `MCBDS.PublicUI.Android/Components/Pages/Commands.razor.css` - Android styling
- `MCBDS.PublicUI.Android/Components/Pages/Home.razor` - Android overview page (NEW)
- `MCBDS.PublicUI.Android/Components/Pages/Home.razor.css` - Android player list styling (NEW)

## Technical Details

### PlayerTracker Class

```csharp
public class PlayerTracker
{
    // Track players in real-time
    public IReadOnlyCollection<string> OnlinePlayers { get; }
    public int PlayerCount { get; }
    
    // Parse log for player events
    public void ParseLog(string logContent);
    public void ParseLogLine(string line);
    
    // Manual control
    public void AddPlayer(string playerName);
    public void RemovePlayer(string playerName);
    public void Clear();
    
    // Query methods
    public bool IsPlayerOnline(string playerName);
    public List<string> GetPlayerSuggestions(string partialName = "");
}
```

### Log Patterns Detected

1. **Join**: `Player connected: Steve, xuid: 1234567890`
2. **Leave**: `Player disconnected: Steve, xuid: 1234567890`
3. **List**: `There are 2 out of maximum 10 players online: Steve, Alex`

### Integration Flow

1. User types command in input field
2. System detects command and current parameter
3. If parameter type is "target", shows player suggestions
4. PlayerTracker provides list of online players
5. User selects player from dropdown
6. Player name inserted into command
7. Command executed, log refreshed
8. PlayerTracker updates from new log content

## Commands with Player Parameters

The following commands automatically show player suggestions:

- `kick <player>` - Kick player
- `ban <player>` - Ban player
- `pardon <player>` - Unban player
- `op <player>` - Grant operator
- `deop <player>` - Revoke operator
- `whitelist add/remove <player>` - Whitelist management
- `tell <player>` - Send private message
- `w <player>` / `msg <player>` - Message aliases
- `gamemode <mode> <player>` - Change game mode
- `give <player> <item>` - Give items
- `clear <player>` - Clear inventory
- `effect <player>` - Apply effects
- `xp <amount> <player>` - Give experience
- `tp <player>` or `tp <x> <y> <z> <player>` - Teleport
- `teleport <player>` - Teleport (extended)
- `title <player>` - Show title
- `kill <player>` - Kill entity

## Future Enhancements

Potential additions:
- Tab completion for item names
- Entity type suggestions for summon command
- Gamerule name completion
- Command history with up/down arrows
- Persistent player cache across sessions
- XP/inventory tracking integration
- Permission level indicators
- Offline player suggestions (from whitelist/ops)

---

**Note**: Player tracking requires the server log to be accessible and updated regularly. The system automatically refreshes the log every 3 seconds to keep the player list current.

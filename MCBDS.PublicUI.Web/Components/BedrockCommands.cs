namespace MCBDS.PublicUI.Web.Components;

public class MinecraftCommand
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Syntax { get; set; } = string.Empty;
    public List<CommandParameter> Parameters { get; set; } = new();
    public List<string> Examples { get; set; } = new();
    public string Category { get; set; } = string.Empty;
}

public class CommandParameter
{
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool Required { get; set; }
    public string Description { get; set; } = string.Empty;
    public List<string>? PossibleValues { get; set; }
}

public static class BedrockCommands
{
    public static readonly List<MinecraftCommand> All = new()
    {
        // Player Management
        new MinecraftCommand { Name = "kick", Description = "Kicks a player from the server", Syntax = "kick <player: target> [reason: message]", Category = "Player Management",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to kick" }, new() { Name = "reason", Type = "message", Required = false, Description = "Reason for kick" } },
            Examples = new() { "kick Steve", "kick Steve Griefing" } },
        new MinecraftCommand { Name = "ban", Description = "Bans a player from the server", Syntax = "ban <player: target> [reason: message]", Category = "Player Management",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to ban" } }, Examples = new() { "ban Steve" } },
        new MinecraftCommand { Name = "pardon", Description = "Removes a player from the ban list", Syntax = "pardon <player: target>", Category = "Player Management",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to unban" } }, Examples = new() { "pardon Steve" } },
        new MinecraftCommand { Name = "op", Description = "Grants operator status to a player", Syntax = "op <player: target>", Category = "Player Management",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to op" } }, Examples = new() { "op Steve" } },
        new MinecraftCommand { Name = "deop", Description = "Revokes operator status from a player", Syntax = "deop <player: target>", Category = "Player Management",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to deop" } }, Examples = new() { "deop Steve" } },
        new MinecraftCommand { Name = "whitelist", Description = "Manages the whitelist", Syntax = "whitelist <on|off|list|add|remove> [player: target]", Category = "Player Management",
            Parameters = new() { new() { Name = "action", Type = "string", Required = true, Description = "Whitelist action", PossibleValues = new() { "on", "off", "list", "add", "remove" } } }, Examples = new() { "whitelist on", "whitelist add Steve" } },

        // Information Commands
        new MinecraftCommand { Name = "list", Description = "Lists all connected players", Syntax = "list", Category = "Information", Parameters = new(), Examples = new() { "list" } },
        new MinecraftCommand { Name = "help", Description = "Shows help for commands", Syntax = "help [command: string]", Category = "Information",
            Parameters = new() { new() { Name = "command", Type = "string", Required = false, Description = "Command to get help for" } }, Examples = new() { "help", "help kick" } },

        // Server Management
        new MinecraftCommand { Name = "stop", Description = "Stops the server gracefully", Syntax = "stop", Category = "Server Management", Parameters = new(), Examples = new() { "stop" } },
        new MinecraftCommand { Name = "save-all", Description = "Saves the world to disk", Syntax = "save-all [flush]", Category = "Server Management", Parameters = new(), Examples = new() { "save-all" } },
        new MinecraftCommand { Name = "save-on", Description = "Enables automatic world saving", Syntax = "save-on", Category = "Server Management", Parameters = new(), Examples = new() { "save-on" } },
        new MinecraftCommand { Name = "save-off", Description = "Disables automatic world saving", Syntax = "save-off", Category = "Server Management", Parameters = new(), Examples = new() { "save-off" } },

        // Communication
        new MinecraftCommand { Name = "say", Description = "Broadcasts a message to all players", Syntax = "say <message: message>", Category = "Communication",
            Parameters = new() { new() { Name = "message", Type = "message", Required = true, Description = "Message to broadcast" } }, Examples = new() { "say Hello everyone!" } },
        new MinecraftCommand { Name = "tell", Description = "Sends a private message to a player", Syntax = "tell <player: target> <message: message>", Category = "Communication",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true, Description = "Player to message" }, new() { Name = "message", Type = "message", Required = true, Description = "Message" } }, Examples = new() { "tell Steve Hello!" } },

        // World Management
        new MinecraftCommand { Name = "difficulty", Description = "Sets the difficulty level", Syntax = "difficulty <peaceful|easy|normal|hard>", Category = "World Management",
            Parameters = new() { new() { Name = "level", Type = "string", Required = true, PossibleValues = new() { "peaceful", "easy", "normal", "hard" } } }, Examples = new() { "difficulty hard" } },
        new MinecraftCommand { Name = "gamemode", Description = "Changes a player's game mode", Syntax = "gamemode <mode> [player: target]", Category = "World Management",
            Parameters = new() { new() { Name = "mode", Type = "string", Required = true, PossibleValues = new() { "survival", "creative", "adventure", "spectator" } } }, Examples = new() { "gamemode creative Steve" } },
        new MinecraftCommand { Name = "gamerule", Description = "Sets or queries a game rule", Syntax = "gamerule <rule> [value: bool]", Category = "World Management",
            Parameters = new() { new() { Name = "rule", Type = "gamerule", Required = true, PossibleValues = new() { "commandBlockOutput", "doDaylightCycle", "doMobSpawning", "keepInventory", "mobGriefing", "pvp", "showCoordinates" } } }, Examples = new() { "gamerule keepInventory true" } },
        new MinecraftCommand { Name = "time", Description = "Changes or queries the world time", Syntax = "time <set|add|query> <value>", Category = "World Management",
            Parameters = new() { new() { Name = "action", Type = "string", Required = true, PossibleValues = new() { "set", "add", "query" } } }, Examples = new() { "time set day" } },
        new MinecraftCommand { Name = "weather", Description = "Sets the weather", Syntax = "weather <clear|rain|thunder> [duration: int]", Category = "World Management",
            Parameters = new() { new() { Name = "type", Type = "string", Required = true, PossibleValues = new() { "clear", "rain", "thunder" } } }, Examples = new() { "weather clear" } },

        // Player Effects
        new MinecraftCommand { Name = "give", Description = "Gives an item to a player", Syntax = "give <player: target> <item: string> [amount: int]", Category = "Player Effects",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true }, new() { Name = "item", Type = "string", Required = true } }, Examples = new() { "give Steve diamond 64" } },
        new MinecraftCommand { Name = "clear", Description = "Clears items from player inventory", Syntax = "clear [player: target] [item: string]", Category = "Player Effects",
            Parameters = new() { new() { Name = "player", Type = "target", Required = false } }, Examples = new() { "clear Steve" } },
        new MinecraftCommand { Name = "effect", Description = "Adds or removes status effects", Syntax = "effect <player: target> <effect: string> [seconds: int]", Category = "Player Effects",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true }, new() { Name = "effect", Type = "string", Required = true } }, Examples = new() { "effect Steve speed 60" } },
        new MinecraftCommand { Name = "tp", Description = "Teleports entities", Syntax = "tp <destination: target> OR tp <x> <y> <z>", Category = "Player Effects",
            Parameters = new() { new() { Name = "destination", Type = "target", Required = true } }, Examples = new() { "tp Steve Alex", "tp 100 64 200" } },
        new MinecraftCommand { Name = "xp", Description = "Adds or removes experience points", Syntax = "xp <amount> [player: target]", Category = "Player Effects",
            Parameters = new() { new() { Name = "amount", Type = "int", Required = true } }, Examples = new() { "xp 100 Steve" } },

        // Entity Management
        new MinecraftCommand { Name = "summon", Description = "Summons an entity", Syntax = "summon <entityType: string> [x] [y] [z]", Category = "Entity Management",
            Parameters = new() { new() { Name = "entityType", Type = "string", Required = true } }, Examples = new() { "summon zombie" } },
        new MinecraftCommand { Name = "kill", Description = "Kills entities", Syntax = "kill [target: target]", Category = "Entity Management",
            Parameters = new() { new() { Name = "target", Type = "target", Required = false } }, Examples = new() { "kill @e[type=zombie]" } },

        // Advanced
        new MinecraftCommand { Name = "title", Description = "Displays a title on screen", Syntax = "title <player: target> <action> [text]", Category = "Advanced",
            Parameters = new() { new() { Name = "player", Type = "target", Required = true }, new() { Name = "action", Type = "string", Required = true, PossibleValues = new() { "title", "subtitle", "actionbar", "clear" } } }, Examples = new() { "title @a title Welcome!" } },
    };

    public static List<MinecraftCommand> SearchCommands(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return All;
        query = query.ToLower().Trim();
        return All.Where(cmd => cmd.Name.ToLower().StartsWith(query) || cmd.Description.ToLower().Contains(query)).ToList();
    }

    public static MinecraftCommand? GetCommand(string name) => All.FirstOrDefault(cmd => cmd.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
    public static List<string> GetCategories() => All.Select(cmd => cmd.Category).Distinct().OrderBy(c => c).ToList();
}

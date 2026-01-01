namespace MCBDS.PublicUI.Android.Components;

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
        new MinecraftCommand
        {
            Name = "kick",
            Description = "Kicks a player from the server",
            Syntax = "kick <player: target> [reason: message]",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to kick" },
                new() { Name = "reason", Type = "message", Required = false, Description = "Reason for kick" }
            },
            Examples = new() { "kick Steve", "kick Steve Griefing" }
        },
        new MinecraftCommand
        {
            Name = "ban",
            Description = "Bans a player from the server",
            Syntax = "ban <player: target> [reason: message]",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to ban" },
                new() { Name = "reason", Type = "message", Required = false, Description = "Reason for ban" }
            },
            Examples = new() { "ban Steve", "ban Steve Cheating" }
        },
        new MinecraftCommand
        {
            Name = "ban-ip",
            Description = "Bans an IP address from the server",
            Syntax = "ban-ip <ip: string> [reason: message]",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "ip", Type = "string", Required = true, Description = "IP address to ban" },
                new() { Name = "reason", Type = "message", Required = false, Description = "Reason for ban" }
            },
            Examples = new() { "ban-ip 192.168.1.1" }
        },
        new MinecraftCommand
        {
            Name = "pardon",
            Description = "Removes a player from the ban list",
            Syntax = "pardon <player: target>",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to unban" }
            },
            Examples = new() { "pardon Steve" }
        },
        new MinecraftCommand
        {
            Name = "pardon-ip",
            Description = "Removes an IP address from the ban list",
            Syntax = "pardon-ip <ip: string>",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "ip", Type = "string", Required = true, Description = "IP address to unban" }
            },
            Examples = new() { "pardon-ip 192.168.1.1" }
        },
        new MinecraftCommand
        {
            Name = "op",
            Description = "Grants operator status to a player",
            Syntax = "op <player: target>",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to op" }
            },
            Examples = new() { "op Steve" }
        },
        new MinecraftCommand
        {
            Name = "deop",
            Description = "Revokes operator status from a player",
            Syntax = "deop <player: target>",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to deop" }
            },
            Examples = new() { "deop Steve" }
        },
        new MinecraftCommand
        {
            Name = "whitelist",
            Description = "Manages the whitelist",
            Syntax = "whitelist <on|off|list|add|remove> [player: target]",
            Category = "Player Management",
            Parameters = new()
            {
                new() { Name = "action", Type = "string", Required = true, Description = "Whitelist action", 
                    PossibleValues = new() { "on", "off", "list", "add", "remove" } },
                new() { Name = "player", Type = "target", Required = false, Description = "Player name (for add/remove)" }
            },
            Examples = new() { "whitelist on", "whitelist add Steve", "whitelist remove Alex", "whitelist list" }
        },

        // Information Commands
        new MinecraftCommand
        {
            Name = "list",
            Description = "Lists all connected players",
            Syntax = "list",
            Category = "Information",
            Parameters = new(),
            Examples = new() { "list" }
        },
        new MinecraftCommand
        {
            Name = "help",
            Description = "Shows help for commands",
            Syntax = "help [command: string]",
            Category = "Information",
            Parameters = new()
            {
                new() { Name = "command", Type = "string", Required = false, Description = "Command to get help for" }
            },
            Examples = new() { "help", "help kick" }
        },
        new MinecraftCommand
        {
            Name = "?",
            Description = "Alias for help command",
            Syntax = "? [command: string]",
            Category = "Information",
            Parameters = new()
            {
                new() { Name = "command", Type = "string", Required = false, Description = "Command to get help for" }
            },
            Examples = new() { "?", "? kick" }
        },

        // Server Management
        new MinecraftCommand
        {
            Name = "stop",
            Description = "Stops the server gracefully",
            Syntax = "stop",
            Category = "Server Management",
            Parameters = new(),
            Examples = new() { "stop" }
        },
        new MinecraftCommand
        {
            Name = "save-all",
            Description = "Saves the world to disk",
            Syntax = "save-all [flush]",
            Category = "Server Management",
            Parameters = new()
            {
                new() { Name = "flush", Type = "string", Required = false, Description = "Force immediate save", PossibleValues = new() { "flush" } }
            },
            Examples = new() { "save-all", "save-all flush" }
        },
        new MinecraftCommand
        {
            Name = "save-on",
            Description = "Enables automatic world saving",
            Syntax = "save-on",
            Category = "Server Management",
            Parameters = new(),
            Examples = new() { "save-on" }
        },
        new MinecraftCommand
        {
            Name = "save-off",
            Description = "Disables automatic world saving",
            Syntax = "save-off",
            Category = "Server Management",
            Parameters = new(),
            Examples = new() { "save-off" }
        },

        // Communication
        new MinecraftCommand
        {
            Name = "say",
            Description = "Broadcasts a message to all players",
            Syntax = "say <message: message>",
            Category = "Communication",
            Parameters = new()
            {
                new() { Name = "message", Type = "message", Required = true, Description = "Message to broadcast" }
            },
            Examples = new() { "say Server restarting in 5 minutes", "say Welcome to our server!" }
        },
        new MinecraftCommand
        {
            Name = "tell",
            Description = "Sends a private message to a player",
            Syntax = "tell <player: target> <message: message>",
            Category = "Communication",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to message" },
                new() { Name = "message", Type = "message", Required = true, Description = "Message to send" }
            },
            Examples = new() { "tell Steve Hello!", "tell Alex Check your inventory" }
        },
        new MinecraftCommand
        {
            Name = "w",
            Description = "Alias for tell command",
            Syntax = "w <player: target> <message: message>",
            Category = "Communication",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to message" },
                new() { Name = "message", Type = "message", Required = true, Description = "Message to send" }
            },
            Examples = new() { "w Steve Hello!" }
        },
        new MinecraftCommand
        {
            Name = "msg",
            Description = "Alias for tell command",
            Syntax = "msg <player: target> <message: message>",
            Category = "Communication",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to message" },
                new() { Name = "message", Type = "message", Required = true, Description = "Message to send" }
            },
            Examples = new() { "msg Steve Hello!" }
        },

        // World Management
        new MinecraftCommand
        {
            Name = "difficulty",
            Description = "Sets the difficulty level",
            Syntax = "difficulty <peaceful|easy|normal|hard>",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "level", Type = "string", Required = true, Description = "Difficulty level",
                    PossibleValues = new() { "peaceful", "easy", "normal", "hard", "p", "e", "n", "h", "0", "1", "2", "3" } }
            },
            Examples = new() { "difficulty peaceful", "difficulty hard", "difficulty 2" }
        },
        new MinecraftCommand
        {
            Name = "defaultgamemode",
            Description = "Sets the default game mode for new players",
            Syntax = "defaultgamemode <survival|creative|adventure|spectator>",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "mode", Type = "string", Required = true, Description = "Game mode",
                    PossibleValues = new() { "survival", "creative", "adventure", "spectator", "s", "c", "a", "sp", "0", "1", "2", "6" } }
            },
            Examples = new() { "defaultgamemode survival", "defaultgamemode creative" }
        },
        new MinecraftCommand
        {
            Name = "gamemode",
            Description = "Changes a player's game mode",
            Syntax = "gamemode <mode> [player: target]",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "mode", Type = "string", Required = true, Description = "Game mode",
                    PossibleValues = new() { "survival", "creative", "adventure", "spectator", "s", "c", "a", "sp", "0", "1", "2", "6" } },
                new() { Name = "player", Type = "target", Required = false, Description = "Player to change (defaults to command executor)" }
            },
            Examples = new() { "gamemode creative", "gamemode survival Steve", "gamemode c Alex" }
        },
        new MinecraftCommand
        {
            Name = "gamerule",
            Description = "Sets or queries a game rule",
            Syntax = "gamerule <rule> [value: bool]",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "rule", Type = "gamerule", Required = true, Description = "Game rule name",
                    PossibleValues = new() { 
                        // Common Game Rules
                        "commandBlockOutput", "doDaylightCycle", "doEntityDrops", "doFireTick", 
                        "doInsomnia", "doMobLoot", "doMobSpawning", "doTileDrops", "doWeatherCycle", 
                        "drowningDamage", "fallDamage", "fireDamage", "freezeDamage",
                        "keepInventory", "mobGriefing", "naturalRegeneration", "pvp",
                        "randomTickSpeed", "sendCommandFeedback", "showCoordinates", "showDeathMessages", 
                        "spawnRadius", "tntExplodes",
                        // Additional Bedrock Rules
                        "announceAdvancements", "disableElytraMovementCheck", "doImmediateRespawn",
                        "doLimitedCrafting", "maxCommandChainLength", "maxEntityCramming",
                        "playersSleepingPercentage", "reducedDebugInfo", "respawnBlocksExplode",
                        "showBorderEffect", "showTags", "spectatorsGenerateChunks",
                        "universalAnger", "doPatrolSpawning", "doTraderSpawning"
                    } },
                new() { Name = "value", Type = "bool", Required = false, Description = "Rule value (true/false)" }
            },
            Examples = new() { "gamerule keepInventory true", "gamerule doDaylightCycle false", "gamerule showCoordinates" }
        },
        new MinecraftCommand
        {
            Name = "time",
            Description = "Changes or queries the world time",
            Syntax = "time <set|add|query> <value>",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "action", Type = "string", Required = true, Description = "Time action",
                    PossibleValues = new() { "set", "add", "query" } },
                new() { Name = "value", Type = "string", Required = true, Description = "Time value or query type",
                    PossibleValues = new() { "day", "night", "noon", "midnight", "sunrise", "sunset", "daytime", "gametime" } }
            },
            Examples = new() { "time set day", "time set 1000", "time add 1000", "time query daytime" }
        },
        new MinecraftCommand
        {
            Name = "weather",
            Description = "Sets the weather",
            Syntax = "weather <clear|rain|thunder> [duration: int]",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "type", Type = "string", Required = true, Description = "Weather type",
                    PossibleValues = new() { "clear", "rain", "thunder" } },
                new() { Name = "duration", Type = "int", Required = false, Description = "Duration in seconds" }
            },
            Examples = new() { "weather clear", "weather rain 600", "weather thunder" }
        },
        new MinecraftCommand
        {
            Name = "setworldspawn",
            Description = "Sets the world spawn point",
            Syntax = "setworldspawn [x: int] [y: int] [z: int]",
            Category = "World Management",
            Parameters = new()
            {
                new() { Name = "x", Type = "int", Required = false, Description = "X coordinate" },
                new() { Name = "y", Type = "int", Required = false, Description = "Y coordinate" },
                new() { Name = "z", Type = "int", Required = false, Description = "Z coordinate" }
            },
            Examples = new() { "setworldspawn", "setworldspawn 100 64 200" }
        },

        // Player Effects
        new MinecraftCommand
        {
            Name = "give",
            Description = "Gives an item to a player",
            Syntax = "give <player: target> <item: string> [amount: int] [data: int]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to give item to" },
                new() { Name = "item", Type = "string", Required = true, Description = "Item ID (e.g., diamond_sword)" },
                new() { Name = "amount", Type = "int", Required = false, Description = "Amount (default: 1)" },
                new() { Name = "data", Type = "int", Required = false, Description = "Data value" }
            },
            Examples = new() { "give Steve diamond_sword", "give Alex diamond 64", "give @a bread 16" }
        },
        new MinecraftCommand
        {
            Name = "clear",
            Description = "Clears items from player inventory",
            Syntax = "clear [player: target] [item: string] [data: int] [maxCount: int]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = false, Description = "Player to clear" },
                new() { Name = "item", Type = "string", Required = false, Description = "Item to clear" },
                new() { Name = "data", Type = "int", Required = false, Description = "Data value" },
                new() { Name = "maxCount", Type = "int", Required = false, Description = "Maximum amount to clear" }
            },
            Examples = new() { "clear", "clear Steve", "clear @a diamond_sword" }
        },
        new MinecraftCommand
        {
            Name = "effect",
            Description = "Adds or removes status effects",
            Syntax = "effect <player: target> <effect: string> [seconds: int] [amplifier: int] [hideParticles: bool]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to affect" },
                new() { Name = "effect", Type = "string", Required = true, Description = "Effect name (e.g., speed, clear)" },
                new() { Name = "seconds", Type = "int", Required = false, Description = "Duration in seconds" },
                new() { Name = "amplifier", Type = "int", Required = false, Description = "Effect amplifier (0-255)" },
                new() { Name = "hideParticles", Type = "bool", Required = false, Description = "Hide particles (true/false)" }
            },
            Examples = new() { "effect Steve speed 30 1", "effect @a clear", "effect Alex regeneration 60 2 true" }
        },
        new MinecraftCommand
        {
            Name = "xp",
            Description = "Adds or removes experience points",
            Syntax = "xp <amount> [player: target] [L]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "amount", Type = "int", Required = true, Description = "Amount of XP" },
                new() { Name = "player", Type = "target", Required = false, Description = "Player to give XP to" },
                new() { Name = "L", Type = "string", Required = false, Description = "Add levels instead of points", PossibleValues = new() { "L" } }
            },
            Examples = new() { "xp 100", "xp 5 Steve L", "xp -10 Alex" }
        },
        new MinecraftCommand
        {
            Name = "tp",
            Description = "Teleports entities",
            Syntax = "tp <destination: target> OR tp <x> <y> <z> [player: target]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "destination OR x", Type = "target OR int", Required = true, Description = "Destination player OR X coordinate" },
                new() { Name = "y", Type = "int", Required = false, Description = "Y coordinate" },
                new() { Name = "z", Type = "int", Required = false, Description = "Z coordinate" },
                new() { Name = "player", Type = "target", Required = false, Description = "Player to teleport" }
            },
            Examples = new() { "tp Steve Alex", "tp 100 64 200", "tp Steve 0 100 0" }
        },
        new MinecraftCommand
        {
            Name = "teleport",
            Description = "Teleports entities (extended version)",
            Syntax = "teleport <destination: target> OR teleport <x> <y> <z> [facing options]",
            Category = "Player Effects",
            Parameters = new()
            {
                new() { Name = "destination OR x", Type = "target OR int", Required = true, Description = "Destination player OR X coordinate" },
                new() { Name = "y", Type = "int", Required = false, Description = "Y coordinate" },
                new() { Name = "z", Type = "int", Required = false, Description = "Z coordinate" }
            },
            Examples = new() { "teleport Steve 100 64 200", "teleport @a 0 100 0" }
        },

        // Entity Management
        new MinecraftCommand
        {
            Name = "summon",
            Description = "Summons an entity",
            Syntax = "summon <entityType: string> [x: int] [y: int] [z: int] [spawnEvent: string]",
            Category = "Entity Management",
            Parameters = new()
            {
                new() { Name = "entityType", Type = "string", Required = true, Description = "Entity type (e.g., zombie, creeper)" },
                new() { Name = "x", Type = "int", Required = false, Description = "X coordinate" },
                new() { Name = "y", Type = "int", Required = false, Description = "Y coordinate" },
                new() { Name = "z", Type = "int", Required = false, Description = "Z coordinate" },
                new() { Name = "spawnEvent", Type = "string", Required = false, Description = "Spawn event" }
            },
            Examples = new() { "summon zombie", "summon creeper 100 64 200", "summon villager ~ ~ ~" }
        },
        new MinecraftCommand
        {
            Name = "kill",
            Description = "Kills entities",
            Syntax = "kill [target: target]",
            Category = "Entity Management",
            Parameters = new()
            {
                new() { Name = "target", Type = "target", Required = false, Description = "Entity to kill (@e for all entities)" }
            },
            Examples = new() { "kill", "kill Steve", "kill @e[type=zombie]" }
        },

        // Advanced
        new MinecraftCommand
        {
            Name = "execute",
            Description = "Executes a command as another entity",
            Syntax = "execute <target> <x> <y> <z> <command>",
            Category = "Advanced",
            Parameters = new()
            {
                new() { Name = "target", Type = "target", Required = true, Description = "Entity to execute as" },
                new() { Name = "x", Type = "int", Required = true, Description = "X coordinate" },
                new() { Name = "y", Type = "int", Required = true, Description = "Y coordinate" },
                new() { Name = "z", Type = "int", Required = true, Description = "Z coordinate" },
                new() { Name = "command", Type = "string", Required = true, Description = "Command to execute" }
            },
            Examples = new() { "execute @a ~ ~ ~ say I'm at my location" }
        },
        new MinecraftCommand
        {
            Name = "testfor",
            Description = "Tests for entities matching specified conditions",
            Syntax = "testfor <target: target>",
            Category = "Advanced",
            Parameters = new()
            {
                new() { Name = "target", Type = "target", Required = true, Description = "Target selector" }
            },
            Examples = new() { "testfor @a", "testfor Steve" }
        },
        new MinecraftCommand
        {
            Name = "title",
            Description = "Displays a title on screen",
            Syntax = "title <player: target> <title|subtitle|actionbar|clear|reset|times> [text]",
            Category = "Advanced",
            Parameters = new()
            {
                new() { Name = "player", Type = "target", Required = true, Description = "Player to show title to" },
                new() { Name = "action", Type = "string", Required = true, Description = "Title action",
                    PossibleValues = new() { "title", "subtitle", "actionbar", "clear", "reset", "times" } },
                new() { Name = "text", Type = "string", Required = false, Description = "Title text" }
            },
            Examples = new() { "title @a title Welcome!", "title Steve subtitle Enjoy your stay", "title @a clear" }
        },
        new MinecraftCommand
        {
            Name = "scoreboard",
            Description = "Manages scoreboard objectives and players",
            Syntax = "scoreboard <objectives|players> <action> [parameters]",
            Category = "Advanced",
            Parameters = new()
            {
                new() { Name = "type", Type = "string", Required = true, Description = "Scoreboard type",
                    PossibleValues = new() { "objectives", "players" } },
                new() { Name = "action", Type = "string", Required = true, Description = "Action to perform" }
            },
            Examples = new() { "scoreboard objectives add deaths dummy", "scoreboard players set Steve deaths 0" }
        }
    };

    public static List<MinecraftCommand> SearchCommands(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return All;

        query = query.ToLower().Trim();
        
        return All.Where(cmd => 
            cmd.Name.ToLower().StartsWith(query) ||
            cmd.Description.ToLower().Contains(query) ||
            cmd.Category.ToLower().Contains(query)
        ).ToList();
    }

    public static MinecraftCommand? GetCommand(string name)
    {
        return All.FirstOrDefault(cmd => cmd.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
    }

    public static List<string> GetCategories()
    {
        return All.Select(cmd => cmd.Category).Distinct().OrderBy(c => c).ToList();
    }
}

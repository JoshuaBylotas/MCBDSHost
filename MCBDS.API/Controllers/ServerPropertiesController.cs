using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using MCBDS.API.Models;

namespace MCBDS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ServerPropertiesController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<ServerPropertiesController> _logger;

    public ServerPropertiesController(
        IConfiguration configuration,
        ILogger<ServerPropertiesController> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    [HttpGet]
    public IActionResult GetServerProperties()
    {
        try
        {
            var serverPropertiesPath = GetServerPropertiesPath();
            
            if (string.IsNullOrEmpty(serverPropertiesPath))
            {
                return NotFound(new { error = "Could not determine server.properties location" });
            }

            if (!System.IO.File.Exists(serverPropertiesPath))
            {
                return NotFound(new { 
                    error = "server.properties file not found", 
                    path = serverPropertiesPath 
                });
            }

            _logger.LogInformation("Reading server.properties from: {Path}", serverPropertiesPath);

            var properties = new Dictionary<string, ServerProperty>();
            var lines = System.IO.File.ReadAllLines(serverPropertiesPath);

            foreach (var line in lines)
            {
                var trimmedLine = line.Trim();
                
                // Skip empty lines and comments
                if (string.IsNullOrWhiteSpace(trimmedLine) || trimmedLine.StartsWith('#'))
                {
                    continue;
                }

                var equalsIndex = trimmedLine.IndexOf('=');
                if (equalsIndex > 0)
                {
                    var key = trimmedLine.Substring(0, equalsIndex).Trim();
                    var value = equalsIndex < trimmedLine.Length - 1 
                        ? trimmedLine.Substring(equalsIndex + 1).Trim() 
                        : string.Empty;

                    properties[key] = new ServerProperty
                    {
                        Key = key,
                        Value = value,
                        Description = GetPropertyDescription(key),
                        Category = GetPropertyCategory(key)
                    };
                }
            }

            // Group by category for easier display
            var grouped = properties.Values
                .GroupBy(p => p.Category)
                .OrderBy(g => GetCategoryOrder(g.Key))
                .Select(g => new
                {
                    Category = g.Key,
                    Properties = g.OrderBy(p => p.Key).ToList()
                })
                .ToList();

            return Ok(new
            {
                path = serverPropertiesPath,
                lastModified = System.IO.File.GetLastWriteTime(serverPropertiesPath),
                totalProperties = properties.Count,
                categories = grouped
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading server.properties");
            return StatusCode(500, new { error = "Failed to read server.properties", message = ex.Message });
        }
    }

    private string? GetServerPropertiesPath()
    {
        // Try to get the path from Runner:ExePath configuration
        var exePath = _configuration["Runner:ExePath"];
        if (!string.IsNullOrWhiteSpace(exePath))
        {
            var bedrockDir = Path.GetDirectoryName(exePath);
            if (!string.IsNullOrEmpty(bedrockDir))
            {
                var propsPath = Path.Combine(bedrockDir, "server.properties");
                if (System.IO.File.Exists(propsPath))
                {
                    return propsPath;
                }
            }
        }

        // Fallback to current directory
        var currentDirPath = Path.Combine(Directory.GetCurrentDirectory(), "server.properties");
        if (System.IO.File.Exists(currentDirPath))
        {
            return currentDirPath;
        }

        return null;
    }

    private static string GetPropertyDescription(string key)
    {
        return key switch
        {
            "server-name" => "The server name shown in the in-game server list",
            "gamemode" => "Default game mode (survival, creative, adventure)",
            "force-gamemode" => "Force players to use the default gamemode",
            "difficulty" => "World difficulty (peaceful, easy, normal, hard)",
            "allow-cheats" => "Allow commands and cheats",
            "max-players" => "Maximum number of players allowed",
            "server-port" => "IPv4 port for the server",
            "server-portv6" => "IPv6 port for the server",
            "enable-lan-visibility" => "Allow LAN discovery",
            "level-name" => "Name of the world folder",
            "level-seed" => "World generation seed",
            "online-mode" => "Require Xbox Live authentication",
            "allow-list" => "Use allowlist for player access",
            "view-distance" => "Maximum view distance in chunks",
            "player-idle-timeout" => "Minutes before kicking idle players (0 = disabled)",
            "max-threads" => "Maximum server threads (0 = auto)",
            "tick-distance" => "Simulation distance in chunks",
            "default-player-permission-level" => "Default permission for new players",
            "texturepack-required" => "Force texture pack download",
            "content-log-file-enabled" => "Enable content error logging",
            "compression-threshold" => "Network compression threshold",
            "compression-algorithm" => "Network compression algorithm (zlib, snappy)",
            "server-authoritative-movement-strict" => "Strict movement validation",
            "server-authoritative-dismount-strict" => "Strict dismount validation",
            "server-authoritative-entity-interactions-strict" => "Strict entity interaction validation",
            "player-position-acceptance-threshold" => "Position tolerance for anti-cheat",
            "player-movement-action-direction-threshold" => "Attack direction tolerance",
            "server-authoritative-block-breaking" => "Server-side block breaking validation",
            "server-authoritative-block-breaking-pick-range-scalar" => "Block breaking range multiplier",
            "chat-restriction" => "Chat restriction level (None, Dropped, Disabled)",
            "disable-player-interaction" => "Disable player-to-player interaction",
            "client-side-chunk-generation-enabled" => "Allow client-side chunk generation",
            "block-network-ids-are-hashes" => "Use hashed block network IDs",
            "disable-persona" => "Disable persona skins",
            "disable-custom-skins" => "Disable custom player skins",
            "server-build-radius-ratio" => "Server-side chunk build ratio",
            "enable-packet-rate-limiter" => "Enable network packet rate limiting",
            _ => string.Empty
        };
    }

    private static string GetPropertyCategory(string key)
    {
        return key switch
        {
            "server-name" or "server-port" or "server-portv6" or "enable-lan-visibility" or "max-players" 
                => "Server",
            
            "gamemode" or "force-gamemode" or "difficulty" or "allow-cheats" 
                => "Gameplay",
            
            "level-name" or "level-seed" 
                => "World",
            
            "online-mode" or "allow-list" or "default-player-permission-level" 
                => "Players & Permissions",
            
            "view-distance" or "tick-distance" or "max-threads" or "player-idle-timeout" 
                => "Performance",
            
            "compression-threshold" or "compression-algorithm" or "enable-packet-rate-limiter" 
                => "Network",
            
            "server-authoritative-movement-strict" or "server-authoritative-dismount-strict" 
                or "server-authoritative-entity-interactions-strict" or "player-position-acceptance-threshold"
                or "player-movement-action-direction-threshold" or "server-authoritative-block-breaking"
                or "server-authoritative-block-breaking-pick-range-scalar"
                => "Anti-Cheat",
            
            "texturepack-required" or "disable-persona" or "disable-custom-skins" or "client-side-chunk-generation-enabled"
                or "block-network-ids-are-hashes" or "server-build-radius-ratio"
                => "Client",
            
            "chat-restriction" or "disable-player-interaction" or "content-log-file-enabled"
                => "Miscellaneous",
            
            _ => "Other"
        };
    }

    private static int GetCategoryOrder(string category)
    {
        return category switch
        {
            "Server" => 0,
            "Gameplay" => 1,
            "World" => 2,
            "Players & Permissions" => 3,
            "Performance" => 4,
            "Network" => 5,
            "Anti-Cheat" => 6,
            "Client" => 7,
            "Miscellaneous" => 8,
            _ => 99
        };
    }
}

public class ServerProperty
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
}

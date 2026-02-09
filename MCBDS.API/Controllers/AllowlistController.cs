using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace MCBDS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AllowlistController : ControllerBase
{
    private readonly ILogger<AllowlistController> _logger;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;

    public AllowlistController(
        ILogger<AllowlistController> logger,
        IConfiguration configuration,
        IWebHostEnvironment environment)
    {
        _logger = logger;
        _configuration = configuration;
        _environment = environment;
    }

    private string GetBedrockDirectory()
    {
        // Get the bedrock server directory from configuration or use default
        var exePath = _configuration["Runner:ExePath"];
        if (string.IsNullOrWhiteSpace(exePath))
        {
            _logger.LogWarning("Runner:ExePath not configured, using default");
            return Path.Combine(_environment.ContentRootPath, "Binaries");
        }

        var directory = Path.GetDirectoryName(exePath);
        return directory ?? Path.Combine(_environment.ContentRootPath, "Binaries");
    }

    private string GetAllowlistPath()
    {
        var bedrockDir = GetBedrockDirectory();
        return Path.Combine(bedrockDir, "allowlist.json");
    }

    private string GetServerPropertiesPath()
    {
        var bedrockDir = GetBedrockDirectory();
        return Path.Combine(bedrockDir, "server.properties");
    }

    /// <summary>
    /// Get the current allowlist
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAllowlist()
    {
        try
        {
            var allowlistPath = GetAllowlistPath();
            
            if (!System.IO.File.Exists(allowlistPath))
            {
                _logger.LogWarning("allowlist.json not found at {Path}", allowlistPath);
                return Ok(new
                {
                    Users = new List<object>(),
                    IsEnabled = await IsAllowlistEnabledAsync()
                });
            }

            var json = await System.IO.File.ReadAllTextAsync(allowlistPath);
            var users = JsonSerializer.Deserialize<List<AllowlistUser>>(json) ?? new List<AllowlistUser>();
            
            var isEnabled = await IsAllowlistEnabledAsync();

            _logger.LogInformation("Retrieved {Count} users from allowlist. Enabled: {Enabled}", users.Count, isEnabled);

            return Ok(new
            {
                Users = users,
                IsEnabled = isEnabled
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading allowlist");
            return StatusCode(500, new { error = $"Failed to read allowlist: {ex.Message}" });
        }
    }

    /// <summary>
    /// Update the entire allowlist
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> UpdateAllowlist([FromBody] AllowlistUpdateRequest request)
    {
        try
        {
            var allowlistPath = GetAllowlistPath();
            
            // Ensure directory exists
            var directory = Path.GetDirectoryName(allowlistPath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // Write allowlist.json
            var options = new JsonSerializerOptions { WriteIndented = true };
            var json = JsonSerializer.Serialize(request.Users, options);
            await System.IO.File.WriteAllTextAsync(allowlistPath, json);

            _logger.LogInformation("Updated allowlist with {Count} users", request.Users.Count);

            // Auto-enable/disable allowlist in server.properties
            bool shouldEnable = request.Users.Count > 0;
            await SetAllowlistEnabledAsync(shouldEnable);

            return Ok(new { message = $"Allowlist updated successfully with {request.Users.Count} users. Allowlist {(shouldEnable ? "enabled" : "disabled")}." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating allowlist");
            return StatusCode(500, new { error = $"Failed to update allowlist: {ex.Message}" });
        }
    }

    /// <summary>
    /// Add a single user to the allowlist
    /// </summary>
    [HttpPost("user")]
    public async Task<IActionResult> AddUser([FromBody] AddAllowlistUserRequest request)
    {
        try
        {
            var allowlistPath = GetAllowlistPath();
            
            // Ensure directory exists
            var directory = Path.GetDirectoryName(allowlistPath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // Read existing allowlist
            List<AllowlistUser> users;
            if (System.IO.File.Exists(allowlistPath))
            {
                var json = await System.IO.File.ReadAllTextAsync(allowlistPath);
                users = JsonSerializer.Deserialize<List<AllowlistUser>>(json) ?? new List<AllowlistUser>();
            }
            else
            {
                users = new List<AllowlistUser>();
            }

            // Check if user already exists
            if (users.Any(u => u.Xuid == request.Xuid))
            {
                return BadRequest(new { error = "User already exists in allowlist" });
            }

            // Add new user
            users.Add(new AllowlistUser
            {
                Name = request.Gamertag,
                Xuid = request.Xuid ?? "",
                IgnoresPlayerLimit = request.IgnoresPlayerLimit
            });

            // Write back
            var options = new JsonSerializerOptions { WriteIndented = true };
            var newJson = JsonSerializer.Serialize(users, options);
            await System.IO.File.WriteAllTextAsync(allowlistPath, newJson);

            _logger.LogInformation("Added user {Gamertag} (XUID: {Xuid}) to allowlist", request.Gamertag, request.Xuid);

            // Auto-enable allowlist if this is the first user
            if (users.Count == 1)
            {
                await SetAllowlistEnabledAsync(true);
            }

            return Ok(new { message = $"User {request.Gamertag} added to allowlist successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding user to allowlist");
            return StatusCode(500, new { error = $"Failed to add user: {ex.Message}" });
        }
    }

    /// <summary>
    /// Remove a user from the allowlist by XUID
    /// </summary>
    [HttpDelete("user/{xuid}")]
    public async Task<IActionResult> RemoveUser(string xuid)
    {
        try
        {
            var allowlistPath = GetAllowlistPath();
            
            if (!System.IO.File.Exists(allowlistPath))
            {
                return NotFound(new { error = "Allowlist file not found" });
            }

            var json = await System.IO.File.ReadAllTextAsync(allowlistPath);
            var users = JsonSerializer.Deserialize<List<AllowlistUser>>(json) ?? new List<AllowlistUser>();

            var userToRemove = users.FirstOrDefault(u => u.Xuid == xuid);
            if (userToRemove == null)
            {
                return NotFound(new { error = "User not found in allowlist" });
            }

            users.Remove(userToRemove);

            // Write back
            var options = new JsonSerializerOptions { WriteIndented = true };
            var newJson = JsonSerializer.Serialize(users, options);
            await System.IO.File.WriteAllTextAsync(allowlistPath, newJson);

            _logger.LogInformation("Removed user {Gamertag} (XUID: {Xuid}) from allowlist", userToRemove.Name, xuid);

            // Auto-disable allowlist if no users left
            if (users.Count == 0)
            {
                await SetAllowlistEnabledAsync(false);
            }

            return Ok(new { message = $"User {userToRemove.Name} removed from allowlist successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing user from allowlist");
            return StatusCode(500, new { error = $"Failed to remove user: {ex.Message}" });
        }
    }

    /// <summary>
    /// Toggle the allowlist feature in server.properties
    /// </summary>
    [HttpPost("toggle")]
    public async Task<IActionResult> ToggleAllowlist([FromBody] ToggleAllowlistRequest request)
    {
        try
        {
            await SetAllowlistEnabledAsync(request.Enabled);
            
            _logger.LogInformation("Allowlist {Status} in server.properties", request.Enabled ? "enabled" : "disabled");
            
            return Ok(new { message = $"Allowlist {(request.Enabled ? "enabled" : "disabled")} successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling allowlist");
            return StatusCode(500, new { error = $"Failed to toggle allowlist: {ex.Message}" });
        }
    }

    // Helper methods

    private async Task<bool> IsAllowlistEnabledAsync()
    {
        try
        {
            var propertiesPath = GetServerPropertiesPath();
            if (!System.IO.File.Exists(propertiesPath))
            {
                return false;
            }

            var lines = await System.IO.File.ReadAllLinesAsync(propertiesPath);
            var allowListLine = lines.FirstOrDefault(l => l.StartsWith("allow-list="));
            
            if (allowListLine == null)
            {
                return false;
            }

            var value = allowListLine.Split('=')[1].Trim().ToLower();
            return value == "true";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading server.properties");
            return false;
        }
    }

    private async Task SetAllowlistEnabledAsync(bool enabled)
    {
        try
        {
            var propertiesPath = GetServerPropertiesPath();
            if (!System.IO.File.Exists(propertiesPath))
            {
                _logger.LogWarning("server.properties not found at {Path}", propertiesPath);
                return;
            }

            var lines = await System.IO.File.ReadAllLinesAsync(propertiesPath);
            var newLines = new List<string>();
            bool found = false;

            foreach (var line in lines)
            {
                if (line.StartsWith("allow-list="))
                {
                    newLines.Add($"allow-list={enabled.ToString().ToLower()}");
                    found = true;
                }
                else
                {
                    newLines.Add(line);
                }
            }

            // If the property wasn't found, add it
            if (!found)
            {
                newLines.Add($"allow-list={enabled.ToString().ToLower()}");
            }

            await System.IO.File.WriteAllLinesAsync(propertiesPath, newLines);
            _logger.LogInformation("Set allow-list={Enabled} in server.properties", enabled);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating server.properties");
            throw;
        }
    }
}

// Request/Response models
public class AllowlistUser
{
    public string Name { get; set; } = string.Empty;
    public string Xuid { get; set; } = string.Empty;
    public bool IgnoresPlayerLimit { get; set; } = false;
}

public class AllowlistUpdateRequest
{
    public List<AllowlistUser> Users { get; set; } = new();
}

public class AddAllowlistUserRequest
{
    public string Gamertag { get; set; } = string.Empty;
    public string? Xuid { get; set; }
    public bool IgnoresPlayerLimit { get; set; } = false;
}

public class ToggleAllowlistRequest
{
    public bool Enabled { get; set; }
}

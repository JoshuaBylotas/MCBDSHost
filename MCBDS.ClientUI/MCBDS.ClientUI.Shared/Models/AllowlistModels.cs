namespace MCBDS.ClientUI.Shared.Models;

/// <summary>
/// Represents a user entry in the Minecraft Bedrock allowlist.json file
/// </summary>
public class AllowlistUser
{
    /// <summary>
    /// The player's gamertag (Xbox Live username)
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// The player's Xbox User ID (XUID) - unique identifier
    /// </summary>
    public string Xuid { get; set; } = string.Empty;

    /// <summary>
    /// Whether this user can join even when the server is at max capacity
    /// </summary>
    public bool IgnoresPlayerLimit { get; set; } = false;

    /// <summary>
    /// Optional notes about this user (not part of allowlist.json, for UI only)
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// When this user was added (not part of allowlist.json, for UI only)
    /// </summary>
    public DateTime AddedDate { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Container for the allowlist data
/// </summary>
public class AllowlistData
{
    /// <summary>
    /// List of users in the allowlist
    /// </summary>
    public List<AllowlistUser> Users { get; set; } = new();

    /// <summary>
    /// Whether the allowlist is currently enabled in server.properties
    /// </summary>
    public bool IsEnabled { get; set; }
}

/// <summary>
/// API capabilities for backward compatibility
/// </summary>
public class ApiCapabilities
{
    /// <summary>
    /// API version string (e.g., "1.0", "1.1")
    /// </summary>
    public string Version { get; set; } = "1.0";

    /// <summary>
    /// Whether the server API supports allowlist management
    /// </summary>
    public bool SupportsAllowlist { get; set; } = false;

    /// <summary>
    /// Whether the server API supports server.properties editing
    /// </summary>
    public bool SupportsServerProperties { get; set; } = false;

    /// <summary>
    /// Whether the server API supports Xbox Live lookups
    /// </summary>
    public bool SupportsXboxLookup { get; set; } = false;

    /// <summary>
    /// List of available features
    /// </summary>
    public List<string> SupportedFeatures { get; set; } = new();
}

/// <summary>
/// Request model for adding a user to the allowlist
/// </summary>
public class AddAllowlistUserRequest
{
    public string Gamertag { get; set; } = string.Empty;
    public string? Xuid { get; set; }
    public bool IgnoresPlayerLimit { get; set; } = false;
}

/// <summary>
/// Response from Xbox Live gamertag lookup
/// </summary>
public class XboxLiveProfile
{
    public string Gamertag { get; set; } = string.Empty;
    public string Xuid { get; set; } = string.Empty;
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
}

namespace MCBDS.ClientUI.Shared.Models;

/// <summary>
/// Configuration for Xbox Live API integration
/// </summary>
public class XboxLiveConfiguration
{
    /// <summary>
    /// API key from OpenXBL (xbl.io)
    /// </summary>
    public string ApiKey { get; set; } = string.Empty;

    /// <summary>
    /// Base URL for Xbox Live API
    /// </summary>
    public string ApiBaseUrl { get; set; } = "https://xbl.io/api/v2";

    /// <summary>
    /// Enable caching of XUID lookups
    /// </summary>
    public bool EnableCaching { get; set; } = true;

    /// <summary>
    /// Cache expiration time in minutes
    /// </summary>
    public int CacheExpirationMinutes { get; set; } = 1440; // 24 hours
}

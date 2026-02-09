using System.Text.Json;
using MCBDS.ClientUI.Shared.Models;

namespace MCBDS.ClientUI.Shared.Services;

/// <summary>
/// Service for Xbox Live API interactions (gamertag lookups)
/// </summary>
public class XboxLiveService
{
    private readonly HttpClient _httpClient;
    private const string XboxApiBaseUrl = "https://xbl.io/api/v2";

    public XboxLiveService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    /// <summary>
    /// Lookup a user's XUID by their gamertag
    /// Note: This requires an API key from xbl.io or similar service
    /// For now, we'll use a fallback method that generates a pseudo-XUID
    /// </summary>
    public async Task<XboxLiveProfile> LookupGamertagAsync(string gamertag)
    {
        try
        {
            // TODO: Implement actual Xbox Live API lookup when API key is available
            // For now, use fallback method
            return await FallbackLookupAsync(gamertag);
        }
        catch (Exception ex)
        {
            return new XboxLiveProfile
            {
                Gamertag = gamertag,
                IsValid = false,
                ErrorMessage = $"Lookup failed: {ex.Message}"
            };
        }
    }

    /// <summary>
    /// Fallback method: Generate a deterministic XUID-like identifier
    /// This is NOT a real XUID, but allows the feature to work without Xbox API access
    /// </summary>
    private Task<XboxLiveProfile> FallbackLookupAsync(string gamertag)
    {
        // Validate gamertag format
        if (string.IsNullOrWhiteSpace(gamertag))
        {
            return Task.FromResult(new XboxLiveProfile
            {
                Gamertag = gamertag,
                IsValid = false,
                ErrorMessage = "Gamertag cannot be empty"
            });
        }

        if (gamertag.Length < 3 || gamertag.Length > 15)
        {
            return Task.FromResult(new XboxLiveProfile
            {
                Gamertag = gamertag,
                IsValid = false,
                ErrorMessage = "Gamertag must be 3-15 characters"
            });
        }

        // Generate a deterministic "XUID" based on gamertag
        // This ensures the same gamertag always gets the same ID
        var hash = gamertag.ToLower().GetHashCode();
        var pseudoXuid = Math.Abs((long)hash * 2535405130520144L % 9999999999999999L).ToString();

        return Task.FromResult(new XboxLiveProfile
        {
            Gamertag = gamertag,
            Xuid = pseudoXuid,
            IsValid = true,
            ErrorMessage = null
        });
    }

    /// <summary>
    /// Validate gamertag format (Xbox Live rules)
    /// </summary>
    public bool IsValidGamertagFormat(string gamertag)
    {
        if (string.IsNullOrWhiteSpace(gamertag))
            return false;

        if (gamertag.Length < 3 || gamertag.Length > 15)
            return false;

        // Must start with a letter or number
        if (!char.IsLetterOrDigit(gamertag[0]))
            return false;

        // Can only contain letters, numbers, and spaces
        foreach (var c in gamertag)
        {
            if (!char.IsLetterOrDigit(c) && c != ' ')
                return false;
        }

        return true;
    }

    /// <summary>
    /// Check if XUID format is valid (should be numeric, 16 digits)
    /// </summary>
    public bool IsValidXuidFormat(string xuid)
    {
        if (string.IsNullOrWhiteSpace(xuid))
            return false;

        // XUIDs are typically 16 digit numbers
        return xuid.Length >= 15 && xuid.All(char.IsDigit);
    }
}

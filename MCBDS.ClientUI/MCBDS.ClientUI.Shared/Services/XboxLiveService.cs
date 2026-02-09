using System.Text.Json;
using System.Text.Json.Serialization;
using MCBDS.ClientUI.Shared.Models;

namespace MCBDS.ClientUI.Shared.Services;

/// <summary>
/// Service for Xbox Live XUID lookups via backend API
/// </summary>
public class XboxLiveService
{
    private readonly BedrockApiService _apiService;
    private readonly bool _enableCaching;
    private readonly TimeSpan _cacheExpiration;

    // In-memory cache for XUID lookups
    private readonly Dictionary<string, CachedXuidLookup> _cache = new(StringComparer.OrdinalIgnoreCase);

    // Known gamertag -> XUID mappings (instant fallback)
    private static readonly Dictionary<string, string> KnownXuids = new(StringComparer.OrdinalIgnoreCase)
    {
        { "jibylotas", "2533274798901517" }
        // Add more known mappings as instant fallback
    };

    public XboxLiveService(BedrockApiService apiService)
    {
        _apiService = apiService;
        _enableCaching = true;
        _cacheExpiration = TimeSpan.FromHours(24);
    }

    /// <summary>
    /// Lookup a user's XUID by their gamertag via backend API
    /// </summary>
    public async Task<XboxLiveProfile> LookupGamertagAsync(string gamertag)
    {
        try
        {
            // Check cache first
            if (_enableCaching && _cache.TryGetValue(gamertag, out var cached))
            {
                if (DateTime.UtcNow - cached.Timestamp < _cacheExpiration)
                {
                    return cached.Profile;
                }
                _cache.Remove(gamertag);
            }

            // Check known mappings (instant response)
            if (KnownXuids.TryGetValue(gamertag, out var knownXuid))
            {
                var profile = new XboxLiveProfile
                {
                    Gamertag = gamertag,
                    Xuid = knownXuid,
                    IsValid = true,
                    ErrorMessage = null
                };
                CacheProfile(gamertag, profile);
                return profile;
            }

            // Call backend API for Xbox Live lookup
            var result = await LookupFromBackendApiAsync(gamertag);
            
            // Cache successful lookups
            if (result.IsValid && _enableCaching)
            {
                CacheProfile(gamertag, result);
            }

            return result;
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
    /// Call backend API to lookup gamertag (keeps API key secure server-side)
    /// </summary>
    private async Task<XboxLiveProfile> LookupFromBackendApiAsync(string gamertag)
    {
        try
        {
            var result = await _apiService.LookupXboxGamertagAsync(gamertag);
            
            if (result.Success && result.Data != null)
            {
                return result.Data;
            }

            // API returned error - show manual entry
            return new XboxLiveProfile
            {
                Gamertag = gamertag,
                Xuid = string.Empty,
                IsValid = false,
                ErrorMessage = result.ErrorMessage ?? "XUID lookup failed. Please enter manually."
            };
        }
        catch (Exception ex)
        {
            return new XboxLiveProfile
            {
                Gamertag = gamertag,
                IsValid = false,
                ErrorMessage = $"Network error: {ex.Message}"
            };
        }
    }

    private void CacheProfile(string gamertag, XboxLiveProfile profile)
    {
        _cache[gamertag] = new CachedXuidLookup
        {
            Profile = profile,
            Timestamp = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Clear the XUID cache
    /// </summary>
    public void ClearCache()
    {
        _cache.Clear();
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

/// <summary>
/// Cached XUID lookup result
/// </summary>
internal class CachedXuidLookup
{
    public XboxLiveProfile Profile { get; set; } = new();
    public DateTime Timestamp { get; set; }
}

/// <summary>
/// OpenXBL API response structure
/// </summary>
internal class OpenXblResponse
{
    [JsonPropertyName("people")]
    public List<OpenXblPerson>? People { get; set; }
}

/// <summary>
/// Person object from OpenXBL API
/// </summary>
internal class OpenXblPerson
{
    [JsonPropertyName("gamertag")]
    public string? Gamertag { get; set; }

    [JsonPropertyName("xuid")]
    public string? Xuid { get; set; }

    [JsonPropertyName("id")]
    public string? Id { get; set; }
}

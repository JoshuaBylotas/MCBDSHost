using Microsoft.AspNetCore.Mvc;

namespace MCBDS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class XboxLiveController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<XboxLiveController> _logger;

    public XboxLiveController(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        ILogger<XboxLiveController> logger)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    /// <summary>
    /// Lookup XUID by gamertag using OpenXBL API
    /// This endpoint keeps the API key server-side for security
    /// </summary>
    [HttpGet("lookup/{gamertag}")]
    public async Task<IActionResult> LookupGamertag(string gamertag)
    {
        try
        {
            var apiKey = _configuration["XboxLive:ApiKey"];
            var apiBaseUrl = _configuration["XboxLive:ApiBaseUrl"] ?? "https://xbl.io/api/v2";

            if (string.IsNullOrWhiteSpace(apiKey) || apiKey == "YOUR_OPENXBL_API_KEY_HERE")
            {
                _logger.LogWarning("Xbox Live API key not configured");
                return BadRequest(new
                {
                    error = "Xbox Live API key not configured on server. Please configure in appsettings.json",
                    requiresManualEntry = true
                });
            }

            var httpClient = _httpClientFactory.CreateClient();
            var request = new HttpRequestMessage(HttpMethod.Get, 
                $"{apiBaseUrl}/search/{Uri.EscapeDataString(gamertag)}");
            request.Headers.Add("X-Authorization", apiKey);
            request.Headers.Add("Accept", "application/json");

            var response = await httpClient.SendAsync(request);

            if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            {
                _logger.LogError("Invalid Xbox Live API key");
                return Unauthorized(new { error = "Invalid API key configured on server" });
            }

            if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            {
                _logger.LogWarning("Xbox Live API rate limit exceeded");
                return StatusCode(429, new
                {
                    error = "API rate limit exceeded. Please try again in a few minutes.",
                    requiresManualEntry = true
                });
            }

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Xbox Live API error: {StatusCode}", response.StatusCode);
                return StatusCode((int)response.StatusCode, new
                {
                    error = $"Xbox Live API error: {response.StatusCode}",
                    requiresManualEntry = true
                });
            }

            var json = await response.Content.ReadAsStringAsync();
            var apiResponse = System.Text.Json.JsonSerializer.Deserialize<OpenXblApiResponse>(json);

            if (apiResponse?.People == null || apiResponse.People.Count == 0)
            {
                _logger.LogInformation("Gamertag not found: {Gamertag}", gamertag);
                return NotFound(new
                {
                    error = "Gamertag not found on Xbox Live",
                    requiresManualEntry = true
                });
            }

            var person = apiResponse.People[0];

            _logger.LogInformation("Successfully looked up gamertag: {Gamertag} -> XUID: {Xuid}",
                gamertag, person.Xuid);

            return Ok(new
            {
                gamertag = person.Gamertag ?? gamertag,
                xuid = person.Xuid,
                isValid = !string.IsNullOrWhiteSpace(person.Xuid)
            });
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Network error during Xbox Live lookup");
            return StatusCode(500, new
            {
                error = "Network error connecting to Xbox Live API",
                requiresManualEntry = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during Xbox Live lookup");
            return StatusCode(500, new
            {
                error = $"Failed to lookup gamertag: {ex.Message}",
                requiresManualEntry = true
            });
        }
    }
}

internal class OpenXblApiResponse
{
    [System.Text.Json.Serialization.JsonPropertyName("people")]
    public List<OpenXblPerson>? People { get; set; }
}

internal class OpenXblPerson
{
    [System.Text.Json.Serialization.JsonPropertyName("gamertag")]
    public string? Gamertag { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("xuid")]
    public string? Xuid { get; set; }
}

using Microsoft.AspNetCore.Mvc;

namespace MCBDS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VersionController : ControllerBase
{
    private readonly ILogger<VersionController> _logger;

    public VersionController(ILogger<VersionController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get API version and supported features for backward compatibility
    /// </summary>
    [HttpGet]
    public IActionResult GetVersion()
    {
        _logger.LogInformation("API version requested");

        var capabilities = new
        {
            Version = "1.1",
            SupportsAllowlist = true,
            SupportsServerProperties = true,
            SupportsXboxLookup = false, // We use fallback method
            SupportsPackManagement = true, // API v1.1 feature
            SupportedFeatures = new List<string>
            {
                "allowlist-management",
                "server-properties-toggle",
                "backup-management",
                "command-execution",
                "pack-management"
            }
        };

        return Ok(capabilities);
    }
}

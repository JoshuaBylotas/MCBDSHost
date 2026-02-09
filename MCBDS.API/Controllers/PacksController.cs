using Microsoft.AspNetCore.Mvc;
using MCBDS.API.Models;
using MCBDS.API.Services;

namespace MCBDS.API.Controllers;

/// <summary>
/// Controller for managing Minecraft Bedrock resource and behavior packs
/// Available in API v1.1+
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PacksController : ControllerBase
{
    private readonly PackManagementService _packService;
    private readonly ILogger<PacksController> _logger;

    public PacksController(
        PackManagementService packService,
        ILogger<PacksController> logger)
    {
        _packService = packService;
        _logger = logger;
    }

    /// <summary>
    /// Upload and install a pack (.zip or .mcpack file)
    /// </summary>
    /// <param name="file">Pack file to upload</param>
    /// <param name="type">Pack type (ResourcePack or BehaviorPack)</param>
    /// <returns>Information about the installed pack</returns>
    [HttpPost("upload")]
    [RequestSizeLimit(100_000_000)] // 100MB limit
    [RequestFormLimits(MultipartBodyLengthLimit = 100_000_000)]
    public async Task<IActionResult> UploadPack(IFormFile file, [FromForm] string type)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { error = "No file uploaded" });
            }

            // Validate file extension
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (extension != ".zip" && extension != ".mcpack")
            {
                return BadRequest(new { error = "Only .zip and .mcpack files are supported" });
            }

            // Parse pack type
            if (!Enum.TryParse<PackType>(type, true, out var packType))
            {
                return BadRequest(new { error = "Invalid pack type. Use 'ResourcePack' or 'BehaviorPack'" });
            }

            _logger.LogInformation("Uploading pack: {FileName} ({Size} bytes) as {Type}", 
                file.FileName, file.Length, packType);

            // Install the pack
            await using var stream = file.OpenReadStream();
            var packInfo = await _packService.InstallPackAsync(stream, file.FileName, packType);

            _logger.LogInformation("Pack installed successfully: {Name} (UUID: {Uuid})", 
                packInfo.Name, packInfo.Uuid);

            return Ok(packInfo);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid pack upload");
            return BadRequest(new { error = ex.Message });
        }
        catch (IOException ex)
        {
            _logger.LogError(ex, "IO error during pack upload");
            return StatusCode(500, new { error = $"File system error: {ex.Message}" });
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogError(ex, "Access denied during pack upload");
            return StatusCode(500, new { error = "Access denied to pack directory. Check server permissions." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading pack");
            return StatusCode(500, new { error = $"Failed to upload pack: {ex.Message}" });
        }
    }

    /// <summary>
    /// Get all installed packs
    /// </summary>
    /// <param name="type">Optional: Filter by pack type (ResourcePack or BehaviorPack)</param>
    /// <returns>List of installed packs</returns>
    [HttpGet]
    public async Task<IActionResult> GetPacks([FromQuery] string? type = null)
    {
        try
        {
            var result = new
            {
                ResourcePacks = new List<PackInfo>(),
                BehaviorPacks = new List<PackInfo>()
            };

            if (string.IsNullOrEmpty(type) || type.Equals("ResourcePack", StringComparison.OrdinalIgnoreCase))
            {
                result.ResourcePacks.AddRange(await _packService.GetPacksAsync(PackType.ResourcePack));
            }

            if (string.IsNullOrEmpty(type) || type.Equals("BehaviorPack", StringComparison.OrdinalIgnoreCase))
            {
                result.BehaviorPacks.AddRange(await _packService.GetPacksAsync(PackType.BehaviorPack));
            }

            _logger.LogInformation("Retrieved packs: {ResourceCount} resource, {BehaviorCount} behavior",
                result.ResourcePacks.Count, result.BehaviorPacks.Count);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting packs");
            return StatusCode(500, new { error = $"Failed to get packs: {ex.Message}" });
        }
    }

    /// <summary>
    /// Delete a pack
    /// </summary>
    /// <param name="packUuid">UUID of the pack to delete</param>
    /// <param name="type">Pack type (ResourcePack or BehaviorPack)</param>
    [HttpDelete("{packUuid}")]
    public async Task<IActionResult> DeletePack(string packUuid, [FromQuery] string type)
    {
        try
        {
            if (!Enum.TryParse<PackType>(type, true, out var packType))
            {
                return BadRequest(new { error = "Invalid pack type. Use 'ResourcePack' or 'BehaviorPack'" });
            }

            var success = await _packService.DeletePackAsync(packUuid, packType);

            if (!success)
            {
                return NotFound(new { error = "Pack not found" });
            }

            _logger.LogInformation("Pack deleted: {Uuid} ({Type})", packUuid, packType);
            return Ok(new { message = "Pack deleted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting pack {Uuid}", packUuid);
            return StatusCode(500, new { error = $"Failed to delete pack: {ex.Message}" });
        }
    }

    /// <summary>
    /// Enable a pack in the world
    /// </summary>
    /// <param name="packUuid">UUID of the pack to enable</param>
    /// <param name="type">Pack type (ResourcePack or BehaviorPack)</param>
    [HttpPost("{packUuid}/enable")]
    public async Task<IActionResult> EnablePack(string packUuid, [FromQuery] string type)
    {
        try
        {
            if (!Enum.TryParse<PackType>(type, true, out var packType))
            {
                return BadRequest(new { error = "Invalid pack type. Use 'ResourcePack' or 'BehaviorPack'" });
            }

            var success = await _packService.EnablePackAsync(packUuid, packType);

            if (!success)
            {
                return NotFound(new { error = "Pack not found" });
            }

            _logger.LogInformation("Pack enabled: {Uuid} ({Type})", packUuid, packType);
            return Ok(new { message = "Pack enabled successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error enabling pack {Uuid}", packUuid);
            return StatusCode(500, new { error = $"Failed to enable pack: {ex.Message}" });
        }
    }

    /// <summary>
    /// Disable a pack in the world
    /// </summary>
    /// <param name="packUuid">UUID of the pack to disable</param>
    /// <param name="type">Pack type (ResourcePack or BehaviorPack)</param>
    [HttpPost("{packUuid}/disable")]
    public async Task<IActionResult> DisablePack(string packUuid, [FromQuery] string type)
    {
        try
        {
            if (!Enum.TryParse<PackType>(type, true, out var packType))
            {
                return BadRequest(new { error = "Invalid pack type. Use 'ResourcePack' or 'BehaviorPack'" });
            }

            var success = await _packService.DisablePackAsync(packUuid, packType);

            if (!success)
            {
                return BadRequest(new { error = "Failed to disable pack" });
            }

            _logger.LogInformation("Pack disabled: {Uuid} ({Type})", packUuid, packType);
            return Ok(new { message = "Pack disabled successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error disabling pack {Uuid}", packUuid);
            return StatusCode(500, new { error = $"Failed to disable pack: {ex.Message}" });
        }
    }
}

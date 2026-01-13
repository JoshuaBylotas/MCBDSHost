using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using MCBDS.API.Models;
using MCBDS.API.Background;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace MCBDS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BackupController : ControllerBase
{
    private readonly IOptionsMonitor<BackupConfiguration> _configMonitor;
    private readonly ILogger<BackupController> _logger;
    private readonly IConfiguration _configuration;
    private readonly BackupHostedService? _backupService;
    private readonly IWebHostEnvironment _environment;

    public BackupController(
        IOptionsMonitor<BackupConfiguration> configMonitor,
        IConfiguration configuration,
        ILogger<BackupController> logger,
        IServiceProvider serviceProvider,
        IWebHostEnvironment environment)
    {
        _configMonitor = configMonitor;
        _configuration = configuration;
        _logger = logger;
        _environment = environment;
        
        _backupService = serviceProvider.GetService<BackupHostedService>();
    }

    [HttpGet("config")]
    public IActionResult GetConfiguration()
    {
        var config = _configMonitor.CurrentValue;
        _logger.LogInformation("GetConfiguration: Freq={Freq}, Dir={Dir}, Max={Max}", 
            config.FrequencyMinutes, config.BackupDirectory, config.MaxBackupsToKeep);
        
        return Ok(new
        {
            FrequencyMinutes = config.FrequencyMinutes,
            BackupDirectory = config.BackupDirectory,
            MaxBackupsToKeep = config.MaxBackupsToKeep,
            WorldPath = config.WorldPath
        });
    }

    [HttpPut("config")]
    public async Task<IActionResult> UpdateConfiguration([FromBody] BackupConfiguration newConfig)
    {
        try
        {
            _logger.LogInformation("UpdateConfiguration called: Freq={Freq}, Dir={Dir}, Max={Max}", 
                newConfig.FrequencyMinutes, newConfig.BackupDirectory, newConfig.MaxBackupsToKeep);

            // Validate configuration
            if (newConfig.FrequencyMinutes < 1 || newConfig.FrequencyMinutes > 1440)
            {
                return BadRequest(new { error = "Frequency must be between 1 and 1440 minutes" });
            }

            if (string.IsNullOrWhiteSpace(newConfig.BackupDirectory))
            {
                return BadRequest(new { error = "Backup directory is required" });
            }

            if (newConfig.MaxBackupsToKeep < 0)
            {
                return BadRequest(new { error = "MaxBackupsToKeep must be 0 or greater" });
            }

            // Try multiple paths to find appsettings.json
            var possiblePaths = new[]
            {
                Path.Combine(_environment.ContentRootPath, "appsettings.json"),
                Path.Combine(AppContext.BaseDirectory, "appsettings.json"),
                Path.Combine(Directory.GetCurrentDirectory(), "appsettings.json")
            };

            string? appSettingsPath = null;
            foreach (var path in possiblePaths)
            {
                _logger.LogInformation("Checking path: {Path}, Exists: {Exists}", path, System.IO.File.Exists(path));
                if (System.IO.File.Exists(path))
                {
                    appSettingsPath = path;
                    break;
                }
            }

            if (appSettingsPath == null)
            {
                _logger.LogError("appsettings.json not found in any expected location");
                return StatusCode(500, new { error = "appsettings.json not found", paths = possiblePaths });
            }

            _logger.LogInformation("Using appsettings.json at: {Path}", appSettingsPath);

            var json = await System.IO.File.ReadAllTextAsync(appSettingsPath);
            var jsonNode = JsonNode.Parse(json);

            if (jsonNode == null)
            {
                return StatusCode(500, new { error = "Failed to parse appsettings.json" });
            }

            // Update or create Backup section
            var backupNode = new JsonObject
            {
                ["FrequencyMinutes"] = newConfig.FrequencyMinutes,
                ["BackupDirectory"] = newConfig.BackupDirectory,
                ["MaxBackupsToKeep"] = newConfig.MaxBackupsToKeep
            };

            if (!string.IsNullOrWhiteSpace(newConfig.WorldPath))
            {
                backupNode["WorldPath"] = newConfig.WorldPath;
            }

            jsonNode["Backup"] = backupNode;

            var options = new JsonSerializerOptions
            {
                WriteIndented = true
            };

            var updatedJson = jsonNode.ToJsonString(options);
            
            _logger.LogInformation("Writing to {Path}: {Json}", appSettingsPath, updatedJson);
            await System.IO.File.WriteAllTextAsync(appSettingsPath, updatedJson);

            _logger.LogInformation("Backup configuration saved to file");

            // Force configuration reload
            if (_configuration is IConfigurationRoot configRoot)
            {
                configRoot.Reload();
                _logger.LogInformation("Configuration reloaded");
                
                // Verify reload worked
                var reloadedConfig = _configMonitor.CurrentValue;
                _logger.LogInformation("After reload: Freq={Freq}, Dir={Dir}, Max={Max}", 
                    reloadedConfig.FrequencyMinutes, reloadedConfig.BackupDirectory, reloadedConfig.MaxBackupsToKeep);
            }

            return Ok(new
            {
                message = "Configuration updated successfully!",
                restartRequired = false,
                config = new
                {
                    FrequencyMinutes = newConfig.FrequencyMinutes,
                    BackupDirectory = newConfig.BackupDirectory,
                    MaxBackupsToKeep = newConfig.MaxBackupsToKeep
                },
                savedTo = appSettingsPath
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating backup configuration");
            return StatusCode(500, new { error = "Failed to update configuration", message = ex.Message });
        }
    }

    [HttpPost("trigger")]
    public async Task<IActionResult> TriggerManualBackup()
    {
        try
        {
            if (_backupService == null)
            {
                return StatusCode(503, new { error = "Backup service is not available" });
            }

            var success = await _backupService.TriggerManualBackupAsync();
            
            if (success)
            {
                _logger.LogInformation("Manual backup triggered successfully via API");
                return Accepted(new
                {
                    message = "Manual backup has been triggered successfully.",
                    note = "Check the API logs for backup progress and completion."
                });
            }
            else
            {
                return StatusCode(409, new
                {
                    error = "A backup is already in progress",
                    message = "Please wait for the current backup to complete before triggering another."
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error triggering manual backup");
            return StatusCode(500, new { error = "Failed to trigger backup", message = ex.Message });
        }
    }

    [HttpGet("list")]
    public IActionResult ListBackups()
    {
        try
        {
            var config = _configMonitor.CurrentValue;
            
            if (string.IsNullOrWhiteSpace(config.BackupDirectory) || !Directory.Exists(config.BackupDirectory))
            {
                return Ok(new { backups = Array.Empty<object>(), message = "Backup directory not configured or doesn't exist" });
            }

            var backupDirs = Directory.GetDirectories(config.BackupDirectory, "backup_*")
                .Select(d => new DirectoryInfo(d))
                .OrderByDescending(d => d.CreationTime)
                .Select(d => new
                {
                    Name = d.Name,
                    CreatedAt = d.CreationTime,
                    SizeMB = GetDirectorySize(d) / (1024.0 * 1024.0),
                    Path = d.FullName
                })
                .ToList();

            return Ok(new { backups = backupDirs, count = backupDirs.Count });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error listing backups");
            return StatusCode(500, new { error = "Failed to list backups", message = ex.Message });
        }
    }

    [HttpDelete("{backupName}")]
    public IActionResult DeleteBackup(string backupName)
    {
        try
        {
            var config = _configMonitor.CurrentValue;
            
            if (string.IsNullOrWhiteSpace(config.BackupDirectory))
            {
                return BadRequest(new { error = "Backup directory not configured" });
            }

            if (backupName.Contains("..") || backupName.Contains("/") || backupName.Contains("\\"))
            {
                return BadRequest(new { error = "Invalid backup name" });
            }

            var backupPath = Path.Combine(config.BackupDirectory, backupName);

            if (!Directory.Exists(backupPath))
            {
                return NotFound(new { error = "Backup not found" });
            }

            Directory.Delete(backupPath, recursive: true);
            _logger.LogInformation("Deleted backup: {BackupName}", backupName);

            return Ok(new { message = $"Backup '{backupName}' deleted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting backup: {BackupName}", backupName);
            return StatusCode(500, new { error = "Failed to delete backup", message = ex.Message });
        }
    }

    [HttpPost("restore/{backupName}")]
    public async Task<IActionResult> RestoreBackup(string backupName)
    {
        try
        {
            _logger.LogInformation("Restore backup API called for: {BackupName}", backupName);

            if (_backupService == null)
            {
                return StatusCode(503, new { error = "Backup service is not available" });
            }

            var (success, message) = await _backupService.RestoreBackupAsync(backupName);
            
            if (success)
            {
                _logger.LogInformation("Backup restored successfully: {BackupName}", backupName);
                return Ok(new
                {
                    message = message,
                    backupName = backupName,
                    restoredAt = DateTime.UtcNow
                });
            }
            else
            {
                _logger.LogWarning("Failed to restore backup: {BackupName}, Reason: {Message}", backupName, message);
                return StatusCode(500, new
                {
                    error = "Failed to restore backup",
                    message = message
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error restoring backup: {BackupName}", backupName);
            return StatusCode(500, new { error = "Failed to restore backup", message = ex.Message });
        }
    }

    private long GetDirectorySize(DirectoryInfo directory)
    {
        try
        {
            return directory.GetFiles("*", SearchOption.AllDirectories).Sum(f => f.Length);
        }
        catch
        {
            return 0;
        }
    }
}

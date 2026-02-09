using System.IO.Compression;
using System.Text.Json;
using MCBDS.API.Models;

namespace MCBDS.API.Services;

/// <summary>
/// Service for managing Minecraft Bedrock resource and behavior packs
/// </summary>
public class PackManagementService
{
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<PackManagementService> _logger;
    private readonly JsonSerializerOptions _jsonOptions;

    public PackManagementService(
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<PackManagementService> logger)
    {
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
        
        _jsonOptions = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNameCaseInsensitive = true
        };
    }

    private string GetBedrockDirectory()
    {
        var exePath = _configuration["Runner:ExePath"];
        if (string.IsNullOrWhiteSpace(exePath))
        {
            _logger.LogWarning("Runner:ExePath not configured, using default");
            return Path.Combine(_environment.ContentRootPath, "Binaries");
        }

        var directory = Path.GetDirectoryName(exePath);
        return directory ?? Path.Combine(_environment.ContentRootPath, "Binaries");
    }

    private string GetPackDirectory(PackType type)
    {
        var bedrockDir = GetBedrockDirectory();
        var folderName = type == PackType.ResourcePack ? "resource_packs" : "behavior_packs";
        return Path.Combine(bedrockDir, folderName);
    }

    private string GetWorldDirectory()
    {
        var bedrockDir = GetBedrockDirectory();
        var worldName = GetWorldNameFromProperties();
        return Path.Combine(bedrockDir, "worlds", worldName);
    }

    private string GetWorldPacksJsonPath(PackType type)
    {
        var worldDir = GetWorldDirectory();
        var fileName = type == PackType.ResourcePack 
            ? "world_resource_packs.json" 
            : "world_behavior_packs.json";
        return Path.Combine(worldDir, fileName);
    }

    /// <summary>
    /// Get world name from server.properties
    /// </summary>
    private string GetWorldNameFromProperties()
    {
        var bedrockDir = GetBedrockDirectory();
        var propertiesPath = Path.Combine(bedrockDir, "server.properties");

        try
        {
            if (File.Exists(propertiesPath))
            {
                var lines = File.ReadAllLines(propertiesPath);
                var levelNameLine = lines.FirstOrDefault(l => l.StartsWith("level-name="));
                if (levelNameLine != null)
                {
                    var worldName = levelNameLine.Split('=', 2)[1].Trim();
                    _logger.LogInformation("Found world name: {WorldName}", worldName);
                    return worldName;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading world name from server.properties");
        }

        _logger.LogWarning("Could not determine world name, using default 'Bedrock level'");
        return "Bedrock level";
    }

    /// <summary>
    /// Extract and install a pack from an uploaded file
    /// </summary>
    public async Task<PackInfo> InstallPackAsync(Stream fileStream, string originalFileName, PackType type)
    {
        var tempPath = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
        
        try
        {
            // Create temp directory
            Directory.CreateDirectory(tempPath);

            // Save uploaded file
            var tempFilePath = Path.Combine(tempPath, originalFileName);
            await using (var fileStreamOut = File.Create(tempFilePath))
            {
                await fileStream.CopyToAsync(fileStreamOut);
            }

            _logger.LogInformation("Saved uploaded file to temp: {Path}", tempFilePath);

            // Extract the archive
            var extractPath = Path.Combine(tempPath, "extracted");
            ZipFile.ExtractToDirectory(tempFilePath, extractPath);

            _logger.LogInformation("Extracted pack to: {Path}", extractPath);

            // Find manifest.json
            var manifestPath = FindManifestFile(extractPath);
            if (manifestPath == null)
            {
                throw new InvalidOperationException("manifest.json not found in pack");
            }

            // Parse manifest
            var manifestJson = await File.ReadAllTextAsync(manifestPath);
            var manifest = JsonSerializer.Deserialize<PackManifest>(manifestJson, _jsonOptions);
            
            if (manifest?.Header == null)
            {
                throw new InvalidOperationException("Invalid manifest.json structure");
            }

            _logger.LogInformation("Pack manifest parsed: {Name} (UUID: {Uuid})", 
                manifest.Header.Name, manifest.Header.Uuid);

            // Log detected type but ALWAYS respect user's selection
            var detectedType = DetectPackTypeFromManifest(manifest);
            if (detectedType != type)
            {
                _logger.LogInformation("Pack type detection: Detected={Detected}, UserSelected={Selected}. Using user selection.",
                    detectedType, type);
            }

            // Create pack folder name (sanitize pack name)
            var packFolderName = SanitizeFolderName(manifest.Header.Name);
            var packDir = GetPackDirectory(type);
            var targetPath = Path.Combine(packDir, packFolderName);

            // Ensure pack directory exists
            Directory.CreateDirectory(packDir);

            // Check if pack with same name exists and get old UUID
            string? oldUuid = null;
            if (Directory.Exists(targetPath))
            {
                try
                {
                    var oldManifestPath = Path.Combine(targetPath, "manifest.json");
                    if (File.Exists(oldManifestPath))
                    {
                        var oldManifestJson = await File.ReadAllTextAsync(oldManifestPath);
                        var oldManifest = JsonSerializer.Deserialize<PackManifest>(oldManifestJson, _jsonOptions);
                        oldUuid = oldManifest?.Header?.Uuid;
                        _logger.LogInformation("Found existing pack with UUID: {OldUuid}, will replace with {NewUuid}",
                            oldUuid, manifest.Header.Uuid);
                    }

                    _logger.LogInformation("Removing existing pack at: {Path}", targetPath);
                    Directory.Delete(targetPath, true);
                    
                    // Small delay to ensure file handles are released
                    await Task.Delay(100);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error removing existing pack at: {Path}", targetPath);
                    throw new InvalidOperationException($"Failed to remove existing pack: {ex.Message}", ex);
                }
            }

            // Copy extracted pack to target location
            var manifestDir = Path.GetDirectoryName(manifestPath)!;
            try
            {
                CopyDirectory(manifestDir, targetPath);
                _logger.LogInformation("Pack installed to: {Path}", targetPath);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error copying pack to: {Path}", targetPath);
                throw new InvalidOperationException($"Failed to install pack: {ex.Message}", ex);
            }

            // If this is a reupload (old UUID exists and differs), update world JSON files
            if (oldUuid != null && oldUuid != manifest.Header.Uuid)
            {
                await ReplacePackUuidInWorldAsync(oldUuid, manifest.Header.Uuid, manifest.Header.Version, type);
            }

            // Create PackInfo response
            var packInfo = new PackInfo
            {
                Id = manifest.Header.Uuid,
                Name = manifest.Header.Name,
                Description = manifest.Header.Description,
                Uuid = manifest.Header.Uuid,
                Version = string.Join(".", manifest.Header.Version),
                Type = type,
                FolderName = packFolderName,
                IsEnabled = false
            };

            return packInfo;
        }
        finally
        {
            // Clean up temp directory
            try
            {
                if (Directory.Exists(tempPath))
                {
                    Directory.Delete(tempPath, true);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to clean up temp directory: {Path}", tempPath);
            }
        }
    }

    /// <summary>
    /// Get all installed packs of a specific type (excludes system/vanilla packs)
    /// </summary>
    public async Task<List<PackInfo>> GetPacksAsync(PackType type)
    {
        var packs = new List<PackInfo>();
        var packDir = GetPackDirectory(type);

        if (!Directory.Exists(packDir))
        {
            _logger.LogInformation("Pack directory does not exist: {Path}", packDir);
            return packs;
        }

        var enabledPacks = await GetEnabledPackUuidsAsync(type);

        foreach (var subDir in Directory.GetDirectories(packDir))
        {
            try
            {
                // Skip system/vanilla packs (issue #3)
                var dirName = Path.GetFileName(subDir).ToLowerInvariant();
                if (dirName.StartsWith("vanilla") || dirName.StartsWith("chemistry"))
                {
                    _logger.LogDebug("Skipping system pack: {DirName}", dirName);
                    continue;
                }

                var manifestPath = Path.Combine(subDir, "manifest.json");
                if (!File.Exists(manifestPath))
                {
                    _logger.LogWarning("No manifest.json found in: {Path}", subDir);
                    continue;
                }

                var manifestJson = await File.ReadAllTextAsync(manifestPath);
                var manifest = JsonSerializer.Deserialize<PackManifest>(manifestJson, _jsonOptions);

                if (manifest?.Header == null)
                {
                    _logger.LogWarning("Invalid manifest in: {Path}", subDir);
                    continue;
                }

                var packInfo = new PackInfo
                {
                    Id = manifest.Header.Uuid,
                    Name = manifest.Header.Name,
                    Description = manifest.Header.Description,
                    Uuid = manifest.Header.Uuid,
                    Version = string.Join(".", manifest.Header.Version),
                    Type = type,
                    FolderName = Path.GetFileName(subDir),
                    IsEnabled = enabledPacks.Contains(manifest.Header.Uuid)
                };

                packs.Add(packInfo);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reading pack from: {Path}", subDir);
            }
        }

        _logger.LogInformation("Found {Count} {Type} packs", packs.Count, type);
        return packs;
    }

    /// <summary>
    /// Delete a pack
    /// </summary>
    public async Task<bool> DeletePackAsync(string packUuid, PackType type)
    {
        var packDir = GetPackDirectory(type);
        
        if (!Directory.Exists(packDir))
        {
            return false;
        }

        // Find the pack folder
        foreach (var subDir in Directory.GetDirectories(packDir))
        {
            try
            {
                var manifestPath = Path.Combine(subDir, "manifest.json");
                if (!File.Exists(manifestPath))
                {
                    continue;
                }

                var manifestJson = await File.ReadAllTextAsync(manifestPath);
                var manifest = JsonSerializer.Deserialize<PackManifest>(manifestJson, _jsonOptions);

                if (manifest?.Header?.Uuid == packUuid)
                {
                    // Disable the pack first
                    await DisablePackAsync(packUuid, type);

                    // Delete the folder
                    Directory.Delete(subDir, true);
                    _logger.LogInformation("Deleted pack: {Uuid} from {Path}", packUuid, subDir);
                    return true;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting pack from: {Path}", subDir);
            }
        }

        return false;
    }

    /// <summary>
    /// Enable a pack in the world
    /// </summary>
    public async Task<bool> EnablePackAsync(string packUuid, PackType type)
    {
        var jsonPath = GetWorldPacksJsonPath(type);
        var packDir = GetPackDirectory(type);

        // Find the pack to get its version
        PackManifest? packManifest = null;
        foreach (var subDir in Directory.GetDirectories(packDir))
        {
            var manifestPath = Path.Combine(subDir, "manifest.json");
            if (File.Exists(manifestPath))
            {
                var manifestJson = await File.ReadAllTextAsync(manifestPath);
                var manifest = JsonSerializer.Deserialize<PackManifest>(manifestJson, _jsonOptions);
                
                if (manifest?.Header?.Uuid == packUuid)
                {
                    packManifest = manifest;
                    break;
                }
            }
        }

        if (packManifest == null)
        {
            _logger.LogWarning("Pack not found: {Uuid}", packUuid);
            return false;
        }

        // Read or create the world packs JSON
        List<WorldPackEntry> worldPacks;
        if (File.Exists(jsonPath))
        {
            var json = await File.ReadAllTextAsync(jsonPath);
            worldPacks = JsonSerializer.Deserialize<List<WorldPackEntry>>(json, _jsonOptions) 
                ?? new List<WorldPackEntry>();
        }
        else
        {
            worldPacks = new List<WorldPackEntry>();
            
            // Ensure world directory exists
            var worldDir = Path.GetDirectoryName(jsonPath);
            if (!string.IsNullOrEmpty(worldDir))
            {
                Directory.CreateDirectory(worldDir);
            }
        }

        // Check if already enabled
        if (worldPacks.Any(p => p.PackId == packUuid))
        {
            _logger.LogInformation("Pack already enabled: {Uuid}", packUuid);
            return true;
        }

        // Add the pack
        worldPacks.Add(new WorldPackEntry
        {
            PackId = packUuid,
            Version = packManifest.Header.Version
        });

        // Save the file
        var updatedJson = JsonSerializer.Serialize(worldPacks, _jsonOptions);
        await File.WriteAllTextAsync(jsonPath, updatedJson);

        _logger.LogInformation("Enabled pack: {Uuid} in {Path}", packUuid, jsonPath);
        return true;
    }

    /// <summary>
    /// Disable a pack in the world
    /// </summary>
    public async Task<bool> DisablePackAsync(string packUuid, PackType type)
    {
        var jsonPath = GetWorldPacksJsonPath(type);

        if (!File.Exists(jsonPath))
        {
            _logger.LogInformation("World packs file does not exist: {Path}", jsonPath);
            return true; // Already disabled
        }

        var json = await File.ReadAllTextAsync(jsonPath);
        var worldPacks = JsonSerializer.Deserialize<List<WorldPackEntry>>(json, _jsonOptions) 
            ?? new List<WorldPackEntry>();

        var initialCount = worldPacks.Count;
        worldPacks.RemoveAll(p => p.PackId == packUuid);

        if (worldPacks.Count == initialCount)
        {
            _logger.LogInformation("Pack not in world packs: {Uuid}", packUuid);
            return true; // Already disabled
        }

        // Save the updated file
        var updatedJson = JsonSerializer.Serialize(worldPacks, _jsonOptions);
        await File.WriteAllTextAsync(jsonPath, updatedJson);

        _logger.LogInformation("Disabled pack: {Uuid} from {Path}", packUuid, jsonPath);
        return true;
    }

    /// <summary>
    /// Replace old UUID with new UUID in world JSON files (for pack reuploads)
    /// </summary>
    private async Task ReplacePackUuidInWorldAsync(string oldUuid, string newUuid, List<int> newVersion, PackType type)
    {
        var jsonPath = GetWorldPacksJsonPath(type);

        if (!File.Exists(jsonPath))
        {
            _logger.LogInformation("World packs file does not exist, nothing to replace: {Path}", jsonPath);
            return;
        }

        try
        {
            var json = await File.ReadAllTextAsync(jsonPath);
            var worldPacks = JsonSerializer.Deserialize<List<WorldPackEntry>>(json, _jsonOptions) 
                ?? new List<WorldPackEntry>();

            // Find and replace the old UUID entry
            var oldEntry = worldPacks.FirstOrDefault(p => p.PackId == oldUuid);
            if (oldEntry != null)
            {
                oldEntry.PackId = newUuid;
                oldEntry.Version = newVersion;

                // Save the updated file
                var updatedJson = JsonSerializer.Serialize(worldPacks, _jsonOptions);
                await File.WriteAllTextAsync(jsonPath, updatedJson);

                _logger.LogInformation("Replaced pack UUID in world: {OldUuid} -> {NewUuid}", oldUuid, newUuid);
            }
            else
            {
                _logger.LogInformation("Old UUID not found in world packs, no replacement needed: {OldUuid}", oldUuid);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error replacing pack UUID in world file: {Path}", jsonPath);
            // Don't throw - this is not critical for pack installation
        }
    }

    private async Task<HashSet<string>> GetEnabledPackUuidsAsync(PackType type)
    {
        var jsonPath = GetWorldPacksJsonPath(type);
        var enabledUuids = new HashSet<string>();

        if (!File.Exists(jsonPath))
        {
            return enabledUuids;
        }

        try
        {
            var json = await File.ReadAllTextAsync(jsonPath);
            var worldPacks = JsonSerializer.Deserialize<List<WorldPackEntry>>(json, _jsonOptions);
            
            if (worldPacks != null)
            {
                foreach (var pack in worldPacks)
                {
                    enabledUuids.Add(pack.PackId);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading enabled packs from: {Path}", jsonPath);
        }

        return enabledUuids;
    }

    private string? FindManifestFile(string directory)
    {
        // Check current directory
        var manifestPath = Path.Combine(directory, "manifest.json");
        if (File.Exists(manifestPath))
        {
            return manifestPath;
        }

        // Check subdirectories (some packs have a single root folder)
        foreach (var subDir in Directory.GetDirectories(directory))
        {
            manifestPath = Path.Combine(subDir, "manifest.json");
            if (File.Exists(manifestPath))
            {
                return manifestPath;
            }
        }

        return null;
    }

    private PackType DetectPackTypeFromManifest(PackManifest manifest)
    {
        // Check module types
        if (manifest.Modules.Any(m => m.Type == "resources"))
        {
            return PackType.ResourcePack;
        }

        if (manifest.Modules.Any(m => m.Type == "data"))
        {
            return PackType.BehaviorPack;
        }

        // Default to behavior pack if unclear
        _logger.LogWarning("Could not detect pack type from manifest, defaulting to BehaviorPack");
        return PackType.BehaviorPack;
    }

    private string SanitizeFolderName(string name)
    {
        // Remove invalid file name characters
        var invalid = Path.GetInvalidFileNameChars();
        var sanitized = string.Join("_", name.Split(invalid, StringSplitOptions.RemoveEmptyEntries));
        
        // Limit length
        if (sanitized.Length > 50)
        {
            sanitized = sanitized.Substring(0, 50);
        }

        return sanitized.Trim();
    }

    private void CopyDirectory(string sourceDir, string targetDir)
    {
        Directory.CreateDirectory(targetDir);

        // Copy files
        foreach (var file in Directory.GetFiles(sourceDir))
        {
            var fileName = Path.GetFileName(file);
            var targetFile = Path.Combine(targetDir, fileName);
            File.Copy(file, targetFile, true);
        }

        // Copy subdirectories
        foreach (var subDir in Directory.GetDirectories(sourceDir))
        {
            var dirName = Path.GetFileName(subDir);
            var targetSubDir = Path.Combine(targetDir, dirName);
            CopyDirectory(subDir, targetSubDir);
        }
    }
}

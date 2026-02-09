using System.Text.Json.Serialization;

namespace MCBDS.API.Models;

/// <summary>
/// Type of Minecraft Bedrock pack
/// </summary>
public enum PackType
{
    /// <summary>
    /// Resource pack (textures, sounds, models)
    /// </summary>
    ResourcePack,
    
    /// <summary>
    /// Behavior pack (game logic, entities, blocks)
    /// </summary>
    BehaviorPack
}

/// <summary>
/// Represents the manifest.json structure from a Minecraft Bedrock pack
/// </summary>
public class PackManifest
{
    /// <summary>
    /// Format version of the manifest
    /// </summary>
    [JsonPropertyName("format_version")]
    public int FormatVersion { get; set; }

    /// <summary>
    /// Pack header information
    /// </summary>
    [JsonPropertyName("header")]
    public PackHeader Header { get; set; } = new();

    /// <summary>
    /// Pack modules
    /// </summary>
    [JsonPropertyName("modules")]
    public List<PackModule> Modules { get; set; } = new();

    /// <summary>
    /// Pack dependencies (optional)
    /// </summary>
    [JsonPropertyName("dependencies")]
    public List<PackDependency>? Dependencies { get; set; }
}

/// <summary>
/// Header section of a pack manifest
/// </summary>
public class PackHeader
{
    /// <summary>
    /// Display name of the pack
    /// </summary>
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Description of the pack
    /// </summary>
    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Unique identifier for the pack
    /// </summary>
    [JsonPropertyName("uuid")]
    public string Uuid { get; set; } = string.Empty;

    /// <summary>
    /// Pack version [major, minor, patch]
    /// </summary>
    [JsonPropertyName("version")]
    public List<int> Version { get; set; } = new() { 1, 0, 0 };

    /// <summary>
    /// Minimum engine version required
    /// </summary>
    [JsonPropertyName("min_engine_version")]
    public List<int>? MinEngineVersion { get; set; }
}

/// <summary>
/// Module section of a pack manifest
/// </summary>
public class PackModule
{
    /// <summary>
    /// Module type (e.g., "resources", "data")
    /// </summary>
    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// Module UUID
    /// </summary>
    [JsonPropertyName("uuid")]
    public string Uuid { get; set; } = string.Empty;

    /// <summary>
    /// Module version
    /// </summary>
    [JsonPropertyName("version")]
    public List<int> Version { get; set; } = new() { 1, 0, 0 };
}

/// <summary>
/// Dependency entry in a pack manifest
/// </summary>
public class PackDependency
{
    /// <summary>
    /// UUID of the required pack
    /// </summary>
    [JsonPropertyName("uuid")]
    public string Uuid { get; set; } = string.Empty;

    /// <summary>
    /// Required version
    /// </summary>
    [JsonPropertyName("version")]
    public List<int> Version { get; set; } = new() { 1, 0, 0 };
}

/// <summary>
/// Information about an installed pack for API responses
/// </summary>
public class PackInfo
{
    /// <summary>
    /// Unique identifier (folder name)
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// Display name from manifest
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Description from manifest
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Pack UUID from manifest
    /// </summary>
    public string Uuid { get; set; } = string.Empty;

    /// <summary>
    /// Pack version string (e.g., "1.0.0")
    /// </summary>
    public string Version { get; set; } = string.Empty;

    /// <summary>
    /// Type of pack
    /// </summary>
    public PackType Type { get; set; }

    /// <summary>
    /// Whether this pack is enabled in the world
    /// </summary>
    public bool IsEnabled { get; set; }

    /// <summary>
    /// Folder name on disk
    /// </summary>
    public string FolderName { get; set; } = string.Empty;
}

/// <summary>
/// Entry in world_behavior_packs.json or world_resource_packs.json
/// </summary>
public class WorldPackEntry
{
    /// <summary>
    /// Pack UUID
    /// </summary>
    [JsonPropertyName("pack_id")]
    public string PackId { get; set; } = string.Empty;

    /// <summary>
    /// Pack version
    /// </summary>
    [JsonPropertyName("version")]
    public List<int> Version { get; set; } = new() { 1, 0, 0 };
}

namespace MCBDS.ClientUI.Shared.Models;

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
/// Information about an installed pack
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
/// Response from GET /api/packs
/// </summary>
public class PacksResponse
{
    /// <summary>
    /// List of resource packs
    /// </summary>
    public List<PackInfo> ResourcePacks { get; set; } = new();

    /// <summary>
    /// List of behavior packs
    /// </summary>
    public List<PackInfo> BehaviorPacks { get; set; } = new();
}

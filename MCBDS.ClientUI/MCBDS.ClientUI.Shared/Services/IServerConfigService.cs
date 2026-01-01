namespace MCBDS.ClientUI.Shared.Services;

/// <summary>
/// Interface for server configuration services
/// Allows different implementations for different platforms (MAUI uses file system, Web uses localStorage)
/// </summary>
public interface IServerConfigService
{
    /// <summary>
    /// Event fired when the server configuration changes
    /// </summary>
    event Action? OnServerChanged;
    
    /// <summary>
    /// Loads the server configuration asynchronously
    /// </summary>
    Task<ServerConfig> LoadConfigAsync();
    
    /// <summary>
    /// Saves the server configuration asynchronously
    /// </summary>
    Task<bool> SaveConfigAsync(ServerConfig config);
    
    /// <summary>
    /// Ensures the service is initialized
    /// </summary>
    Task EnsureInitializedAsync();
    
    /// <summary>
    /// Gets the cached configuration (may be null if not yet loaded)
    /// </summary>
    ServerConfig GetCachedConfig();
    
    /// <summary>
    /// Gets the current server URL
    /// </summary>
    string GetCurrentServerUrl();
    
    /// <summary>
    /// Gets the current server display name
    /// </summary>
    string GetCurrentServerName();
    
    /// <summary>
    /// Gets all saved servers
    /// </summary>
    List<SavedServer> GetSavedServers();
    
    /// <summary>
    /// Switches to a different server
    /// </summary>
    Task<bool> SwitchServerAsync(string serverUrl);
    
    /// <summary>
    /// Adds a new server to the saved servers list
    /// </summary>
    Task<bool> AddServerAsync(string name, string url);
    
    /// <summary>
    /// Removes a server from the saved servers list
    /// </summary>
    Task<bool> RemoveServerAsync(string url);
}

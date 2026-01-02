using System.Text.Json;
using Microsoft.JSInterop;
using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI.Web.Services;

/// <summary>
/// Web-specific implementation of server configuration using browser localStorage
/// </summary>
public class WebServerConfigService : IServerConfigService
{
    private readonly IJSRuntime _jsRuntime;
    private readonly HttpClient _httpClient;
    private ServerConfig? _cachedConfig;
    private bool _isInitialized = false;
    private readonly SemaphoreSlim _initLock = new(1, 1);
    private const string StorageKey = "mcbds_server_config";

    public event Action? OnServerChanged;

    public WebServerConfigService(IJSRuntime jsRuntime, HttpClient httpClient)
    {
        _jsRuntime = jsRuntime;
        _httpClient = httpClient;
        
        // Initialize with default config immediately so GetCurrentServerUrl() works before async load
        _cachedConfig = GetDefaultConfig();
    }

    public async Task<ServerConfig> LoadConfigAsync()
    {
        await _initLock.WaitAsync();
        try
        {
            if (_isInitialized && _cachedConfig != null)
            {
                return _cachedConfig;
            }
            
            try
            {
                var json = await _jsRuntime.InvokeAsync<string?>("localStorage.getItem", StorageKey);
                
                if (!string.IsNullOrEmpty(json))
                {
                    var loadedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
                    if (loadedConfig != null)
                    {
                        _cachedConfig = loadedConfig;
                    }
                }
            }
            catch (InvalidOperationException)
            {
                // JSInterop not available yet (prerendering) - use default config
                Console.WriteLine("JSInterop not available yet, using default config");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading server config from localStorage: {ex.Message}");
            }

            _cachedConfig ??= GetDefaultConfig();
            _isInitialized = true;
            return _cachedConfig;
        }
        finally
        {
            _initLock.Release();
        }
    }

    public async Task<bool> SaveConfigAsync(ServerConfig config)
    {
        try
        {
            var json = JsonSerializer.Serialize(config, new JsonSerializerOptions
            {
                WriteIndented = false
            });

            await _jsRuntime.InvokeVoidAsync("localStorage.setItem", StorageKey, json);
            _cachedConfig = config;
            return true;
        }
        catch (InvalidOperationException)
        {
            // JSInterop not available yet (prerendering)
            Console.WriteLine("JSInterop not available, cannot save config");
            _cachedConfig = config;
            return false;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving server config to localStorage: {ex.Message}");
            return false;
        }
    }

    public async Task EnsureInitializedAsync()
    {
        if (!_isInitialized)
        {
            await LoadConfigAsync();
        }
    }

    public ServerConfig GetCachedConfig()
    {
        return _cachedConfig ?? GetDefaultConfig();
    }

    public string GetCurrentServerUrl()
    {
        // Return cached config URL or default - never null/empty
        var url = _cachedConfig?.CurrentServerUrl;
        if (string.IsNullOrWhiteSpace(url))
        {
            url = GetDefaultConfig().CurrentServerUrl;
        }
        return url;
    }

    public string GetCurrentServerName()
    {
        var config = _cachedConfig ?? GetDefaultConfig();
        var current = config.SavedServers?.FirstOrDefault(s => s.Url == config.CurrentServerUrl);
        return current?.Name ?? config.CurrentServerUrl;
    }

    public List<SavedServer> GetSavedServers()
    {
        return _cachedConfig?.SavedServers ?? GetDefaultConfig().SavedServers;
    }

    public async Task<bool> SwitchServerAsync(string serverUrl)
    {
        var config = _cachedConfig ?? GetDefaultConfig();
        config.CurrentServerUrl = serverUrl;
        
        var saved = await SaveConfigAsync(config);
        
        if (saved)
        {
            OnServerChanged?.Invoke();
        }
        
        return saved;
    }

    public async Task<bool> AddServerAsync(string name, string url)
    {
        var config = _cachedConfig ?? GetDefaultConfig();
        
        // Normalize URL - strip any protocol prefix and add http:// if needed
        url = NormalizeUrl(url);
        
        // Check if server already exists
        var existing = config.SavedServers.FirstOrDefault(s => 
            s.Url.Equals(url, StringComparison.OrdinalIgnoreCase));
        
        if (existing != null)
        {
            // Update existing server name
            existing.Name = name;
        }
        else
        {
            config.SavedServers.Add(new SavedServer { Name = name, Url = url });
        }
        
        return await SaveConfigAsync(config);
    }

    public async Task<bool> RemoveServerAsync(string url)
    {
        var config = _cachedConfig ?? GetDefaultConfig();
        
        var server = config.SavedServers.FirstOrDefault(s => 
            s.Url.Equals(url, StringComparison.OrdinalIgnoreCase));
        
        if (server != null)
        {
            config.SavedServers.Remove(server);
            
            // If we removed the current server, switch to the first available
            if (config.CurrentServerUrl.Equals(url, StringComparison.OrdinalIgnoreCase) 
                && config.SavedServers.Count > 0)
            {
                config.CurrentServerUrl = config.SavedServers.First().Url;
            }
            
            return await SaveConfigAsync(config);
        }
        
        return false;
    }

    private static string NormalizeUrl(string url)
    {
        // Remove any protocol prefix (valid or malformed like hpps://, htps://, etc.)
        var protocolIndex = url.IndexOf("://", StringComparison.OrdinalIgnoreCase);
        if (protocolIndex > 0)
        {
            var protocol = url.Substring(0, protocolIndex).ToLowerInvariant();
            // Only keep valid protocols, strip invalid ones
            if (protocol == "http" || protocol == "https")
            {
                // Valid protocol, keep as-is but normalize to lowercase
                url = protocol + url.Substring(protocolIndex);
            }
            else
            {
                // Invalid protocol, strip it
                url = url.Substring(protocolIndex + 3);
            }
        }
        
        // Add http:// if no protocol (case-insensitive check)
        if (!url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && 
            !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            url = "http://" + url;
        }
        
        // Remove trailing slash
        url = url.TrimEnd('/');
        
        return url;
    }

    private static ServerConfig GetDefaultConfig()
    {
        return new ServerConfig
        {
            CurrentServerUrl = "http://localhost:8080",
            SavedServers = new List<SavedServer>
            {
                new SavedServer { Name = "Local Development", Url = "http://localhost:8080" }
            }
        };
    }
}

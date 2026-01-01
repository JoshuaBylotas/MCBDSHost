using System.Text.Json;

namespace MCBDS.ClientUI.Shared.Services;

/// <summary>
/// Service to manage server connection configuration with persistence
/// Uses file system for MAUI/desktop applications
/// </summary>
public class ServerConfigService : IServerConfigService
{
    private readonly string _settingsFilePath;
    private ServerConfig? _cachedConfig;
    private readonly HttpClient _httpClient;
    private bool _isInitialized = false;
    private readonly SemaphoreSlim _initLock = new(1, 1);

    public event Action? OnServerChanged;

    public ServerConfigService(HttpClient httpClient, string? settingsDirectory = null)
    {
        _httpClient = httpClient;
        var directory = settingsDirectory ?? Directory.GetCurrentDirectory();
        _settingsFilePath = Path.Combine(directory, "server-config.json");
        
        // Set default base address immediately (synchronously)
        InitializeDefaultConfig();
    }

    private void InitializeDefaultConfig()
    {
        try
        {
            // Try to load config synchronously on startup
            if (File.Exists(_settingsFilePath))
            {
                var json = File.ReadAllText(_settingsFilePath);
                _cachedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
            }
            
            _cachedConfig ??= GetDefaultConfig();
            
            // Set the HttpClient base address immediately
            if (!string.IsNullOrWhiteSpace(_cachedConfig.CurrentServerUrl))
            {
                SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            }
            
            _isInitialized = true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error initializing server config: {ex.Message}");
            _cachedConfig = GetDefaultConfig();
            SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            _isInitialized = true;
        }
    }

    public async Task<ServerConfig> LoadConfigAsync()
    {
        await _initLock.WaitAsync();
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                var json = await File.ReadAllTextAsync(_settingsFilePath);
                _cachedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
                
                if (_cachedConfig != null && !string.IsNullOrWhiteSpace(_cachedConfig.CurrentServerUrl))
                {
                    SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
                }
                
                return _cachedConfig ?? GetDefaultConfig();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading server config: {ex.Message}");
        }
        finally
        {
            _initLock.Release();
        }

        _cachedConfig ??= GetDefaultConfig();
        return _cachedConfig;
    }

    public async Task<bool> SaveConfigAsync(ServerConfig config)
    {
        try
        {
            // Ensure directory exists
            var directory = Path.GetDirectoryName(_settingsFilePath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }
            
            var json = JsonSerializer.Serialize(config, new JsonSerializerOptions
            {
                WriteIndented = true
            });

            await File.WriteAllTextAsync(_settingsFilePath, json);
            _cachedConfig = config;
            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving server config: {ex.Message}");
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
        return _cachedConfig?.CurrentServerUrl ?? GetDefaultConfig().CurrentServerUrl;
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
        
        SetHttpClientBaseAddress(serverUrl);
        
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
        
        // Normalize URL
        if (!url.StartsWith("http://") && !url.StartsWith("https://"))
        {
            url = "http://" + url;
        }
        
        // Remove trailing slash
        url = url.TrimEnd('/');
        
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
                SetHttpClientBaseAddress(config.CurrentServerUrl);
            }
            
            return await SaveConfigAsync(config);
        }
        
        return false;
    }

    private void SetHttpClientBaseAddress(string url)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(url))
            {
                return;
            }
            
            if (!url.StartsWith("http://") && !url.StartsWith("https://"))
            {
                url = "http://" + url;
            }
            
            var newUri = new Uri(url.TrimEnd('/') + "/");
            
            // HttpClient.BaseAddress can only be set once before any request is made
            // After that, we need to use a different approach - prepend the base URL to requests
            // However, for MAUI apps with a fresh HttpClient, this should work
            if (_httpClient.BaseAddress == null)
            {
                _httpClient.BaseAddress = newUri;
            }
            else if (_httpClient.BaseAddress != newUri)
            {
                // If the base address is already set to a different value,
                // we need to clear pending requests and try to set it
                // This is a limitation of HttpClient - BaseAddress is immutable after first request
                try
                {
                    _httpClient.BaseAddress = newUri;
                }
                catch (InvalidOperationException)
                {
                    // BaseAddress already set and requests have been made
                    // The workaround is to use absolute URIs in requests
                    // Store the base URL for later use
                    Console.WriteLine($"HttpClient BaseAddress already set. New URL: {newUri}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error setting HttpClient base address: {ex.Message}");
        }
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

public class ServerConfig
{
    public string CurrentServerUrl { get; set; } = "http://localhost:8080";
    public List<SavedServer> SavedServers { get; set; } = new();
}

public class SavedServer
{
    public string Name { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}

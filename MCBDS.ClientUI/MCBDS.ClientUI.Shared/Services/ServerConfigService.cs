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
            // Note: CrashLogger may not be available yet, use Debug.WriteLine as backup
            System.Diagnostics.Debug.WriteLine("ServerConfigService: Initializing default config");
            System.Diagnostics.Debug.WriteLine($"ServerConfigService: Settings file path: {_settingsFilePath}");

            // Try to load config synchronously on startup
            if (File.Exists(_settingsFilePath))
            {
                System.Diagnostics.Debug.WriteLine("ServerConfigService: Config file exists, attempting to read");
                var json = File.ReadAllText(_settingsFilePath);
                _cachedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
                System.Diagnostics.Debug.WriteLine("ServerConfigService: Config loaded successfully");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine("ServerConfigService: Config file does not exist, using defaults");
            }
            
            _cachedConfig ??= GetDefaultConfig();
            
            // Set the HttpClient base address immediately
            if (!string.IsNullOrWhiteSpace(_cachedConfig.CurrentServerUrl))
            {
                SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
                System.Diagnostics.Debug.WriteLine($"ServerConfigService: HttpClient base address set to: {_cachedConfig.CurrentServerUrl}");
            }
            
            _isInitialized = true;
            System.Diagnostics.Debug.WriteLine("ServerConfigService: Initialized successfully");
        }
        catch (UnauthorizedAccessException ex)
        {
            System.Diagnostics.Debug.WriteLine($"ServerConfigService: File access denied - using default config. Error: {ex.Message}");
            _cachedConfig = GetDefaultConfig();
            SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            _isInitialized = true;
        }
        catch (IOException ex)
        {
            System.Diagnostics.Debug.WriteLine($"ServerConfigService: IO error - using default config. Error: {ex.Message}");
            _cachedConfig = GetDefaultConfig();
            SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            _isInitialized = true;
        }
        catch (JsonException ex)
        {
            System.Diagnostics.Debug.WriteLine($"ServerConfigService: JSON parsing error - using default config. Error: {ex.Message}");
            _cachedConfig = GetDefaultConfig();
            SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            _isInitialized = true;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"ServerConfigService: Unexpected error during initialization - using default config. Error: {ex.GetType().Name}: {ex.Message}");
            _cachedConfig = GetDefaultConfig();
            try
            {
                SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            }
            catch (Exception httpEx)
            {
                System.Diagnostics.Debug.WriteLine($"ServerConfigService: Failed to set HttpClient base address: {httpEx.Message}");
            }
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
        var url = _cachedConfig?.CurrentServerUrl ?? GetDefaultConfig().CurrentServerUrl;
        return string.IsNullOrWhiteSpace(url) ? "" : url;
    }

    public string GetCurrentServerName()
    {
        var config = _cachedConfig ?? GetDefaultConfig();
        if (string.IsNullOrWhiteSpace(config.CurrentServerUrl))
        {
            return "No Server Configured";
        }
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
            
            // If we removed the current server, switch to the first available or empty
            if (config.CurrentServerUrl.Equals(url, StringComparison.OrdinalIgnoreCase))
            {
                if (config.SavedServers.Count > 0)
                {
                    config.CurrentServerUrl = config.SavedServers.First().Url;
                    SetHttpClientBaseAddress(config.CurrentServerUrl);
                }
                else
                {
                    config.CurrentServerUrl = "";
                    // Don't attempt to set HttpClient base address when empty
                }
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
            CurrentServerUrl = "",
            SavedServers = new List<SavedServer>()
        };
    }
}

public class ServerConfig
{
    public string CurrentServerUrl { get; set; } = "";
    public List<SavedServer> SavedServers { get; set; } = new();
}

public class SavedServer
{
    public string Name { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}

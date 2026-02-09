using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using MCBDS.ClientUI.Shared.Models;

namespace MCBDS.ClientUI.Shared.Services;

/// <summary>
/// Result wrapper for API calls with error handling
/// </summary>
public class ApiResult<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? ErrorMessage { get; set; }
    public ApiErrorType ErrorType { get; set; } = ApiErrorType.None;
    
    public static ApiResult<T> Ok(T data) => new() { Success = true, Data = data };
    public static ApiResult<T> Fail(string message, ApiErrorType errorType = ApiErrorType.Unknown) 
        => new() { Success = false, ErrorMessage = message, ErrorType = errorType };
}

public enum ApiErrorType
{
    None,
    ConnectionFailed,
    Timeout,
    NotFound,
    ServerError,
    Unknown
}

public class BedrockApiService
{
    private readonly HttpClient _httpClient;
    private readonly IServerConfigService? _serverConfig;

    public BedrockApiService(HttpClient httpClient, IServerConfigService? serverConfig = null)
    {
        _httpClient = httpClient;
        _serverConfig = serverConfig;
        // Set a reasonable timeout
        _httpClient.Timeout = TimeSpan.FromSeconds(30);
    }

    /// <summary>
    /// Gets the base URL for API requests
    /// </summary>
    private string GetBaseUrl()
    {
        if (_serverConfig != null)
        {
            var url = _serverConfig.GetCurrentServerUrl();
            if (!string.IsNullOrWhiteSpace(url))
            {
                return url.TrimEnd('/');
            }
        }
        
        // Fallback to HttpClient's BaseAddress if set
        if (_httpClient.BaseAddress != null)
        {
            return _httpClient.BaseAddress.ToString().TrimEnd('/');
        }
        
        // Default fallback
        return "http://localhost:8080";
    }

    /// <summary>
    /// Builds a full URL for the given endpoint
    /// </summary>
    private string BuildUrl(string endpoint)
    {
        var baseUrl = GetBaseUrl();
        var path = endpoint.StartsWith("/") ? endpoint : "/" + endpoint;
        return baseUrl + path;
    }

    private static ApiErrorType GetErrorType(Exception ex)
    {
        return ex switch
        {
            HttpRequestException => ApiErrorType.ConnectionFailed,
            TaskCanceledException => ApiErrorType.Timeout,
            InvalidOperationException when ex.Message.Contains("BaseAddress") => ApiErrorType.ConnectionFailed,
            _ => ApiErrorType.Unknown
        };
    }

    private static string GetFriendlyErrorMessage(Exception ex, string operation)
    {
        return ex switch
        {
            HttpRequestException => $"Unable to connect to server. Please check if the server is running and the URL is correct.",
            TaskCanceledException => $"Request timed out while trying to {operation}. The server may be slow or unreachable.",
            InvalidOperationException when ex.Message.Contains("BaseAddress") => "No server configured. Please select or add a server.",
            _ => $"An error occurred while trying to {operation}: {ex.Message}"
        };
    }

    public async Task<ApiResult<string>> GetLogAsync()
    {
        try
        {
            var url = BuildUrl("/api/runner/log");
            var result = await _httpClient.GetStringAsync(url);
            return ApiResult<string>.Ok(result);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "get server log"), GetErrorType(ex));
        }
    }

    public async Task<ApiResult<string>> SendLineAsync(string line)
    {
        try
        {
            var url = BuildUrl("/api/runner/send");
            var response = await _httpClient.PostAsJsonAsync(url, new { line });
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }
            return ApiResult<string>.Fail($"Server returned error: {response.StatusCode}", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "send command"), GetErrorType(ex));
        }
    }

    public async Task<ApiResult<string>> RestartAsync()
    {
        try
        {
            var url = BuildUrl("/api/runner/restart");
            var response = await _httpClient.PostAsync(url, null);
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }
            return ApiResult<string>.Fail($"Server returned error: {response.StatusCode}", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "restart server"), GetErrorType(ex));
        }
    }

    // Backup API methods
    public async Task<ApiResult<BackupConfigResponse>> GetBackupConfigAsync()
    {
        try
        {
            var url = BuildUrl("/api/backup/config");
            var result = await _httpClient.GetFromJsonAsync<BackupConfigResponse>(url);
            return result != null 
                ? ApiResult<BackupConfigResponse>.Ok(result) 
                : ApiResult<BackupConfigResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<BackupConfigResponse>.Fail(GetFriendlyErrorMessage(ex, "get backup configuration"), GetErrorType(ex));
        }
    }

    public async Task<(bool success, string? message, BackupConfigResponse? savedConfig)> UpdateBackupConfigAsync(int frequencyMinutes, string backupDirectory, int maxBackupsToKeep)
    {
        try
        {
            var url = BuildUrl("/api/backup/config");
            var response = await _httpClient.PutAsJsonAsync(url, new
            {
                FrequencyMinutes = frequencyMinutes,
                BackupDirectory = backupDirectory,
                MaxBackupsToKeep = maxBackupsToKeep
            });

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<UpdateConfigResponse>();
                
                var savedConfig = new BackupConfigResponse
                {
                    FrequencyMinutes = frequencyMinutes,
                    BackupDirectory = backupDirectory,
                    MaxBackupsToKeep = maxBackupsToKeep
                };
                
                return (true, result?.message, savedConfig);
            }

            var error = await response.Content.ReadAsStringAsync();
            return (false, error, null);
        }
        catch (Exception ex)
        {
            return (false, GetFriendlyErrorMessage(ex, "update backup configuration"), null);
        }
    }

    public async Task<(bool success, string? message)> TriggerManualBackupAsync()
    {
        try
        {
            var url = BuildUrl("/api/backup/trigger");
            var response = await _httpClient.PostAsync(url, null);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<TriggerBackupResponse>();
                return (true, result?.message);
            }

            var error = await response.Content.ReadAsStringAsync();
            return (false, error);
        }
        catch (Exception ex)
        {
            return (false, GetFriendlyErrorMessage(ex, "trigger backup"));
        }
    }

    public async Task<ApiResult<BackupListResponse>> GetBackupListAsync()
    {
        try
        {
            var url = BuildUrl("/api/backup/list");
            var result = await _httpClient.GetFromJsonAsync<BackupListResponse>(url);
            return result != null 
                ? ApiResult<BackupListResponse>.Ok(result) 
                : ApiResult<BackupListResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<BackupListResponse>.Fail(GetFriendlyErrorMessage(ex, "get backup list"), GetErrorType(ex));
        }
    }

    public async Task<(bool success, string? message)> DeleteBackupAsync(string backupName)
    {
        try
        {
            var url = BuildUrl($"/api/backup/{backupName}");
            var response = await _httpClient.DeleteAsync(url);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<DeleteBackupResponse>();
                return (true, result?.message);
            }

            var error = await response.Content.ReadAsStringAsync();
            return (false, error);
        }
        catch (Exception ex)
        {
            return (false, GetFriendlyErrorMessage(ex, "delete backup"));
        }
    }

    public async Task<ApiResult<RestoreBackupResponse>> RestoreBackupAsync(string backupName)
    {
        try
        {
            var url = BuildUrl($"/api/backup/restore/{backupName}");
            var response = await _httpClient.PostAsync(url, null);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<RestoreBackupResponse>();
                return result != null 
                    ? ApiResult<RestoreBackupResponse>.Ok(result) 
                    : ApiResult<RestoreBackupResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<RestoreBackupResponse>.Fail(error, ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<RestoreBackupResponse>.Fail(GetFriendlyErrorMessage(ex, "restore backup"), GetErrorType(ex));
        }
    }

    // Server Properties API methods
    public async Task<ApiResult<ServerPropertiesResponse>> GetServerPropertiesAsync()
    {
        try
        {
            var url = BuildUrl("/api/serverproperties");
            var result = await _httpClient.GetFromJsonAsync<ServerPropertiesResponse>(url);
            return result != null 
                ? ApiResult<ServerPropertiesResponse>.Ok(result) 
                : ApiResult<ServerPropertiesResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<ServerPropertiesResponse>.Fail(GetFriendlyErrorMessage(ex, "get server properties"), GetErrorType(ex));
        }
    }

    // Server Status API methods
    public async Task<ApiResult<SystemStatusResponse>> GetSystemStatusAsync()
    {
        try
        {
            var url = BuildUrl("/api/runner/status");
            var result = await _httpClient.GetFromJsonAsync<SystemStatusResponse>(url);
            return result != null 
                ? ApiResult<SystemStatusResponse>.Ok(result) 
                : ApiResult<SystemStatusResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<SystemStatusResponse>.Fail(GetFriendlyErrorMessage(ex, "get system status"), GetErrorType(ex));
        }
    }
    
    /// <summary>
    /// Test connection to the server
    /// </summary>
    public async Task<ApiResult<bool>> TestConnectionAsync()
    {
        try
        {
            var url = BuildUrl("/api/runner/status");
            var response = await _httpClient.GetAsync(url);
            return response.IsSuccessStatusCode 
                ? ApiResult<bool>.Ok(true) 
                : ApiResult<bool>.Fail($"Server returned status {response.StatusCode}", ApiErrorType.ServerError);
        }
        catch (Exception ex)
        {
            return ApiResult<bool>.Fail(GetFriendlyErrorMessage(ex, "connect to server"), GetErrorType(ex));
        }
    }

    // ===========================
    // API Capabilities (Backward Compatibility)
    // ===========================

    /// <summary>
    /// Get API capabilities for feature detection (backward compatibility)
    /// </summary>
    public async Task<Models.ApiCapabilities> GetCapabilitiesAsync()
    {
        try
        {
            var url = BuildUrl("/api/version");
            var result = await _httpClient.GetFromJsonAsync<Models.ApiCapabilities>(url);
            return result ?? new Models.ApiCapabilities 
            { 
                Version = "1.0", 
                SupportsAllowlist = false,
                SupportsServerProperties = false
            };
        }
        catch
        {
            // Fallback for older servers that don't have /api/version endpoint
            return new Models.ApiCapabilities 
            { 
                Version = "1.0", 
                SupportsAllowlist = false,
                SupportsServerProperties = false,
                SupportedFeatures = new List<string>()
            };
        }
    }

    // ===========================
    // Allowlist Management
    // ===========================

    /// <summary>
    /// Get the current allowlist from the server
    /// </summary>
    public async Task<ApiResult<Models.AllowlistData>> GetAllowlistAsync()
    {
        try
        {
            var url = BuildUrl("/api/allowlist");
            var result = await _httpClient.GetFromJsonAsync<Models.AllowlistData>(url);
            return result != null 
                ? ApiResult<Models.AllowlistData>.Ok(result) 
                : ApiResult<Models.AllowlistData>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<Models.AllowlistData>.Fail("Allowlist feature not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<Models.AllowlistData>.Fail(GetFriendlyErrorMessage(ex, "get allowlist"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Update the entire allowlist on the server
    /// </summary>
    public async Task<ApiResult<string>> UpdateAllowlistAsync(Models.AllowlistData allowlistData)
    {
        try
        {
            var url = BuildUrl("/api/allowlist");
            var response = await _httpClient.PostAsJsonAsync(url, allowlistData);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Allowlist feature not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "update allowlist"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Add a single user to the allowlist
    /// </summary>
    public async Task<ApiResult<string>> AddAllowlistUserAsync(Models.AddAllowlistUserRequest request)
    {
        try
        {
            var url = BuildUrl("/api/allowlist/user");
            var response = await _httpClient.PostAsJsonAsync(url, request);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Allowlist feature not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "add user to allowlist"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Remove a user from the allowlist by XUID
    /// </summary>
    public async Task<ApiResult<string>> RemoveAllowlistUserAsync(string xuid)
    {
        try
        {
            var url = BuildUrl($"/api/allowlist/user/{xuid}");
            var response = await _httpClient.DeleteAsync(url);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Allowlist feature not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "remove user from allowlist"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Toggle the allowlist feature in server.properties
    /// </summary>
    public async Task<ApiResult<string>> ToggleAllowlistAsync(bool enabled)
    {
        try
        {
            var url = BuildUrl("/api/allowlist/toggle");
            var response = await _httpClient.PostAsJsonAsync(url, new { enabled });
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Allowlist toggle not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "toggle allowlist"), GetErrorType(ex));
        }
    }

    // ===========================
    // Pack Management (API v1.1+)
    // ===========================

    /// <summary>
    /// Upload and install a pack (.zip or .mcpack file)
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<Models.PackInfo>> UploadPackAsync(Stream fileStream, string fileName, Models.PackType type)
    {
        try
        {
            // Check API version first
            var capabilities = await GetCapabilitiesAsync();
            if (!capabilities.SupportsPackManagement)
            {
                return ApiResult<Models.PackInfo>.Fail(
                    "Pack management is not supported by this server version. Please upgrade to API v1.1+", 
                    ApiErrorType.NotFound);
            }

            var url = BuildUrl("/api/packs/upload");
            
            using var content = new MultipartFormDataContent();
            using var streamContent = new StreamContent(fileStream);
            streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
            content.Add(streamContent, "file", fileName);
            content.Add(new StringContent(type.ToString()), "type");

            var response = await _httpClient.PostAsync(url, content);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<Models.PackInfo>();
                return result != null 
                    ? ApiResult<Models.PackInfo>.Ok(result) 
                    : ApiResult<Models.PackInfo>.Fail("No data returned from server", ApiErrorType.ServerError);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<Models.PackInfo>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<Models.PackInfo>.Fail("Pack management not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<Models.PackInfo>.Fail(GetFriendlyErrorMessage(ex, "upload pack"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Get all installed packs
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<Models.PacksResponse>> GetPacksAsync()
    {
        try
        {
            // Check API version first
            var capabilities = await GetCapabilitiesAsync();
            if (!capabilities.SupportsPackManagement)
            {
                return ApiResult<Models.PacksResponse>.Fail(
                    "Pack management is not supported by this server version. Please upgrade to API v1.1+", 
                    ApiErrorType.NotFound);
            }

            var url = BuildUrl("/api/packs");
            var result = await _httpClient.GetFromJsonAsync<Models.PacksResponse>(url);
            return result != null 
                ? ApiResult<Models.PacksResponse>.Ok(result) 
                : ApiResult<Models.PacksResponse>.Fail("No data returned from server", ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<Models.PacksResponse>.Fail("Pack management not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<Models.PacksResponse>.Fail(GetFriendlyErrorMessage(ex, "get packs"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Delete a pack
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<string>> DeletePackAsync(string packUuid, Models.PackType type)
    {
        try
        {
            var capabilities = await GetCapabilitiesAsync();
            if (!capabilities.SupportsPackManagement)
            {
                return ApiResult<string>.Fail(
                    "Pack management is not supported by this server version. Please upgrade to API v1.1+", 
                    ApiErrorType.NotFound);
            }

            var url = BuildUrl($"/api/packs/{packUuid}?type={type}");
            var response = await _httpClient.DeleteAsync(url);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Pack management not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "delete pack"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Enable a pack in the world
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<string>> EnablePackAsync(string packUuid, Models.PackType type)
    {
        try
        {
            var capabilities = await GetCapabilitiesAsync();
            if (!capabilities.SupportsPackManagement)
            {
                return ApiResult<string>.Fail(
                    "Pack management is not supported by this server version. Please upgrade to API v1.1+", 
                    ApiErrorType.NotFound);
            }

            var url = BuildUrl($"/api/packs/{packUuid}/enable?type={type}");
            var response = await _httpClient.PostAsync(url, null);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Pack management not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "enable pack"), GetErrorType(ex));
        }
    }

    /// <summary>
    /// Disable a pack in the world
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<string>> DisablePackAsync(string packUuid, Models.PackType type)
    {
        try
        {
            var capabilities = await GetCapabilitiesAsync();
            if (!capabilities.SupportsPackManagement)
            {
                return ApiResult<string>.Fail(
                    "Pack management is not supported by this server version. Please upgrade to API v1.1+", 
                    ApiErrorType.NotFound);
            }

            var url = BuildUrl($"/api/packs/{packUuid}/disable?type={type}");
            var response = await _httpClient.PostAsync(url, null);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadAsStringAsync();
                return ApiResult<string>.Ok(result);
            }

            var error = await response.Content.ReadAsStringAsync();
            return ApiResult<string>.Fail(error, ApiErrorType.ServerError);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<string>.Fail("Pack management not supported by this server version", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<string>.Fail(GetFriendlyErrorMessage(ex, "disable pack"), GetErrorType(ex));
        }
    }

    // ===========================
    // Xbox Live Lookup (API v1.1+)
    // ===========================

    /// <summary>
    /// Lookup Xbox Live XUID by gamertag via backend API
    /// Requires API v1.1+
    /// </summary>
    public async Task<ApiResult<XboxLiveProfile>> LookupXboxGamertagAsync(string gamertag)
    {
        try
        {
            var url = BuildUrl($"/api/xboxlive/lookup/{Uri.EscapeDataString(gamertag)}");
            var response = await _httpClient.GetAsync(url);
            
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<XboxLiveLookupResponse>();
                if (result != null)
                {
                    return ApiResult<XboxLiveProfile>.Ok(new XboxLiveProfile
                    {
                        Gamertag = result.Gamertag ?? gamertag,
                        Xuid = result.Xuid ?? string.Empty,
                        IsValid = result.IsValid,
                        ErrorMessage = null
                    });
                }
            }

            // Check for specific error responses
            var errorContent = await response.Content.ReadAsStringAsync();
            return ApiResult<XboxLiveProfile>.Fail(
                errorContent.Contains("not configured") 
                    ? "Xbox Live API not configured on server. Please enter XUID manually." 
                    : "Gamertag not found. Please enter XUID manually.",
                ApiErrorType.NotFound);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return ApiResult<XboxLiveProfile>.Fail("Gamertag not found on Xbox Live", ApiErrorType.NotFound);
        }
        catch (Exception ex)
        {
            return ApiResult<XboxLiveProfile>.Fail(GetFriendlyErrorMessage(ex, "lookup Xbox gamertag"), GetErrorType(ex));
        }
    }
}

/// <summary>
/// Response from Xbox Live lookup API
/// </summary>
public class XboxLiveLookupResponse
{
    public string? Gamertag { get; set; }
    public string? Xuid { get; set; }
    public bool IsValid { get; set; }
}

public class BackupConfigResponse
{
    public int FrequencyMinutes { get; set; }
    public string BackupDirectory { get; set; } = string.Empty;
    public int MaxBackupsToKeep { get; set; }
}

public class UpdateConfigResponse
{
    public string? message { get; set; }
    public bool restartRequired { get; set; }
}

public class TriggerBackupResponse
{
    public string? message { get; set; }
    public string? note { get; set; }
}

public class BackupListResponse
{
    public List<BackupInfo>? backups { get; set; }
    public int count { get; set; }
    public string? message { get; set; }
}

public class BackupInfo
{
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public double SizeMB { get; set; }
    public string Path { get; set; } = string.Empty;
}

public class DeleteBackupResponse
{
    public string? message { get; set; }
}

public class RestoreBackupResponse
{
    public string? message { get; set; }
    public string? backupName { get; set; }
    public DateTime restoredAt { get; set; }
}

public class ServerPropertiesResponse
{
    public string Path { get; set; } = string.Empty;
    public DateTime LastModified { get; set; }
    public int TotalProperties { get; set; }
    public List<ServerPropertyCategory>? Categories { get; set; }
}

public class ServerPropertyCategory
{
    public string Category { get; set; } = string.Empty;
    public List<ServerPropertyItem>? Properties { get; set; }
}

public class ServerPropertyItem
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
}

public class SystemStatusResponse
{
    public ServerStatusInfo? Server { get; set; }
    public ApiHostStatusInfo? Api { get; set; }
    public DateTime Timestamp { get; set; }
}

public class ServerStatusInfo
{
    public bool IsRunning { get; set; }
    public int ProcessId { get; set; }
    public string ProcessName { get; set; } = string.Empty;
    public DateTime StartTimeUtc { get; set; }
    public TimeSpan Uptime { get; set; }
    public double WorkingSetMB { get; set; }
    public double PrivateMemoryMB { get; set; }
    public double VirtualMemoryMB { get; set; }
    public double PeakWorkingSetMB { get; set; }
    public TimeSpan TotalProcessorTime { get; set; }
    public TimeSpan UserProcessorTime { get; set; }
    public int ThreadCount { get; set; }
    public int HandleCount { get; set; }
}

public class ApiHostStatusInfo
{
    public int ProcessId { get; set; }
    public string ProcessName { get; set; } = string.Empty;
    public DateTime StartTimeUtc { get; set; }
    public TimeSpan Uptime { get; set; }
    public double WorkingSetMB { get; set; }
    public double PrivateMemoryMB { get; set; }
    public double VirtualMemoryMB { get; set; }
    public TimeSpan TotalProcessorTime { get; set; }
    public int ThreadCount { get; set; }
    public int HandleCount { get; set; }
    public double GCHeapSizeMB { get; set; }
    public int GCGen0Collections { get; set; }
    public int GCGen1Collections { get; set; }
    public int GCGen2Collections { get; set; }
}

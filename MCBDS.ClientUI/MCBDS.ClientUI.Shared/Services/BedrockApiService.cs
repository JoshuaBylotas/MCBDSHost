using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace MCBDS.ClientUI.Shared.Services;

public class BedrockApiService
{
    private readonly HttpClient _httpClient;

    public BedrockApiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string?> GetLogAsync()
    {
        return await _httpClient.GetStringAsync("/api/runner/log");
    }

    public async Task<string?> SendLineAsync(string line)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/runner/send", new { line });
        return response.IsSuccessStatusCode ? await response.Content.ReadAsStringAsync() : null;
    }

    public async Task<string?> RestartAsync()
    {
        var response = await _httpClient.PostAsync("/api/runner/restart", null);
        return response.IsSuccessStatusCode ? await response.Content.ReadAsStringAsync() : null;
    }

    // Backup API methods
    public async Task<BackupConfigResponse?> GetBackupConfigAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<BackupConfigResponse>("/api/backup/config");
        }
        catch
        {
            return null;
        }
    }

    public async Task<(bool success, string? message, BackupConfigResponse? savedConfig)> UpdateBackupConfigAsync(int frequencyMinutes, string backupDirectory, int maxBackupsToKeep)
    {
        try
        {
            var response = await _httpClient.PutAsJsonAsync("/api/backup/config", new
            {
                FrequencyMinutes = frequencyMinutes,
                BackupDirectory = backupDirectory,
                MaxBackupsToKeep = maxBackupsToKeep
            });

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<UpdateConfigResponse>();
                
                // Return the saved config values
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
            return (false, ex.Message, null);
        }
    }

    public async Task<(bool success, string? message)> TriggerManualBackupAsync()
    {
        try
        {
            var response = await _httpClient.PostAsync("/api/backup/trigger", null);
            
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
            return (false, ex.Message);
        }
    }

    public async Task<BackupListResponse?> GetBackupListAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<BackupListResponse>("/api/backup/list");
        }
        catch
        {
            return null;
        }
    }

    public async Task<(bool success, string? message)> DeleteBackupAsync(string backupName)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"/api/backup/{backupName}");
            
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
            return (false, ex.Message);
        }
    }

    // Server Properties API methods
    public async Task<ServerPropertiesResponse?> GetServerPropertiesAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<ServerPropertiesResponse>("/api/serverproperties");
        }
        catch
        {
            return null;
        }
    }
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

// Server Properties response classes
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

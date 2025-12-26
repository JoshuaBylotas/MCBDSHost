using System.Text.Json;
using MCBDS.ClientUI.Shared.Models;

namespace MCBDS.ClientUI.Shared.Services;

public class BackupSettingsService
{
    private readonly string _settingsFilePath;
    private BackupSettings? _cachedSettings;

    public BackupSettingsService(string? settingsDirectory = null)
    {
        // Use provided directory or default to current directory for web apps
        var directory = settingsDirectory ?? Directory.GetCurrentDirectory();
        _settingsFilePath = Path.Combine(directory, "backup-settings.json");
    }

    public async Task<BackupSettings> LoadSettingsAsync()
    {
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                var json = await File.ReadAllTextAsync(_settingsFilePath);
                _cachedSettings = JsonSerializer.Deserialize<BackupSettings>(json);
                return _cachedSettings ?? new BackupSettings();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading backup settings: {ex.Message}");
        }

        _cachedSettings = new BackupSettings();
        return _cachedSettings;
    }

    public async Task<bool> SaveSettingsAsync(BackupSettings settings)
    {
        try
        {
            var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions
            {
                WriteIndented = true
            });

            await File.WriteAllTextAsync(_settingsFilePath, json);
            _cachedSettings = settings;
            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving backup settings: {ex.Message}");
            return false;
        }
    }

    public BackupSettings? GetCachedSettings()
    {
        return _cachedSettings;
    }

    public string GetSettingsFilePath()
    {
        return _settingsFilePath;
    }
}

using System.Text.Json;
using MCBDS.ClientUI.Shared.Models;

namespace MCBDS.ClientUI.Shared.Services;

public class CommandHistoryService
{
    private readonly string _historyFilePath;
    private CommandHistory _history;
    private readonly SemaphoreSlim _fileLock = new(1, 1);
    private readonly JsonSerializerOptions _jsonOptions;

    public CommandHistoryService(string dataDirectory)
    {
        _historyFilePath = Path.Combine(dataDirectory, "command-history.json");
        _jsonOptions = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNameCaseInsensitive = true
        };
        
        // Ensure directory exists
        Directory.CreateDirectory(dataDirectory);
        
        // Load existing history
        _history = LoadHistory();
    }

    public List<CommandHistoryEntry> GetHistory(int count = 50)
    {
        return _history.Entries
            .OrderByDescending(e => e.Timestamp)
            .Take(count)
            .ToList();
    }

    public List<CommandHistoryEntry> SearchHistory(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return GetHistory();

        var lowerQuery = query.ToLower();
        return _history.Entries
            .Where(e => e.Command.ToLower().Contains(lowerQuery))
            .OrderByDescending(e => e.Timestamp)
            .Take(50)
            .ToList();
    }

    public async Task AddCommandAsync(string command, bool success, string? errorMessage = null)
    {
        await _fileLock.WaitAsync();
        try
        {
            var entry = new CommandHistoryEntry
            {
                Command = command,
                Timestamp = DateTime.UtcNow,
                Success = success,
                ErrorMessage = errorMessage
            };

            _history.Entries.Add(entry);

            // Trim to max entries (keep most recent)
            if (_history.Entries.Count > _history.MaxEntries)
            {
                _history.Entries = _history.Entries
                    .OrderByDescending(e => e.Timestamp)
                    .Take(_history.MaxEntries)
                    .ToList();
            }

            await SaveHistoryAsync();
        }
        finally
        {
            _fileLock.Release();
        }
    }

    public async Task ClearHistoryAsync()
    {
        await _fileLock.WaitAsync();
        try
        {
            _history.Entries.Clear();
            await SaveHistoryAsync();
        }
        finally
        {
            _fileLock.Release();
        }
    }

    public Dictionary<string, int> GetCommandStats()
    {
        return _history.Entries
            .GroupBy(e => e.Command.Split(' ')[0]) // Group by command name only
            .OrderByDescending(g => g.Count())
            .Take(10)
            .ToDictionary(g => g.Key, g => g.Count());
    }

    public int GetSuccessRate()
    {
        if (_history.Entries.Count == 0)
            return 100;

        var successCount = _history.Entries.Count(e => e.Success);
        return (int)((double)successCount / _history.Entries.Count * 100);
    }

    private CommandHistory LoadHistory()
    {
        try
        {
            if (File.Exists(_historyFilePath))
            {
                var json = File.ReadAllText(_historyFilePath);
                var history = JsonSerializer.Deserialize<CommandHistory>(json, _jsonOptions);
                return history ?? new CommandHistory();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to load command history: {ex.Message}");
        }

        return new CommandHistory();
    }

    private async Task SaveHistoryAsync()
    {
        try
        {
            var json = JsonSerializer.Serialize(_history, _jsonOptions);
            await File.WriteAllTextAsync(_historyFilePath, json);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to save command history: {ex.Message}");
        }
    }
}

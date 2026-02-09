using System.Text.Json;

namespace MCBDS.ClientUI.Shared.Models;

public class CommandHistoryEntry
{
    public string Command { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}

public class CommandHistory
{
    public List<CommandHistoryEntry> Entries { get; set; } = new();
    public int MaxEntries { get; set; } = 100; // Keep last 100 commands
}

using System.Text.RegularExpressions;

namespace MCBDS.PublicUI.Android.Components;

/// <summary>
/// Tracks online players by parsing server log output
/// </summary>
public class PlayerTracker
{
    private readonly HashSet<string> _onlinePlayers = new();
    private readonly object _lock = new();
    
    // Regex patterns for detecting player join/leave events
    private static readonly Regex PlayerJoinedPattern = new(@"Player connected: (.+?),", RegexOptions.Compiled);
    private static readonly Regex PlayerDisconnectedPattern = new(@"Player disconnected: (.+?),", RegexOptions.Compiled);
    private static readonly Regex PlayerListPattern = new(@"There (?:are|is) \d+ out of maximum \d+ players online:(.*)", RegexOptions.Compiled);
    
    public IReadOnlyCollection<string> OnlinePlayers
    {
        get
        {
            lock (_lock)
            {
                return _onlinePlayers.ToList();
            }
        }
    }

    public int PlayerCount
    {
        get
        {
            lock (_lock)
            {
                return _onlinePlayers.Count;
            }
        }
    }

    /// <summary>
    /// Parses server log to update player list
    /// </summary>
    public void ParseLog(string logContent)
    {
        if (string.IsNullOrWhiteSpace(logContent))
            return;

        var lines = logContent.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        
        foreach (var line in lines)
        {
            ParseLogLine(line);
        }
    }

    /// <summary>
    /// Parses a single log line for player events
    /// </summary>
    public void ParseLogLine(string line)
    {
        if (string.IsNullOrWhiteSpace(line))
            return;

        lock (_lock)
        {
            // Check for player joined
            var joinMatch = PlayerJoinedPattern.Match(line);
            if (joinMatch.Success)
            {
                var playerName = joinMatch.Groups[1].Value.Trim();
                _onlinePlayers.Add(playerName);
                return;
            }

            // Check for player disconnected
            var leaveMatch = PlayerDisconnectedPattern.Match(line);
            if (leaveMatch.Success)
            {
                var playerName = leaveMatch.Groups[1].Value.Trim();
                _onlinePlayers.Remove(playerName);
                return;
            }

            // Check for player list command output
            var listMatch = PlayerListPattern.Match(line);
            if (listMatch.Success)
            {
                var playerList = listMatch.Groups[1].Value;
                if (!string.IsNullOrWhiteSpace(playerList))
                {
                    // Clear and rebuild list
                    _onlinePlayers.Clear();
                    
                    // Split by comma and clean up names
                    var players = playerList.Split(',')
                        .Select(p => p.Trim())
                        .Where(p => !string.IsNullOrWhiteSpace(p));
                    
                    foreach (var player in players)
                    {
                        _onlinePlayers.Add(player);
                    }
                }
                else
                {
                    // "No players online" case
                    _onlinePlayers.Clear();
                }
            }
        }
    }

    /// <summary>
    /// Manually adds a player to the online list
    /// </summary>
    public void AddPlayer(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return;

        lock (_lock)
        {
            _onlinePlayers.Add(playerName.Trim());
        }
    }

    /// <summary>
    /// Manually removes a player from the online list
    /// </summary>
    public void RemovePlayer(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return;

        lock (_lock)
        {
            _onlinePlayers.Remove(playerName.Trim());
        }
    }

    /// <summary>
    /// Clears all players (e.g., server restart)
    /// </summary>
    public void Clear()
    {
        lock (_lock)
        {
            _onlinePlayers.Clear();
        }
    }

    /// <summary>
    /// Checks if a player is online
    /// </summary>
    public bool IsPlayerOnline(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return false;

        lock (_lock)
        {
            return _onlinePlayers.Contains(playerName.Trim());
        }
    }

    /// <summary>
    /// Gets player name suggestions for autocomplete
    /// </summary>
    public List<string> GetPlayerSuggestions(string partialName = "")
    {
        lock (_lock)
        {
            if (string.IsNullOrWhiteSpace(partialName))
                return _onlinePlayers.OrderBy(p => p).ToList();

            var query = partialName.ToLower();
            return _onlinePlayers
                .Where(p => p.ToLower().StartsWith(query))
                .OrderBy(p => p)
                .ToList();
        }
    }
}

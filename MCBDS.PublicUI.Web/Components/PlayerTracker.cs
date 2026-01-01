using System.Text.RegularExpressions;

namespace MCBDS.PublicUI.Web.Components;

/// <summary>
/// Tracks online players by parsing server log output
/// </summary>
public class PlayerTracker
{
    private readonly HashSet<string> _onlinePlayers = new();
    private readonly object _lock = new();
    
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

    public void ParseLogLine(string line)
    {
        if (string.IsNullOrWhiteSpace(line))
            return;

        lock (_lock)
        {
            var joinMatch = PlayerJoinedPattern.Match(line);
            if (joinMatch.Success)
            {
                var playerName = joinMatch.Groups[1].Value.Trim();
                _onlinePlayers.Add(playerName);
                return;
            }

            var leaveMatch = PlayerDisconnectedPattern.Match(line);
            if (leaveMatch.Success)
            {
                var playerName = leaveMatch.Groups[1].Value.Trim();
                _onlinePlayers.Remove(playerName);
                return;
            }

            var listMatch = PlayerListPattern.Match(line);
            if (listMatch.Success)
            {
                var playerList = listMatch.Groups[1].Value;
                if (!string.IsNullOrWhiteSpace(playerList))
                {
                    _onlinePlayers.Clear();
                    
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
                    _onlinePlayers.Clear();
                }
            }
        }
    }

    public void AddPlayer(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return;

        lock (_lock)
        {
            _onlinePlayers.Add(playerName.Trim());
        }
    }

    public void RemovePlayer(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return;

        lock (_lock)
        {
            _onlinePlayers.Remove(playerName.Trim());
        }
    }

    public void Clear()
    {
        lock (_lock)
        {
            _onlinePlayers.Clear();
        }
    }

    public bool IsPlayerOnline(string playerName)
    {
        if (string.IsNullOrWhiteSpace(playerName))
            return false;

        lock (_lock)
        {
            return _onlinePlayers.Contains(playerName.Trim());
        }
    }

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

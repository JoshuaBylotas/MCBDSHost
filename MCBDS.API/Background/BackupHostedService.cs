using System.Text.RegularExpressions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MCBDS.API.Models;

namespace MCBDS.API.Background;

public class BackupHostedService : BackgroundService
{
    private readonly RunnerHostedService _runnerService;
    private readonly ILogger<BackupHostedService> _logger;
    private readonly IOptionsMonitor<BackupConfiguration> _configMonitor;
    private readonly IConfiguration _configuration;
    private readonly SemaphoreSlim _backupSemaphore = new(1, 1);
    private CancellationTokenSource? _loopCts;
    private string? _cachedLevelName;

    public BackupHostedService(
        RunnerHostedService runnerService,
        IOptionsMonitor<BackupConfiguration> configMonitor,
        IConfiguration configuration,
        ILogger<BackupHostedService> logger)
    {
        _runnerService = runnerService;
        _logger = logger;
        _configMonitor = configMonitor;
        _configuration = configuration;
        
        // Subscribe to configuration changes
        _configMonitor.OnChange(config =>
        {
            _logger.LogInformation("Backup configuration changed. New frequency: {Frequency} minutes", config.FrequencyMinutes);
            RestartBackupLoop();
        });
    }

    private BackupConfiguration CurrentConfig => _configMonitor.CurrentValue;

    private void RestartBackupLoop()
    {
        // Cancel the current loop and let ExecuteAsync restart with new settings
        _loopCts?.Cancel();
    }

    /// <summary>
    /// Reads the level-name from server.properties file
    /// </summary>
    private string GetLevelName()
    {
        // Return cached value if available
        if (!string.IsNullOrEmpty(_cachedLevelName))
        {
            return _cachedLevelName;
        }

        var exePath = _configuration["Runner:ExePath"];
        if (string.IsNullOrWhiteSpace(exePath))
        {
            _logger.LogWarning("Runner:ExePath not configured, using default level name");
            return "Bedrock level";
        }

        var bedrockServerDir = Path.GetDirectoryName(exePath);
        if (string.IsNullOrEmpty(bedrockServerDir))
        {
            _logger.LogWarning("Could not determine bedrock server directory, using default level name");
            return "Bedrock level";
        }

        var serverPropertiesPath = Path.Combine(bedrockServerDir, "server.properties");
        
        if (!File.Exists(serverPropertiesPath))
        {
            _logger.LogWarning("server.properties not found at {Path}, using default level name", serverPropertiesPath);
            return "Bedrock level";
        }

        try
        {
            var lines = File.ReadAllLines(serverPropertiesPath);
            foreach (var line in lines)
            {
                var trimmedLine = line.Trim();
                if (trimmedLine.StartsWith("level-name=", StringComparison.OrdinalIgnoreCase))
                {
                    var levelName = trimmedLine.Substring("level-name=".Length).Trim();
                    if (!string.IsNullOrEmpty(levelName))
                    {
                        _cachedLevelName = levelName;
                        _logger.LogInformation("Level name from server.properties: {LevelName}", levelName);
                        return levelName;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading server.properties at {Path}", serverPropertiesPath);
        }

        _logger.LogWarning("level-name not found in server.properties, using default");
        return "Bedrock level";
    }

    /// <summary>
    /// Clears the cached level name, forcing a re-read from server.properties
    /// </summary>
    public void ClearLevelNameCache()
    {
        _cachedLevelName = null;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("BackupHostedService started");

        while (!stoppingToken.IsCancellationRequested)
        {
            _loopCts = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);
            
            try
            {
                await RunBackupLoopAsync(_loopCts.Token);
            }
            catch (OperationCanceledException) when (_loopCts.IsCancellationRequested && !stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Backup loop restarting due to configuration change...");
                await Task.Delay(1000, stoppingToken); // Small delay before restarting
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in backup loop");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }

    private async Task RunBackupLoopAsync(CancellationToken cancellationToken)
    {
        var config = CurrentConfig;
        
        if (string.IsNullOrWhiteSpace(config.BackupDirectory))
        {
            _logger.LogWarning("Backup directory not configured. Backup service will not run.");
            await Task.Delay(Timeout.Infinite, cancellationToken);
            return;
        }

        if (config.FrequencyMinutes < 1)
        {
            _logger.LogWarning("Invalid backup frequency: {Frequency} minutes. Must be at least 1 minute.", config.FrequencyMinutes);
            await Task.Delay(Timeout.Infinite, cancellationToken);
            return;
        }

        try
        {
            Directory.CreateDirectory(config.BackupDirectory);
            _logger.LogInformation("Backup directory: {Directory}", config.BackupDirectory);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create backup directory: {Directory}", config.BackupDirectory);
            await Task.Delay(Timeout.Infinite, cancellationToken);
            return;
        }

        var worldPath = GetBedrockWorldPath();
        if (!Directory.Exists(worldPath))
        {
            _logger.LogWarning("World directory does not exist: {WorldPath}. Waiting for it to be created...", worldPath);
        }
        else
        {
            _logger.LogInformation("World directory: {WorldPath}", worldPath);
        }

        await Task.Delay(TimeSpan.FromSeconds(30), cancellationToken);

        var interval = TimeSpan.FromMinutes(config.FrequencyMinutes);
        _logger.LogInformation("Backup frequency set to {Frequency} minutes", config.FrequencyMinutes);

        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                await PerformBackupWithSemaphoreAsync(cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Error during backup operation");
            }

            // Re-read interval in case it changed
            interval = TimeSpan.FromMinutes(CurrentConfig.FrequencyMinutes);
            await Task.Delay(interval, cancellationToken);
        }
    }

    public async Task<bool> TriggerManualBackupAsync()
    {
        try
        {
            _logger.LogInformation("Manual backup triggered");
            
            if (!await _backupSemaphore.WaitAsync(0))
            {
                _logger.LogWarning("A backup is already in progress");
                return false;
            }

            try
            {
                await PerformBackupCoreAsync(CancellationToken.None);
                return true;
            }
            finally
            {
                _backupSemaphore.Release();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during manual backup");
            return false;
        }
    }

    /// <summary>
    /// Wrapper that acquires the semaphore before performing backup
    /// </summary>
    private async Task PerformBackupWithSemaphoreAsync(CancellationToken cancellationToken)
    {
        await _backupSemaphore.WaitAsync(cancellationToken);
        
        try
        {
            await PerformBackupCoreAsync(cancellationToken);
        }
        finally
        {
            _backupSemaphore.Release();
        }
    }

    /// <summary>
    /// Core backup logic - assumes semaphore is already held by caller
    /// </summary>
    private async Task PerformBackupCoreAsync(CancellationToken cancellationToken)
    {
        var config = CurrentConfig;
        var levelName = GetLevelName();
        
        try
        {
            _logger.LogInformation("Starting backup process for world: {LevelName}", levelName);

            _logger.LogInformation("Sending 'save hold' command...");
            if (!_runnerService.SendLineToProcess("save hold"))
            {
                _logger.LogError("Failed to send 'save hold' command. Server may not be running.");
                return;
            }

            _logger.LogInformation("Waiting for save hold to complete...");
            await Task.Delay(3000, cancellationToken);

            _logger.LogInformation("Sending 'save query' command and waiting for response...");
            
            if (!_runnerService.SendLineToProcess("save query"))
            {
                _logger.LogError("Failed to send 'save query' command");
                await ResumeWorldSaving();
                return;
            }

            var maxWaitTime = TimeSpan.FromSeconds(10);
            var waitInterval = TimeSpan.FromMilliseconds(500);
            var elapsedTime = TimeSpan.Zero;
            bool filesReady = false;

            while (elapsedTime < maxWaitTime && !cancellationToken.IsCancellationRequested)
            {
                await Task.Delay(waitInterval, cancellationToken);
                elapsedTime += waitInterval;

                var currentLog = _runnerService.GetLog();
                
                if (currentLog.Contains("Files are now ready to be copied", StringComparison.OrdinalIgnoreCase) ||
                    currentLog.Contains("Data saved", StringComparison.OrdinalIgnoreCase))
                {
                    filesReady = true;
                    _logger.LogInformation("Received confirmation that files are ready to be copied");
                    break;
                }
            }

            if (!filesReady)
            {
                _logger.LogError("Timeout waiting for 'save query' response. Files may not be ready.");
                await ResumeWorldSaving();
                return;
            }

            await Task.Delay(500, cancellationToken);

            var filesToBackup = ParseFileList(levelName);

            if (filesToBackup.Count == 0)
            {
                _logger.LogWarning("No files identified for backup from save query response");
                await ResumeWorldSaving();
                return;
            }

            _logger.LogInformation("Identified {Count} files to backup", filesToBackup.Count);

            var timestamp = DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
            var backupPath = Path.Combine(config.BackupDirectory, $"backup_{timestamp}");
            Directory.CreateDirectory(backupPath);

            _logger.LogInformation("Created backup directory: {BackupPath}", backupPath);

            var copiedCount = 0;
            var failedCount = 0;
            var bedrockWorldPath = GetBedrockWorldPath();

            _logger.LogInformation("Starting file copy from: {SourcePath}", bedrockWorldPath);

            foreach (var file in filesToBackup)
            {
                try
                {
                    var sourcePath = Path.Combine(bedrockWorldPath, file);
                    var destPath = Path.Combine(backupPath, file);

                    var destDir = Path.GetDirectoryName(destPath);
                    if (!string.IsNullOrEmpty(destDir))
                    {
                        Directory.CreateDirectory(destDir);
                    }

                    if (File.Exists(sourcePath))
                    {
                        File.Copy(sourcePath, destPath, overwrite: true);
                        copiedCount++;
                        _logger.LogDebug("Copied: {File}", file);
                    }
                    else
                    {
                        _logger.LogWarning("Source file not found: {File}", sourcePath);
                        failedCount++;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to copy file: {File}", file);
                    failedCount++;
                }
            }

            if (copiedCount > 0)
            {
                _logger.LogInformation("Backup completed. Copied {Copied} files, {Failed} failed to {BackupPath}", 
                    copiedCount, failedCount, backupPath);
            }
            else
            {
                _logger.LogError("Backup failed. No files were copied.");
            }

            await ResumeWorldSaving();

            if (copiedCount > 0)
            {
                await CleanupOldBackupsAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Backup process failed");
            await ResumeWorldSaving();
        }
    }

    private async Task ResumeWorldSaving()
    {
        _logger.LogInformation("Sending 'save resume' command...");
        if (_runnerService.SendLineToProcess("save resume"))
        {
            await Task.Delay(1000);
            _logger.LogInformation("World saving resumed");
        }
        else
        {
            _logger.LogError("Failed to send 'save resume' command");
        }
    }

    private List<string> ParseFileList(string levelName)
    {
        var files = new List<string>();
        var log = _runnerService.GetLog();
        var worldPrefix = $"{levelName}/";

        _logger.LogInformation("Parsing file list for level: {LevelName}", levelName);

        var lines = log.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        
        // Search from the end of the log backwards to find the most recent file list
        for (int i = lines.Length - 1; i >= 0; i--)
        {
            var line = lines[i].Trim();
            
            // Skip empty lines and log metadata lines (those with timestamps like [2025-12-27...])
            if (string.IsNullOrWhiteSpace(line))
                continue;
            
            // Look for a line that starts with the level name (the file list line)
            // The file list line looks like: "POPP-BYLOTAS/db/007758.ldb:121346, POPP-BYLOTAS/db/..."
            if (line.StartsWith(levelName, StringComparison.OrdinalIgnoreCase) && line.Contains(':'))
            {
                _logger.LogInformation("Found file list line starting with level name");
                
                // This is the file list line - parse all entries
                var entries = line.Split(',', StringSplitOptions.TrimEntries);

                foreach (var entry in entries)
                {
                    // Each entry is like "POPP-BYLOTAS/db/007758.ldb:121346"
                    var colonIndex = entry.IndexOf(':');
                    string fullPath = colonIndex > 0 ? entry.Substring(0, colonIndex).Trim() : entry.Trim();
                    
                    if (fullPath.StartsWith(worldPrefix, StringComparison.OrdinalIgnoreCase))
                    {
                        var relativePath = fullPath.Substring(worldPrefix.Length);
                        if (!string.IsNullOrWhiteSpace(relativePath))
                        {
                            files.Add(relativePath);
                        }
                    }
                }
                
                _logger.LogInformation("Parsed {Count} files from file list", files.Count);
                break;
            }
            
            // Also check if the level name appears mid-line (in case of log prefix)
            // This handles lines like: "[INFO] POPP-BYLOTAS/db/..."
            if (line.Contains($"{levelName}/", StringComparison.OrdinalIgnoreCase) && line.Contains(':'))
            {
                var firstLevelIndex = line.IndexOf($"{levelName}/", StringComparison.OrdinalIgnoreCase);
                if (firstLevelIndex >= 0)
                {
                    _logger.LogInformation("Found file list with level name at position {Position}", firstLevelIndex);
                    
                    var fileListPortion = line.Substring(firstLevelIndex);
                    var entries = fileListPortion.Split(',', StringSplitOptions.TrimEntries);

                    foreach (var entry in entries)
                    {
                        var colonIndex = entry.IndexOf(':');
                        string fullPath = colonIndex > 0 ? entry.Substring(0, colonIndex).Trim() : entry.Trim();
                        
                        if (fullPath.StartsWith(worldPrefix, StringComparison.OrdinalIgnoreCase))
                        {
                            var relativePath = fullPath.Substring(worldPrefix.Length);
                            if (!string.IsNullOrWhiteSpace(relativePath))
                            {
                                files.Add(relativePath);
                            }
                        }
                    }
                    
                    if (files.Count > 0)
                    {
                        _logger.LogInformation("Parsed {Count} files from file list", files.Count);
                        break;
                    }
                }
            }
        }

        if (files.Count > 0)
        {
            _logger.LogInformation("Total files to backup: {Count}", files.Count);
        }
        else
        {
            // Log the last few lines to help debug
            var lastLines = lines.Length > 10 ? string.Join("\n", lines.Skip(lines.Length - 10)) : string.Join("\n", lines);
            _logger.LogWarning("No files parsed from save query response. Last 10 lines of log:\n{Log}", lastLines);
        }

        return files;
    }

    private string GetBedrockWorldPath()
    {
        var config = CurrentConfig;
        
        // If explicit world path is configured, use it
        if (!string.IsNullOrWhiteSpace(config.WorldPath))
        {
            return config.WorldPath;
        }

        // Get level name from server.properties
        var levelName = GetLevelName();

        var exePath = _configuration["Runner:ExePath"];
        if (!string.IsNullOrWhiteSpace(exePath))
        {
            var bedrockServerDir = Path.GetDirectoryName(exePath);
            if (!string.IsNullOrEmpty(bedrockServerDir))
            {
                return Path.Combine(bedrockServerDir, "worlds", levelName);
            }
        }

        var assemblyLocation = Path.GetDirectoryName(typeof(BackupHostedService).Assembly.Location) ?? string.Empty;
        return Path.Combine(assemblyLocation, "worlds", levelName);
    }

    private async Task CleanupOldBackupsAsync()
    {
        var config = CurrentConfig;
        
        try
        {
            if (config.MaxBackupsToKeep <= 0)
            {
                return;
            }

            var backupDirs = Directory.GetDirectories(config.BackupDirectory, "backup_*")
                .Select(d => new DirectoryInfo(d))
                .OrderByDescending(d => d.CreationTime)
                .ToList();

            if (backupDirs.Count > config.MaxBackupsToKeep)
            {
                var toDelete = backupDirs.Skip(config.MaxBackupsToKeep).ToList();
                
                foreach (var dir in toDelete)
                {
                    try
                    {
                        _logger.LogInformation("Deleting old backup: {Directory}", dir.Name);
                        dir.Delete(recursive: true);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to delete old backup: {Directory}", dir.Name);
                    }
                }

                _logger.LogInformation("Cleaned up {Count} old backup(s)", toDelete.Count);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during backup cleanup");
        }

        await Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("BackupHostedService stopping...");
        _loopCts?.Cancel();
        await base.StopAsync(cancellationToken);
    }
}

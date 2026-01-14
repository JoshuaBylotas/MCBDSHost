using System.Diagnostics;

namespace MCBDS.PublicUI.Services;

/// <summary>
/// Lightweight crash and diagnostic logging service for Store apps
/// Logs to file and Debug output without throwing exceptions
/// </summary>
public static class CrashLogger
{
    private static string? _logFilePath;
    private static bool _isInitialized = false;
    private static readonly object _lock = new();

    /// <summary>
    /// Initialize the logger with the app data directory
    /// Safe to call multiple times
    /// </summary>
    public static void Initialize(string appDataDirectory)
    {
        lock (_lock)
        {
            if (_isInitialized)
                return;

            try
            {
                // Ensure directory exists
                if (!Directory.Exists(appDataDirectory))
                {
                    Directory.CreateDirectory(appDataDirectory);
                }

                _logFilePath = Path.Combine(appDataDirectory, "crash-log.txt");
                
                // Write initialization entry
                var initMessage = $"=== CrashLogger Initialized ==={Environment.NewLine}App Data: {appDataDirectory}{Environment.NewLine}Log File: {_logFilePath}{Environment.NewLine}";
                File.AppendAllText(_logFilePath, initMessage);
                
                _isInitialized = true;
                Debug.WriteLine($"CrashLogger initialized: {_logFilePath}");
            }
            catch (Exception ex)
            {
                // Fallback to temp directory
                try
                {
                    var tempPath = Path.GetTempPath();
                    _logFilePath = Path.Combine(tempPath, "mcbds-crash-log.txt");
                    File.AppendAllText(_logFilePath, $"Fallback to temp: {ex.Message}{Environment.NewLine}");
                    _isInitialized = true;
                    Debug.WriteLine($"CrashLogger fallback to temp: {_logFilePath}");
                }
                catch
                {
                    // Last resort - just use Debug output
                    Debug.WriteLine($"CrashLogger initialization failed: {ex.Message}");
                    _isInitialized = true; // Prevent repeated attempts
                }
            }
        }
    }

    /// <summary>
    /// Log a message with optional exception details
    /// Never throws exceptions
    /// </summary>
    public static void Log(string message, Exception? ex = null)
    {
        try
        {
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            var logEntry = $"[{timestamp}] {message}";
            
            if (ex != null)
            {
                logEntry += $"{Environment.NewLine}  Exception: {ex.GetType().Name}";
                logEntry += $"{Environment.NewLine}  Message: {ex.Message}";
                logEntry += $"{Environment.NewLine}  StackTrace: {ex.StackTrace}";
                
                if (ex.InnerException != null)
                {
                    logEntry += $"{Environment.NewLine}  Inner Exception: {ex.InnerException.GetType().Name}";
                    logEntry += $"{Environment.NewLine}  Inner Message: {ex.InnerException.Message}";
                }
            }

            // Always write to Debug output
            Debug.WriteLine(logEntry);

            // Try to write to file if initialized
            if (_isInitialized && _logFilePath != null)
            {
                lock (_lock)
                {
                    File.AppendAllText(_logFilePath, logEntry + Environment.NewLine);
                }
            }
        }
        catch
        {
            // Swallow all errors - logging failure should never crash the app
            Debug.WriteLine($"CrashLogger failed to log: {message}");
        }
    }

    /// <summary>
    /// Log a fatal error (app-crashing severity)
    /// </summary>
    public static void LogFatal(string message, Exception? ex = null)
    {
        Log($"FATAL: {message}", ex);
    }

    /// <summary>
    /// Log an error (recoverable)
    /// </summary>
    public static void LogError(string message, Exception? ex = null)
    {
        Log($"ERROR: {message}", ex);
    }

    /// <summary>
    /// Log a warning
    /// </summary>
    public static void LogWarning(string message)
    {
        Log($"WARNING: {message}");
    }

    /// <summary>
    /// Log informational message
    /// </summary>
    public static void LogInfo(string message)
    {
        Log($"INFO: {message}");
    }

    /// <summary>
    /// Get the path to the log file (may be null if initialization failed)
    /// </summary>
    public static string? GetLogFilePath() => _logFilePath;

    /// <summary>
    /// Clear the log file
    /// </summary>
    public static void ClearLog()
    {
        try
        {
            if (_logFilePath != null && File.Exists(_logFilePath))
            {
                lock (_lock)
                {
                    File.WriteAllText(_logFilePath, $"=== Log Cleared at {DateTime.Now} ==={Environment.NewLine}");
                }
            }
        }
        catch
        {
            // Swallow errors
            Debug.WriteLine("CrashLogger: Failed to clear log");
        }
    }

    /// <summary>
    /// Get the current log content
    /// </summary>
    public static string? ReadLog()
    {
        try
        {
            if (_logFilePath != null && File.Exists(_logFilePath))
            {
                lock (_lock)
                {
                    return File.ReadAllText(_logFilePath);
                }
            }
        }
        catch
        {
            // Swallow errors
            Debug.WriteLine("CrashLogger: Failed to read log");
        }
        
        return null;
    }
}

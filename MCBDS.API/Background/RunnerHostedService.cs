using System.Diagnostics;
using System.Text;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MCBDS.API.Background
{
    public class RunnerHostedService : IHostedService
    {
        private Process? _bedrockProcess;
        private readonly StringBuilder _logBuilder = new();
        private readonly object _lock = new();
        private readonly IConfiguration _config;
        private readonly ILogger<RunnerHostedService> _logger;
        private string? _logFilePath;
        private JobObject? _jobObject;
        private DateTime _processStartTime;

        public RunnerHostedService(IConfiguration config, ILogger<RunnerHostedService> logger)
        {
            _config = config;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("RunnerHostedService.StartAsync called");
            string exePath = _config["Runner:ExePath"] ?? throw new Exception("Runner:ExePath not set");
            _logFilePath = _config["Runner:LogFilePath"] ?? "runner.log";

            _logger.LogInformation("Bedrock server executable path: {ExePath}", exePath);

            // Verify the executable exists
            if (!File.Exists(exePath))
            {
                _logger.LogError("Bedrock server executable not found at: {ExePath}", exePath);
                AppendLog($"ERROR: Bedrock server executable not found at: {exePath}");
                return Task.CompletedTask;
            }

            _logger.LogInformation("Bedrock server executable found at: {ExePath}", exePath);

            // Get the directory containing the executable - bedrock server must run from its directory
            string? workingDirectory = Path.GetDirectoryName(exePath);
            if (string.IsNullOrEmpty(workingDirectory))
            {
                workingDirectory = Environment.CurrentDirectory;
            }

            _logger.LogInformation("Working directory set to: {WorkingDirectory}", workingDirectory);

            // Clean up the log file before starting
            if (!string.IsNullOrEmpty(_logFilePath) && File.Exists(_logFilePath))
            {
                try { File.Delete(_logFilePath); } catch { /* ignore errors */ }
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = exePath,
                WorkingDirectory = workingDirectory,  // Critical: bedrock server needs to run from its own directory
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                RedirectStandardInput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            _bedrockProcess = new Process { StartInfo = startInfo };
            _bedrockProcess.EnableRaisingEvents = true;
            _bedrockProcess.OutputDataReceived += (s, e) => AppendLog(e.Data);
            _bedrockProcess.ErrorDataReceived += (s, e) => AppendLog(e.Data);
            _bedrockProcess.Exited += (s, e) =>
            {
                _logger.LogWarning("Bedrock server process exited with code: {ExitCode}", _bedrockProcess?.ExitCode);
                AppendLog($"Process exited with code: {_bedrockProcess?.ExitCode}");
            };

            try
            {
                _bedrockProcess.Start();
                _processStartTime = DateTime.UtcNow;
                _logger.LogInformation("Bedrock server process started with PID: {ProcessId}", _bedrockProcess.Id);
                AppendLog($"Bedrock server started with PID: {_bedrockProcess.Id}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start Bedrock server process");
                AppendLog($"ERROR: Failed to start Bedrock server: {ex.Message}");
                return Task.CompletedTask;
            }
            
            // Create job object to ensure child process terminates with parent
            if (OperatingSystem.IsWindows())
            {
                try
                {
                    _jobObject = new JobObject();
                    _jobObject.AddProcess(_bedrockProcess.Handle);
                    _logger.LogInformation("Bedrock process added to job object for automatic cleanup");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to add process to job object. Process may not terminate automatically.");
                }
            }
            
            _bedrockProcess.BeginOutputReadLine();
            _bedrockProcess.BeginErrorReadLine();
            return Task.CompletedTask;
        }

        public async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("RunnerHostedService.StopAsync called");
            if (_bedrockProcess != null && !_bedrockProcess.HasExited)
            {
                try
                {
                    _bedrockProcess.Kill(entireProcessTree: true);
                    await _bedrockProcess.WaitForExitAsync(cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to stop the process gracefully");
                }
                finally
                {
                    _bedrockProcess.Dispose();
                    _bedrockProcess = null;
                }
            }
            else
            {
                _logger.LogInformation("Process was already exited or not started");
            }
            
            _jobObject?.Dispose();
            _jobObject = null;
        }

        private void AppendLog(string? data)
        {
            if (string.IsNullOrEmpty(data)) return;
            lock (_lock)
            {
                _logBuilder.AppendLine(data);
                if (!string.IsNullOrEmpty(_logFilePath))
                    File.AppendAllText(_logFilePath, data + Environment.NewLine);
            }
        }

        public string GetLog()
        {
            lock (_lock)
            {
                return _logBuilder.ToString();
            }
        }

        public bool SendLineToProcess(string line)
        {
            if (_bedrockProcess != null && !_bedrockProcess.HasExited)
            {
                try
                {
                    _bedrockProcess.StandardInput.WriteLine(line);
                    _bedrockProcess.StandardInput.Flush();
                    return true;
                }
                catch
                {
                    // Could not write to process
                }
            }
            return false;
        }

        public async Task<string?> SendLineAndReadResponseAsync(string line, int timeoutMs = 5000)
        {
            if (_bedrockProcess == null || _bedrockProcess.HasExited)
                return null;

            // Store the current log length to capture only new output
            int initialLogLength;
            lock (_lock)
            {
                initialLogLength = _logBuilder.Length;
            }

            // Send the command
            try
            {
                _bedrockProcess.StandardInput.WriteLine(line);
                _bedrockProcess.StandardInput.Flush();
                _logger.LogInformation("Command sent: {Line}", line);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send command: {Line}", line);
                return null;
            }

            // Wait for new log output
            var startTime = DateTime.UtcNow;
            while ((DateTime.UtcNow - startTime).TotalMilliseconds < timeoutMs)
            {
                await Task.Delay(100);
                
                string newOutput;
                lock (_lock)
                {
                    if (_logBuilder.Length > initialLogLength)
                    {
                        // Get only the new output since the command was sent
                        newOutput = _logBuilder.ToString(initialLogLength, _logBuilder.Length - initialLogLength);
                        _logger.LogInformation("New output captured: {Output}", newOutput);
                        return newOutput.Trim();
                    }
                }
            }

            _logger.LogWarning("Command timed out after {TimeoutMs}ms: {Line}", timeoutMs, line);
            return "Command sent successfully (no immediate response)";
        }

        public async Task<bool> RestartProcessAsync()
        {
            await StopAsync(CancellationToken.None);
            try
            {
                await Task.Delay(1000); // Small delay to ensure process is released
                await StartAsync(CancellationToken.None);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Gets the current status of the Bedrock server process
        /// </summary>
        public ServerStatus GetServerStatus()
        {
            var status = new ServerStatus
            {
                IsRunning = _bedrockProcess != null && !_bedrockProcess.HasExited,
                StartTimeUtc = _processStartTime
            };

            if (status.IsRunning && _bedrockProcess != null)
            {
                try
                {
                    _bedrockProcess.Refresh();
                    status.Uptime = DateTime.UtcNow - _processStartTime;
                    status.ProcessId = _bedrockProcess.Id;
                    status.ProcessName = _bedrockProcess.ProcessName;
                    
                    // Memory stats
                    status.WorkingSetMB = _bedrockProcess.WorkingSet64 / (1024.0 * 1024.0);
                    status.PrivateMemoryMB = _bedrockProcess.PrivateMemorySize64 / (1024.0 * 1024.0);
                    status.VirtualMemoryMB = _bedrockProcess.VirtualMemorySize64 / (1024.0 * 1024.0);
                    status.PeakWorkingSetMB = _bedrockProcess.PeakWorkingSet64 / (1024.0 * 1024.0);
                    
                    // CPU time
                    status.TotalProcessorTime = _bedrockProcess.TotalProcessorTime;
                    status.UserProcessorTime = _bedrockProcess.UserProcessorTime;
                    
                    // Thread count
                    status.ThreadCount = _bedrockProcess.Threads.Count;
                    
                    // Handle count (Windows only)
                    if (OperatingSystem.IsWindows())
                    {
                        status.HandleCount = _bedrockProcess.HandleCount;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error getting process stats");
                }
            }

            return status;
        }

        /// <summary>
        /// Gets the API container/host process statistics
        /// </summary>
        public static ApiHostStatus GetApiHostStatus()
        {
            var currentProcess = Process.GetCurrentProcess();
            var status = new ApiHostStatus
            {
                ProcessId = currentProcess.Id,
                ProcessName = currentProcess.ProcessName,
                StartTimeUtc = currentProcess.StartTime.ToUniversalTime(),
                Uptime = DateTime.UtcNow - currentProcess.StartTime.ToUniversalTime(),
                WorkingSetMB = currentProcess.WorkingSet64 / (1024.0 * 1024.0),
                PrivateMemoryMB = currentProcess.PrivateMemorySize64 / (1024.0 * 1024.0),
                VirtualMemoryMB = currentProcess.VirtualMemorySize64 / (1024.0 * 1024.0),
                TotalProcessorTime = currentProcess.TotalProcessorTime,
                ThreadCount = currentProcess.Threads.Count
            };

            if (OperatingSystem.IsWindows())
            {
                status.HandleCount = currentProcess.HandleCount;
            }

            // Get GC memory info
            var gcInfo = GC.GetGCMemoryInfo();
            status.GCHeapSizeMB = GC.GetTotalMemory(false) / (1024.0 * 1024.0);
            status.GCGen0Collections = GC.CollectionCount(0);
            status.GCGen1Collections = GC.CollectionCount(1);
            status.GCGen2Collections = GC.CollectionCount(2);

            return status;
        }
    }

    public class ServerStatus
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

    public class ApiHostStatus
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

    [SupportedOSPlatform("windows")]
    internal sealed class JobObject : IDisposable
    {
        private IntPtr _handle;
        private bool _disposed;

        public JobObject()
        {
            _handle = CreateJobObject(IntPtr.Zero, null);
            
            var info = new JOBOBJECT_BASIC_LIMIT_INFORMATION
            {
                LimitFlags = 0x2000  // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
            };

            var extendedInfo = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION
            {
                BasicLimitInformation = info
            };

            int length = Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
            IntPtr extendedInfoPtr = Marshal.AllocHGlobal(length);
            try
            {
                Marshal.StructureToPtr(extendedInfo, extendedInfoPtr, false);
                if (!SetInformationJobObject(_handle, JobObjectInfoType.ExtendedLimitInformation, extendedInfoPtr, (uint)length))
                {
                    throw new InvalidOperationException("Unable to set job object information");
                }
            }
            finally
            {
                Marshal.FreeHGlobal(extendedInfoPtr);
            }
        }

        public void AddProcess(IntPtr processHandle)
        {
            if (!AssignProcessToJobObject(_handle, processHandle))
            {
                throw new InvalidOperationException("Unable to assign process to job object");
            }
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                if (_handle != IntPtr.Zero)
                {
                    CloseHandle(_handle);
                    _handle = IntPtr.Zero;
                }
                _disposed = true;
            }
            GC.SuppressFinalize(this);
        }

        ~JobObject()
        {
            Dispose();
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string? name);

        [DllImport("kernel32.dll")]
        private static extern bool SetInformationJobObject(IntPtr job, JobObjectInfoType infoType, IntPtr lpJobObjectInfo, uint cbJobObjectInfoLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CloseHandle(IntPtr hObject);

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            public long PerProcessUserTimeLimit;
            public long PerJobUserTimeLimit;
            public uint LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public uint ActiveProcessLimit;
            public UIntPtr Affinity;
            public uint PriorityClass;
            public uint SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IO_COUNTERS
        {
            public ulong ReadOperationCount;
            public ulong WriteOperationCount;
            public ulong OtherOperationCount;
            public ulong ReadTransferCount;
            public ulong WriteTransferCount;
            public ulong OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        private enum JobObjectInfoType
        {
            ExtendedLimitInformation = 9
        }
    }
}

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

            // Clean up the log file before starting
            if (!string.IsNullOrEmpty(_logFilePath) && File.Exists(_logFilePath))
            {
                try { File.Delete(_logFilePath); } catch { /* ignore errors */ }
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = exePath,
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
            _bedrockProcess.Start();
            
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

        public async Task<string?> SendLineAndReadResponseAsync(string line, int timeoutMs = 3000)
        {
            if (_bedrockProcess == null || _bedrockProcess.HasExited)
                return null;
            var tcs = new TaskCompletionSource<string?>();
            DataReceivedEventHandler? handler = null;
            handler = (s, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    _bedrockProcess!.OutputDataReceived -= handler;
                    tcs.TrySetResult(e.Data);
                }
            };
            _bedrockProcess.OutputDataReceived += handler;
            try
            {
                _bedrockProcess.StandardInput.WriteLine(line);
                _bedrockProcess.StandardInput.Flush();
            }
            catch
            {
                _bedrockProcess.OutputDataReceived -= handler;
                return null;
            }
            var completedTask = await Task.WhenAny(tcs.Task, Task.Delay(timeoutMs));
            if (completedTask == tcs.Task)
                return tcs.Task.Result;
            _bedrockProcess.OutputDataReceived -= handler;
            return null;
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

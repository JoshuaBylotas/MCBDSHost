using System.Diagnostics;
using System.Text;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MCBDS.API.Background
{
    public class RunnerHostedService : IHostedService, IDisposable
    {
        private Process? _process;
        private readonly StringBuilder _logBuilder = new();
        private readonly object _lock = new();
        private readonly IConfiguration _config;
        private readonly ILogger<RunnerHostedService> _logger;
        private readonly IHostApplicationLifetime _lifetime;
        private string? _logFilePath;
        private bool _isDisposed = false;

        public RunnerHostedService(IConfiguration config, ILogger<RunnerHostedService> logger, IHostApplicationLifetime lifetime)
        {
            _config = config;
            _logger = logger;
            _lifetime = lifetime;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("RunnerHostedService.StartAsync called");
            
            // Register shutdown handlers
            _lifetime.ApplicationStopping.Register(() =>
            {
                _logger.LogInformation("ApplicationStopping triggered, stopping process");
                StopProcess();
            });

            // Also hook into process exit to ensure cleanup
            AppDomain.CurrentDomain.ProcessExit += (s, e) =>
            {
                _logger.LogInformation("ProcessExit triggered, stopping process");
                StopProcess();
            };

            Console.CancelKeyPress += (s, e) =>
            {
                _logger.LogInformation("CancelKeyPress triggered, stopping process");
                StopProcess();
            };
            
            string exePath = _config["Runner:ExePath"] ?? throw new Exception("Runner:ExePath not set");
            _logFilePath = _config["Runner:LogFilePath"] ?? "runner.log";
            _process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = exePath,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                },
                EnableRaisingEvents = true
            };
            
            _process.Exited += (s, e) => _logger.LogInformation("Bedrock server process exited");
            _process.OutputDataReceived += (s, e) => AppendLog(e.Data);
            _process.ErrorDataReceived += (s, e) => AppendLog(e.Data);
            _process.Start();
            _process.BeginOutputReadLine();
            _process.BeginErrorReadLine();
            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("RunnerHostedService.StopAsync called");
            StopProcess();
            return Task.CompletedTask;
        }

        private void StopProcess()
        {
            if (_isDisposed) return;
            
            lock (_lock)
            {
                if (_isDisposed) return;
                _isDisposed = true;
            }

            if (_process != null && !_process.HasExited)
            {
                try
                {
                    _logger.LogInformation("Attempting to stop process gracefully...");
                    _process.StandardInput.WriteLine("stop");
                    _process.StandardInput.Flush();
                    _logger.LogInformation("Sent 'stop' command to process");
                    
                    bool exited = _process.WaitForExit(5000);
                    if (!exited)
                    {
                        _logger.LogWarning("Process did not exit gracefully within 5 seconds, killing process");
                        _process.Kill();
                        _process.WaitForExit(2000);
                    }
                    else
                    {
                        _logger.LogInformation("Process exited gracefully");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error while stopping process");
                    try
                    {
                        if (_process != null && !_process.HasExited)
                        {
                            _process.Kill();
                        }
                    }
                    catch { }
                }
            }
            else
            {
                _logger.LogInformation("Process was already exited or not started");
            }
        }

        private void AppendLog(string? data)
        {
            if (string.IsNullOrEmpty(data)) return;
            lock (_lock)
            {
                _logBuilder.AppendLine(data);
                if (!string.IsNullOrEmpty(_logFilePath))
                {
                    try
                    {
                        File.AppendAllText(_logFilePath, data + Environment.NewLine);
                    }
                    catch { }
                }
            }
        }

        public string GetLog()
        {
            lock (_lock)
            {
                return _logBuilder.ToString();
            }
        }

        public void Dispose()
        {
            StopProcess();
            _process?.Dispose();
        }
    }
}

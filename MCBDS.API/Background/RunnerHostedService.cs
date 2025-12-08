using System.Diagnostics;
using System.Text;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;

namespace MCBDS.API.Background
{
    public class RunnerHostedService : IHostedService
    {
        private Process? _process;
        private readonly StringBuilder _logBuilder = new();
        private readonly object _lock = new();
        private readonly IConfiguration _config;
        private string? _logFilePath;

        public RunnerHostedService(IConfiguration config)
        {
            _config = config;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            string exePath = _config["Runner:ExePath"] ?? throw new Exception("Runner:ExePath not set");
            _logFilePath = _config["Runner:LogFilePath"] ?? "runner.log";
            exePath = System.IO.Path.Combine(AppContext.BaseDirectory, exePath);
            _process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = exePath,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            _process.OutputDataReceived += (s, e) => AppendLog(e.Data);
            _process.ErrorDataReceived += (s, e) => AppendLog(e.Data);
            _process.Start();
            _process.BeginOutputReadLine();
            _process.BeginErrorReadLine();
            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            if (_process != null && !_process.HasExited)
            {
                _process.Kill();
            }
            return Task.CompletedTask;
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
    }
}

using System.Diagnostics;
using System.Text;

namespace MCBDSHost.Runner
{
    public class ExeRunner
    {
        private readonly string _exePath;
        private readonly string _logFilePath;
        private readonly StringBuilder _logBuilder = new();
        private readonly object _lock = new();

        public ExeRunner(string exePath, string logFilePath)
        {
            _exePath = exePath;
            _logFilePath = logFilePath;
        }

        public void Start()
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = _exePath,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.OutputDataReceived += (s, e) => AppendLog(e.Data);
            process.ErrorDataReceived += (s, e) => AppendLog(e.Data);

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
        }

        private void AppendLog(string? data)
        {
            if (string.IsNullOrEmpty(data)) return;
            lock (_lock)
            {
                _logBuilder.AppendLine(data);
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

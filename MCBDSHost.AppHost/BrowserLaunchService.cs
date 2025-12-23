using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

namespace MCBDSHost.AppHost;

public class BrowserLaunchService : IHostedService
{
    private readonly ILogger<BrowserLaunchService> _logger;
    private readonly IConfiguration _configuration;

    public BrowserLaunchService(ILogger<BrowserLaunchService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        // Wait for services to start
        await Task.Delay(3000, cancellationToken);

        try
        {
            // Open Aspire Dashboard first
            _logger.LogInformation("Opening Aspire Dashboard");
            OpenUrl("https://localhost:17097");
            
            // Wait a moment before opening the second URL
            await Task.Delay(1000, cancellationToken);
            
            // Open API Runner Log
            _logger.LogInformation("Opening API Runner Log");
            OpenUrl("https://localhost:7060/api/runner/log");

            // Wait a moment before opening the third URL
            await Task.Delay(1000, cancellationToken);

            // Open runner.html UI
            _logger.LogInformation("Opening runner.html UI");
            OpenUrl("https://localhost:7060/runner.html");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to open browser windows");
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    private void OpenUrl(string url)
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = url,
                UseShellExecute = true
            });
        }
        catch
        {
            // Fallback for different platforms
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                Process.Start(new ProcessStartInfo("cmd", $"/c start {url}") { CreateNoWindow = true });
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                Process.Start("xdg-open", url);
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                Process.Start("open", url);
            }
        }
    }
}

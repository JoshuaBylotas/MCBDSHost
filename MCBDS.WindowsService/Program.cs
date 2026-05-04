using MCBDS.API.Models;
using MCBDS.API.Background;
using System.Diagnostics;
using Microsoft.AspNetCore.Server.Kestrel.Core;

namespace MCBDS.WindowsService;

public class Program
{
    private const string ServiceName = "MCBDSAPIService";
    private const string ServiceDisplayName = "MCBDS API Service";

    public static void Main(string[] args)
    {
        // Handle service installation/uninstallation commands
        if (args.Length > 0)
        {
            switch (args[0].ToLower())
            {
                case "install":
                    InstallService();
                    return;
                case "uninstall":
                    UninstallService();
                    return;
            }
        }

        // Create WebApplication builder instead of generic Host
        var builder = WebApplication.CreateBuilder(args);

        // Configure to run as Windows Service
        builder.Services.AddWindowsService(options =>
        {
            options.ServiceName = ServiceDisplayName;
        });

        // Configure Kestrel explicitly via WebHost
        builder.WebHost.ConfigureKestrel(serverOptions =>
        {
            // Read port from config or use default
            var port = builder.Configuration.GetValue<int>("Port", 8080);
            serverOptions.ListenAnyIP(port);
        });

        // Add logging to help debug
        builder.Logging.ClearProviders();
        builder.Logging.AddConsole();
        builder.Logging.AddEventLog(); // Windows Event Log for service

        // Configure API services
        ConfigureApiServices(builder);

        var app = builder.Build();

        // Configure the HTTP request pipeline
        app.UseCors();
        app.MapControllers();
        app.MapHealthChecks("/health");

        // Log the URLs we're listening on
        var logger = app.Logger;
        logger.LogInformation("Starting MCBDS API Service...");
        logger.LogInformation("Listening on: {Urls}", string.Join(", ", app.Urls));

        app.Run();
    }

    /// <summary>
    /// Installs the application as a Windows Service
    /// </summary>
    private static void InstallService()
    {
        try
        {
            string exePath = Process.GetCurrentProcess().MainModule?.FileName ?? "";
            
            // Use sc.exe to create the service
            // This is called by the NSIS installer
            var startInfo = new ProcessStartInfo
            {
                FileName = "sc.exe",
                Arguments = $"create {ServiceName} binPath= \"{exePath}\" start= auto DisplayName= \"{ServiceDisplayName}\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using var process = Process.Start(startInfo);
            process?.WaitForExit();

            if (process?.ExitCode == 0)
            {
                Console.WriteLine($"Service '{ServiceDisplayName}' installed successfully.");
            }
            else
            {
                Console.WriteLine($"Failed to install service. Exit code: {process?.ExitCode}");
                Environment.Exit(1);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error installing service: {ex.Message}");
            Environment.Exit(1);
        }
    }

    /// <summary>
    /// Uninstalls the Windows Service
    /// </summary>
    private static void UninstallService()
    {
        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "sc.exe",
                Arguments = $"delete {ServiceName}",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using var process = Process.Start(startInfo);
            process?.WaitForExit();

            if (process?.ExitCode == 0)
            {
                Console.WriteLine($"Service '{ServiceDisplayName}' uninstalled successfully.");
            }
            else
            {
                Console.WriteLine($"Failed to uninstall service. Exit code: {process?.ExitCode}");
                Environment.Exit(1);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error uninstalling service: {ex.Message}");
            Environment.Exit(1);
        }
    }

    private static void ConfigureApiServices(WebApplicationBuilder builder)
    {
        var serviceDirectory = AppContext.BaseDirectory;

        // Insert defaults FIRST so appsettings.json can override them
        var defaults = new Dictionary<string, string?>
        {
            ["Runner:ExePath"] = Path.Combine(serviceDirectory, "Binaries", "bedrock_server.exe"),
            ["Runner:LogFilePath"] = Path.Combine(serviceDirectory, "logs", "runner.log"),
            ["Backup:BackupDirectory"] = Path.Combine(serviceDirectory, "backups"),
            ["Backup:FrequencyMinutes"] = "30",
            ["Backup:MaxBackupsToKeep"] = "30"
        };

        // Insert at position 0 so JSON files and env vars take priority
        builder.Configuration.Sources.Insert(0,
            new Microsoft.Extensions.Configuration.Memory.MemoryConfigurationSource
            {
                InitialData = defaults
            });

        // Add services
        builder.Services.AddControllers();
        
        // Configure CORS to allow any origin for the service (since it's typically used locally)
        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.AllowAnyOrigin()
                      .AllowAnyMethod()
                      .AllowAnyHeader();
            });
        });

        // Configure backup settings
        builder.Services.Configure<BackupConfiguration>(builder.Configuration.GetSection("Backup"));

        // Register HttpClientFactory for external API calls (Xbox Live, etc.)
        builder.Services.AddHttpClient();

        // Register PackManagementService
        builder.Services.AddScoped<MCBDS.API.Services.PackManagementService>();

        // Register RunnerHostedService
        builder.Services.AddSingleton<RunnerHostedService>();
        builder.Services.AddHostedService(provider => provider.GetRequiredService<RunnerHostedService>());

        // Register BackupHostedService
        builder.Services.AddSingleton<BackupHostedService>();
        builder.Services.AddHostedService(provider => provider.GetRequiredService<BackupHostedService>());

        // Add health checks
        builder.Services.AddHealthChecks();
    }
}


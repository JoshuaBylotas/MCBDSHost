using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;
using MCBDS.PublicUI.Services;

namespace MCBDS.PublicUI;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		try
		{
			var builder = MauiApp.CreateBuilder();
			builder
				.UseMauiApp<App>()
				.ConfigureFonts(fonts =>
				{
					fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
				});

			// Initialize crash logger FIRST thing
			try
			{
				var appDataDirectory = FileSystem.Current.AppDataDirectory;
				CrashLogger.Initialize(appDataDirectory);
				CrashLogger.LogInfo("MauiProgram.CreateMauiApp started");
				CrashLogger.LogInfo($"App Data Directory: {appDataDirectory}");
			}
			catch (Exception ex)
			{
				// If crash logger fails, continue but log to Debug
				System.Diagnostics.Debug.WriteLine($"CrashLogger initialization failed: {ex.Message}");
			}

			// Create HttpClient - the base address will be set by ServerConfigService
			var httpClient = new HttpClient
			{
				Timeout = TimeSpan.FromSeconds(30)
			};
			builder.Services.AddSingleton(httpClient);
			CrashLogger.LogInfo("HttpClient configured with 30s timeout");
			
			// Register ServerConfigService with MAUI AppDataDirectory for persistence
			// This will load the saved server configuration synchronously in the constructor
			builder.Services.AddSingleton<ServerConfigService>(sp => 
			{
				try
				{
					var client = sp.GetRequiredService<HttpClient>();
					var appDataDir = FileSystem.Current.AppDataDirectory;
					CrashLogger.LogInfo($"Creating ServerConfigService with directory: {appDataDir}");
					return new ServerConfigService(client, appDataDir);
				}
				catch (Exception ex)
				{
					CrashLogger.LogError("Failed to create ServerConfigService", ex);
					throw;
				}
			});
			
			// Register BedrockApiService with ServerConfigService for dynamic URL resolution
			builder.Services.AddSingleton<BedrockApiService>(sp =>
			{
				try
				{
					var client = sp.GetRequiredService<HttpClient>();
					var serverConfig = sp.GetRequiredService<ServerConfigService>();
					CrashLogger.LogInfo("Creating BedrockApiService");
					return new BedrockApiService(client, serverConfig);
				}
				catch (Exception ex)
				{
					CrashLogger.LogError("Failed to create BedrockApiService", ex);
					throw;
				}
			});

			// Register BackupSettingsService with MAUI AppDataDirectory
			builder.Services.AddSingleton<BackupSettingsService>(sp => 
			{
				try
				{
					var appDataDir = FileSystem.Current.AppDataDirectory;
					CrashLogger.LogInfo($"Creating BackupSettingsService with directory: {appDataDir}");
					return new BackupSettingsService(appDataDir);
				}
				catch (Exception ex)
				{
					CrashLogger.LogError("Failed to create BackupSettingsService", ex);
					throw;
				}
			});

			builder.Services.AddMauiBlazorWebView();

#if DEBUG
			builder.Services.AddBlazorWebViewDeveloperTools();
			builder.Logging.AddDebug();
#endif

			CrashLogger.LogInfo("MauiProgram.CreateMauiApp completed successfully");
			return builder.Build();
		}
		catch (Exception ex)
		{
			CrashLogger.LogFatal("MauiProgram.CreateMauiApp failed", ex);
			System.Diagnostics.Debug.WriteLine($"FATAL ERROR in MauiProgram: {ex}");
			throw;
		}
	}
}

using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI.Android;

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

#if DEBUG
			builder.Logging.AddDebug();
			builder.Logging.SetMinimumLevel(LogLevel.Trace);
#endif

			try
			{
				// Create HttpClient - the base address will be set by ServerConfigService
				var httpClient = new HttpClient();
				builder.Services.AddSingleton(httpClient);
				System.Diagnostics.Debug.WriteLine("? HttpClient registered");
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine($"? HttpClient registration failed: {ex}");
				throw;
			}

			try
			{
				// Register ServerConfigService with MAUI AppDataDirectory for persistence
				builder.Services.AddSingleton<ServerConfigService>(sp => 
				{
					var client = sp.GetRequiredService<HttpClient>();
					return new ServerConfigService(client, FileSystem.Current.AppDataDirectory);
				});
				System.Diagnostics.Debug.WriteLine("? ServerConfigService registered");
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine($"? ServerConfigService registration failed: {ex}");
				throw;
			}

			try
			{
				// Register BedrockApiService with ServerConfigService for dynamic URL resolution
				builder.Services.AddSingleton<BedrockApiService>(sp =>
				{
					var client = sp.GetRequiredService<HttpClient>();
					var serverConfig = sp.GetRequiredService<ServerConfigService>();
					return new BedrockApiService(client, serverConfig);
				});
				System.Diagnostics.Debug.WriteLine("? BedrockApiService registered");
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine($"? BedrockApiService registration failed: {ex}");
				throw;
			}

			try
			{
				builder.Services.AddMauiBlazorWebView();
				System.Diagnostics.Debug.WriteLine("? Blazor WebView registered");
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine($"? Blazor WebView registration failed: {ex}");
				throw;
			}

#if DEBUG
			try
			{
				builder.Services.AddBlazorWebViewDeveloperTools();
				System.Diagnostics.Debug.WriteLine("? Developer tools registered");
			}
			catch (Exception ex)
			{
				System.Diagnostics.Debug.WriteLine($"? Developer tools registration failed: {ex}");
				// Don't throw - dev tools are optional
			}
#endif

			System.Diagnostics.Debug.WriteLine("? Building MAUI app...");
			var app = builder.Build();
			System.Diagnostics.Debug.WriteLine("? MAUI app built successfully");
			return app;
		}
		catch (Exception ex)
		{
			System.Diagnostics.Debug.WriteLine($"??? CRITICAL ERROR in CreateMauiApp: {ex}");
			System.Diagnostics.Debug.WriteLine($"Exception Type: {ex.GetType().Name}");
			System.Diagnostics.Debug.WriteLine($"Message: {ex.Message}");
			System.Diagnostics.Debug.WriteLine($"StackTrace: {ex.StackTrace}");
			if (ex.InnerException != null)
			{
				System.Diagnostics.Debug.WriteLine($"Inner Exception: {ex.InnerException.Message}");
			}
			throw;
		}
	}
}

using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI.Android;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
			});

		// Register HttpClient with Android-specific configuration
		var httpClient = new HttpClient(GetPlatformMessageHandler())
		{
			Timeout = TimeSpan.FromSeconds(60) // Increased timeout for remote servers
		};
		builder.Services.AddSingleton(httpClient);

		// Register ServerConfigService with MAUI AppDataDirectory for persistence
		builder.Services.AddSingleton<ServerConfigService>(sp => 
		{
			var client = sp.GetRequiredService<HttpClient>();
			return new ServerConfigService(client, FileSystem.Current.AppDataDirectory);
		});

		// Register BedrockApiService with ServerConfigService for dynamic URL resolution
		builder.Services.AddSingleton<BedrockApiService>(sp =>
		{
			var client = sp.GetRequiredService<HttpClient>();
			var serverConfig = sp.GetRequiredService<ServerConfigService>();
			return new BedrockApiService(client, serverConfig);
		});

		// Register BackupSettingsService with MAUI AppDataDirectory
		builder.Services.AddSingleton<BackupSettingsService>(sp => 
			new BackupSettingsService(FileSystem.Current.AppDataDirectory));

		builder.Services.AddMauiBlazorWebView();

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}

	private static HttpMessageHandler GetPlatformMessageHandler()
	{
#if ANDROID
		var handler = new Xamarin.Android.Net.AndroidMessageHandler
		{
			ServerCertificateCustomValidationCallback = (message, cert, chain, errors) =>
			{
#if DEBUG
				// Allow self-signed certificates and all SSL errors in DEBUG mode
				System.Diagnostics.Debug.WriteLine($"SSL Validation - URL: {message.RequestUri}");
				System.Diagnostics.Debug.WriteLine($"SSL Errors: {errors}");
				return true;
#else
				return errors == System.Net.Security.SslPolicyErrors.None;
#endif
			},
			// Enable automatic decompression
			AutomaticDecompression = System.Net.DecompressionMethods.GZip | System.Net.DecompressionMethods.Deflate
		};
		
		System.Diagnostics.Debug.WriteLine("Android HttpClient handler configured");
		return handler;
#else
		return new HttpClientHandler();
#endif
	}
}

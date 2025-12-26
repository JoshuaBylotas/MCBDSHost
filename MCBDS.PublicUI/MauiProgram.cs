using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI;

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

		// Register BedrockApiService with HttpClient
		// When running locally, connect to the Aspire-orchestrated API
		// You can find the actual URL in the Aspire Dashboard after starting the AppHost
		var httpClient = new HttpClient
		{
#if DEBUG
			// For local development, update this URL from the Aspire Dashboard
			// The Aspire dashboard shows the actual port assigned to "mcbds-api"
			BaseAddress = new Uri("https://localhost:7060") // Update port as needed
#else
			// For production, use your deployed API URL
			BaseAddress = new Uri("https://your-production-api-url.com")
#endif
		};
		builder.Services.AddSingleton(httpClient);
		builder.Services.AddSingleton<BedrockApiService>();

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
}

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

		// Create HttpClient - the base address will be set by ServerConfigService
		var httpClient = new HttpClient();
		builder.Services.AddSingleton(httpClient);
		
		// Register ServerConfigService with MAUI AppDataDirectory for persistence
		// This will load the saved server configuration synchronously in the constructor
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
}

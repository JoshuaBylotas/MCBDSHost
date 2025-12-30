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

		// Register HttpClient
		var httpClient = new HttpClient();
		builder.Services.AddSingleton(httpClient);

		// Register ServerConfigService with MAUI AppDataDirectory for persistence
		builder.Services.AddSingleton<ServerConfigService>(sp => 
		{
			var client = sp.GetRequiredService<HttpClient>();
			return new ServerConfigService(client, FileSystem.Current.AppDataDirectory);
		});

		// Register BedrockApiService
		builder.Services.AddSingleton<BedrockApiService>(sp =>
		{
			var client = sp.GetRequiredService<HttpClient>();
			var serverConfig = sp.GetRequiredService<ServerConfigService>();
			return new BedrockApiService(client, serverConfig);
		});

		builder.Services.AddMauiBlazorWebView();

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}

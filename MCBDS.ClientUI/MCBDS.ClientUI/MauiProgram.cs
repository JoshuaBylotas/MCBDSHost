using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;
using MCBDS.ClientUI.Services;

namespace MCBDS.ClientUI;

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

        // Add device-specific services used by the MCBDS.ClientUI.Shared project
        builder.Services.AddSingleton<IFormFactor, FormFactor>();

        // Register BedrockApiService with HttpClient
        // When running locally, connect to the Aspire-orchestrated API
        // You can find the actual URL in the Aspire Dashboard after starting the AppHost
        var httpClient = new HttpClient
        {
#if DEBUG
            // For local development, update this URL from the Aspire Dashboard
            // The Aspire dashboard shows the actual port assigned to "mcbds-api"
            BaseAddress = new Uri("https://localhost:7000") // Update port as needed
#else
            // For production, use your deployed API URL
            BaseAddress = new Uri("https://your-production-api-url.com")
#endif
        };
        builder.Services.AddSingleton(httpClient);
        builder.Services.AddSingleton<BedrockApiService>();

        builder.Services.AddMauiBlazorWebView();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}

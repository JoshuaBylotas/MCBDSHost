using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using MCBDS.PublicUI.Web;
using MCBDS.PublicUI.Web.Services;
using MCBDS.ClientUI.Shared.Services;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

// Create HttpClient with base address from the hosting environment
var httpClient = new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) };
builder.Services.AddSingleton(httpClient);

// Register WebServerConfigService - uses browser localStorage for persistence
builder.Services.AddSingleton<WebServerConfigService>();

// Register IServerConfigService interface pointing to WebServerConfigService
builder.Services.AddSingleton<IServerConfigService>(sp => sp.GetRequiredService<WebServerConfigService>());

// Register BedrockApiService with IServerConfigService for dynamic URL resolution
builder.Services.AddSingleton<BedrockApiService>(sp =>
{
    var client = sp.GetRequiredService<HttpClient>();
    var serverConfig = sp.GetRequiredService<IServerConfigService>();
    return new BedrockApiService(client, serverConfig);
});

// Register BackupSettingsService - no file system access in web
builder.Services.AddSingleton<BackupSettingsService>(sp => 
    new BackupSettingsService(null));

await builder.Build().RunAsync();

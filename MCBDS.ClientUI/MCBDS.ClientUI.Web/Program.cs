using MCBDS.ClientUI.Web.Components;
using MCBDS.ClientUI.Shared.Services;
using MCBDS.ClientUI.Web.Services;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Add device-specific services used by the MCBDS.ClientUI.Shared project
builder.Services.AddSingleton<IFormFactor, FormFactor>();

// Register BedrockApiService with HttpClient using Aspire service discovery
builder.Services.AddHttpClient<MCBDS.ClientUI.Shared.Services.BedrockApiService>(client =>
{
    // Aspire will automatically resolve "mcbds-api" to the correct URL
    // Use http in container environments, https+http for local development with Aspire
    var apiBaseUrl = builder.Configuration["ApiSettings:BaseUrl"] ?? "https+http://mcbds-api";
    client.BaseAddress = new Uri(apiBaseUrl);
});

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    
    // Only use HSTS and HTTPS redirection when not running in a container
    var runningInContainer = Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true";
    if (!runningInContainer)
    {
        app.UseHsts();
        app.UseHttpsRedirection();
    }
}
else
{
    app.UseHttpsRedirection();
}

app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);

app.UseAntiforgery();

app.MapStaticAssets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AddAdditionalAssemblies(
        typeof(MCBDS.ClientUI.Shared._Imports).Assembly);

app.Run();

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
    client.BaseAddress = new Uri("https+http://mcbds-api");
});

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAntiforgery();

app.MapStaticAssets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AddAdditionalAssemblies(
        typeof(MCBDS.ClientUI.Shared._Imports).Assembly);

app.Run();

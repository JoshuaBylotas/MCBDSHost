using MCBDS.Marketing.Components;
using MCBDS.Marketing.Services;
using System.Runtime.InteropServices;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents();

// Add SEO Services
builder.Services.AddScoped<DocumentationService>();
builder.Services.AddScoped<StructuredDataService>();

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();
if (builder.Environment.IsProduction() && RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
{
    builder.Logging.AddEventLog();
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);

// Custom HTTPS redirection that excludes ACME challenge requests
app.Use(async (context, next) =>
{
    // Allow HTTP for ACME challenge requests (Let's Encrypt)
    if (context.Request.Path.StartsWithSegments("/.well-known/acme-challenge"))
    {
        await next();
        return;
    }

    // Redirect all other HTTP requests to HTTPS in production
    if (!app.Environment.IsDevelopment() && !context.Request.IsHttps)
    {
        var httpsUrl = $"https://{context.Request.Host}{context.Request.Path}{context.Request.QueryString}";
        context.Response.Redirect(httpsUrl, permanent: true);
        return;
    }

    await next();
});

// Add security headers for SEO and security
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "SAMEORIGIN";
    context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
    context.Response.Headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()";
    
    await next();
});

// Serve static files
app.UseStaticFiles();

app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>();

app.Run();

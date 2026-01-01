using MCBDS.API.Models;

var builder = WebApplication.CreateBuilder(args);

// Enable configuration reload on file change
builder.Configuration.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
builder.Configuration.AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true);

builder.AddServiceDefaults();

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Configure CORS to allow web clients to connect
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
    
    // Named policy for more restrictive production use
    options.AddPolicy("Production", policy =>
    {
        policy.WithOrigins(
                "http://localhost:5000",
                "http://localhost:5001",
                "https://localhost:5001",
                "http://localhost:8080",
                "https://localhost:8080",
                "http://127.0.0.1:5000",
                "http://127.0.0.1:8080"
            )
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// Configure backup settings with change tracking
builder.Services.Configure<BackupConfiguration>(builder.Configuration.GetSection("Backup"));

// Register RunnerHostedService as singleton
builder.Services.AddSingleton<MCBDS.API.Background.RunnerHostedService>();
builder.Services.AddHostedService(provider => provider.GetRequiredService<MCBDS.API.Background.RunnerHostedService>());

// Register BackupHostedService as singleton to make it accessible to the controller
builder.Services.AddSingleton<MCBDS.API.Background.BackupHostedService>();
builder.Services.AddHostedService(provider => provider.GetRequiredService<MCBDS.API.Background.BackupHostedService>());

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseHttpsRedirection();
}

// Enable CORS - must be before UseAuthorization
app.UseCors();

app.UseAuthorization();

app.UseStaticFiles();

app.MapControllers();

app.Run();

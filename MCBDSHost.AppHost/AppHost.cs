using Microsoft.Extensions.DependencyInjection;
using MCBDSHost.AppHost;
using Projects;

var builder = DistributedApplication.CreateBuilder(args);

// Register browser launcher service to open URLs on startup
builder.Services.AddHostedService<BrowserLaunchService>();

builder.AddProject<Projects.MCBDS_API>("mcbds-api")
    .WithHttpHealthCheck("/health")
    .WithEndpoint(targetPort: 19132, scheme: "udp", name: "minecraft")
    .WithEndpoint(targetPort: 19133, scheme: "udp", name: "minecraft-v6");

builder.AddProject<Projects.MCBDS_ClientUI_Web>("mcbds-clientui-web");

builder.Build().Run();

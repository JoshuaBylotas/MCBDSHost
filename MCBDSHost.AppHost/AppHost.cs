var builder = DistributedApplication.CreateBuilder(args);

// Using container for proper SIGTERM signal handling and graceful shutdown
var mcbdsApi = builder.AddDockerfile("mcbds-api", "../MCBDS.API")
    .WithHttpEndpoint(port: 8080, targetPort: 8080, name: "http")
    .WithHttpsEndpoint(port: 8081, targetPort: 8081, name: "https")
    .WithEnvironment("ASPNETCORE_ENVIRONMENT", "Development")
    .WithEnvironment("Runner__ExePath", "/bedrock/bedrock_server")
    .WithEnvironment("Runner__LogFilePath", "/app/runner.log")
    .WithHttpHealthCheck("/health");

builder.Build().Run();

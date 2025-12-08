var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.MCBDS_API>("mcbds-api");

builder.Build().Run();

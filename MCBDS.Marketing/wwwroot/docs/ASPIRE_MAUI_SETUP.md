# Aspire + MAUI Configuration Guide

## Overview

This solution uses .NET Aspire to orchestrate backend services, with MAUI apps connecting to those services.

## Architecture

### Aspire-Orchestrated Services (Run via AppHost)
- **MCBDS.API** - Backend API for Minecraft Bedrock Dedicated Server
- **MCBDS.ClientUI.Web** - Blazor Web App (uses Aspire service discovery)

### Standalone MAUI Apps (Run separately)
- **MCBDS.ClientUI** - MAUI Blazor Hybrid App (mobile/desktop)
- **MCBDS.PublicUI** - MAUI Blazor Hybrid App (mobile/desktop)

## How to Run

### 1. Start the Aspire AppHost

Set `MCBDSHost.AppHost` as the startup project and run it. This will:
- Start the MCBDS.API service
- Start the MCBDS.ClientUI.Web service
- Open the Aspire Dashboard

### 2. Get the API URL from Aspire Dashboard

1. Open the Aspire Dashboard (it opens automatically)
2. Find the `mcbds-api` service
3. Note the HTTPS endpoint URL (e.g., `https://localhost:7123`)

### 3. Update MAUI App Configuration

Update the API URL in both MAUI apps:

**MCBDS.ClientUI\MCBDS.ClientUI\MauiProgram.cs:**
```csharp
client.BaseAddress = new Uri("https://localhost:7123"); // Use URL from Aspire Dashboard
```

**MCBDS.PublicUI\MauiProgram.cs:**
```csharp
client.BaseAddress = new Uri("https://localhost:7123"); // Use URL from Aspire Dashboard
```

### 4. Run the MAUI Apps

Set either `MCBDS.ClientUI` or `MCBDS.PublicUI` as the startup project and run them separately.

## Service Discovery

### Blazor Web App (MCBDS.ClientUI.Web)
Uses Aspire's built-in service discovery:
```csharp
client.BaseAddress = new Uri("https+http://mcbds-api");
```

Aspire automatically resolves `mcbds-api` to the correct URL.

### MAUI Apps
Cannot use Aspire service discovery (they run outside Aspire). They use direct URLs:
```csharp
client.BaseAddress = new Uri("https://localhost:7123");
```

## Production Deployment

For production:

1. **Deploy API** to your hosting platform (Azure, AWS, etc.)
2. **Update MAUI apps** with production API URL:
```csharp
#else
    client.BaseAddress = new Uri("https://your-production-api.com");
#endif
```
3. **Publish MAUI apps** to app stores with production configuration

## Shared Service (BedrockApiService)

The `BedrockApiService` is now in `MCBDS.ClientUI.Shared` and used by:
- ? MCBDS.ClientUI.Web (Blazor Web)
- ? MCBDS.ClientUI (MAUI)
- ? MCBDS.PublicUI (MAUI)

All three projects share the same API client implementation.

## Important Notes

- **MAUI apps cannot be added to Aspire orchestration** - they are client applications
- **The Web app uses Aspire service discovery** - it automatically finds the API
- **MAUI apps use direct URLs** - you must update the URL manually
- **Check Aspire Dashboard** for the actual API port (it changes each run in development)

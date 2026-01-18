# MCBDS Host - Copilot Instructions

## Project Overview
MCBDS Host is a Minecraft Bedrock Dedicated Server (MCBDS) hosting and management platform built on .NET 10 with Aspire orchestration. The system wraps Minecraft Bedrock server binaries with a management API and provides cross-platform UI clients.

## Architecture

### Key Projects
- **MCBDSHost.AppHost** - .NET Aspire orchestrator managing service discovery and startup
- **MCBDS.API** - Backend API that wraps and manages the Minecraft Bedrock server process
- **MCBDS.ClientUI.Shared** - Shared Blazor components library used by both web and MAUI clients
- **MCBDS.ClientUI.Web** - Blazor Server web application (production UI)
- **MCBDS.PublicUI** - .NET MAUI cross-platform mobile app (Android, iOS, Windows, macOS)
- **MCBDSHost.ServiceDefaults** - Shared Aspire service defaults

### Service Communication
- **Aspire Service Discovery**: Web client uses `https+http://mcbds-api` naming convention for automatic service resolution
- **Dynamic Server Configuration**: MAUI apps use `ServerConfigService` with file-based persistence (`server-config.json` in `AppDataDirectory`)
- **HTTP-only for MAUI**: Mobile apps connect via user-configured HTTP endpoints, not Aspire

### Critical Process Management
The `RunnerHostedService` in MCBDS.API manages the Minecraft Bedrock server executable:
- Runs as `IHostedService` singleton - use `AddSingleton` + `AddHostedService` pattern
- Must run from bedrock server's directory (set `WorkingDirectory` in `ProcessStartInfo`)
- Executable path configured via `appsettings.json` ? `Runner:ExePath`
- Exposes UDP endpoints on ports 19132 (IPv4) and 19133 (IPv6) - configured in AppHost with `.WithEndpoint(scheme: "udp")`

## Development Workflows

### Running the Application
```bash
# Start all services via Aspire orchestrator (recommended)
dotnet run --project MCBDSHost.AppHost

# The AppHost includes BrowserLaunchService that auto-opens the dashboard
# Access web UI at: https://localhost:<assigned-port>/mcbds-clientui-web
```

### Testing MAUI Apps
- MAUI apps require manual server URL configuration on first launch
- Use `AddServerModal` component for initial setup
- Test with Android emulator: Right-click MCBDS.PublicUI ? Deploy ? Android Emulator
- Server URL format: `http://<local-ip>:8080` (find port in Aspire dashboard)

### Building
```bash
# Build entire solution
dotnet build MCBDSHost.sln

# MAUI builds require platform-specific TFM
dotnet build MCBDS.PublicUI/MCBDS.PublicUI.csproj -f net10.0-android
```

## Critical Conventions

### Service Registration Patterns
**Web App (uses Aspire service discovery):**
```csharp
builder.Services.AddHttpClient<BedrockApiService>(client => {
    client.BaseAddress = new Uri("https+http://mcbds-api");
});
```

**MAUI App (uses dynamic configuration):**
```csharp
// Order matters: HttpClient ? ServerConfigService ? BedrockApiService
builder.Services.AddSingleton(new HttpClient());
builder.Services.AddSingleton<ServerConfigService>(sp => 
    new ServerConfigService(sp.GetRequiredService<HttpClient>(), 
                           FileSystem.Current.AppDataDirectory));
builder.Services.AddSingleton<BedrockApiService>();
```

### Shared Component Integration
Components from `MCBDS.ClientUI.Shared` are used in both web and MAUI apps:
- Web: Register via `.AddAdditionalAssemblies(typeof(MCBDS.ClientUI.Shared._Imports).Assembly)`
- MAUI: Automatically included through project reference
- Use `IFormFactor` abstraction for platform-specific UI adjustments (see `MauiFormFactorService`)

### Android MAUI Customizations
- **BlazorWebView**: Custom handler `CustomBlazorWebViewHandler` provides safe area insets for Android
- Register in `MauiProgram.cs`: `handlers.AddHandler<BlazorWebView, CustomBlazorWebViewHandler>()`
- See `AndroidToolbar.razor` and `AndroidBottomNav.razor` for platform-specific UI components

### Error Handling & Logging
- MAUI apps use `CrashLogger.Initialize(FileSystem.Current.AppDataDirectory)` - call in `MauiProgram` before service registration
- API uses standard `ILogger<T>` injection
- `ServerConfigService` initializes synchronously in constructor to set `HttpClient.BaseAddress` immediately

### Static Asset Handling
MAUI projects have custom MSBuild target to remove duplicate static web assets:
```xml
<ResolveStaticWebAssetsInputsDependsOn>
    $(ResolveStaticWebAssetsInputsDependsOn);RemoveDuplicateStaticWebAssets
</ResolveStaticWebAssetsInputsDependsOn>
```

## Server Binary Deployment
The MCBDS.API project includes a post-build copy task:
```xml
<Target Name="CopyBinariesOnBuild" AfterTargets="Build">
  <!-- Copies Binaries/** to output directory -->
</Target>
```
Place Minecraft Bedrock server executables in `MCBDS.API/Binaries/` directory.

## Docker Deployment

### Container Images
The solution includes Dockerfiles for both Linux and Windows:
- **Linux**: `MCBDS.API/Dockerfile` - Uses `mcr.microsoft.com/dotnet/aspnet:10.0`
- **Windows**: `MCBDS.API/Dockerfile.windows` - Uses `windowsservercore-ltsc2022` (includes VC++ Redistributable for bedrock_server.exe)
- **Web UI**: `MCBDS.ClientUI.Web/Dockerfile` - Standard ASP.NET Core container

### Key Container Considerations

**Port Mappings:**
```yaml
# HTTP/HTTPS
- 8080:8080
- 8081:8081
# Minecraft Bedrock UDP ports
- 19132:19132/udp
- 19133:19133/udp
```

**Volume Mounts (recommended for persistence):**
```yaml
volumes:
  - ./bedrock-binaries:/app/Binaries         # Server executable
  - ./logs:/app/logs                         # Runner logs
  - ./backups:/app/backups                   # Automatic backups
  - ./server-data:/app/Binaries/worlds       # World data persistence
```

**Environment Variables:**
```bash
# Path configuration (default: /app/Binaries/bedrock_server)
Runner__ExePath=/app/Binaries/bedrock_server

# Backup configuration
Backup__FrequencyMinutes=30
Backup__BackupDirectory=/app/backups
Backup__MaxBackupsToKeep=30

# Aspire detection (set by container runtime)
DOTNET_RUNNING_IN_CONTAINER=true
```

**Health Checks:**
The API exposes `/health` endpoint. Container includes curl for healthcheck support:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Building Container Images
```bash
# Build API (Linux)
docker build -f MCBDS.API/Dockerfile -t mcbds-api:latest .

# Build API (Windows Server)
docker build -f MCBDS.API/Dockerfile.windows --build-arg WINDOWS_VERSION=ltsc2022 -t mcbds-api:windows-latest .

# Build Web UI
docker build -f MCBDS.ClientUI/MCBDS.ClientUI.Web/Dockerfile -t mcbds-web:latest .
```

### Running Standalone Containers
```bash
# API container with volumes
docker run -d --name mcbds-api \
  -p 8080:8080 \
  -p 19132:19132/udp \
  -p 19133:19133/udp \
  -v $(pwd)/bedrock-server:/app/Binaries \
  -v $(pwd)/backups:/app/backups \
  -v $(pwd)/logs:/app/logs \
  -e Runner__ExePath=/app/Binaries/bedrock_server \
  mcbds-api:latest

# Web UI container (needs API URL)
docker run -d --name mcbds-web \
  -p 5000:8080 \
  -e ApiSettings__BaseUrl=http://mcbds-api:8080 \
  --link mcbds-api \
  mcbds-web:latest
```

### Docker Compose Example
```yaml
services:
  mcbds-api:
    build:
      context: .
      dockerfile: MCBDS.API/Dockerfile
    ports:
      - "8080:8080"
      - "19132:19132/udp"
      - "19133:19133/udp"
    volumes:
      - ./bedrock-server:/app/Binaries
      - ./backups:/app/backups
      - ./logs:/app/logs
    environment:
      - Runner__ExePath=/app/Binaries/bedrock_server
      - Backup__FrequencyMinutes=30
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      
  mcbds-web:
    build:
      context: .
      dockerfile: MCBDS.ClientUI/MCBDS.ClientUI.Web/Dockerfile
    ports:
      - "5000:8080"
    environment:
      - ApiSettings__BaseUrl=http://mcbds-api:8080
    depends_on:
      - mcbds-api
```

### Important Notes
- **MAUI apps cannot be containerized** - they are client applications requiring native UI frameworks
- **Aspire AppHost** is for local development orchestration only, not container deployment
- **Windows containers** require Visual C++ Redistributable (automatically installed in Dockerfile.windows)
- **Linux containers** run under non-root user (`$APP_UID`) for security
- **Bedrock server binaries** must be mounted or copied into `/app/Binaries` before container start

## Common Pitfalls
1. **MAUI HttpClient timing**: `ServerConfigService` must initialize before `BedrockApiService`
2. **Bedrock server working directory**: Process must run from its own directory or it won't find data files
3. **UDP endpoint configuration**: Don't forget `scheme: "udp"` in AppHost `.WithEndpoint()` calls
4. **CORS in API**: Default policy allows any origin for development; use "Production" policy for deployed environments
5. **Android BlazorWebView**: Must use custom handler for proper layout on Android - standard handler has safe area issues

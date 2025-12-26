# Minecraft Bedrock Server Port Configuration

## Ports Configured

The following ports have been configured for the Minecraft Bedrock Server:

### Minecraft Server Ports (UDP)
- **Port 19132** - IPv4 Minecraft Bedrock Server port
- **Port 19133** - IPv6 Minecraft Bedrock Server port

### API Ports (HTTP/HTTPS)
- **Port 8080** - HTTP endpoint for the .NET API
- **Port 8081** - HTTPS endpoint for the .NET API

## Configuration Files Updated

### 1. Dockerfile (`MCBDS.API/Dockerfile`)
```dockerfile
EXPOSE 8080
EXPOSE 8081
EXPOSE 19132/udp
EXPOSE 19133/udp
```

### 2. AppHost Configuration (`MCBDSHost.AppHost/AppHost.cs`)
```csharp
builder.AddProject<Projects.MCBDS_API>("mcbds-api")
    .WithHttpHealthCheck("/health")
    .WithEndpoint(19132, 19132, "minecraft", "udp")
    .WithEndpoint(19133, 19133, "minecraft-v6", "udp");
```

### 3. Bedrock Server Properties (`MCBDS.API/bedrock-server/server.properties`)
```properties
server-port=19132
server-portv6=19133
```

## Running with Docker

When you run the application with Docker installed, the ports will be automatically mapped. If you need to run Docker manually:

```bash
docker build -t mcbds-api -f MCBDS.API/Dockerfile .
docker run -p 8080:8080 -p 8081:8081 -p 19132:19132/udp -p 19133:19133/udp mcbds-api
```

## Connecting to the Server

Players can connect to your Minecraft Bedrock server using:
- **Server Address**: Your server's IP address or hostname
- **Port**: 19132 (default, can be omitted in most clients)

## Firewall Configuration

If running in production, ensure your firewall allows:
- **UDP traffic on port 19132** (required)
- **UDP traffic on port 19133** (optional, for IPv6)
- **TCP traffic on ports 8080/8081** (for API access)

## Notes

- The Bedrock server uses **UDP protocol**, not TCP
- Port 19132 is the default Minecraft Bedrock server port
- IPv6 support is provided through port 19133
- The .NET Aspire dashboard will show these endpoints when running

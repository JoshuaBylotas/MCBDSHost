# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
# Using .NET 10.0 stable images (change to 10.0 when available)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
EXPOSE 19132/udp
EXPOSE 19133/udp


# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MCBDS.API/MCBDS.API.csproj", "MCBDS.API/"]
COPY ["MCBDSHost.ServiceDefaults/MCBDSHost.ServiceDefaults.csproj", "MCBDSHost.ServiceDefaults/"]
RUN dotnet restore "./MCBDS.API/MCBDS.API.csproj"
COPY . .
WORKDIR "/src/MCBDS.API"
RUN dotnet build "./MCBDS.API.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./MCBDS.API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app

# Install curl for healthcheck
USER root
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /app/logs /app/backups /https && \
    chmod 755 /app/logs /app/backups /https

# Copy the published app
COPY --from=publish /app/publish .

# Set ownership to app user
RUN chown -R $APP_UID:$APP_UID /app

USER $APP_UID
ENTRYPOINT ["dotnet", "MCBDS.API.dll"]
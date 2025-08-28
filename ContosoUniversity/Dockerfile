# Use the official .NET 9 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# Use the official .NET 9 ASP.NET Core runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Install required packages for Application Insights and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security first
RUN addgroup --system --gid 1001 dotnet \
    && adduser --system --uid 1001 --gid 1001 dotnet

# Copy the published app and set permissions
COPY --from=build /app/publish .
RUN chown -R dotnet:dotnet /app

USER dotnet

# Expose port 8080 (Container Apps default)
EXPOSE 8080

# Configure ASP.NET Core to bind to port 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "ContosoUniversity.dll"]
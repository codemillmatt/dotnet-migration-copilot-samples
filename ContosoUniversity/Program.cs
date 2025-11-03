using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using ContosoUniversity.Configuration;
using ContosoUniversity.Services;
using ContosoUniversity.Data;
using System;

var builder = WebApplication.CreateBuilder(args);

// Configure logging early
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
if (builder.Environment.IsDevelopment())
{
    builder.Logging.AddDebug();
}

var logger = LoggerFactory.Create(config => config.AddConsole()).CreateLogger<Program>();

try
{
    logger.LogInformation("Starting Contoso University application...");
    logger.LogInformation("Environment: {Environment}", builder.Environment.EnvironmentName);

    // Log configuration for debugging
    logger.LogInformation("Configuration Sources:");
    foreach (var source in builder.Configuration.Sources)
    {
        logger.LogInformation("  - {Source}", source.GetType().Name);
    }

    // Add Application Insights telemetry
    var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
    if (!string.IsNullOrEmpty(appInsightsConnectionString))
    {
        logger.LogInformation("Application Insights configured");
        builder.Services.AddApplicationInsightsTelemetry(appInsightsConnectionString);
    }
    else
    {
        logger.LogWarning("Application Insights not configured - APPLICATIONINSIGHTS_CONNECTION_STRING is missing");
    }

    // Build connection string from environment variables
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    if (string.IsNullOrEmpty(connectionString))
    {
        connectionString = builder.Configuration["ConnectionStrings__DefaultConnection"];
    }

    // If still empty, try to build from individual components
    if (string.IsNullOrEmpty(connectionString))
    {
        var sqlServer = builder.Configuration["AZURE_SQL_SERVER"];
        var sqlDatabase = builder.Configuration["AZURE_SQL_DATABASE"];
        
        if (!string.IsNullOrEmpty(sqlServer) && !string.IsNullOrEmpty(sqlDatabase))
        {
            connectionString = $"Server=tcp:{sqlServer}.database.windows.net;Database={sqlDatabase};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
            logger.LogInformation("Built connection string from environment variables");
        }
    }

    logger.LogInformation("Database connection string configured: {HasConnectionString}", !string.IsNullOrEmpty(connectionString));
    if (!string.IsNullOrEmpty(connectionString))
    {
        // Log connection details (without sensitive info)
        var serverMatch = System.Text.RegularExpressions.Regex.Match(connectionString, @"Server=tcp:([^;]+)");
        var databaseMatch = System.Text.RegularExpressions.Regex.Match(connectionString, @"Database=([^;]+)");
        if (serverMatch.Success && databaseMatch.Success)
        {
            logger.LogInformation("Connecting to SQL Server: {Server}, Database: {Database}", 
                serverMatch.Groups[1].Value, databaseMatch.Groups[1].Value);
        }
    }

    // Add Entity Framework DbContext with Azure SQL Database
    if (!string.IsNullOrEmpty(connectionString))
    {
        builder.Services.AddDbContext<SchoolContext>(options =>
        {
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorNumbersToAdd: null);
                sqlOptions.CommandTimeout(120);
            });
            
            if (builder.Environment.IsDevelopment())
            {
                options.EnableSensitiveDataLogging();
                options.EnableDetailedErrors();
            }
            
            options.LogTo(message => logger.LogInformation("EF Core: {Message}", message), Microsoft.Extensions.Logging.LogLevel.Information);
        });
        
        logger.LogInformation("Entity Framework DbContext configured for SQL Server with retry policy");
    }
    else
    {
        logger.LogError("Database connection string is not configured. Check environment variables.");
        throw new InvalidOperationException("Database connection string is not configured. Check environment variables.");
    }

    // Add services to the container
    builder.Services.AddControllersWithViews();

    // Configure session
    builder.Services.AddSession(options =>
    {
        options.IdleTimeout = TimeSpan.FromMinutes(30);
        options.Cookie.HttpOnly = true;
        options.Cookie.IsEssential = true;
    });

    // Configure notification queue options
    var serviceBusNamespace = builder.Configuration["NotificationQueue__ServiceBusNamespace"];
    if (string.IsNullOrEmpty(serviceBusNamespace))
    {
        serviceBusNamespace = builder.Configuration["AZURE_SERVICE_BUS_NAMESPACE"];
        if (!string.IsNullOrEmpty(serviceBusNamespace) && !serviceBusNamespace.EndsWith(".servicebus.windows.net"))
        {
            serviceBusNamespace += ".servicebus.windows.net";
        }
    }

    logger.LogInformation("Service Bus namespace: {ServiceBusNamespace}", serviceBusNamespace ?? "Not configured");

    builder.Services.Configure<NotificationQueueOptions>(options =>
    {
        options.ServiceBusNamespace = serviceBusNamespace ?? "";
        options.QueueName = builder.Configuration["NotificationQueue__QueueName"] ?? "notifications";
    });

    // Register NotificationService as a scoped service
    if (!string.IsNullOrEmpty(serviceBusNamespace))
    {
        builder.Services.AddScoped<NotificationService>();
        logger.LogInformation("NotificationService configured with Service Bus");
    }
    else
    {
        logger.LogWarning("NotificationService not configured - Service Bus namespace is missing");
        // Register a dummy service to prevent DI errors
        builder.Services.AddScoped<NotificationService>(provider => 
        {
            var dummyOptions = Microsoft.Extensions.Options.Options.Create(new NotificationQueueOptions());
            var dummyLogger = provider.GetRequiredService<ILogger<NotificationService>>();
            return new NotificationService(dummyOptions, dummyLogger);
        });
    }

    // Add health checks
    builder.Services.AddHealthChecks()
        .AddDbContextCheck<SchoolContext>("database")
        .AddCheck("self", () => HealthCheckResult.Healthy("Application is healthy"));

    var app = builder.Build();

    logger.LogInformation("Application built successfully");

    // Initialize database on startup (only in development or when explicitly enabled)
    var initializeDb = builder.Configuration.GetValue<bool>("InitializeDatabase", builder.Environment.IsDevelopment());
    if (initializeDb)
    {
        try
        {
            logger.LogInformation("Attempting to initialize database...");
            using var scope = app.Services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<SchoolContext>();
            
            // Test database connectivity
            await context.Database.CanConnectAsync();
            logger.LogInformation("Database connection test successful");
            
            DbInitializer.Initialize(context);
            logger.LogInformation("Database initialization completed successfully");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Database initialization failed: {Message}", ex.Message);
            if (builder.Environment.IsDevelopment())
            {
                throw;
            }
        }
    }

    // Configure the HTTP request pipeline
    if (!app.Environment.IsDevelopment())
    {
        app.UseExceptionHandler("/Home/Error");
        app.UseHsts();
    }

    app.UseStatusCodePagesWithReExecute("/Home/StatusErrorCode", "?code={0}");

    // Configure for reverse proxy (Container Apps)
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedFor | 
                          Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.XForwardedProto
    });

    // Don't redirect to HTTPS in container - let the reverse proxy handle it
    if (!app.Environment.IsProduction())
    {
        app.UseHttpsRedirection();
    }

    app.UseStaticFiles();

    app.UseRouting();
    app.UseSession();

    // Add health check endpoints
    app.MapHealthChecks("/health");
    app.MapHealthChecks("/healthz");

    app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}");

    // Log startup completion
    logger.LogInformation("Contoso University application configuration completed");
    logger.LogInformation("Health check endpoints: /health, /healthz");
    logger.LogInformation("Starting web host...");

    app.Run();
}
catch (Exception ex)
{
    logger.LogCritical(ex, "Application failed to start: {Message}", ex.Message);
    throw;
}
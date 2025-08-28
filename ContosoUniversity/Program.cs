using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ContosoUniversity.Configuration;
using ContosoUniversity.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSystemWebAdapters()
    .AddWrappedAspNetCoreSession()
    .AddJsonSessionSerializer(options =>
    {
        options.RegisterKey<string>("MachineName");
        options.RegisterKey<string>("SessionStartTime");
    })
    .AddHttpApplication<MvcApplication>();

// Add services to the container.
builder.Services.AddControllersWithViews();

// Configure notification queue options
builder.Services.Configure<NotificationQueueOptions>(
    builder.Configuration.GetSection(NotificationQueueOptions.SectionName));

// Register NotificationService as a scoped service
builder.Services.AddScoped<NotificationService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error"); // Global error handler
    app.UseHsts();
}
else
{
    app.UseExceptionHandler("/Home/Error"); // Global error handler for development too
}

app.UseStatusCodePagesWithReExecute("/Home/StatusErrorCode", "?code={0}");

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseSession();
app.UseSystemWebAdapters();

app.MapControllers()
    .RequireSystemWebAdapterSession();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .RequireSystemWebAdapterSession();

app.Run();
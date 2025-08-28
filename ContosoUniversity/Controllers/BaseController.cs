using System;
using ContosoUniversity.Services;
using ContosoUniversity.Models;
using ContosoUniversity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Controllers
{
    public abstract class BaseController : Controller
    {
        protected SchoolContext db;
        protected readonly NotificationService notificationService;
        protected readonly ILogger<BaseController> logger;

        public BaseController(NotificationService notificationService, ILogger<BaseController> logger)
        {
            this.notificationService = notificationService;
            this.logger = logger;
            db = SchoolContextFactory.Create();
        }

        protected void SendEntityNotification(string entityType, string entityId, EntityOperation operation)
        {
            SendEntityNotification(entityType, entityId, null, operation);
        }

        protected void SendEntityNotification(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            try
            {
                var userName = "System"; // No authentication, use System as default user
                notificationService.SendNotification(entityType, entityId, entityDisplayName, operation, userName);
            }
            catch (Exception ex)
            {
                // Log the error but don't break the main operation
                logger.LogError(ex, "Failed to send notification for {EntityType} {Operation}", entityType, operation);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db?.Dispose();
                // NotificationService is now managed by DI container, so we don't dispose it manually
            }
            base.Dispose(disposing);
        }
    }
}

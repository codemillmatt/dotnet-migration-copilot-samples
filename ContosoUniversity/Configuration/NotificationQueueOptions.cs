using System;

namespace ContosoUniversity.Configuration
{
    public class NotificationQueueOptions
    {
        public const string SectionName = "NotificationQueue";
        
        /// <summary>
        /// The fully qualified namespace of the Azure Service Bus (e.g., myservicebus.servicebus.windows.net)
        /// </summary>
        public string ServiceBusNamespace { get; set; } = string.Empty;
        
        /// <summary>
        /// The name of the Service Bus queue for notifications
        /// </summary>
        public string QueueName { get; set; } = "notifications";
        
        // Legacy property for backward compatibility
        [Obsolete("Use ServiceBusNamespace and QueueName instead")]
        public string QueuePath { get; set; } = ".\\Private$\\ContosoUniversityNotifications";
    }
}
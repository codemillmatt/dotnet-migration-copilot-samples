using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Azure.Identity;
using ContosoUniversity.Models;
using ContosoUniversity.Configuration;
using Newtonsoft.Json;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Services
{
    public class NotificationService : IDisposable
    {
        private readonly ServiceBusClient? _serviceBusClient;
        private readonly ServiceBusSender? _sender;
        private readonly string _queueName;
        private readonly ILogger<NotificationService> _logger;
        private readonly bool _isConfigured;

        public NotificationService(IOptions<NotificationQueueOptions> queueOptions, ILogger<NotificationService> logger)
        {
            _logger = logger;
            _queueName = queueOptions.Value.QueueName;
            
            try
            {
                var fullyQualifiedNamespace = queueOptions.Value.ServiceBusNamespace;
                
                if (string.IsNullOrEmpty(fullyQualifiedNamespace))
                {
                    _logger.LogWarning("Service Bus namespace not configured. Notification service will operate in dummy mode.");
                    _isConfigured = false;
                    return;
                }

                // Use Managed Identity to connect to Service Bus
                _serviceBusClient = new ServiceBusClient(fullyQualifiedNamespace, new DefaultAzureCredential());
                _sender = _serviceBusClient.CreateSender(_queueName);
                _isConfigured = true;
                
                _logger.LogInformation("NotificationService initialized with Service Bus namespace: {Namespace}", fullyQualifiedNamespace);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize NotificationService with Service Bus. Operating in dummy mode.");
                _isConfigured = false;
            }
        }

        public async Task SendNotificationAsync(string entityType, string entityId, EntityOperation operation, string userName = null)
        {
            await SendNotificationAsync(entityType, entityId, null, operation, userName);
        }

        public async Task SendNotificationAsync(string entityType, string entityId, string entityDisplayName, EntityOperation operation, string userName = null)
        {
            if (!_isConfigured || _sender == null)
            {
                _logger.LogWarning("Service Bus not configured. Notification not sent for {EntityType} {Operation}", entityType, operation);
                return;
            }

            try
            {
                var notification = new Notification
                {
                    EntityType = entityType,
                    EntityId = entityId,
                    Operation = operation.ToString(),
                    Message = GenerateMessage(entityType, entityId, entityDisplayName, operation),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userName ?? "System",
                    IsRead = false
                };

                var jsonMessage = JsonConvert.SerializeObject(notification);
                var serviceBusMessage = new ServiceBusMessage(jsonMessage)
                {
                    Subject = $"{entityType}_{operation}",
                    MessageId = Guid.NewGuid().ToString(),
                    ContentType = "application/json"
                };

                await _sender.SendMessageAsync(serviceBusMessage);
                _logger.LogInformation("Notification sent to Service Bus for {EntityType} {Operation}", entityType, operation);
            }
            catch (Exception ex)
            {
                // Log error but don't break the main operation
                _logger.LogError(ex, "Failed to send notification for {EntityType} {Operation}", entityType, operation);
            }
        }

        public async Task<Notification?> ReceiveNotificationAsync()
        {
            if (!_isConfigured || _serviceBusClient == null)
            {
                _logger.LogWarning("Service Bus not configured. Cannot receive notifications.");
                return null;
            }

            try
            {
                await using var receiver = _serviceBusClient.CreateReceiver(_queueName);
                var receivedMessage = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(1));
                
                if (receivedMessage != null)
                {
                    var jsonContent = receivedMessage.Body.ToString();
                    var notification = JsonConvert.DeserializeObject<Notification>(jsonContent);
                    
                    // Complete the message to remove it from the queue
                    await receiver.CompleteMessageAsync(receivedMessage);
                    
                    return notification;
                }
                
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to receive notification from Service Bus");
                return null;
            }
        }

        public void MarkAsRead(int notificationId)
        {
            // In a real implementation, you might want to store notifications in database as well
            // for persistence and tracking read status
            _logger.LogInformation("Notification {NotificationId} marked as read", notificationId);
        }

        private string GenerateMessage(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            var displayText = !string.IsNullOrWhiteSpace(entityDisplayName) 
                ? $"{entityType} '{entityDisplayName}'" 
                : $"{entityType} (ID: {entityId})";

            return operation switch
            {
                EntityOperation.CREATE => $"New {displayText} has been created",
                EntityOperation.UPDATE => $"{displayText} has been updated",
                EntityOperation.DELETE => $"{displayText} has been deleted",
                _ => $"{displayText} operation: {operation}"
            };
        }

        public void Dispose()
        {
            if (_isConfigured)
            {
                _sender?.DisposeAsync().AsTask().Wait();
                _serviceBusClient?.DisposeAsync().AsTask().Wait();
            }
        }
    }
}

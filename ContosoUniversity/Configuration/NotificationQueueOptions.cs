namespace ContosoUniversity.Configuration
{
    public class NotificationQueueOptions
    {
        public const string SectionName = "NotificationQueue";
        
        public string QueuePath { get; set; } = ".\\Private$\\ContosoUniversityNotifications";
    }
}
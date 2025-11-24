using System;

namespace DocumentGenerator.Core.Entities
{
    public class Document
    {
        public Guid Id { get; set; }
        public Guid TemplateId { get; set; }
        public Guid UserId { get; set; }
        public string StoragePath { get; set; } = string.Empty;
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
        public string Metadata { get; set; } = string.Empty;

        // Navigation property
        public Template? Template { get; set; }
    }
}

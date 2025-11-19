using System;

namespace DocumentGenerator.Core.Entities
{
    public class Template
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public Guid CreatedByUserId { get; set; }
    }
}

using System.ComponentModel.DataAnnotations;

namespace DocumentGenerator.Core.DTOs
{
    public class TemplateDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class CreateTemplateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public string Content { get; set; } = string.Empty;
    }

    public class UpdateTemplateDto
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? Content { get; set; }
    }
}

using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace DocumentGenerator.Core.DTOs
{
    public class GenerationRequestDto
    {
        [Required]
        public Guid TemplateId { get; set; }

        [Required]
        public object Data { get; set; } = new object();
    }

    public class DocumentDto
    {
        public Guid Id { get; set; }
        public Guid TemplateId { get; set; }
        public string TemplateName { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public DateTime GeneratedAt { get; set; }
        public string DownloadUrl { get; set; } = string.Empty;
    }
}

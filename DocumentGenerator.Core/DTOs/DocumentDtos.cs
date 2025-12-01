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
        public string FileName { get; set; } = string.Empty;
        public string Metadata { get; set; } = string.Empty;
    }

    public class BatchGenerationRequestDto
    {
        [Required]
        public Guid TemplateId { get; set; }

        [Required]
        [MinLength(1, ErrorMessage = "At least one data item is required")]
        [MaxLength(100, ErrorMessage = "Batch size cannot exceed 100 items")]
        public List<object> DataItems { get; set; } = new();
    }

    public class BatchGenerationResultDto
    {
        public int TotalRequested { get; set; }
        public int SuccessCount { get; set; }
        public int FailureCount { get; set; }
        public List<DocumentDto> Documents { get; set; } = new();
        public List<BatchGenerationError> Errors { get; set; } = new();
    }

    public class BatchGenerationError
    {
        public int Index { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}

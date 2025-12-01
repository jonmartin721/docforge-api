using DocumentGenerator.Core.DTOs;

namespace DocumentGenerator.Core.Interfaces
{
    public interface IDocumentService
    {
        Task<DocumentDto> GenerateDocumentAsync(GenerationRequestDto request, Guid userId);
        Task<BatchGenerationResultDto> GenerateDocumentBatchAsync(BatchGenerationRequestDto request, Guid userId);
        Task<DocumentDto?> GetByIdAsync(Guid id, Guid userId);
        Task<PaginatedResult<DocumentDto>> GetAllAsync(Guid userId, int page = 1, int pageSize = 20);
        Task<(byte[] FileData, string FileName)?> GetDocumentFileAsync(Guid id, Guid userId);
        Task<bool> DeleteAsync(Guid id, Guid userId);
        Task DeleteByTemplateIdAsync(Guid templateId);
    }
}

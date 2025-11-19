using DocumentGenerator.Core.DTOs;

namespace DocumentGenerator.Core.Interfaces
{
    public interface IDocumentService
    {
        Task<DocumentDto> GenerateDocumentAsync(GenerationRequestDto request, Guid userId);
        Task<DocumentDto?> GetByIdAsync(Guid id, Guid userId);
        Task<IEnumerable<DocumentDto>> GetAllAsync(Guid userId);
        Task<(byte[] FileData, string FileName)?> GetDocumentFileAsync(Guid id, Guid userId);
        Task<bool> DeleteAsync(Guid id, Guid userId);
    }
}

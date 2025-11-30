using DocumentGenerator.Core.DTOs;

namespace DocumentGenerator.Core.Interfaces
{
    public interface ITemplateService
    {
        Task<PaginatedResult<TemplateDto>> GetAllAsync(Guid userId, int page = 1, int pageSize = 20);
        Task<TemplateDto?> GetByIdAsync(Guid id, Guid userId);
        Task<TemplateDto> CreateAsync(CreateTemplateDto createDto, Guid userId);
        Task<TemplateDto?> UpdateAsync(Guid id, UpdateTemplateDto updateDto, Guid userId);
        Task<bool> DeleteAsync(Guid id, Guid userId);
    }
}

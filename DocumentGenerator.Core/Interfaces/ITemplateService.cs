using DocumentGenerator.Core.DTOs;

namespace DocumentGenerator.Core.Interfaces
{
    public interface ITemplateService
    {
        Task<IEnumerable<TemplateDto>> GetAllAsync();
        Task<TemplateDto?> GetByIdAsync(Guid id);
        Task<TemplateDto> CreateAsync(CreateTemplateDto createDto, Guid userId);
        Task<TemplateDto?> UpdateAsync(Guid id, UpdateTemplateDto updateDto);
        Task<bool> DeleteAsync(Guid id);
    }
}

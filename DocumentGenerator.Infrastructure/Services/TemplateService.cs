using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using HandlebarsDotNet;

namespace DocumentGenerator.Infrastructure.Services
{
    public class TemplateService : ITemplateService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly IDocumentService _documentService;

        public TemplateService(ApplicationDbContext context, IMapper mapper, IDocumentService documentService)
        {
            _context = context;
            _mapper = mapper;
            _documentService = documentService;
        }

        public async Task<IEnumerable<TemplateDto>> GetAllAsync()
        {
            var templates = await _context.Templates.ToListAsync();
            return _mapper.Map<IEnumerable<TemplateDto>>(templates);
        }

        public async Task<TemplateDto?> GetByIdAsync(Guid id)
        {
            var template = await _context.Templates.FindAsync(id);
            return template == null ? null : _mapper.Map<TemplateDto>(template);
        }

        public async Task<TemplateDto> CreateAsync(CreateTemplateDto createDto, Guid userId)
        {
            // Validate Handlebars syntax
            try
            {
                Handlebars.Compile(createDto.Content);
            }
            catch (Exception ex)
            {
                throw new ArgumentException($"Invalid template syntax: {ex.Message}");
            }

            var template = _mapper.Map<Template>(createDto);
            template.Id = Guid.NewGuid();
            template.CreatedByUserId = userId;
            template.CreatedAt = DateTime.UtcNow;

            _context.Templates.Add(template);
            await _context.SaveChangesAsync();

            return _mapper.Map<TemplateDto>(template);
        }

        public async Task<TemplateDto?> UpdateAsync(Guid id, UpdateTemplateDto updateDto)
        {
            var template = await _context.Templates.FindAsync(id);
            if (template == null) return null;

            if (!string.IsNullOrEmpty(updateDto.Content))
            {
                try
                {
                    Handlebars.Compile(updateDto.Content);
                }
                catch (Exception ex)
                {
                    throw new ArgumentException($"Invalid template syntax: {ex.Message}");
                }
                template.Content = updateDto.Content;
            }

            if (!string.IsNullOrEmpty(updateDto.Name)) template.Name = updateDto.Name;
            if (!string.IsNullOrEmpty(updateDto.Description)) template.Description = updateDto.Description;
            
            template.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return _mapper.Map<TemplateDto>(template);
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var template = await _context.Templates.FindAsync(id);
            if (template == null) return false;

            await _documentService.DeleteByTemplateIdAsync(id);

            _context.Templates.Remove(template);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

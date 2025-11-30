using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Exceptions;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Infrastructure.Data;
using HandlebarsDotNet;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DocumentGenerator.Infrastructure.Services
{
    public class TemplateService : ITemplateService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly IDocumentService _documentService;
        private readonly ILogger<TemplateService> _logger;

        public TemplateService(
            ApplicationDbContext context,
            IMapper mapper,
            IDocumentService documentService,
            ILogger<TemplateService> logger)
        {
            _context = context;
            _mapper = mapper;
            _documentService = documentService;
            _logger = logger;
        }

        public async Task<PaginatedResult<TemplateDto>> GetAllAsync(Guid userId, int page = 1, int pageSize = 20)
        {
            var query = _context.Templates.Where(t => t.CreatedByUserId == userId);

            var totalCount = await query.CountAsync();
            var templates = await query
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = _mapper.Map<IEnumerable<TemplateDto>>(templates);

            _logger.LogDebug("Retrieved {Count} templates for user {UserId} (page {Page})", templates.Count, userId, page);
            return PaginatedResult<TemplateDto>.Create(items, totalCount, page, pageSize);
        }

        public async Task<TemplateDto?> GetByIdAsync(Guid id, Guid userId)
        {
            var template = await _context.Templates
                .FirstOrDefaultAsync(t => t.Id == id && t.CreatedByUserId == userId);

            if (template == null)
            {
                _logger.LogDebug("Template {TemplateId} not found or not owned by user {UserId}", id, userId);
                return null;
            }

            return _mapper.Map<TemplateDto>(template);
        }

        public async Task<TemplateDto> CreateAsync(CreateTemplateDto createDto, Guid userId)
        {
            try
            {
                Handlebars.Compile(createDto.Content);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Template compilation failed: {Message}", ex.Message);
                throw new TemplateCompilationException(ex.Message, ex);
            }

            var template = _mapper.Map<Template>(createDto);
            template.Id = Guid.NewGuid();
            template.CreatedByUserId = userId;
            template.CreatedAt = DateTime.UtcNow;

            _context.Templates.Add(template);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Template {TemplateId} created by user {UserId}: {TemplateName}",
                template.Id, userId, template.Name);
            return _mapper.Map<TemplateDto>(template);
        }

        public async Task<TemplateDto?> UpdateAsync(Guid id, UpdateTemplateDto updateDto, Guid userId)
        {
            var template = await _context.Templates
                .FirstOrDefaultAsync(t => t.Id == id && t.CreatedByUserId == userId);

            if (template == null)
            {
                _logger.LogDebug("Template {TemplateId} not found or not owned by user {UserId} for update", id, userId);
                return null;
            }

            if (!string.IsNullOrEmpty(updateDto.Content))
            {
                try
                {
                    Handlebars.Compile(updateDto.Content);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning("Template compilation failed during update: {Message}", ex.Message);
                    throw new TemplateCompilationException(ex.Message, ex);
                }
                template.Content = updateDto.Content;
            }

            if (!string.IsNullOrEmpty(updateDto.Name)) template.Name = updateDto.Name;
            if (!string.IsNullOrEmpty(updateDto.Description)) template.Description = updateDto.Description;

            template.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Template {TemplateId} updated by user {UserId}", id, userId);
            return _mapper.Map<TemplateDto>(template);
        }

        public async Task<bool> DeleteAsync(Guid id, Guid userId)
        {
            var template = await _context.Templates
                .FirstOrDefaultAsync(t => t.Id == id && t.CreatedByUserId == userId);

            if (template == null)
            {
                _logger.LogDebug("Template {TemplateId} not found or not owned by user {UserId} for deletion", id, userId);
                return false;
            }

            await _documentService.DeleteByTemplateIdAsync(id);

            _context.Templates.Remove(template);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Template {TemplateId} deleted by user {UserId}", id, userId);
            return true;
        }
    }
}

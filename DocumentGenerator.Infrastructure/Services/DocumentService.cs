using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Infrastructure.Data;
using HandlebarsDotNet;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace DocumentGenerator.Infrastructure.Services
{
    public class DocumentService : IDocumentService
    {
        private readonly ApplicationDbContext _context;
        private readonly IPdfService _pdfService;
        private readonly IMapper _mapper;
        private readonly ILogger<DocumentService> _logger;
        private readonly string _storagePath;

        public DocumentService(
            ApplicationDbContext context,
            IPdfService pdfService,
            IMapper mapper,
            ILogger<DocumentService> logger)
        {
            _context = context;
            _pdfService = pdfService;
            _mapper = mapper;
            _logger = logger;
            _storagePath = Path.Combine(Directory.GetCurrentDirectory(), "GeneratedDocuments");
            if (!Directory.Exists(_storagePath))
            {
                Directory.CreateDirectory(_storagePath);
            }
        }

        public async Task<DocumentDto> GenerateDocumentAsync(GenerationRequestDto request, Guid userId)
        {
            var template = await _context.Templates.FindAsync(request.TemplateId);
            if (template == null)
            {
                _logger.LogWarning("Template {TemplateId} not found for document generation", request.TemplateId);
                throw new KeyNotFoundException("Template not found");
            }

            _logger.LogInformation("Generating document from template {TemplateId} for user {UserId}", request.TemplateId, userId);

            // 1. Compile Handlebars
            var compiledTemplate = Handlebars.Compile(template.Content);
            var htmlContent = compiledTemplate(request.Data);

            // 2. Generate PDF
            var pdfBytes = await _pdfService.GeneratePdfAsync(htmlContent);

            // 3. Save File
            var fileName = $"doc-{Guid.NewGuid()}.pdf";
            var filePath = Path.Combine(_storagePath, fileName);
            await File.WriteAllBytesAsync(filePath, pdfBytes);

            // 4. Save Entity
            var document = new Document
            {
                Id = Guid.NewGuid(),
                TemplateId = template.Id,
                UserId = userId,
                StoragePath = filePath,
                GeneratedAt = DateTime.UtcNow,
                Metadata = JsonSerializer.Serialize(request.Data)
            };

            _context.Documents.Add(document);
            await _context.SaveChangesAsync();

            var dto = _mapper.Map<DocumentDto>(document);
            dto.TemplateName = template.Name;
            dto.DownloadUrl = $"/api/documents/{document.Id}/download";

            _logger.LogInformation("Document {DocumentId} generated successfully ({Size} bytes)", document.Id, pdfBytes.Length);
            return dto;
        }

        public async Task<BatchGenerationResultDto> GenerateDocumentBatchAsync(BatchGenerationRequestDto request, Guid userId)
        {
            var result = new BatchGenerationResultDto
            {
                TotalRequested = request.DataItems.Count
            };

            var template = await _context.Templates.FindAsync(request.TemplateId);
            if (template == null)
            {
                _logger.LogWarning("Template {TemplateId} not found for batch document generation", request.TemplateId);
                throw new KeyNotFoundException("Template not found");
            }

            _logger.LogInformation("Starting batch generation of {Count} documents from template {TemplateId} for user {UserId}",
                request.DataItems.Count, request.TemplateId, userId);

            var compiledTemplate = Handlebars.Compile(template.Content);

            for (int i = 0; i < request.DataItems.Count; i++)
            {
                try
                {
                    var data = request.DataItems[i];
                    var htmlContent = compiledTemplate(data);
                    var pdfBytes = await _pdfService.GeneratePdfAsync(htmlContent);

                    var fileName = $"doc-{Guid.NewGuid()}.pdf";
                    var filePath = Path.Combine(_storagePath, fileName);
                    await File.WriteAllBytesAsync(filePath, pdfBytes);

                    var document = new Document
                    {
                        Id = Guid.NewGuid(),
                        TemplateId = template.Id,
                        UserId = userId,
                        StoragePath = filePath,
                        GeneratedAt = DateTime.UtcNow,
                        Metadata = JsonSerializer.Serialize(data)
                    };

                    _context.Documents.Add(document);

                    var dto = _mapper.Map<DocumentDto>(document);
                    dto.TemplateName = template.Name;
                    dto.DownloadUrl = $"/api/documents/{document.Id}/download";

                    result.Documents.Add(dto);
                    result.SuccessCount++;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to generate document at index {Index} in batch", i);
                    result.Errors.Add(new BatchGenerationError
                    {
                        Index = i,
                        Message = ex.Message
                    });
                    result.FailureCount++;
                }
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Batch generation completed: {Success} succeeded, {Failed} failed",
                result.SuccessCount, result.FailureCount);

            return result;
        }

        public async Task<DocumentDto?> GetByIdAsync(Guid id, Guid userId)
        {
            var document = await _context.Documents
                .Include(d => d.Template)
                .FirstOrDefaultAsync(d => d.Id == id && d.UserId == userId);

            if (document == null) return null;

            var dto = _mapper.Map<DocumentDto>(document);
            dto.TemplateName = document.Template?.Name ?? "Unknown";
            dto.DownloadUrl = $"/api/documents/{document.Id}/download";

            return dto;
        }

        public async Task<PaginatedResult<DocumentDto>> GetAllAsync(Guid userId, int page = 1, int pageSize = 20)
        {
            var query = _context.Documents
                .Include(d => d.Template)
                .Where(d => d.UserId == userId);

            var totalCount = await query.CountAsync();
            var documents = await query
                .OrderByDescending(d => d.GeneratedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = documents.Select(doc =>
            {
                var dto = _mapper.Map<DocumentDto>(doc);
                dto.TemplateName = doc.Template?.Name ?? "Unknown";
                dto.DownloadUrl = $"/api/documents/{doc.Id}/download";
                return dto;
            });

            _logger.LogDebug("Retrieved {Count} documents for user {UserId} (page {Page})", documents.Count, userId, page);
            return PaginatedResult<DocumentDto>.Create(items, totalCount, page, pageSize);
        }

        public async Task<(byte[] FileData, string FileName)?> GetDocumentFileAsync(Guid id, Guid userId)
        {
            var document = await _context.Documents.FindAsync(id);
            if (document == null || document.UserId != userId) return null;

            if (!File.Exists(document.StoragePath))
                throw new FileNotFoundException("Document file not found on server");

            var bytes = await File.ReadAllBytesAsync(document.StoragePath);
            return (bytes, Path.GetFileName(document.StoragePath));
        }

        public async Task<bool> DeleteAsync(Guid id, Guid userId)
        {
            var document = await _context.Documents.FindAsync(id);
            if (document == null || document.UserId != userId)
            {
                _logger.LogDebug("Document {DocumentId} not found or not owned by user {UserId} for deletion", id, userId);
                return false;
            }

            DeleteFileIfExists(document.StoragePath);

            _context.Documents.Remove(document);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Document {DocumentId} deleted by user {UserId}", id, userId);
            return true;
        }

        public async Task DeleteByTemplateIdAsync(Guid templateId)
        {
            var documents = await _context.Documents
                .Where(d => d.TemplateId == templateId)
                .ToListAsync();

            foreach (var doc in documents)
            {
                DeleteFileIfExists(doc.StoragePath);
                _context.Documents.Remove(doc);
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Deleted {Count} documents for template {TemplateId}", documents.Count, templateId);
        }

        private void DeleteFileIfExists(string path)
        {
            if (File.Exists(path))
            {
                try
                {
                    File.Delete(path);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete file at path: {Path}", path);
                }
            }
        }
    }
}

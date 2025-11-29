using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Infrastructure.Data;
using HandlebarsDotNet;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace DocumentGenerator.Infrastructure.Services
{
    public class DocumentService : IDocumentService
    {
        private readonly ApplicationDbContext _context;
        private readonly IPdfService _pdfService;
        private readonly IMapper _mapper;
        private readonly string _storagePath;

        public DocumentService(ApplicationDbContext context, IPdfService pdfService, IMapper mapper)
        {
            _context = context;
            _pdfService = pdfService;
            _mapper = mapper;
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
                throw new KeyNotFoundException("Template not found");

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

            return dto;
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

        public async Task<IEnumerable<DocumentDto>> GetAllAsync(Guid userId)
        {
            var documents = await _context.Documents
                .Include(d => d.Template)
                .Where(d => d.UserId == userId)
                .OrderByDescending(d => d.GeneratedAt)
                .ToListAsync();

            return documents.Select(doc =>
            {
                var dto = _mapper.Map<DocumentDto>(doc);
                dto.TemplateName = doc.Template?.Name ?? "Unknown";
                dto.DownloadUrl = $"/api/documents/{doc.Id}/download";
                return dto;
            });
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
            if (document == null || document.UserId != userId) return false;

            DeleteFileIfExists(document.StoragePath);

            _context.Documents.Remove(document);
            await _context.SaveChangesAsync();
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
        }
        private void DeleteFileIfExists(string path)
        {
            if (File.Exists(path))
            {
                try
                {
                    File.Delete(path);
                }
                catch (Exception)
                {
                    // Log error or ignore if file deletion fails
                }
            }
        }
    }
}

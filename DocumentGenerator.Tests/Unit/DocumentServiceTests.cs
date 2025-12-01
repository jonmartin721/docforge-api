using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Core.Settings;
using DocumentGenerator.Infrastructure.Data;
using DocumentGenerator.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class DocumentServiceTests : IDisposable
    {
        private readonly DocumentService _documentService;
        private readonly ApplicationDbContext _context;
        private readonly Mock<ITemplateService> _mockTemplateService;
        private readonly Mock<IPdfService> _mockPdfService;
        private readonly Mock<IMapper> _mockMapper;
        private readonly Mock<ILogger<DocumentService>> _mockLogger;

        public DocumentServiceTests()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
                .Options;
            _context = new ApplicationDbContext(options);

            _mockTemplateService = new Mock<ITemplateService>();
            _mockPdfService = new Mock<IPdfService>();
            _mockMapper = new Mock<IMapper>();
            _mockLogger = new Mock<ILogger<DocumentService>>();

            var storageSettings = Options.Create(new StorageSettings { DocumentsPath = Path.Combine(Path.GetTempPath(), "TestDocs_" + Guid.NewGuid()) });

            _documentService = new DocumentService(_context, _mockPdfService.Object, _mockMapper.Object, _mockLogger.Object, storageSettings);
        }

        public void Dispose()
        {
            _context.Database.EnsureDeleted();
            _context.Dispose();
        }

        [Fact]
        public async Task GenerateDocumentAsync_ShouldCreateDocument_WhenValidRequest()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var requestDto = new GenerationRequestDto
            {
                TemplateId = templateId,
                Data = new { Name = "Test" }
            };

            var template = new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>{{Name}}</h1>",
                CreatedByUserId = userId
            };

            // DocumentService uses context directly, so we add template to context.

            _context.Templates.Add(template);
            await _context.SaveChangesAsync();

            _mockPdfService.Setup(s => s.GeneratePdfAsync(It.IsAny<string>()))
                .ReturnsAsync(new byte[] { 1, 2, 3 });

            _mockMapper.Setup(m => m.Map<DocumentDto>(It.IsAny<Document>()))
                .Returns((Document d) => new DocumentDto { Id = d.Id, TemplateName = "Test Template", DownloadUrl = "url" });

            // Act
            var result = await _documentService.GenerateDocumentAsync(requestDto, userId);

            // Assert
            result.Should().NotBeNull();
            result.TemplateName.Should().Be("Test Template");

            var doc = await _context.Documents.FindAsync(result.Id);
            doc.Should().NotBeNull();
            doc!.StoragePath.Should().NotBeEmpty();
        }

        [Fact]
        public async Task GetByIdAsync_ShouldReturnDocument_WhenExists()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var document = new Document
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                TemplateId = templateId,
                StoragePath = "path/to/file",
                GeneratedAt = DateTime.UtcNow
            };
            _context.Documents.Add(document);

            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            await _context.SaveChangesAsync();

            _mockMapper.Setup(m => m.Map<DocumentDto>(It.IsAny<Document>()))
                .Returns(new DocumentDto { Id = document.Id, TemplateName = "Test", DownloadUrl = "url" });

            // Act
            var result = await _documentService.GetByIdAsync(document.Id, userId);

            // Assert
            result.Should().NotBeNull();
            result.Id.Should().Be(document.Id);
        }

        [Fact]
        public async Task GetByIdAsync_ShouldReturnNull_WhenNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Act
            var result = await _documentService.GetByIdAsync(Guid.NewGuid(), userId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task GetAllAsync_ShouldReturnPaginatedResults()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            // Add 5 documents
            for (int i = 0; i < 5; i++)
            {
                _context.Documents.Add(new Document
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    TemplateId = templateId,
                    StoragePath = $"path/to/file{i}",
                    GeneratedAt = DateTime.UtcNow.AddMinutes(-i)
                });
            }
            await _context.SaveChangesAsync();

            _mockMapper.Setup(m => m.Map<DocumentDto>(It.IsAny<Document>()))
                .Returns((Document d) => new DocumentDto { Id = d.Id, TemplateName = "Test", DownloadUrl = "url" });

            // Act - request page 1 with page size 2
            var result = await _documentService.GetAllAsync(userId, page: 1, pageSize: 2);

            // Assert
            result.Should().NotBeNull();
            result.Items.Should().HaveCount(2);
            result.TotalCount.Should().Be(5);
            result.Page.Should().Be(1);
            result.PageSize.Should().Be(2);
            result.TotalPages.Should().Be(3);
        }

        [Fact]
        public async Task GetAllAsync_ShouldReturnEmptyForDifferentUser()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            _context.Documents.Add(new Document
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                TemplateId = templateId,
                StoragePath = "path/to/file",
                GeneratedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _documentService.GetAllAsync(otherUserId);

            // Assert
            result.Items.Should().BeEmpty();
            result.TotalCount.Should().Be(0);
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnTrue_WhenDocumentExists()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var documentId = Guid.NewGuid();

            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            var document = new Document
            {
                Id = documentId,
                UserId = userId,
                TemplateId = templateId,
                StoragePath = Path.Combine(Path.GetTempPath(), "nonexistent.pdf"),
                GeneratedAt = DateTime.UtcNow
            };
            _context.Documents.Add(document);
            await _context.SaveChangesAsync();

            // Act
            var result = await _documentService.DeleteAsync(documentId, userId);

            // Assert
            result.Should().BeTrue();
            var deletedDoc = await _context.Documents.FindAsync(documentId);
            deletedDoc.Should().BeNull();
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnFalse_WhenDocumentNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Act
            var result = await _documentService.DeleteAsync(Guid.NewGuid(), userId);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnFalse_WhenDifferentUserOwnsDocument()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var documentId = Guid.NewGuid();

            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            var document = new Document
            {
                Id = documentId,
                UserId = userId,
                TemplateId = templateId,
                StoragePath = "path/to/file.pdf",
                GeneratedAt = DateTime.UtcNow
            };
            _context.Documents.Add(document);
            await _context.SaveChangesAsync();

            // Act - try to delete with different user
            var result = await _documentService.DeleteAsync(documentId, otherUserId);

            // Assert
            result.Should().BeFalse();
            var doc = await _context.Documents.FindAsync(documentId);
            doc.Should().NotBeNull(); // Document should still exist
        }

        [Fact]
        public async Task GetDocumentFileAsync_ShouldReturnNull_WhenDocumentNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Act
            var result = await _documentService.GetDocumentFileAsync(Guid.NewGuid(), userId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task GetDocumentFileAsync_ShouldReturnNull_WhenDifferentUserOwnsDocument()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var documentId = Guid.NewGuid();

            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            var document = new Document
            {
                Id = documentId,
                UserId = userId,
                TemplateId = templateId,
                StoragePath = "path/to/file.pdf",
                GeneratedAt = DateTime.UtcNow
            };
            _context.Documents.Add(document);
            await _context.SaveChangesAsync();

            // Act
            var result = await _documentService.GetDocumentFileAsync(documentId, otherUserId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task GenerateDocumentAsync_ShouldThrow_WhenTemplateNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var requestDto = new GenerationRequestDto
            {
                TemplateId = Guid.NewGuid(),
                Data = new { Name = "Test" }
            };

            // Act
            Func<Task> act = async () => await _documentService.GenerateDocumentAsync(requestDto, userId);

            // Assert
            await act.Should().ThrowAsync<KeyNotFoundException>();
        }

        [Fact]
        public async Task DeleteByTemplateIdAsync_ShouldDeleteAllDocumentsForTemplate()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            var template = new Template { Id = templateId, Name = "Test", CreatedByUserId = userId };
            _context.Templates.Add(template);

            // Add 3 documents for this template
            for (int i = 0; i < 3; i++)
            {
                _context.Documents.Add(new Document
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    TemplateId = templateId,
                    StoragePath = Path.Combine(Path.GetTempPath(), $"doc{i}.pdf"),
                    GeneratedAt = DateTime.UtcNow
                });
            }
            await _context.SaveChangesAsync();

            // Act
            await _documentService.DeleteByTemplateIdAsync(templateId);

            // Assert
            var remainingDocs = await _context.Documents.Where(d => d.TemplateId == templateId).ToListAsync();
            remainingDocs.Should().BeEmpty();
        }

        [Fact]
        public async Task GenerateDocumentBatchAsync_ShouldGenerateMultipleDocuments()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            var template = new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>{{Name}}</h1>",
                CreatedByUserId = userId
            };
            _context.Templates.Add(template);
            await _context.SaveChangesAsync();

            var request = new BatchGenerationRequestDto
            {
                TemplateId = templateId,
                DataItems = new List<object>
                {
                    new { Name = "Doc1" },
                    new { Name = "Doc2" }
                }
            };

            _mockPdfService.Setup(s => s.GeneratePdfAsync(It.IsAny<string>()))
                .ReturnsAsync(new byte[] { 1, 2, 3 });

            _mockMapper.Setup(m => m.Map<DocumentDto>(It.IsAny<Document>()))
                .Returns((Document d) => new DocumentDto { Id = d.Id, TemplateName = "Test", DownloadUrl = "url" });

            // Act
            var result = await _documentService.GenerateDocumentBatchAsync(request, userId);

            // Assert
            result.Should().NotBeNull();
            result.TotalRequested.Should().Be(2);
            result.SuccessCount.Should().Be(2);
            result.Documents.Should().HaveCount(2);
        }

        [Fact]
        public async Task GenerateDocumentBatchAsync_ShouldThrow_WhenTemplateNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var request = new BatchGenerationRequestDto
            {
                TemplateId = Guid.NewGuid(),
                DataItems = new List<object> { new { Name = "Test" } }
            };

            // Act
            Func<Task> act = async () => await _documentService.GenerateDocumentBatchAsync(request, userId);

            // Assert
            await act.Should().ThrowAsync<KeyNotFoundException>();
        }
    }
}

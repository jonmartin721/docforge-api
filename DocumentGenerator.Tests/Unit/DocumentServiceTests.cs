using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Infrastructure.Data;
using DocumentGenerator.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
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

        public DocumentServiceTests()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            _context = new ApplicationDbContext(options);

            _mockTemplateService = new Mock<ITemplateService>();
            _mockPdfService = new Mock<IPdfService>();
            _mockMapper = new Mock<IMapper>();

            _documentService = new DocumentService(_context, _mockPdfService.Object, _mockMapper.Object);
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
    }
}

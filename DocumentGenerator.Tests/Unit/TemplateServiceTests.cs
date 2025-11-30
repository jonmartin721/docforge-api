using AutoMapper;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Exceptions;
using DocumentGenerator.Core.Mappings;
using DocumentGenerator.Infrastructure.Data;
using DocumentGenerator.Infrastructure.Services;
using DocumentGenerator.Core.Interfaces;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class TemplateServiceTests
    {
        private readonly TemplateService _templateService;
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly Mock<IDocumentService> _mockDocumentService;
        private readonly Mock<ILogger<TemplateService>> _mockLogger;

        public TemplateServiceTests()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            _context = new ApplicationDbContext(options);

            var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
            _mapper = config.CreateMapper();

            _mockDocumentService = new Mock<IDocumentService>();
            _mockLogger = new Mock<ILogger<TemplateService>>();
            _templateService = new TemplateService(_context, _mapper, _mockDocumentService.Object, _mockLogger.Object);
        }

        [Fact]
        public async Task CreateAsync_ShouldCreateTemplate_WhenValidHandlebars()
        {
            // Arrange
            var dto = new CreateTemplateDto
            {
                Name = "Invoice",
                Content = "<h1>{{title}}</h1>",
                Description = "Test Template"
            };
            var userId = Guid.NewGuid();

            // Act
            var result = await _templateService.CreateAsync(dto, userId);

            // Assert
            result.Should().NotBeNull();
            result.Name.Should().Be("Invoice");

            var template = await _context.Templates.FindAsync(result.Id);
            template.Should().NotBeNull();
            template!.Content.Should().Be("<h1>{{title}}</h1>");
        }

        [Fact]
        public async Task CreateAsync_ShouldThrow_WhenInvalidHandlebars()
        {
            // Arrange
            var dto = new CreateTemplateDto
            {
                Name = "Invoice",
                Content = "<h1>{{#if title}} unclosed block",
                Description = "Test Template"
            };
            var userId = Guid.NewGuid();

            // Act
            Func<Task> act = async () => await _templateService.CreateAsync(dto, userId);

            // Assert
            await act.Should().ThrowAsync<TemplateCompilationException>().WithMessage("*Invalid template syntax*");
        }
    }
}

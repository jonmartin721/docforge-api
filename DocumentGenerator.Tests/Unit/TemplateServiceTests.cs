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

        [Fact]
        public async Task GetAllAsync_ShouldReturnPaginatedResults()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Add 5 templates
            for (int i = 0; i < 5; i++)
            {
                _context.Templates.Add(new Template
                {
                    Id = Guid.NewGuid(),
                    Name = $"Template {i}",
                    Content = "<h1>Test</h1>",
                    CreatedByUserId = userId,
                    CreatedAt = DateTime.UtcNow.AddMinutes(-i)
                });
            }
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.GetAllAsync(userId, page: 1, pageSize: 2);

            // Assert
            result.Should().NotBeNull();
            result.Items.Should().HaveCount(2);
            result.TotalCount.Should().Be(5);
            result.TotalPages.Should().Be(3);
        }

        [Fact]
        public async Task GetAllAsync_ShouldReturnEmptyForDifferentUser()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = Guid.NewGuid(),
                Name = "Template",
                Content = "<h1>Test</h1>",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.GetAllAsync(otherUserId);

            // Assert
            result.Items.Should().BeEmpty();
            result.TotalCount.Should().Be(0);
        }

        [Fact]
        public async Task GetByIdAsync_ShouldReturnTemplate_WhenExists()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>Test</h1>",
                Description = "A test",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.GetByIdAsync(templateId, userId);

            // Assert
            result.Should().NotBeNull();
            result!.Id.Should().Be(templateId);
            result.Name.Should().Be("Test Template");
        }

        [Fact]
        public async Task GetByIdAsync_ShouldReturnNull_WhenNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Act
            var result = await _templateService.GetByIdAsync(Guid.NewGuid(), userId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task GetByIdAsync_ShouldReturnNull_WhenDifferentUserOwnsTemplate()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>Test</h1>",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.GetByIdAsync(templateId, otherUserId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task UpdateAsync_ShouldUpdateTemplate_WhenExists()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Original Name",
                Content = "<h1>Original</h1>",
                Description = "Original desc",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            var updateDto = new UpdateTemplateDto
            {
                Name = "Updated Name",
                Content = "<h1>Updated</h1>",
                Description = "Updated desc"
            };

            // Act
            var result = await _templateService.UpdateAsync(templateId, updateDto, userId);

            // Assert
            result.Should().NotBeNull();
            result!.Name.Should().Be("Updated Name");

            var template = await _context.Templates.FindAsync(templateId);
            template!.Content.Should().Be("<h1>Updated</h1>");
            template.UpdatedAt.Should().NotBeNull();
        }

        [Fact]
        public async Task UpdateAsync_ShouldReturnNull_WhenNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var updateDto = new UpdateTemplateDto { Name = "Updated" };

            // Act
            var result = await _templateService.UpdateAsync(Guid.NewGuid(), updateDto, userId);

            // Assert
            result.Should().BeNull();
        }

        [Fact]
        public async Task UpdateAsync_ShouldThrow_WhenInvalidHandlebars()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>Test</h1>",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            var updateDto = new UpdateTemplateDto
            {
                Content = "<h1>{{#if title}} unclosed block"
            };

            // Act
            Func<Task> act = async () => await _templateService.UpdateAsync(templateId, updateDto, userId);

            // Assert
            await act.Should().ThrowAsync<TemplateCompilationException>();
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnTrue_WhenExists()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>Test</h1>",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.DeleteAsync(templateId, userId);

            // Assert
            result.Should().BeTrue();
            var template = await _context.Templates.FindAsync(templateId);
            template.Should().BeNull();
            _mockDocumentService.Verify(s => s.DeleteByTemplateIdAsync(templateId), Times.Once);
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnFalse_WhenNotFound()
        {
            // Arrange
            var userId = Guid.NewGuid();

            // Act
            var result = await _templateService.DeleteAsync(Guid.NewGuid(), userId);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public async Task DeleteAsync_ShouldReturnFalse_WhenDifferentUserOwnsTemplate()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var otherUserId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            _context.Templates.Add(new Template
            {
                Id = templateId,
                Name = "Test Template",
                Content = "<h1>Test</h1>",
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            // Act
            var result = await _templateService.DeleteAsync(templateId, otherUserId);

            // Assert
            result.Should().BeFalse();
            var template = await _context.Templates.FindAsync(templateId);
            template.Should().NotBeNull(); // Template should still exist
        }
    }
}

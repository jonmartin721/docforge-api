using DocumentGenerator.API.Controllers;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Interfaces;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using System.Security.Claims;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class TemplatesControllerTests
    {
        private readonly TemplatesController _controller;
        private readonly Mock<ITemplateService> _mockTemplateService;
        private readonly Guid _userId;

        public TemplatesControllerTests()
        {
            _mockTemplateService = new Mock<ITemplateService>();
            _controller = new TemplatesController(_mockTemplateService.Object);
            _userId = Guid.NewGuid();

            // Setup User Context
            var user = new ClaimsPrincipal(new ClaimsIdentity(new Claim[]
            {
                new Claim(ClaimTypes.NameIdentifier, _userId.ToString())
            }, "mock"));

            _controller.ControllerContext = new ControllerContext()
            {
                HttpContext = new DefaultHttpContext() { User = user }
            };
        }

        [Fact]
        public async Task Create_ShouldReturnCreated_WhenValidRequest()
        {
            // Arrange
            var request = new CreateTemplateDto { Name = "Test", Content = "<h1>Test</h1>" };
            var expectedResponse = new TemplateDto { Id = Guid.NewGuid(), Name = "Test" };

            _mockTemplateService.Setup(s => s.CreateAsync(request, It.IsAny<Guid>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.Create(request);

            // Assert
            var createdResult = result.Result as CreatedAtActionResult;
            createdResult.Should().NotBeNull();
            createdResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task GetAll_ShouldReturnOk_WhenTemplatesExist()
        {
            // Arrange
            var templates = new List<TemplateDto>
            {
                new TemplateDto { Id = Guid.NewGuid(), Name = "T1" },
                new TemplateDto { Id = Guid.NewGuid(), Name = "T2" }
            };

            var paginatedResult = new PaginatedResult<TemplateDto>(templates, 2, 1, 20);

            _mockTemplateService.Setup(s => s.GetAllAsync(It.IsAny<Guid>(), 1, 20))
                .ReturnsAsync(paginatedResult);

            // Act
            var result = await _controller.GetAll();

            // Assert
            var okResult = result.Result as OkObjectResult;
            okResult.Should().NotBeNull();
            var returnedResult = okResult!.Value as PaginatedResult<TemplateDto>;
            returnedResult.Should().NotBeNull();
            returnedResult!.Items.Should().HaveCount(2);
        }
    }
}

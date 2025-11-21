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
    public class DocumentsControllerTests
    {
        private readonly DocumentsController _controller;
        private readonly Mock<IDocumentService> _mockDocumentService;

        public DocumentsControllerTests()
        {
            _mockDocumentService = new Mock<IDocumentService>();
            _controller = new DocumentsController(_mockDocumentService.Object);

            // Setup User Context
            var user = new ClaimsPrincipal(new ClaimsIdentity(new Claim[]
            {
                new Claim(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString())
            }, "mock"));

            _controller.ControllerContext = new ControllerContext()
            {
                HttpContext = new DefaultHttpContext() { User = user }
            };
        }

        [Fact]
        public async Task Generate_ShouldReturnOk_WhenValidRequest()
        {
            // Arrange
            var request = new GenerationRequestDto { TemplateId = Guid.NewGuid() };
            var expectedResponse = new DocumentDto { Id = Guid.NewGuid(), DownloadUrl = "http://test.com" };

            _mockDocumentService.Setup(s => s.GenerateDocumentAsync(request, It.IsAny<Guid>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _controller.Generate(request);

            // Assert
            var okResult = result.Result as OkObjectResult;
            okResult.Should().NotBeNull();
            okResult!.Value.Should().BeEquivalentTo(expectedResponse);
        }

        [Fact]
        public async Task Download_ShouldReturnFile_WhenDocumentExists()
        {
            // Arrange
            var docId = Guid.NewGuid();
            var fileContent = new byte[] { 1, 2, 3 };
            var fileName = "test.pdf";

            _mockDocumentService.Setup(s => s.GetDocumentFileAsync(docId, It.IsAny<Guid>()))
                .ReturnsAsync((fileContent, fileName));

            // Act
            var result = await _controller.Download(docId);

            // Assert
            var fileResult = result as FileContentResult;
            fileResult.Should().NotBeNull();
            fileResult!.FileContents.Should().BeEquivalentTo(fileContent);
            fileResult.ContentType.Should().Be("application/pdf");
            fileResult.FileDownloadName.Should().Be(fileName);
        }
    }
}

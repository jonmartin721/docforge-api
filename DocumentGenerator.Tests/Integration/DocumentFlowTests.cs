using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Infrastructure.Data;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net.Http.Json;
using Xunit;
using Moq;
using DocumentGenerator.Core.Interfaces;

namespace DocumentGenerator.Tests.Integration
{
    public class DocumentFlowTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;
        private readonly HttpClient _client;

        public DocumentFlowTests(WebApplicationFactory<Program> factory)
        {
            _factory = factory.WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    var descriptor = services.SingleOrDefault(
                        d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));

                    if (descriptor != null)
                    {
                        services.Remove(descriptor);
                    }

                    services.AddDbContext<ApplicationDbContext>(options =>
                    {
                        options.UseInMemoryDatabase("InMemoryDbForTesting");
                    });

                    var pdfServiceDescriptor = services.SingleOrDefault(d => d.ServiceType == typeof(IPdfService));
                    if (pdfServiceDescriptor != null) services.Remove(pdfServiceDescriptor);

                    var mockPdfService = new Mock<IPdfService>();
                    mockPdfService.Setup(x => x.GeneratePdfAsync(It.IsAny<string>()))
                        .ReturnsAsync(new byte[] { 0x01, 0x02, 0x03 });
                    services.AddSingleton(mockPdfService.Object);
                });
            });

            _client = _factory.CreateClient();
        }

        [Fact]
        public async Task FullFlow_ShouldGenerateDocument()
        {
            // 1. Register
            var registerDto = new RegisterDto
            {
                Username = "flowuser",
                Email = "flow@example.com",
                Password = "password123"
            };
            var registerResponse = await _client.PostAsJsonAsync("/api/auth/register", registerDto);
            registerResponse.EnsureSuccessStatusCode();
            var authResult = await registerResponse.Content.ReadFromJsonAsync<AuthResponseDto>();
            authResult.Should().NotBeNull();
            var token = authResult!.Token;

            _client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

            // 2. Create Template
            var templateDto = new CreateTemplateDto
            {
                Name = "Integration Template",
                Content = "<h1>Hello {{name}}</h1>",
                Description = "Test"
            };
            var templateResponse = await _client.PostAsJsonAsync("/api/templates", templateDto);
            templateResponse.EnsureSuccessStatusCode();
            var templateResult = await templateResponse.Content.ReadFromJsonAsync<TemplateDto>();
            templateResult.Should().NotBeNull();
            var templateId = templateResult!.Id;

            // 3. Generate Document
            var genRequest = new GenerationRequestDto
            {
                TemplateId = templateId,
                Data = new { name = "World" }
            };
            var docResponse = await _client.PostAsJsonAsync("/api/documents/generate", genRequest);
            docResponse.EnsureSuccessStatusCode();
            var docResult = await docResponse.Content.ReadFromJsonAsync<DocumentDto>();
            docResult.Should().NotBeNull();
            docResult!.DownloadUrl.Should().NotBeNullOrEmpty();

            // 4. Download Document
            var downloadResponse = await _client.GetAsync(docResult.DownloadUrl);
            downloadResponse.EnsureSuccessStatusCode();
            var pdfBytes = await downloadResponse.Content.ReadAsByteArrayAsync();
            pdfBytes.Should().NotBeEmpty();
        }
    }
}

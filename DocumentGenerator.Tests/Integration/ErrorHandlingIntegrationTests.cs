using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Infrastructure.Data;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Json;
using Xunit;

namespace DocumentGenerator.Tests.Integration
{
    public class ErrorHandlingIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;
        private readonly HttpClient _client;

        public ErrorHandlingIntegrationTests(WebApplicationFactory<Program> factory)
        {
            _factory = factory.WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    // Remove ALL EF Core related services to avoid provider conflicts
                    var descriptorsToRemove = services
                        .Where(d => d.ServiceType.FullName?.Contains("EntityFrameworkCore") == true ||
                                    d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>) ||
                                    d.ServiceType == typeof(ApplicationDbContext))
                        .ToList();

                    foreach (var descriptor in descriptorsToRemove)
                    {
                        services.Remove(descriptor);
                    }

                    services.AddDbContext<ApplicationDbContext>(options =>
                    {
                        options.UseInMemoryDatabase("InMemoryDbForErrorTesting");
                    });
                });
            });

            _client = _factory.CreateClient();
        }

        [Fact]
        public async Task GetDocument_ShouldReturnNotFound_WhenIdDoesNotExist()
        {
            // Arrange
            var token = await AuthenticateAsync();
            _client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

            // Act
            var response = await _client.GetAsync($"/api/documents/{Guid.NewGuid()}/download");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }

        [Fact]
        public async Task CreateTemplate_ShouldReturnBadRequest_WhenInvalidData()
        {
            // Arrange
            var token = await AuthenticateAsync();
            _client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

            var invalidDto = new CreateTemplateDto { Name = "", Content = "" }; // Invalid

            // Act
            var response = await _client.PostAsJsonAsync("/api/templates", invalidDto);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task ProtectedEndpoint_ShouldReturnUnauthorized_WhenNoToken()
        {
            // Act
            var response = await _client.GetAsync("/api/templates");

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        private async Task<string> AuthenticateAsync()
        {
            var registerDto = new RegisterDto
            {
                Username = $"user_{Guid.NewGuid()}",
                Email = $"user_{Guid.NewGuid()}@example.com",
                Password = "Password123!"
            };
            var response = await _client.PostAsJsonAsync("/api/auth/register", registerDto);
            response.EnsureSuccessStatusCode();
            var authResult = await response.Content.ReadFromJsonAsync<AuthResponseDto>();
            return authResult!.Token;
        }
    }
}

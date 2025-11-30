using DocumentGenerator.Infrastructure.Data;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using Xunit;

namespace DocumentGenerator.Tests.Integration
{
    public class SecurityIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;
        private readonly HttpClient _client;

        public SecurityIntegrationTests(WebApplicationFactory<Program> factory)
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
                        options.UseInMemoryDatabase("InMemoryDbForSecurityTesting");
                    });
                });
            });

            _client = _factory.CreateClient();
        }

        [Fact]
        public async Task SecureHeaders_ShouldBePresent_InResponse()
        {
            // Act
            var response = await _client.GetAsync("/api/auth/login"); // Any endpoint will do

            // Assert
            response.Headers.Contains("X-Content-Type-Options").Should().BeTrue();
            response.Headers.GetValues("X-Content-Type-Options").Should().Contain("nosniff");

            response.Headers.Contains("X-Frame-Options").Should().BeTrue();
            response.Headers.GetValues("X-Frame-Options").Should().Contain("DENY");

            response.Headers.Contains("X-XSS-Protection").Should().BeTrue();
            response.Headers.GetValues("X-XSS-Protection").Should().Contain("1; mode=block");

            response.Headers.Contains("Referrer-Policy").Should().BeTrue();
            response.Headers.GetValues("Referrer-Policy").Should().Contain("strict-origin-when-cross-origin");

            response.Headers.Contains("Content-Security-Policy").Should().BeTrue();
        }

        [Fact]
        public async Task RateLimiter_ShouldBlock_TooManyRequests()
        {
            // Arrange
            // Note: Rate limit is 100 per minute. We need to exceed this.
            // Using a loop to fire off requests.
            // To avoid running this test for too long or flakiness, we might want to configure a tighter limit for testing,
            // but since we can't easily change Program.cs configuration from here without more complex setup,
            // we will try to hit the limit. 
            // However, 100 requests is fast to execute against in-memory app.

            int limit = 105;
            HttpResponseMessage? lastResponse = null;

            // Act
            for (int i = 0; i < limit; i++)
            {
                lastResponse = await _client.GetAsync("/api/auth/login");
                if (lastResponse.StatusCode == HttpStatusCode.TooManyRequests)
                {
                    break;
                }
            }

            // Assert
            lastResponse.Should().NotBeNull();
            lastResponse!.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
        }

        [Fact]
        public async Task CORS_ShouldAllow_SpecificOrigin()
        {
            // Arrange
            var request = new HttpRequestMessage(HttpMethod.Options, "/api/auth/login");
            request.Headers.Add("Origin", "http://localhost:5173");
            request.Headers.Add("Access-Control-Request-Method", "POST");

            // Act
            var response = await _client.SendAsync(request);

            // Assert
            response.Headers.Contains("Access-Control-Allow-Origin").Should().BeTrue();
            response.Headers.GetValues("Access-Control-Allow-Origin").Should().Contain("http://localhost:5173");
        }
    }
}

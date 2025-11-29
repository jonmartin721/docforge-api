using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Settings;
using DocumentGenerator.Infrastructure.Data;
using DocumentGenerator.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class AuthServiceTests
    {
        private readonly AuthService _authService;
        private readonly ApplicationDbContext _context;
        private readonly Mock<IOptions<JwtSettings>> _mockJwtSettings;

        public AuthServiceTests()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            _context = new ApplicationDbContext(options);

            _mockJwtSettings = new Mock<IOptions<JwtSettings>>();
            _mockJwtSettings.Setup(s => s.Value).Returns(new JwtSettings
            {
                Secret = "THIS_IS_A_SUPER_SECRET_KEY_FOR_TESTING_PURPOSES_ONLY",
                Issuer = "TestIssuer",
                Audience = "TestAudience",
                ExpiryMinutes = 60,
                RefreshTokenExpiryDays = 7
            });

            _authService = new AuthService(_context, _mockJwtSettings.Object);
        }

        [Fact]
        public async Task RegisterAsync_ShouldCreateUser_WhenValidDto()
        {
            // Arrange
            var dto = new RegisterDto
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "password123"
            };

            // Act
            var result = await _authService.RegisterAsync(dto);

            // Assert
            result.Should().NotBeNull();
            result.Token.Should().NotBeNullOrEmpty();

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == "testuser");
            user.Should().NotBeNull();
            user!.Email.Should().Be("test@example.com");
        }

        [Fact]
        public async Task RegisterAsync_ShouldThrow_WhenUsernameExists()
        {
            // Arrange
            var existingUser = new User
            {
                Id = Guid.NewGuid(),
                Username = "testuser",
                Email = "existing@example.com",
                PasswordHash = "hash"
            };
            _context.Users.Add(existingUser);
            await _context.SaveChangesAsync();

            var dto = new RegisterDto
            {
                Username = "testuser",
                Email = "new@example.com",
                Password = "password123"
            };

            // Act
            Func<Task> act = async () => await _authService.RegisterAsync(dto);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("Username already exists");
        }
    }
}

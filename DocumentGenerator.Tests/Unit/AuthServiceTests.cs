using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Exceptions;
using DocumentGenerator.Core.Settings;
using DocumentGenerator.Infrastructure.Data;
using DocumentGenerator.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
        private readonly Mock<ILogger<AuthService>> _mockLogger;

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

            _mockLogger = new Mock<ILogger<AuthService>>();

            _authService = new AuthService(_context, _mockJwtSettings.Object, _mockLogger.Object);
        }

        [Fact]
        public async Task RegisterAsync_ShouldCreateUser_WhenValidDto()
        {
            // Arrange
            var dto = new RegisterDto
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Password123!"
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
                Password = "Password123!"
            };

            // Act
            Func<Task> act = async () => await _authService.RegisterAsync(dto);

            // Assert
            await act.Should().ThrowAsync<DuplicateUsernameException>();
        }

        [Fact]
        public async Task RegisterAsync_ShouldThrow_WhenEmailExists()
        {
            // Arrange
            var existingUser = new User
            {
                Id = Guid.NewGuid(),
                Username = "existinguser",
                Email = "test@example.com",
                PasswordHash = "hash"
            };
            _context.Users.Add(existingUser);
            await _context.SaveChangesAsync();

            var dto = new RegisterDto
            {
                Username = "newuser",
                Email = "test@example.com",
                Password = "Password123!"
            };

            // Act
            Func<Task> act = async () => await _authService.RegisterAsync(dto);

            // Assert
            await act.Should().ThrowAsync<DuplicateEmailException>();
        }

        [Fact]
        public async Task LoginAsync_ShouldReturnTokens_WhenCredentialsValid()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "loginuser",
                Email = "login@example.com",
                Password = "Password123!"
            };
            await _authService.RegisterAsync(registerDto);

            var loginDto = new LoginDto
            {
                Username = "loginuser",
                Password = "Password123!"
            };

            // Act
            var result = await _authService.LoginAsync(loginDto);

            // Assert
            result.Should().NotBeNull();
            result.Token.Should().NotBeNullOrEmpty();
            result.RefreshToken.Should().NotBeNullOrEmpty();
        }

        [Fact]
        public async Task LoginAsync_ShouldThrow_WhenUserNotFound()
        {
            // Arrange
            var loginDto = new LoginDto
            {
                Username = "nonexistent",
                Password = "Password123!"
            };

            // Act
            Func<Task> act = async () => await _authService.LoginAsync(loginDto);

            // Assert
            await act.Should().ThrowAsync<InvalidCredentialsException>();
        }

        [Fact]
        public async Task LoginAsync_ShouldThrow_WhenPasswordInvalid()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "testuser2",
                Email = "test2@example.com",
                Password = "Password123!"
            };
            await _authService.RegisterAsync(registerDto);

            var loginDto = new LoginDto
            {
                Username = "testuser2",
                Password = "WrongPassword!"
            };

            // Act
            Func<Task> act = async () => await _authService.LoginAsync(loginDto);

            // Assert
            await act.Should().ThrowAsync<InvalidCredentialsException>();
        }

        [Fact]
        public async Task LoginAsync_ShouldLockAccount_After5FailedAttempts()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "lockuser",
                Email = "lock@example.com",
                Password = "Password123!"
            };
            await _authService.RegisterAsync(registerDto);

            var loginDto = new LoginDto
            {
                Username = "lockuser",
                Password = "WrongPassword!"
            };

            // Act - Make 5 failed attempts
            for (int i = 0; i < 5; i++)
            {
                try { await _authService.LoginAsync(loginDto); } catch { }
            }

            // Try a 6th time - should throw AccountLockedException
            Func<Task> act = async () => await _authService.LoginAsync(loginDto);

            // Assert
            await act.Should().ThrowAsync<AccountLockedException>();
        }

        [Fact]
        public async Task LoginAsync_ShouldResetFailedAttempts_OnSuccessfulLogin()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "resetuser",
                Email = "reset@example.com",
                Password = "Password123!"
            };
            await _authService.RegisterAsync(registerDto);

            var wrongLoginDto = new LoginDto
            {
                Username = "resetuser",
                Password = "WrongPassword!"
            };

            // Make a few failed attempts (but not enough to lock)
            for (int i = 0; i < 3; i++)
            {
                try { await _authService.LoginAsync(wrongLoginDto); } catch { }
            }

            // Now login successfully
            var correctLoginDto = new LoginDto
            {
                Username = "resetuser",
                Password = "Password123!"
            };

            // Act
            var result = await _authService.LoginAsync(correctLoginDto);

            // Assert
            result.Should().NotBeNull();
            var user = await _context.Users.FirstAsync(u => u.Username == "resetuser");
            user.FailedLoginAttempts.Should().Be(0);
        }

        [Fact]
        public async Task RefreshTokenAsync_ShouldReturnNewTokens_WhenRefreshTokenValid()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "refreshuser",
                Email = "refresh@example.com",
                Password = "Password123!"
            };
            var authResponse = await _authService.RegisterAsync(registerDto);

            // Act
            var result = await _authService.RefreshTokenAsync(authResponse.Token, authResponse.RefreshToken);

            // Assert
            result.Should().NotBeNull();
            result.Token.Should().NotBeNullOrEmpty();
            result.RefreshToken.Should().NotBeNullOrEmpty();
        }

        [Fact]
        public async Task RefreshTokenAsync_ShouldThrow_WhenRefreshTokenInvalid()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "invalidrefresh",
                Email = "invalidrefresh@example.com",
                Password = "Password123!"
            };
            var authResponse = await _authService.RegisterAsync(registerDto);

            // Act
            Func<Task> act = async () => await _authService.RefreshTokenAsync(authResponse.Token, "invalid-refresh-token");

            // Assert
            await act.Should().ThrowAsync<InvalidRefreshTokenException>();
        }

        [Fact]
        public async Task RefreshTokenAsync_ShouldThrow_WhenRefreshTokenExpired()
        {
            // Arrange
            var user = new User
            {
                Id = Guid.NewGuid(),
                Username = "expireduser",
                Email = "expired@example.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Password123!"),
                RefreshToken = "expired-token",
                RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(-1) // Expired yesterday
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // Act
            Func<Task> act = async () => await _authService.RefreshTokenAsync("some-token", "expired-token");

            // Assert
            await act.Should().ThrowAsync<InvalidRefreshTokenException>();
        }
    }
}

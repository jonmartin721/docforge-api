using DocumentGenerator.API.Controllers;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Interfaces;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class AuthControllerTests
    {
        private readonly Mock<IAuthService> _mockAuthService;
        private readonly AuthController _controller;

        public AuthControllerTests()
        {
            _mockAuthService = new Mock<IAuthService>();
            _controller = new AuthController(_mockAuthService.Object);
        }

        [Fact]
        public async Task Register_ShouldReturnOk_WithAuthResponse()
        {
            // Arrange
            var registerDto = new RegisterDto
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Password123!"
            };
            var authResponse = new AuthResponseDto
            {
                Token = "jwt-token",
                RefreshToken = "refresh-token",
                Expiration = DateTime.UtcNow.AddHours(1)
            };
            _mockAuthService.Setup(s => s.RegisterAsync(registerDto)).ReturnsAsync(authResponse);

            // Act
            var result = await _controller.Register(registerDto);

            // Assert
            var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
            okResult.Value.Should().Be(authResponse);
        }

        [Fact]
        public async Task Login_ShouldReturnOk_WithAuthResponse()
        {
            // Arrange
            var loginDto = new LoginDto
            {
                Username = "testuser",
                Password = "Password123!"
            };
            var authResponse = new AuthResponseDto
            {
                Token = "jwt-token",
                RefreshToken = "refresh-token",
                Expiration = DateTime.UtcNow.AddHours(1)
            };
            _mockAuthService.Setup(s => s.LoginAsync(loginDto)).ReturnsAsync(authResponse);

            // Act
            var result = await _controller.Login(loginDto);

            // Assert
            var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
            okResult.Value.Should().Be(authResponse);
        }

        [Fact]
        public async Task RefreshToken_ShouldReturnOk_WithAuthResponse()
        {
            // Arrange
            var refreshDto = new RefreshTokenDto
            {
                Token = "old-jwt-token",
                RefreshToken = "old-refresh-token"
            };
            var authResponse = new AuthResponseDto
            {
                Token = "new-jwt-token",
                RefreshToken = "new-refresh-token",
                Expiration = DateTime.UtcNow.AddHours(1)
            };
            _mockAuthService.Setup(s => s.RefreshTokenAsync(refreshDto.Token, refreshDto.RefreshToken))
                .ReturnsAsync(authResponse);

            // Act
            var result = await _controller.RefreshToken(refreshDto);

            // Assert
            var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
            okResult.Value.Should().Be(authResponse);
        }
    }
}

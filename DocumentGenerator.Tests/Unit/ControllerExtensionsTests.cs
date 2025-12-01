using System.Security.Claims;
using DocumentGenerator.API.Extensions;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class ControllerExtensionsTests
    {
        private TestController CreateControllerWithClaims(params Claim[] claims)
        {
            var controller = new TestController();
            var identity = new ClaimsIdentity(claims, "TestAuth");
            var principal = new ClaimsPrincipal(identity);
            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = principal }
            };
            return controller;
        }

        [Fact]
        public void GetUserId_ShouldReturnGuid_WhenValidClaim()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var controller = CreateControllerWithClaims(
                new Claim(ClaimTypes.NameIdentifier, userId.ToString())
            );

            // Act
            var result = controller.GetUserId();

            // Assert
            result.Should().Be(userId);
        }

        [Fact]
        public void GetUserId_ShouldThrow_WhenClaimMissing()
        {
            // Arrange
            var controller = CreateControllerWithClaims(); // No claims

            // Act
            Action act = () => controller.GetUserId();

            // Assert
            act.Should().Throw<UnauthorizedAccessException>()
                .WithMessage("*User ID not found*");
        }

        [Fact]
        public void GetUserId_ShouldThrow_WhenClaimValueEmpty()
        {
            // Arrange
            var controller = CreateControllerWithClaims(
                new Claim(ClaimTypes.NameIdentifier, "")
            );

            // Act
            Action act = () => controller.GetUserId();

            // Assert
            act.Should().Throw<UnauthorizedAccessException>()
                .WithMessage("*User ID not found*");
        }

        [Fact]
        public void GetUserId_ShouldThrow_WhenClaimValueInvalidGuid()
        {
            // Arrange
            var controller = CreateControllerWithClaims(
                new Claim(ClaimTypes.NameIdentifier, "not-a-guid")
            );

            // Act
            Action act = () => controller.GetUserId();

            // Assert
            act.Should().Throw<UnauthorizedAccessException>()
                .WithMessage("*Invalid user identifier*");
        }

        // Test controller that exposes the extension method
        private class TestController : ControllerBase
        {
            public Guid GetUserId() => ControllerExtensions.GetUserId(this);
        }
    }
}

using System.Net;
using DocumentGenerator.API.Middleware;
using DocumentGenerator.Core.Exceptions;
using FluentAssertions;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace DocumentGenerator.Tests.Unit
{
    public class ExceptionHandlingMiddlewareTests
    {
        private readonly Mock<ILogger<ExceptionHandlingMiddleware>> _mockLogger;

        public ExceptionHandlingMiddlewareTests()
        {
            _mockLogger = new Mock<ILogger<ExceptionHandlingMiddleware>>();
        }

        private DefaultHttpContext CreateHttpContext()
        {
            var context = new DefaultHttpContext();
            context.Response.Body = new MemoryStream();
            return context;
        }

        private async Task<string> GetResponseBody(HttpContext context)
        {
            context.Response.Body.Seek(0, SeekOrigin.Begin);
            using var reader = new StreamReader(context.Response.Body);
            return await reader.ReadToEndAsync();
        }

        [Fact]
        public async Task InvokeAsync_ShouldPassThrough_WhenNoException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => Task.CompletedTask, _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be(200);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn400_ForValidationException()
        {
            // Arrange
            var context = CreateHttpContext();
            var failures = new List<ValidationFailure>
            {
                new ValidationFailure("Field", "Field is required")
            };
            var validationException = new ValidationException(failures);

            var middleware = new ExceptionHandlingMiddleware(_ => throw validationException, _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.BadRequest);
            var body = await GetResponseBody(context);
            body.Should().Contain("Validation Failed");
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn409_ForDuplicateUsernameException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new DuplicateUsernameException("testuser"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Conflict);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn409_ForDuplicateEmailException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new DuplicateEmailException("test@example.com"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Conflict);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn401_ForInvalidCredentialsException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new InvalidCredentialsException(), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn401_ForInvalidRefreshTokenException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new InvalidRefreshTokenException(), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn429_ForAccountLockedException()
        {
            // Arrange
            var context = CreateHttpContext();
            var lockoutEnd = DateTime.UtcNow.AddMinutes(15);
            var middleware = new ExceptionHandlingMiddleware(_ => throw new AccountLockedException(lockoutEnd), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.TooManyRequests);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn400_ForTemplateCompilationException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new TemplateCompilationException("Invalid syntax"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn403_ForUnauthorizedResourceAccessException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new UnauthorizedResourceAccessException(), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Forbidden);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn404_ForKeyNotFoundException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new KeyNotFoundException("Not found"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.NotFound);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn401_ForUnauthorizedAccessException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new UnauthorizedAccessException(), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn400_ForArgumentException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new ArgumentException("Bad argument"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn400_ForInvalidOperationException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new InvalidOperationException("Invalid operation"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn404_ForFileNotFoundException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new FileNotFoundException("File not found"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.NotFound);
        }

        [Fact]
        public async Task InvokeAsync_ShouldReturn500_ForGenericException()
        {
            // Arrange
            var context = CreateHttpContext();
            var middleware = new ExceptionHandlingMiddleware(_ => throw new Exception("Unexpected error"), _mockLogger.Object);

            // Act
            await middleware.InvokeAsync(context);

            // Assert
            context.Response.StatusCode.Should().Be((int)HttpStatusCode.InternalServerError);
            var body = await GetResponseBody(context);
            body.Should().Contain("Internal Server Error");
        }
    }
}

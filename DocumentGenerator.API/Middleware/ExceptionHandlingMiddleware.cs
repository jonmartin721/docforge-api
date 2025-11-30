using System.Net;
using System.Text.Json;
using DocumentGenerator.Core.Exceptions;
using FluentValidation;

namespace DocumentGenerator.API.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;

        public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            _logger.LogError(exception, "An unexpected error occurred.");

            context.Response.ContentType = "application/json";
            var response = new ErrorResponse();

            switch (exception)
            {
                case ValidationException validationEx:
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    response.Message = "Validation Failed";
                    response.Errors = validationEx.Errors.Select(e => e.ErrorMessage).ToList();
                    break;

                case DuplicateUsernameException:
                case DuplicateEmailException:
                    context.Response.StatusCode = (int)HttpStatusCode.Conflict;
                    response.Message = exception.Message;
                    break;

                case InvalidCredentialsException:
                case InvalidRefreshTokenException:
                    context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                    response.Message = exception.Message;
                    break;

                case TemplateCompilationException:
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    response.Message = exception.Message;
                    break;

                case UnauthorizedResourceAccessException:
                    context.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                    response.Message = exception.Message;
                    break;

                case KeyNotFoundException:
                    context.Response.StatusCode = (int)HttpStatusCode.NotFound;
                    response.Message = "Resource not found";
                    break;

                case UnauthorizedAccessException:
                    context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                    response.Message = "Unauthorized";
                    break;

                case ArgumentException argEx:
                    context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    response.Message = argEx.Message;
                    break;

                default:
                    context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                    response.Message = "Internal Server Error";
                    break;
            }

            var json = JsonSerializer.Serialize(response);
            await context.Response.WriteAsync(json);
        }
    }

    public class ErrorResponse
    {
        public string Message { get; set; } = string.Empty;
        public List<string>? Errors { get; set; }
    }
}

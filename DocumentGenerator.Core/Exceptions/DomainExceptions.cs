namespace DocumentGenerator.Core.Exceptions
{
    /// <summary>
    /// Thrown when attempting to register with a username that already exists.
    /// </summary>
    public class DuplicateUsernameException : Exception
    {
        public DuplicateUsernameException()
            : base("Username already exists") { }

        public DuplicateUsernameException(string username)
            : base($"Username '{username}' already exists") { }
    }

    /// <summary>
    /// Thrown when attempting to register with an email that already exists.
    /// </summary>
    public class DuplicateEmailException : Exception
    {
        public DuplicateEmailException()
            : base("Email already exists") { }

        public DuplicateEmailException(string email)
            : base($"Email '{email}' already exists") { }
    }

    /// <summary>
    /// Thrown when login credentials are invalid.
    /// </summary>
    public class InvalidCredentialsException : Exception
    {
        public InvalidCredentialsException()
            : base("Invalid credentials") { }
    }

    /// <summary>
    /// Thrown when an account is locked due to too many failed login attempts.
    /// </summary>
    public class AccountLockedException : Exception
    {
        public DateTime? LockoutEnd { get; }

        public AccountLockedException()
            : base("Account is locked due to too many failed login attempts") { }

        public AccountLockedException(DateTime lockoutEnd)
            : base($"Account is locked until {lockoutEnd:u}")
        {
            LockoutEnd = lockoutEnd;
        }
    }

    /// <summary>
    /// Thrown when a refresh token is invalid or expired.
    /// </summary>
    public class InvalidRefreshTokenException : Exception
    {
        public InvalidRefreshTokenException()
            : base("Invalid or expired refresh token") { }
    }

    /// <summary>
    /// Thrown when a Handlebars template fails to compile.
    /// </summary>
    public class TemplateCompilationException : Exception
    {
        public TemplateCompilationException(string message)
            : base($"Invalid template syntax: {message}") { }

        public TemplateCompilationException(string message, Exception innerException)
            : base($"Invalid template syntax: {message}", innerException) { }
    }

    /// <summary>
    /// Thrown when a user attempts to access a resource they don't own.
    /// </summary>
    public class UnauthorizedResourceAccessException : Exception
    {
        public UnauthorizedResourceAccessException()
            : base("You do not have permission to access this resource") { }

        public UnauthorizedResourceAccessException(string resourceType, Guid resourceId)
            : base($"You do not have permission to access {resourceType} with ID {resourceId}") { }
    }
}

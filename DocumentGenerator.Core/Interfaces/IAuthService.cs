using DocumentGenerator.Core.DTOs;

namespace DocumentGenerator.Core.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponseDto> RegisterAsync(RegisterDto registerDto);
        Task<AuthResponseDto> LoginAsync(LoginDto loginDto);
        Task<AuthResponseDto> RefreshTokenAsync(string token, string refreshToken);
    }
}

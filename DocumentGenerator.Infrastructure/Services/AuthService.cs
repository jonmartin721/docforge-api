using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using DocumentGenerator.Core.DTOs;
using DocumentGenerator.Core.Entities;
using DocumentGenerator.Core.Interfaces;
using DocumentGenerator.Core.Settings;
using DocumentGenerator.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace DocumentGenerator.Infrastructure.Services
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly JwtSettings _jwtSettings;

        public AuthService(ApplicationDbContext context, IOptions<JwtSettings> jwtSettings)
        {
            _context = context;
            _jwtSettings = jwtSettings.Value;
        }

        public async Task<AuthResponseDto> RegisterAsync(RegisterDto registerDto)
        {
            if (await _context.Users.AnyAsync(u => u.Username == registerDto.Username))
                throw new Exception("Username already exists");

            if (await _context.Users.AnyAsync(u => u.Email == registerDto.Email))
                throw new Exception("Email already exists");

            var user = new User
            {
                Id = Guid.NewGuid(),
                Username = registerDto.Username,
                Email = registerDto.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(registerDto.Password),
                Role = "User"
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return GenerateAuthResponse(user);
        }

        public async Task<AuthResponseDto> LoginAsync(LoginDto loginDto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == loginDto.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
                throw new Exception("Invalid credentials");

            return GenerateAuthResponse(user);
        }

        public async Task<AuthResponseDto> RefreshTokenAsync(string token, string refreshToken)
        {
            // Simple implementation for now, would need more robust validation in production
            var user = await _context.Users.FirstOrDefaultAsync(u => u.RefreshToken == refreshToken);

            if (user == null || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
                throw new Exception("Invalid refresh token");

            return GenerateAuthResponse(user);
        }

        private AuthResponseDto GenerateAuthResponse(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_jwtSettings.Secret);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, user.Role)
                }),
                Expires = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpiryMinutes),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = _jwtSettings.Issuer,
                Audience = _jwtSettings.Audience
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var refreshToken = Guid.NewGuid().ToString();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);
            _context.SaveChanges();

            return new AuthResponseDto
            {
                Token = tokenHandler.WriteToken(token),
                RefreshToken = refreshToken,
                Expiration = tokenDescriptor.Expires.Value
            };
        }
    }
}

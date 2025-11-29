using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace DocumentGenerator.API.Extensions
{
    public static class ControllerExtensions
    {
        public static Guid GetUserId(this ControllerBase controller)
        {
            var userIdClaim = controller.User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || string.IsNullOrEmpty(userIdClaim.Value))
            {
                throw new UnauthorizedAccessException("User ID not found in token");
            }
            return Guid.Parse(userIdClaim.Value);
        }
    }
}

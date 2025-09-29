// hl-api/Controllers/AuthController.cs
using Microsoft.AspNetCore.Mvc;
using HLApi.Services;
using Microsoft.AspNetCore.Authorization;


namespace HLApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private static readonly Dictionary<string, string> Users = new(StringComparer.OrdinalIgnoreCase)
        {
            { "admin", "ChangeMe123!" },
            { "alice", "demo123" }
        };

        private readonly TokenService _tokenService;


        public AuthController(TokenService tokenService)
        {
            _tokenService = tokenService;
        }


        [HttpPost("login")]
        [AllowAnonymous] 
        public ActionResult Login([FromBody] LoginRequest request)
        {
            if (!Users.TryGetValue(request.Username, out var expectedPassword) || expectedPassword != request.Password)
            {
                return Unauthorized("Invalid credentials");
            }


            var token = _tokenService.GenerateToken(request.Username);
            return Ok(new { token });
        }
    }


    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}

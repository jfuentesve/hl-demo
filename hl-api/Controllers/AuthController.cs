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
        private sealed record DemoUser(string Password, string Role, string Client);

        private static readonly Dictionary<string, DemoUser> Users = new(StringComparer.OrdinalIgnoreCase)
        {
            { "admin", new DemoUser("ChangeMe123!", "Admin", "Corporate HQ") },
            { "alice", new DemoUser("demo123", "User", "Acme Corp") },
            { "bob",   new DemoUser("demo123", "User", "Globex LLC") },
            { "guest", new DemoUser("guest",   "Viewer", "Public") }
        };

        private readonly TokenService _tokenService;


        public AuthController(TokenService tokenService)
        {
            _tokenService = tokenService;
        }


        [HttpPost("login")]
        [AllowAnonymous] 
        public async Task<ActionResult> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
        {
            if (!Users.TryGetValue(request.Username, out var user) || user.Password != request.Password)
            {
                return Unauthorized("Invalid credentials");
            }


            var token = await _tokenService.GenerateTokenAsync(request.Username, user.Role, user.Client, cancellationToken).ConfigureAwait(false);
            return Ok(new { token });
        }
    }


    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}

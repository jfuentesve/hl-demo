// hl-api/Controllers/AuthController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using HLApi.Models;
using HLApi.Services;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;


namespace HLApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly TokenService _tokenService;


        public AuthController(TokenService tokenService)
        {
            _tokenService = tokenService;
        }


        [HttpPost("login")]
        [AllowAnonymous] 
        public ActionResult Login([FromBody] LoginRequest request)
        {
            // For demo purposes, accept hardcoded user
            if (request.Username != "admin" || request.Password != "ChangeMe123!")
                return Unauthorized("Invalid credentials");


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
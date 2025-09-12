// hl-api/Services/TokenService.cs
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;


namespace HLApi.Services
{
    public class TokenService
    {
        private readonly IConfiguration _config;


        public TokenService(IConfiguration config)
        {
            _config = config;
        }


        public string GenerateToken(string username)
        {
            var claims = new[] {
new Claim(JwtRegisteredClaimNames.Sub, username),
new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
new Claim(ClaimTypes.Name, username),
new Claim(ClaimTypes.Role, "User")
};


            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);


            var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds
            );


            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
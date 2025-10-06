// hl-api/Services/TokenService.cs
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using HLApi.Services.Secrets;


namespace HLApi.Services
{
    public class TokenService
    {
        private readonly IConfiguration _config;
        private readonly JwtSecretAccessor _jwtSecretAccessor;


        public TokenService(IConfiguration config, JwtSecretAccessor jwtSecretAccessor)
        {
            _config = config;
            _jwtSecretAccessor = jwtSecretAccessor;
        }


        public async Task<string> GenerateTokenAsync(string username, string role, string client, CancellationToken cancellationToken = default)
        {
            var claims = new[] {
            new Claim(JwtRegisteredClaimNames.Sub, username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Role, role),
            new Claim("client", client)
            };


            var keyBytes = await _jwtSecretAccessor.GetSigningKeyBytesAsync(cancellationToken).ConfigureAwait(false);
            var key = new SymmetricSecurityKey(keyBytes);
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

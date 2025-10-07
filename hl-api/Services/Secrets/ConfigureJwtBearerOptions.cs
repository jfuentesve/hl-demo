// hl-api/Services/Secrets/ConfigureJwtBearerOptions.cs
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace HLApi.Services.Secrets
{
    public class ConfigureJwtBearerOptions : IPostConfigureOptions<JwtBearerOptions>
    {
        private readonly JwtSecretAccessor _jwtSecretAccessor;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ConfigureJwtBearerOptions> _logger;

        public ConfigureJwtBearerOptions(
            JwtSecretAccessor jwtSecretAccessor,
            IConfiguration configuration,
            ILogger<ConfigureJwtBearerOptions> logger)
        {
            _jwtSecretAccessor = jwtSecretAccessor;
            _configuration = configuration;
            _logger = logger;
        }

        public void PostConfigure(string? name, JwtBearerOptions options)
        {
            byte[] signingKey;

            try
            {
                signingKey = _jwtSecretAccessor.GetSigningKeyBytesAsync().GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unable to resolve JWT signing key from secret provider");
                throw;
            }

            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = _configuration["Jwt:Issuer"],
                ValidAudience = _configuration["Jwt:Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(signingKey)
            };
        }
    }
}

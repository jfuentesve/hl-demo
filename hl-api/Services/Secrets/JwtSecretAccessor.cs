// hl-api/Services/Secrets/JwtSecretAccessor.cs
using System.Text;
using Microsoft.Extensions.Options;

namespace HLApi.Services.Secrets
{
    public class JwtSecretAccessor
    {
        private readonly ISecretProvider _secretProvider;
        private readonly IConfiguration _configuration;
        private readonly ILogger<JwtSecretAccessor> _logger;
        private readonly JwtSecretOptions _options;
        private string? _cachedKey;

        public JwtSecretAccessor(
            ISecretProvider secretProvider,
            IConfiguration configuration,
            IOptions<JwtSecretOptions> options,
            ILogger<JwtSecretAccessor> logger)
        {
            _secretProvider = secretProvider;
            _configuration = configuration;
            _logger = logger;
            _options = options.Value;
        }

        public async Task<string?> GetSigningKeyAsync(CancellationToken cancellationToken = default)
        {
            if (!string.IsNullOrEmpty(_cachedKey))
            {
                return _cachedKey;
            }

            if (!string.IsNullOrEmpty(_options.SecretName))
            {
                var secret = await _secretProvider.GetSecretAsync(_options.SecretName, cancellationToken).ConfigureAwait(false);
                if (!string.IsNullOrEmpty(secret))
                {
                    _cachedKey = secret;
                    return secret;
                }

                _logger.LogWarning("JWT secret '{SecretName}' not found; falling back to configuration", _options.SecretName);
            }

            var fallback = _configuration["Jwt:Key"];
            if (string.IsNullOrEmpty(fallback))
            {
                _logger.LogError("No JWT signing key configured. Provide Jwt:Key or set Secrets:Jwt:SecretName");
                return null;
            }

            _cachedKey = fallback;
            return fallback;
        }

        public async Task<byte[]> GetSigningKeyBytesAsync(CancellationToken cancellationToken = default)
        {
            var key = await GetSigningKeyAsync(cancellationToken).ConfigureAwait(false);
            if (string.IsNullOrEmpty(key))
            {
                throw new InvalidOperationException("JWT signing key cannot be null or empty");
            }

            return Encoding.UTF8.GetBytes(key);
        }
    }

    public class JwtSecretOptions
    {
        public string? SecretName { get; set; }
    }

    // Future Vault integration: add a VaultSecretOptions + accessor mirroring this class,
    // pointing SecretName to a Vault path and resolving using a VaultSecretProvider.
}

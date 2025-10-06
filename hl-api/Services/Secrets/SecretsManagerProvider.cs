// hl-api/Services/Secrets/SecretsManagerProvider.cs
using System.Text;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

namespace HLApi.Services.Secrets
{
    public class SecretsManagerProvider : CachedSecretProviderBase
    {
        private readonly IAmazonSecretsManager _secretsManager;
        private readonly ILogger<SecretsManagerProvider> _logger;

        public SecretsManagerProvider(
            IAmazonSecretsManager secretsManager,
            ILogger<SecretsManagerProvider> logger)
        {
            _secretsManager = secretsManager;
            _logger = logger;
        }

        protected override async Task<string?> FetchSecretAsync(string name, CancellationToken cancellationToken)
        {
            try
            {
                var response = await _secretsManager.GetSecretValueAsync(new GetSecretValueRequest
                {
                    SecretId = name
                }, cancellationToken).ConfigureAwait(false);

                if (!string.IsNullOrEmpty(response.SecretString))
                {
                    return response.SecretString;
                }

                if (response.SecretBinary is { Length: > 0 })
                {
                    return Encoding.UTF8.GetString(response.SecretBinary.ToArray());
                }

                _logger.LogWarning("Secrets Manager secret '{Name}' returned no data", name);
                return null;
            }
            catch (ResourceNotFoundException)
            {
                _logger.LogWarning("Secrets Manager secret '{Name}' not found", name);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving Secrets Manager secret '{Name}'", name);
                throw;
            }
        }
    }
}

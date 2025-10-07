// hl-api/Services/Secrets/SsmParameterStoreProvider.cs
using Amazon.SimpleSystemsManagement;
using Amazon.SimpleSystemsManagement.Model;

namespace HLApi.Services.Secrets
{
    public class SsmParameterStoreProvider : CachedSecretProviderBase
    {
        private readonly IAmazonSimpleSystemsManagement _ssmClient;
        private readonly ILogger<SsmParameterStoreProvider> _logger;

        public SsmParameterStoreProvider(
            IAmazonSimpleSystemsManagement ssmClient,
            ILogger<SsmParameterStoreProvider> logger)
        {
            _ssmClient = ssmClient;
            _logger = logger;
        }

        protected override async Task<string?> FetchSecretAsync(string name, CancellationToken cancellationToken)
        {
            try
            {
                var response = await _ssmClient.GetParameterAsync(new GetParameterRequest
                {
                    Name = name,
                    WithDecryption = true
                }, cancellationToken).ConfigureAwait(false);

                return response.Parameter?.Value;
            }
            catch (ParameterNotFoundException)
            {
                _logger.LogWarning("SSM parameter '{Name}' not found", name);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving SSM parameter '{Name}'", name);
                throw;
            }
        }
    }
}

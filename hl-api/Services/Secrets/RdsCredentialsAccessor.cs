// hl-api/Services/Secrets/RdsCredentialsAccessor.cs
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace HLApi.Services.Secrets
{
    public class RdsCredentialsAccessor
    {
        private readonly ISecretProvider _secretProvider;
        private readonly IConfiguration _configuration;
        private readonly ILogger<RdsCredentialsAccessor> _logger;
        private readonly RdsSecretOptions _options;
        private DatabaseCredentials? _cachedCredentials;

        public RdsCredentialsAccessor(
            ISecretProvider secretProvider,
            IConfiguration configuration,
            ILogger<RdsCredentialsAccessor> logger,
            IOptions<RdsSecretOptions> options)
        {
            _secretProvider = secretProvider;
            _configuration = configuration;
            _logger = logger;
            _options = options.Value;
        }

        public async Task<DatabaseCredentials?> GetCredentialsAsync(CancellationToken cancellationToken = default)
        {
            if (_cachedCredentials is not null)
            {
                return _cachedCredentials;
            }

            if (!string.IsNullOrEmpty(_options.SecretName))
            {
                var secretValue = await _secretProvider.GetSecretAsync(_options.SecretName, cancellationToken).ConfigureAwait(false);
                if (!string.IsNullOrEmpty(secretValue))
                {
                    try
                    {
                        var creds = JsonSerializer.Deserialize<DatabaseCredentials>(secretValue);
                        if (creds is not null)
                        {
                            _cachedCredentials = creds;
                            return creds;
                        }

                        _logger.LogWarning("RDS credentials secret '{SecretName}' did not deserialize", _options.SecretName);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse RDS credentials secret '{SecretName}'", _options.SecretName);
                        throw;
                    }
                }
            }

            _logger.LogWarning("Falling back to appsettings connection string for RDS credentials");
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                _logger.LogError("No connection string configured for DefaultConnection");
                return null;
            }

            return DatabaseCredentials.FromConnectionString(connectionString);
        }
    }

    public class RdsSecretOptions
    {
        public string? SecretName { get; set; }
    }

    public record DatabaseCredentials
    {
        public string Username { get; init; } = string.Empty;
        public string Password { get; init; } = string.Empty;
        public string Endpoint { get; init; } = string.Empty;
        public int Port { get; init; }
        public string Database { get; init; } = string.Empty;

        public static DatabaseCredentials FromConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);
            return new DatabaseCredentials
            {
                Username = builder.UserID,
                Password = ***REDACTED***
                Endpoint = builder.DataSource,
                Port = builder.DataSource.Contains(",",
                        StringComparison.Ordinal) &&
                        int.TryParse(builder.DataSource.Split(',')[1], out var parsedPort)
                        ? parsedPort
                        : 1433,
                Database = builder.InitialCatalog
            };
        }
    }

    // Future Vault extension: reuse DatabaseCredentials with a dedicated Vault secret keyed by
    // path convention (e.g., database/creds/hldeals), resolved via a VaultSecretProvider.
}

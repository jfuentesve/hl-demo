// hl-api/Services/Secrets/ISecretProvider.cs
using System.Collections.Concurrent;

namespace HLApi.Services.Secrets
{
    public interface ISecretProvider
    {
        Task<string?> GetSecretAsync(string name, CancellationToken cancellationToken = default);
    }

    /// <summary>
    /// Base class with naive in-memory caching. Concrete providers only implement FetchSecretAsync.
    /// </summary>
    public abstract class CachedSecretProviderBase : ISecretProvider
    {
        private readonly ConcurrentDictionary<string, Lazy<Task<string?>>> _cache = new();

        public Task<string?> GetSecretAsync(string name, CancellationToken cancellationToken = default)
        {
            var lazyTask = _cache.GetOrAdd(name, key => new Lazy<Task<string?>>(async () =>
            {
                var secret = await FetchSecretAsync(key, cancellationToken).ConfigureAwait(false);
                return secret;
            }));

            return lazyTask.Value;
        }

        protected abstract Task<string?> FetchSecretAsync(string name, CancellationToken cancellationToken);
    }

    // Future extension idea: add a VaultSecretProvider that derives from CachedSecretProviderBase and
    // fetches secrets from HashiCorp Vault using the Vault HTTP API or official SDK.
}

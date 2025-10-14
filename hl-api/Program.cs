// hl-api/Program.cs
using Amazon.Extensions.NETCore.Setup;
using Amazon.SecretsManager;
using Amazon.SimpleSystemsManagement;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Data.SqlClient;
using HLApi.Data;
using HLApi.Services;
using HLApi.Services.Secrets;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDefaultAWSOptions(builder.Configuration.GetAWSOptions());
builder.Services.AddAWSService<IAmazonSimpleSystemsManagement>();
builder.Services.AddAWSService<IAmazonSecretsManager>();

builder.Services.Configure<JwtSecretOptions>(builder.Configuration.GetSection("Secrets:Jwt"));
builder.Services.Configure<RdsSecretOptions>(builder.Configuration.GetSection("Secrets:Rds"));

builder.Services.AddSingleton<SsmParameterStoreProvider>();
builder.Services.AddSingleton<SecretsManagerProvider>();
builder.Services.AddSingleton<ISecretProvider>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var backend = Environment.GetEnvironmentVariable("SECRETS_BACKEND")
                  ?? configuration["Secrets:Backend"];

    return backend?.Equals("sm", StringComparison.OrdinalIgnoreCase) == true
        ? sp.GetRequiredService<SecretsManagerProvider>()
        : sp.GetRequiredService<SsmParameterStoreProvider>();
    // Future vault integration: register VaultSecretProvider and switch here via SECRETS_BACKEND=vault or Secrets:Backend=vault.
});

builder.Services.AddSingleton<JwtSecretAccessor>();
builder.Services.AddSingleton<RdsCredentialsAccessor>();

builder.Services.AddDbContext<AppDbContext>((serviceProvider, options) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    var logger = serviceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("DbConnectionFactory");
    var connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection is required");

    try
    {
        var credentialsAccessor = serviceProvider.GetRequiredService<RdsCredentialsAccessor>();
        var credentials = credentialsAccessor.GetCredentialsAsync().GetAwaiter().GetResult();

        if (credentials is not null)
        {
            var sqlBuilder = new SqlConnectionStringBuilder(connectionString);

            if (!string.IsNullOrEmpty(credentials.Username))
            {
                sqlBuilder.UserID = credentials.Username;
            }

            if (!string.IsNullOrEmpty(credentials.Password))
            {
                sqlBuilder.Password = credentials.Password;
            }

            if (!string.IsNullOrEmpty(credentials.Database))
            {
                sqlBuilder.InitialCatalog = credentials.Database;
            }

            if (!string.IsNullOrEmpty(credentials.Endpoint))
            {
                var dataSource = credentials.Endpoint;
                if (!dataSource.Contains(',', StringComparison.Ordinal) && credentials.Port > 0)
                {
                    dataSource = $"{dataSource},{credentials.Port}";
                }

                sqlBuilder.DataSource = dataSource;
            }

            connectionString = sqlBuilder.ConnectionString;
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to build connection string from secrets");
        throw;
    }

    options.UseSqlServer(connectionString, sqlOptions => sqlOptions.EnableRetryOnFailure());
});

builder.Services.AddCors(options =>
{
    var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();

    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (allowedOrigins != null && allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer();

builder.Services.AddSingleton<IPostConfigureOptions<JwtBearerOptions>, ConfigureJwtBearerOptions>();

builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

builder.Services.AddSingleton<TokenService>(); 


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("DefaultCorsPolicy");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/healthz", () => Results.Ok("ok"));

app.Run();

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using HLApi.Data;

namespace HLApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DatabaseController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<DatabaseController> _logger;

    public DatabaseController(AppDbContext context, IConfiguration configuration, ILogger<DatabaseController> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpPost("initialize")]
    public async Task<IActionResult> InitializeDatabase()
    {
        var result = new DatabaseInitResult();

        try
        {
            _logger.LogInformation("🔧 Starting database initialization...");

            // Step 1: Check database connection
            var connectionTest = await TestDatabaseConnection();
            result.ConnectionTest = connectionTest;

            if (!connectionTest.Success)
            {
                result.Success = false;
                result.Message = "Database connection failed";
                return BadRequest(result);
            }

            // Step 2: Check if database exists
            var dbExists = await CheckDatabaseExists();
            result.DatabaseExists = dbExists;

            // Step 3: Check if tables exist
            var tablesExist = await CheckTablesExist();
            result.TablesExist = tablesExist;

            // Step 4: Create tables if they don't exist
            if (!tablesExist.Success || tablesExist.TableCount == 0)
            {
                _logger.LogInformation("📋 Creating tables...");
                var tableCreation = await CreateDealsTable();
                result.TableCreation = tableCreation;

                if (!tableCreation.Success)
                {
                    result.Success = false;
                    result.Message = $"Table creation failed: {tableCreation.Message}";
                    return BadRequest(result);
                }
            }

            // Step 5: Verify everything is working
            var finalCheck = await CheckTablesExist();
            result.FinalVerification = finalCheck;

            result.Success = finalCheck.Success && finalCheck.TableCount > 0;
            result.Message = result.Success ? "Database initialization completed successfully" : "Database initialization failed";

            _logger.LogInformation(result.Message);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database initialization failed");
            result.Success = false;
            result.Message = $"Database initialization error: {ex.Message}";
            result.Error = ex.Message;
            return StatusCode(500, result);
        }
    }

    [HttpGet("status")]
    public async Task<IActionResult> GetDatabaseStatus()
    {
        try
        {
            var status = new DatabaseStatus();

            status.ConnectionTest = await TestDatabaseConnection();
            status.DatabaseExists = await CheckDatabaseExists();
            status.TablesExist = await CheckTablesExist();

            return Ok(status);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database status check failed");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    private async Task<OperationResult> TestDatabaseConnection()
    {
        try
        {
            await _context.Database.OpenConnectionAsync();
            await _context.Database.CloseConnectionAsync();
            return new OperationResult { Success = true, Message = "Database connection successful" };
        }
        catch (Exception ex)
        {
            return new OperationResult { Success = false, Message = $"Database connection failed: {ex.Message}", Error = ex.Message };
        }
    }

    private async Task<OperationResult> CheckDatabaseExists()
    {
        try
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                return new OperationResult { Success = false, Message = "Connection string not found", Error = "Configuration error" };
            }

            // Parse database name from connection string manually
            var parts = connectionString.Split(';').Select(p => p.Trim()).ToArray();
            var databaseName = "hldeals"; // Default to what we know it should be

            foreach (var part in parts)
            {
                if (part.ToLower().StartsWith("database="))
                {
                    databaseName = part.Split('=').Last().Trim();
                    break;
                }
                if (part.ToLower().StartsWith("initial catalog="))
                {
                    databaseName = part.Split('=').Last().Trim();
                    break;
                }
            }

            return new OperationResult { Success = true, Message = $"Database '{databaseName}' configured in connection string" };
        }
        catch (Exception ex)
        {
            return new OperationResult { Success = false, Message = $"Error checking database: {ex.Message}", Error = ex.Message };
        }
    }

    private async Task<TablesExistResult> CheckTablesExist()
    {
        try
        {
            var entityTypes = _context.Model.GetEntityTypes();
            var tables = entityTypes.ToDictionary(et => et.DisplayName() ?? "Unknown", et => et.GetTableName() ?? "Unknown");

            var result = new TablesExistResult { Success = true, Tables = tables };

            // Check specific tables we care about
            result.TableCount = tables.Count;

            if (tables.Values.Contains("Deals"))
            {
                result.DealsTableExists = true;
                result.Message = $"{tables.Count} tables found including Deals table";
            }
            else
            {
                result.DealsTableExists = false;
                result.Message = $"{tables.Count} tables found, but Deals table missing";
            }

            return result;
        }
        catch (Exception ex)
        {
            return new TablesExistResult { Success = false, Message = $"Error checking tables: {ex.Message}", Error = ex.Message };
        }
    }

    private async Task<OperationResult> CreateDealsTable()
    {
        try
        {
            var sql = @"
                IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Deals')
                BEGIN
                    CREATE TABLE [Deals] (
                        [Id] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
                        [Name] nvarchar(max) NULL,
                        [Client] nvarchar(max) NULL,
                        [Amount] decimal(18,2) NOT NULL DEFAULT 0,
                        [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE()
                    );
                END
                ELSE
                BEGIN
                    PRINT 'Deals table already exists';
                END";

            await _context.Database.ExecuteSqlRawAsync(sql);
            return new OperationResult { Success = true, Message = "Deals table created or verified successfully" };
        }
        catch (Exception ex)
        {
            return new OperationResult { Success = false, Message = $"Error creating Deals table: {ex.Message}", Error = ex.Message };
        }
    }
}

public class DatabaseInitResult
{
    public bool Success { get; set; } = false;
    public string Message { get; set; } = "";
    public string? Error { get; set; }
    public OperationResult ConnectionTest { get; set; } = new();
    public OperationResult DatabaseExists { get; set; } = new();
    public TablesExistResult TablesExist { get; set; } = new();
    public OperationResult TableCreation { get; set; } = new();
    public TablesExistResult FinalVerification { get; set; } = new();
}

public class DatabaseStatus
{
    public OperationResult ConnectionTest { get; set; } = new();
    public OperationResult DatabaseExists { get; set; } = new();
    public TablesExistResult TablesExist { get; set; } = new();
}

public class OperationResult
{
    public bool Success { get; set; } = false;
    public string Message { get; set; } = "";
    public string? Error { get; set; }
}

public class TablesExistResult : OperationResult
{
    public int TableCount { get; set; } = 0;
    public bool DealsTableExists { get; set; } = false;
    public Dictionary<string, string>? Tables { get; set; }
}

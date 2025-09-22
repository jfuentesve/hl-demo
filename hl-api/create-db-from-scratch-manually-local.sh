


sqlcmd -S localhost,1433 -U sa -P 'StrongP4ssw0rd123!' -C -Q "IF SUSER_ID('hladmin') IS NULL CREATE LOGIN hladmin WITH PASSWORD=***REDACTED***!'; SELECT name,type_desc FROM sys.server_principals WHERE name='hladmin';"



sqlcmd -S localhost,1433 -U sa -P 'StrongP4ssw0rd123!' -C -Q "IF DB_ID('hldeals') IS NULL CREATE DATABASE hldeals; SELECT name FROM sys.databases WHERE name='hldeals';"


sqlcmd -S localhost,1433 -U sa -P 'StrongP4ssw0rd123!' -C -Q "USE hldeals; IF USER_ID('hladmin') IS NULL CREATE USER hladmin FOR LOGIN hladmin; SELECT name,type_desc FROM sys.database_principals WHERE name='hladmin';"

# make hladmin a db_owner
sqlcmd -S localhost,1433 -U sa -P 'StrongP4ssw0rd123!' -C -Q "
USE hldeals;
IF NOT EXISTS (
  SELECT 1
  FROM sys.database_role_members drm
  JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id AND r.name = 'db_owner'
  JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id AND m.name = 'hladmin'
)
BEGIN
  ALTER ROLE db_owner ADD MEMBER hladmin;
END;
SELECT r.name AS role_name, m.name AS member_name
FROM sys.database_role_members drm
JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
WHERE m.name = 'hladmin';
"

#Create dbo.DEals to work with EF Core.

sqlcmd -S localhost,1433 -U hladmin -P 'StrongP4ssw0rd123!' -C -d hldeals -Q "
IF OBJECT_ID(N'dbo.Deals','U') IS NULL
BEGIN
  CREATE TABLE dbo.Deals
  (
    Id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    Title         NVARCHAR(200)        NOT NULL,
    Description   NVARCHAR(MAX)        NULL,
    Client        NVARCHAR(200)        NOT NULL CONSTRAINT DF_Deals_Client DEFAULT (N''),
    Amount        DECIMAL(18,2)        NOT NULL CONSTRAINT DF_Deals_Amount DEFAULT (0),
    CurrencyCode  CHAR(3)              NOT NULL CONSTRAINT DF_Deals_Currency DEFAULT ('USD'),
    Status        NVARCHAR(50)         NOT NULL CONSTRAINT DF_Deals_Status DEFAULT ('New'),
    CreatedAt     DATETIME2(0)         NOT NULL CONSTRAINT DF_Deals_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt     DATETIME2(0)         NULL,
    IsDeleted     BIT                  NOT NULL CONSTRAINT DF_Deals_IsDeleted DEFAULT (0)
  );
END;
"



-- Simple script to create the Deals table in hldeals database
-- This will create the table if it doesn't already exist

USE hldeals;

IF OBJECT_ID('Deals', 'U') IS NULL
BEGIN
    CREATE TABLE Deals (
        Id int IDENTITY(1,1) PRIMARY KEY,
        Name nvarchar(max) NULL,
        Client nvarchar(max) NULL,
        Amount decimal(18,2) NOT NULL,
        CreatedAt datetime2 NOT NULL DEFAULT GETUTCDATE()
    );

    PRINT 'Deals table created successfully!';
END
ELSE
    PRINT 'Deals table already exists.';

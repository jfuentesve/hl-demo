-- Manual EF Core migration for HL-API Deals table
-- Create Deals table in hldeals database

USE hldeals;

-- Create Deals table
CREATE TABLE [Deals] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max) NULL,
    [Client] nvarchar(max) NULL,
    [Amount] decimal(18,2) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Deals] PRIMARY KEY ([Id])
);

-- Create indexes for better performance
CREATE INDEX [IX_Deals_CreatedAt] ON [Deals] ([CreatedAt]);
CREATE INDEX [IX_Deals_Client] ON [Deals] ([Client]);

PRINT 'Deals table created successfully in hldeals database';

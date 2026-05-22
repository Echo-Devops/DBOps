/*
    DBOps - Backup Credentials

    Creates SQL Server credentials for all Azure Blob Storage backup containers
    using Managed Identity authentication.

    Deploy with: sqlcmd -S <server> -i V3-1-Credentials.sql [-v StorageAccountName="myaccount"]
*/

-- SQLCMD variable defaults (override with sqlcmd -v)
:setvar StorageAccountName "redazprodechobackups"

-- Drop and recreate credentials (idempotent)
IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'https://$(StorageAccountName).blob.core.windows.net/v3-1-weeklychain')
    DROP CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-1-weeklychain];

CREATE CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-1-weeklychain]
WITH IDENTITY = 'Managed Identity';
GO

IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'https://$(StorageAccountName).blob.core.windows.net/v3-2-copyonly-monthlyfull')
    DROP CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-2-copyonly-monthlyfull];

CREATE CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-2-copyonly-monthlyfull]
WITH IDENTITY = 'Managed Identity';
GO

IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'https://$(StorageAccountName).blob.core.windows.net/v3-3-copyonly-annual')
    DROP CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-3-copyonly-annual];

CREATE CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-3-copyonly-annual]
WITH IDENTITY = 'Managed Identity';
GO

IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'https://$(StorageAccountName).blob.core.windows.net/v3-4-copyonly-dailyfull')
    DROP CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-4-copyonly-dailyfull];

CREATE CREDENTIAL [https://$(StorageAccountName).blob.core.windows.net/v3-4-copyonly-dailyfull]
WITH IDENTITY = 'Managed Identity';
GO

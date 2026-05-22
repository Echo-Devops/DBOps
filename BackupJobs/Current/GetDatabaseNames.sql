/*
    Get current database names on the SQL Server instance.
    Use this to identify which databases to include in the DatabaseList SQLCMD variable.
*/

SELECT
    name
FROM sys.databases
WHERE database_id > 4          -- exclude system databases (master, tempdb, model, msdb)
  AND state_desc = 'ONLINE'
  AND name NOT IN ('distribution', 'ReportServer', 'ReportServerTempDB')
ORDER BY name
GO

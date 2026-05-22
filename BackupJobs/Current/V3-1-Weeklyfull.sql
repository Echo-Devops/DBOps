/*
    DBOps - BackupV3-1 - Weeklyfull

    Parametric SQL Agent job for WEEKLY FULL backups to Azure Blob Storage.
    All databases in the list get individual job steps.

    Deploy with: sqlcmd -S <server> -i V3-1-Weeklyfull.sql [-v DatabaseList="db1,db2" StorageAccountName="myaccount" ...]
*/

-- SQLCMD variable defaults (override with sqlcmd -v)
:setvar StorageAccountName "redazprodechobackups"
:setvar StoredProcedure "dpAudit.dbo.DatabaseBackup"
:setvar OperatorName "SQL Admins"
:setvar OwnerLogin "sa"
:setvar JobEnabled 1
:setvar ScheduleStartTime 190000

-- Derived constants (do not override)
:setvar JobName "DBOps - BackupV3-1 - Weeklyfull - @Saturday 19:00 PM - Dur:--mins~"
:setvar ContainerPath "v3-1-weeklychain/weeklyfull"
:setvar ScheduleName "BACKUP WEEKLYFULL SCHEDULE SATURDAY 19:00"

USE [msdb]
GO

-- Idempotent: drop existing job if it exists
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'$(JobName)')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'$(JobName)', @delete_unused_schedule = 1
END
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

-- Create category if not exists
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N'Database Maintenance' AND category_class = 1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB', @type = N'LOCAL', @name = N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

-- Create the job
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job
    @job_name = N'$(JobName)',
    @enabled = $(JobEnabled),
    @notify_level_eventlog = 0,
    @notify_level_email = 2,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0,
    @description = N'Parametric V3-1 Weeklyfull backup job. Deployed via DBOps.',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'$(OwnerLogin)',
    @notify_email_operator_name = N'$(OperatorName)',
    @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Populate database list from online user databases
DECLARE @Databases TABLE (Id INT IDENTITY(1,1), DbName NVARCHAR(128))
INSERT INTO @Databases (DbName)
SELECT name
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
  AND name NOT IN ('distribution', 'ReportServer', 'ReportServerTempDB')
ORDER BY name

DECLARE @TotalSteps INT = (SELECT COUNT(*) FROM @Databases)
DECLARE @i INT = 1
DECLARE @DbName NVARCHAR(128)
DECLARE @StepName NVARCHAR(256)
DECLARE @Command NVARCHAR(MAX)
DECLARE @OnSuccessAction INT

WHILE @i <= @TotalSteps
BEGIN
    SELECT @DbName = DbName FROM @Databases WHERE Id = @i
    SET @StepName = @DbName + N'-$(StorageAccountName)-$(ContainerPath)'
    SET @OnSuccessAction = CASE WHEN @i = @TotalSteps THEN 1 ELSE 3 END

    SET @Command = N'EXECUTE $(StoredProcedure)
@Databases = ''' + @DbName + N''',
@URL = ''https://$(StorageAccountName).blob.core.windows.net/$(ContainerPath)'',
@BackupType = ''FULL'',
@Compress = ''Y'',
@CheckSum = ''N'',
@BufferCount = 50,
@MaxTransferSize = 4194304,
@NumberOfFiles = 1,
@LogToTable = ''Y'',
@DirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'',
@AvailabilityGroupDirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'''

    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep
        @job_id = @jobId,
        @step_name = @StepName,
        @step_id = @i,
        @cmdexec_success_code = 0,
        @on_success_action = @OnSuccessAction,
        @on_success_step_id = 0,
        @on_fail_action = 2,
        @on_fail_step_id = 0,
        @retry_attempts = 0,
        @retry_interval = 0,
        @os_run_priority = 0,
        @subsystem = N'TSQL',
        @command = @Command,
        @database_name = N'master',
        @flags = 0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    SET @i = @i + 1
END

-- Set start step
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Schedule: every Saturday at 19:00
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule
    @job_id = @jobId,
    @name = N'$(ScheduleName)',
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 64,
    @freq_subday_type = 1,
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1,
    @active_start_date = 20231027,
    @active_end_date = 99991231,
    @active_start_time = $(ScheduleStartTime),
    @active_end_time = 235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Target server
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

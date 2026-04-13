USE [msdb]
GO

/****** Object:  Job [DBAdmin - BackupV2 - CopyOnly dailyfull - ALL_DATABASES - @Everyday 11:AM - Dur:7mins~]    Script Date: 4/13/2026 12:37:50 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 4/13/2026 12:37:50 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin - BackupV2 - CopyOnly dailyfull - ALL_DATABASES - @Everyday 11:AM - Dur:7mins~', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Please refer to https://bitbucket.org/selectedinterventions/sql-jobs/src/master/ for the full documentation.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL Admins', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [echo2_redazprodechobackups_v22copyonlydailyfull]    Script Date: 4/13/2026 12:37:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'echo2_redazprodechobackups_v22copyonlydailyfull', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE SQLAdmin.dbo.DatabaseBackup 
@Databases = ''echo2'', 
@URL = ''https://redazprodechobackups.blob.core.windows.net/v22copyonlydailyfull'',
@BackupType = ''FULL'', 
@Compress = ''Y'', 
@CheckSum = ''N'', 
@BufferCount = 50,
@MaxTransferSize = 4194304,
@NumberOfFiles = 2, 
@CopyOnly = ''Y'', 
@LogToTable = ''Y'', 
@DirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'',
@AvailabilityGroupDirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SQLAdmin_redazprodechobackups_v22copyonlydailyfull]    Script Date: 4/13/2026 12:37:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQLAdmin_redazprodechobackups_v22copyonlydailyfull', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE SQLAdmin.dbo.DatabaseBackup 
@Databases = ''SQLAdmin'', 
@URL = ''https://redazprodechobackups.blob.core.windows.net/v22copyonlydailyfull'',
@BackupType = ''FULL'', 
@Compress = ''Y'', 
@CheckSum = ''N'', 
@BufferCount = 50,
@MaxTransferSize = 4194304,
@CopyOnly = ''Y'', 
@LogToTable = ''Y'', 
@DirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'',
@AvailabilityGroupDirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [dpAudit_redazprodechobackups_v22copyonlydailyfull]    Script Date: 4/13/2026 12:37:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'dpAudit_redazprodechobackups_v22copyonlydailyfull', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE SQLAdmin.dbo.DatabaseBackup 
@Databases = ''dpAudit'', 
@URL = ''https://redazprodechobackups.blob.core.windows.net/v22copyonlydailyfull'',
@BackupType = ''FULL'', 
@Compress = ''Y'', 
@CheckSum = ''N'', 
@BufferCount = 50,
@MaxTransferSize = 4194304,
@CopyOnly = ''Y'', 
@LogToTable = ''Y'', 
@DirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'',
@AvailabilityGroupDirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSISDB_redazprodechobackups_v22copyonlydailyfull]    Script Date: 4/13/2026 12:37:50 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SSISDB_redazprodechobackups_v22copyonlydailyfull', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE SQLAdmin.dbo.DatabaseBackup 
@Databases = ''SSISDB'', 
@URL = ''https://redazprodechobackups.blob.core.windows.net/v22copyonlydailyfull'',
@BackupType = ''FULL'', 
@Compress = ''Y'', 
@CheckSum = ''N'', 
@BufferCount = 50,
@MaxTransferSize = 4194304,
@CopyOnly = ''Y'', 
@LogToTable = ''Y'', 
@DirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}'',
@AvailabilityGroupDirectoryStructure = ''{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'BACKUP USER_DATABASES SCHEDULE DAILY', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=15, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=0, 
		@active_start_date=20231027, 
		@active_end_date=99991231, 
		@active_start_time=110000, 
		@active_end_time=235959, 
		@schedule_uid=N'44a48c08-f123-4d4b-b3be-46289a072a12'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



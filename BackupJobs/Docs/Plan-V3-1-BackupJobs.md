# Plan: Parametric V3 Backup Job Scripts (Log, Dailydiff, Weeklyfull)

## Context
Replace the hardcoded backup job script with parametric, environment-deployable scripts following the documented V3 backup architecture. The "main backup chain" (Log, Dailydiff, Weeklyfull) all target the `v3-1-weeklychain` container with sub-paths. Per requirements, backup-specific parameters (BackupType, Compress, CheckSum, etc.) are **hardcoded per job type**, not parametric. Only environment-varying values (storage account, stored procedure, operator, schedule start time) are SQLCMD variables.

## Files Created
Three separate SQL scripts under `Current/`:

| File | Job Name | Schedule | Container Sub-path |
|---|---|---|---|
| `Current/V3-1-Log.sql` | `DBOps - BackupV3-1 - Log - @Every15mins - Dur:--mins~` | Every 15 mins | `v3-1-weeklychain/logs` |
| `Current/V3-1-Dailydiff.sql` | `DBOps - BackupV3-1 - Dailydiff - @Everyday 22:00 PM - Dur:--mins~` | Daily 22:00 | `v3-1-weeklychain/dailydiff` |
| `Current/V3-1-Weeklyfull.sql` | `DBOps - BackupV3-1 - Weeklyfull - @Saturday 19:00 PM - Dur:--mins~` | Saturday 19:00 | `v3-1-weeklychain/weeklyfull` |

Supporting script:
| `Current/GetDatabaseNames.sql` | Standalone query to list online user databases |

## SQLCMD Variables

| Variable | Default | Purpose |
|---|---|---|
| `StorageAccountName` | `redazprodechobackups` | Azure storage account name |
| `StoredProcedure` | `dpAudit.dbo.DatabaseBackup` | Fully qualified backup SP name |
| `OperatorName` | `SQL Admins` | SQL Agent Operator for email notifications |
| `OwnerLogin` | `sa` | Job owner login |
| `JobEnabled` | `1` | 1=enabled, 0=disabled |
| `ScheduleStartTime` | Varies per job (0, 220000, 190000) | Schedule start time in HHMMSS format |

## Database List Population
The `DatabaseList` SQLCMD variable was removed. Instead, each script dynamically queries `sys.databases` at deploy time:

```sql
SELECT name FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
  AND name NOT IN ('distribution', 'ReportServer', 'ReportServerTempDB')
ORDER BY name
```

**Log backup only**: additionally filters on `recovery_model_desc = 'FULL'` since SIMPLE recovery model databases do not support log backups.

## Hardcoded (NOT parametric) per Job Type

**LOG** — from doc section "1-LOG BACKUP":
```
@BackupType = 'LOG', @Compress = 'Y', @Verify = 'Y', @CheckSum = 'N',
@OverrideBackupPreference = 'Y', @LogToTable = 'Y'
```
(No BufferCount, MaxTransferSize, NumberOfFiles)

**DAILYDIFF** — from doc section "2-DAILY DIFF BACKUP":
```
@BackupType = 'DIFF', @Compress = 'Y', @CheckSum = 'N', @Verify = 'Y',
@BufferCount = 50, @MaxTransferSize = 4194304, @NumberOfFiles = 1, @LogToTable = 'Y'
```

**WEEKLYFULL** — from doc section "3-WEEKLY FULL BACKUP":
```
@BackupType = 'FULL', @Compress = 'Y', @CheckSum = 'N',
@BufferCount = 50, @MaxTransferSize = 4194304, @NumberOfFiles = 1, @LogToTable = 'Y'
```

## Step Naming Convention
`{DbName}-{StorageAccountName}-{ContainerPath}`
Example: `echo2-redazprodechobackups-v3-1-weeklychain/logs`

## Script Structure
1. SQLCMD variable declarations with defaults
2. `USE [msdb]`
3. Idempotent cleanup (`sp_delete_job` if job exists)
4. `BEGIN TRANSACTION`
5. Create category `Database Maintenance` if not exists
6. `sp_add_job` with parametric operator, owner, enabled
7. Query `sys.databases` into `@Databases` table variable
8. `WHILE` loop: one `sp_add_jobstep` per database
9. `sp_update_job` start step = 1
10. `sp_add_jobschedule` with parametric `ScheduleStartTime`
11. `sp_add_jobserver` (local)
12. `COMMIT` / `QuitWithRollback` / `EndSave`

## Deployment Examples
```bash
# Prod (all defaults)
sqlcmd -S prodserver -i Current/V3-1-Log.sql
sqlcmd -S prodserver -i Current/V3-1-Dailydiff.sql
sqlcmd -S prodserver -i Current/V3-1-Weeklyfull.sql

# Dev (different storage account, different schedule)
sqlcmd -S devserver -i Current/V3-1-Log.sql \
  -v StorageAccountName="devbackups" \
     StoredProcedure="SQLAdmin.dbo.DatabaseBackup" \
     OperatorName="Dev DBAs" \
     ScheduleStartTime="60000"
```

## Verification
1. Run with `sqlcmd -p` (parse-only) to verify syntax
2. Deploy to test SQL Server and confirm correct number of steps matches database count
3. Verify step names follow naming convention
4. Re-run script to confirm idempotency (drop + recreate)
5. Test `sqlcmd -v` overrides for StorageAccountName and ScheduleStartTime

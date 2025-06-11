CREATE PROCEDURE [dbo].[sp_CreateOrUpdateExtendedEventSessions]
	@startSessions bit = 1,
	@logPath nvarchar(max) = 'G:\Logs_SQL'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql nvarchar(max);

	-- Создаем каталог для логов, если его еще нет
	SET @sql = 'EXEC master.sys.xp_create_subdir N''' + @logPath + ''''
	EXECUTE sp_executesql @sql
	
	-- Сессия сбора по ошибкам
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'Errors'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [Errors] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [Errors] ON SERVER
ADD EVENT sqlserver.error_reported(     ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.username)
	WHERE ([severity]>(10)))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\Errors.xel'',max_file_size=(100),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON);
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [Errors] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END

	-- Сессия сбора тяжелых запросов по ЦП
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'HeavyQueryByCPU'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [HeavyQueryByCPU] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [HeavyQueryByCPU] ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000))))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\HeavyQueryByCPU.xel'',max_file_size=(500),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [HeavyQueryByCPU] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END


	-- Сессия сбора тяжелых запросов по чтениям
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'HeavyQueryByReads'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [HeavyQueryByReads] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [HeavyQueryByReads] ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([logical_reads]>(12500))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([logical_reads]>(12500)))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\HeavyQueryByReads.xel'',max_file_size=(500),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [HeavyQueryByReads] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END

	-- Сессия сбора информации об ожиданиях на блокировках
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'BlocksAndDeadlocksAnalyse'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER'
		EXEC sp_executesql @sql
	END

	SET @sql = N'
EXEC sp_configure ''show advanced options'', 1;
RECONFIGURE;
EXEC sp_configure ''blocked process threshold'', ''5'';
RECONFIGURE;
'
	EXEC sp_executesql @sql

	SET @sql = N'
CREATE EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_instance_name)),
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_instance_name))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\LockAndDeadlockAnalyzeReports.xel'',max_file_size=(100),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END
END
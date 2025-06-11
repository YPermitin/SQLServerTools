ALTER PROCEDURE [dbo].[sp_FixMissingStatisticOnAlwaysOnReplica]
	@databaseName sysname = null
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max),
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

    IF @databaseName IS NOT NULL AND DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END

	DECLARE @currentDatabaseName sysname;

	DECLARE databases_cursor CURSOR  
	FOR SELECT
		[name]
	FROM sys.databases
	WHERE (@databaseName is null or [name] = @databaseName)
		AND [name] in (
			select distinct
				database_name
			from sys.dm_hadr_database_replica_cluster_states dhdrcs
				inner join sys.availability_replicas ar
				on dhdrcs.replica_id = ar.replica_id
			where availability_mode_desc = 'ASYNCHRONOUS_COMMIT'
		)
	OPEN databases_cursor;
	FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT @currentDatabaseName;

		DECLARE @sql nvarchar(max);
		SET @sql = CAST('
		USE [' AS nvarchar(max)) + CAST(@currentDatabaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;

		DECLARE
			@objid int,
			@statsid INT,
			@NeedResetCache bit = 0,
			@dbname sysname = DB_NAME();
		DECLARE cur CURSOR FOR
 
		SELECT s.object_id, s.stats_id
		FROM sys.stats AS s
			JOIN sys.objects AS o
			ON s.object_id = o.object_id
		WHERE o.is_ms_shipped = 0
		OPEN cur
		FETCH NEXT FROM cur INTO @objid, @statsid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if not exists (select *
			from [sys].[dm_db_stats_properties] (@objid, @statsid))
		BEGIN
 
				PRINT (convert(varchar(10), @objid) + ''|'' + convert(varchar(10), @statsid))
 
				IF(@useMonitoringDatabase = 1)
				BEGIN
					INSERT [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[AlwaysOnReplicaMissingStats]
					SELECT @dbname, o.[name], s.[name], GETDATE()
					FROM sys.stats AS s JOIN sys.objects AS o
						ON s.object_id = o.object_id
					WHERE o.object_id = @objid AND s.stats_id = @statsid
				END
				
				SET @NeedResetCache = 1
 
			END
			FETCH NEXT FROM cur INTO @objid, @statsid
		END
		CLOSE cur
		DEALLOCATE cur
 
		IF @NeedResetCache = 1
		BEGIN
			PRINT ''Был сброшен системный кэш для базы данных''
			PRINT @dbname
			DBCC FREESYSTEMCACHE(@dbname);
		END
		' AS nvarchar(max))

		EXECUTE sp_executesql
			@sql,
			N'@useMonitoringDatabase bit, @monitoringDatabaseName sysname',
			@useMonitoringDatabase, @monitoringDatabaseName

		FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;
	END
	CLOSE databases_cursor;  
	DEALLOCATE databases_cursor;
END
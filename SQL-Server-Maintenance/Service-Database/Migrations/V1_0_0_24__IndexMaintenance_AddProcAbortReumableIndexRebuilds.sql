CREATE PROCEDURE [dbo].[sp_AbortResumableIndexRebuilds] 
	@databaseNameFilter nvarchar(max) = null,
	@dataFileName nvarchar(max) = null
AS
BEGIN
	SET NOCOUNT ON;
		
	IF OBJECT_ID('tempdb..#controlDataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #controlDataFileInfoByDatabases;
	CREATE TABLE #controlDataFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		DataFileName varchar(255),
		DataFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[DataSizeMB] numeric(15,0),
		[DataMaxSizeMB] numeric(15,0),
		[DataFileCanGrow] bit,
		[DataFileFreeSpaceMB] numeric(15,0),
		[ResumableRebuildDataFileUsageMb] numeric(15,0),
		[SqlAbort] nvarchar(max)
	);

	DECLARE 
		@RunDate datetime = GetDate(),
		@startDate datetime = GetDate(),
		@finishDate datetime = GetDate(),
		@MaintenanceActionLogId bigint,
		@SqlStatement nvarchar(MAX),
		@CurrentDatabaseName sysname,
		@message nvarchar(max);
	DECLARE ControlDatabaseList CURSOR LOCAL FAST_FORWARD FOR
		SELECT [name] FROM sys.databases 
		WHERE state_desc = 'ONLINE'
			AND NOT [name] IN ('master', 'tempdb', 'model', 'msdb');;
	OPEN ControlDatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM ControlDatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;

		-- Заполняем информации о файлах данных
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'
IF(EXISTS(SELECT * FROM sys.index_resumable_operations))
BEGIN
	INSERT INTO #controlDataFileInfoByDatabases
	SELECT
		DB_NAME(f.database_id) AS [Database],
		f.[name] AS [DataFileName],
		f.physical_name AS [DataFilePath],
		volume_mount_point AS [Disk],
		available_bytes/1048576 as [DiskFreeSpaceMB],
		CAST(f.size AS bigint) * 8 / 1024 AS [DataSizeMB],
		CAST(f.size AS bigint) * 8 / 1024 + CAST(available_bytes/1048576 AS bigint) AS [DataMaxSizeMB],
		CASE 
			WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
			THEN 0
			ELSE 1
		END AS [DataFileCanGrow],
		size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [DataFileFreeSpaceMB],
		ISNULL(rir.DataFileUsageMb, 0) AS [ResumableRebuildDataFileUsageMb],
		''USE ['' + DB_NAME(f.database_id) + '']; ALTER INDEX ['' + rir.[name] + ''] ON ['' + [SchemaName] + ''].['' + [ObjectName] + ''] ABORT'' AS [SqlAbort]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	  INNER JOIN (
			SELECT 
				disks.FileName,
				disks.PhysicalName,
				iro.object_id,
				OBJECT_NAME(iro.object_id) AS [ObjectName],
				OBJECT_SCHEMA_NAME(iro.object_id) AS [SchemaName],
				iro.index_id,
				iro.name,
				iro.page_count * 8 / 1024 AS [DataFileUsageMb]
			FROM sys.index_resumable_operations iro
				INNER JOIN (
					select 
						p.object_id AS [ObjectId],
						p.[index_id] AS [IndexId],
						ISNULL(p.[partition_number], 1) AS [PartitionNumber],
						f.[name] AS [FileName],
						f.physical_name AS [PhysicalName]
					from sys.allocation_units u 
						join sys.database_files f on u.data_space_id = f.data_space_id 
						join sys.partitions p on u.container_id = p.hobt_id
				) disks
				ON iro.object_id = disks.ObjectId
					AND iro.index_id = disks.IndexId
					AND ISNULL(iro.partition_number, 1) = disks.PartitionNumber
	  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
	WHERE [type_desc] = ''ROWS''
		and f.database_id = DB_ID()
END';
				
		BEGIN TRY
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH
	END

	DECLARE
		@currentDataFileName nvarchar(max),
		@currentResumableRebuildDataFileUsageMb bigint,
		@currentSqlAbort nvarchar(max);
	DECLARE controlDataFileUsageByResumableRebuild CURSOR FOR
	SELECT 
		DatabaseName,
		DataFileName,
		ResumableRebuildDataFileUsageMb,
		[SqlAbort]
	FROM #controlDataFileInfoByDatabases
	WHERE (@databaseNameFilter IS NULL OR [DatabaseName] = @databaseNameFilter)
		AND (@dataFileName IS NULL OR DataFileName = @dataFileName);
	OPEN controlDataFileUsageByResumableRebuild;
	FETCH NEXT FROM controlDataFileUsageByResumableRebuild 
	INTO @currentDatabaseName, @currentDataFileName, @currentResumableRebuildDataFileUsageMb, @currentSqlAbort;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @message = 
			'Для базы данных ' + @currentDatabaseName + ' файла ' + @currentDataFileName + ' отменена возобновляемая операция перестроения. ' +
			'Команда: ' + @currentSqlAbort + '.';
		PRINT @message

		BEGIN TRY
			EXECUTE(@currentSqlAbort);
		END TRY
		BEGIN CATCH
			SET @message = 'Ошибка: ' + ERROR_MESSAGE() + '. ' + 'Не удалось завершить возобновляемую операцию.'
			PRINT @message
		END CATCH

		EXECUTE [dbo].[sp_add_maintenance_action_log]
			''
			,''
			,'RESUMABLE REBULD CONTROL'
			,@RunDate
		    ,@startDate
			,@finishDate
			,@currentDatabaseName
			,0
			,@message
			,0
			,0
			,@currentSqlAbort
			,@MaintenanceActionLogId OUTPUT;

		FETCH NEXT FROM controlDataFileUsageByResumableRebuild 
		INTO @currentDatabaseName, @currentDataFileName, @currentResumableRebuildDataFileUsageMb, @currentSqlAbort;
	END
	CLOSE controlDataFileUsageByResumableRebuild;  
	DEALLOCATE controlDataFileUsageByResumableRebuild;

	IF OBJECT_ID('tempdb..#controlDataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #controlDataFileInfoByDatabases;
END
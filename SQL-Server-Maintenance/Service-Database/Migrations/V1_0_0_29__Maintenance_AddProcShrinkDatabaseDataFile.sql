CREATE PROCEDURE [dbo].[sp_ShrinkDatabaseDataFile] 
	@databaseName sysname,
	@databaseFileName nvarchar(512) = null,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@delayBetweenSteps nvarchar(8) = '00:00:10',
	@shrinkStepMb int = 10240,
	@stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3) = 1.0
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE		
	   @sql nvarchar(max)
	   ,@msg nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + @databaseName + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	IF OBJECT_ID('tempdb..#dataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #dataFileInfoByDatabases;
	CREATE TABLE #dataFileInfoByDatabases
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
		[ResumableRebuildDataFileUsageMb] numeric(15,0)
	);

	-- Заполняем информации о файлах данных
	SET @sql = N'USE '
		+ QUOTENAME(@databaseName)
		+ CHAR(13)+ CHAR(10)
		+ N'
		INSERT INTO #dataFileInfoByDatabases
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
			ISNULL(rir.DataFileUsageMb, 0) AS [ResumableRebuildDataFileUsageMb]
		FROM sys.master_files AS f CROSS APPLY 
		  sys.dm_os_volume_stats(f.database_id, f.file_id)
		  LEFT JOIN (
				SELECT 
					disks.FileName,
					disks.PhysicalName,
					SUM(iro.page_count * 8 / 1024) AS [DataFileUsageMb]
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
				GROUP BY disks.FileName, disks.PhysicalName
		  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
		WHERE [type_desc] = ''ROWS''
			and f.database_id = DB_ID()';

	BEGIN TRY			
		EXECUTE(@sql);
	END TRY
	BEGIN CATCH
		PRINT 'Не удалось получить информацию о файлах.'
	END CATCH

	IF(@databaseFileName IS NULL)
	BEGIN
		IF(EXISTS(SELECT COUNT(*) FROM #dataFileInfoByDatabases HAVING(COUNT(*) > 1)))
		BEGIN
			SET @msg = 'Required to setup parameter @databaseFileName. Database has multiple data files.';
			THROW 51000, @msg, 1;
			RETURN -1;
		END

		SELECT @databaseFileName = DataFileName FROM #dataFileInfoByDatabases
	END
	ELSE BEGIN
		PRINT 1
		IF(NOT EXISTS(SELECT * FROM #dataFileInfoByDatabases WHERE DataFileName = @databaseFileName))
		BEGIN
			SET @msg = 'Data file with name ' + @databaseFileName + 'not exists.';
			THROW 51000, @msg, 1;
			--RETURN -1;
		END
	END

	SET @sql = CAST('
	USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
	DECLARE @currentFreeSpaceDataFilePercent numeric(15,3) = 0;
	IF(NOT EXISTS(SELECT * FROM sys.index_resumable_operations))
	BEGIN
		DECLARE @totalDatabaseSize BIGINT;
		WHILE 1 = 1
		BEGIN
			-- Включаем контроль потребления ресурсов текущим соединением
			if(@timeFrom is not null and @timeTo is not null)
			BEGIN
				EXEC [SQLServerMonitoring].[dbo].[sp_AddSessionControlSetting]
					@databaseName = @databaseName,
					@workFrom = @timeFrom,
					@workTo = @timeTo,
					@timeTimeoutSec = 60,
					@abortIfLockOtherSessions = 1,
					@abortIfLockOtherSessionsTimeoutSec = 0;
			END

		  SELECT
			@totalDatabaseSize = [Size] / 128.0
		  FROM sys.database_files (NOLOCK) 
		  WHERE [name] = @databaseFileName
		  OPTION (RECOMPILE)
		  set @totalDatabaseSize = @totalDatabaseSize - @shrinkStepMb
  
		  PRINT @totalDatabaseSize

		  DBCC SHRINKFILE (@databaseFileName , @totalDatabaseSize)  

		  -- Удаляем контроль для текущей сессии
		  EXEC [SQLServerMonitoring].[dbo].[sp_RemoveSessionControlSetting];

		  -- Проверяем границу свободного пространства в файле данных
		SELECT
			@currentFreeSpaceDataFilePercent = CAST(size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS numeric(15,0)) / CAST(CAST(f.size AS bigint) * 8 / 1024 AS numeric(15,0)) * 100
		FROM sys.master_files AS f CROSS APPLY 
			sys.dm_os_volume_stats(f.database_id, f.file_id)
				LEFT JOIN (
						SELECT 
							disks.FileName,
							disks.PhysicalName,
							SUM(iro.page_count * 8 / 1024) AS [DataFileUsageMb]
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
						GROUP BY disks.FileName, disks.PhysicalName
				  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
		WHERE [type_desc] = ''ROWS'' and f.database_id = DB_ID()
			AND f.[name] = @databaseFileName;

		  if(@stopShrinkThresholdByDataFileFreeSpacePercent >= @currentFreeSpaceDataFilePercent)
		  BEGIN
			PRINT ''Достигнута граница свободного пространства. Сжатие (shrink) файла данных остановлено.''
			return
		  END

		  WAITFOR DELAY @delayBetweenSteps
		END
	END
	' AS nvarchar(max));

	EXECUTE sp_executesql
			@sql,
			N'@databaseName sysname, @databaseFileName nvarchar(512), @timeFrom TIME, @timeTo TIME, @delayBetweenSteps nvarchar(8), @shrinkStepMb int, @stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3)',
			@databaseName, @databaseFileName, @timeFrom, @timeTo, @delayBetweenSteps, @shrinkStepMb, @stopShrinkThresholdByDataFileFreeSpacePercent;
END
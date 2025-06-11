ALTER PROCEDURE [dbo].[sp_ControlTransactionLogUsage]
	@databaseNameFilter nvarchar(255) = null,
	@showDiagnosticMessages bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- Время работы задания ограничено 2 минутами, чтобы защитить
	-- зависания задания, если оно будет ожидать завершения других соединений
	DECLARE @currentDatabase nvarchar(250) = DB_NAME();
	EXECUTE [dbo].[sp_AddSessionControlSetting] 
	   @databaseName = @currentDatabase
	  ,@workFrom = '00:00:00'
	  ,@workTo = '00:00:00'
	  ,@timeTimeoutSec = 120;

	-- Очистка устаревших настроек контроля соединений
	EXEC [dbo].[sp_ClearOldSessionControlSettings];

	DECLARE @startDate datetime = GetDate(),
		@finishDate datetime = GetDate(),
		@MaintenanceActionLogId bigint;

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

	IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;
	CREATE TABLE #logFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		LogFileName varchar(255),
		LogFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[LogSizeMB] numeric(15,0),
		[LogMaxSizeMB] numeric(15,0),
		[LogFileCanGrow] bit,
		[LogFileFreeSpaceMB] numeric(15,0)
	);

	DECLARE
		@SqlStatement nvarchar(MAX)
		,@CurrentDatabaseName sysname;
	DECLARE DatabaseList CURSOR LOCAL FAST_FORWARD FOR
		SELECT name FROM sys.databases 
		WHERE state_desc = 'ONLINE' 
		AND NOT [name] IN ('master', 'tempdb', 'model', 'msdb');
	OPEN DatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM DatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;

		PRINT @CurrentDatabaseName

		-- Заполняем информации о файлах логов транзакций
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'INSERT INTO #logFileInfoByDatabases
	SELECT
		DB_NAME(f.database_id) AS [Database],
		f.[name] AS [LogFileName],
		f.physical_name AS [LogFilePath],
		volume_mount_point AS [Disk],
		available_bytes/1048576 as [DiskFreeSpaceMB],
		CAST(f.size AS bigint) * 8 / 1024 AS [LogSizeMB],
		CAST(CASE WHEN f.max_size <= 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024 AS [LogMaxSizeMB],
		CASE 
			WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
			THEN 0
			ELSE 1
		END AS [LogFileCanGrow],
		size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [LogFileFreeSpaceMB]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	WHERE [type_desc] = ''LOG''
		and f.database_id = DB_ID();';
		BEGIN TRY
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH
	
		-- Заполняем информации о файлах данных
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'
IF(EXISTS(SELECT * FROM sys.index_resumable_operations))
BEGIN
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
		and f.database_id = DB_ID()
END';

		BEGIN TRY			
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH

	END
	CLOSE DatabaseList;
	DEALLOCATE DatabaseList;
	
	DECLARE @databaseName sysname,
			@MinDiskFreeSpaceMB int,
			@MaxLogUsagePercentThreshold int,
			@MinAllowDataFileFreeSpaceForResumableRebuildMb int,
			@currentTransactionLogSizeFreePercent int,
			@currentTransactionLogSizeFreeMB int,
			@logUsageBadStatus bit = 0,
			@RunDate datetime = GETDATE(),
			@comment nvarchar(255),
			@message nvarchar(max);

	-- Проверка общих правил контроля использования лога транзакций
	DECLARE databasesUnderControl CURSOR FOR
    -- Правила для конкретных баз
	SELECT
		[DatabaseName],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold],[MinAllowDataFileFreeSpaceForResumableRebuildMb]
	FROM [dbo].[LogTransactionControlSettings]
	WHERE [DatabaseName] IS NOT NULL
		AND ([DatabaseName] = @databaseNameFilter or @databaseNameFilter IS NULL)
	UNION
    -- Правало общее для всех баз по умолчанию. 
    -- Кроме тех баз, для которых правила заданы явно.
	SELECT
		dbs.[name],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold],[MinAllowDataFileFreeSpaceForResumableRebuildMb]
	FROM [sys].[databases] dbs
		LEFT JOIN [dbo].[LogTransactionControlSettings] ltcs
			ON ltcs.[DatabaseName] IS NULL
	WHERE [DatabaseName] IS NULL
		AND dbs.[name] NOT IN ('master','model','tempdb','msdb')
		AND NOT dbs.[name] IN (
			SELECT
				[DatabaseName]
			FROM [dbo].[LogTransactionControlSettings]
			WHERE [DatabaseName] IS NOT NULL
		)
		AND (dbs.[name] = @databaseNameFilter or @databaseNameFilter IS NULL);
	OPEN databasesUnderControl;

	FETCH NEXT FROM databasesUnderControl 
	INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold, @MinAllowDataFileFreeSpaceForResumableRebuildMb;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		BEGIN -- Проверка использования файлов данных
			-- Если поддерживается возобновляемое обслуживание, тогда
			-- проверка имеет смысл
			IF([dbo].fn_ResumableIndexMaintenanceAvailiable() = 1)
			BEGIN				
				-- Получаем использование файлов данных возобновляемыми операциями.
				-- Проверяем сколько свободного места в файле данных осталось
				-- с учетом возможности его роста.
				-- Если остается менее 300 ГБ (см. в настройке), то прерываем перестроение.
				-- Также отменяем возобновляемую операцию
				DECLARE
					@dataFileName nvarchar(max),
					@resumableRebuildDataFileUsageMb bigint,
					@totalAvailiableDataSpaceForRebuild bigint;
				DECLARE dataFileUsageByResumableRebuild CURSOR FOR
				SELECT
					DataFileName
					,ResumableRebuildDataFileUsageMb
					,DataMaxSizeMB - DataSizeMB + DataFileFreeSpaceMB AS [TotalAvailiableDataSpaceForRebuild]
				FROM #dataFileInfoByDatabases d
				WHERE d.DatabaseName = @databaseName
					AND ResumableRebuildDataFileUsageMb > 0
					AND (DataMaxSizeMB - DataSizeMB + DataFileFreeSpaceMB) <= @MinAllowDataFileFreeSpaceForResumableRebuildMb;
				OPEN dataFileUsageByResumableRebuild;
				FETCH NEXT FROM dataFileUsageByResumableRebuild 
				INTO @dataFileName, @resumableRebuildDataFileUsageMb, @totalAvailiableDataSpaceForRebuild;
				WHILE @@FETCH_STATUS = 0  
				BEGIN
					SET @message = 
							'Для базы данных ' + @databaseName + ' файла ' + @dataFileName + ' будут отменены все возобновляемые перестроения. ' +
							'Свободного места осталось ' + CAST(@totalAvailiableDataSpaceForRebuild AS nvarchar(max)) + 
							' МБ, при этом минимально допустимое значение ' + CAST(@MinAllowDataFileFreeSpaceForResumableRebuildMb AS nvarchar(max)) + ' МБ.';
					PRINT @message

					EXEC [dbo].[sp_AbortResumableIndexRebuilds]
						@databaseNameFilter = @databaseName,
						@dataFileName = @dataFileName;

					FETCH NEXT FROM dataFileUsageByResumableRebuild 
					INTO @dataFileName, @resumableRebuildDataFileUsageMb, @totalAvailiableDataSpaceForRebuild;
				END
				CLOSE dataFileUsageByResumableRebuild;  
				DEALLOCATE dataFileUsageByResumableRebuild;
			END
		END
		
		BEGIN -- Проверка использования файлов логов транзакций
			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = 'Запуск проверки лога транзакций для базы ' 
					+ @databaseName 
					+ '. Мин. свободное место на диске должно быть ' 
					+ CAST(@MinDiskFreeSpaceMB AS nvarchar(max))
					+ ' МБ. Мин. занятый % лога транзакций при этом '
					+ CAST(@MaxLogUsagePercentThreshold AS nvarchar(max))
					+ '%.'
				PRINT @message

				SELECT
					[Disk],
					[LogFilePath],
					[LogFileFreeSpaceMB],
					[DiskFreeSpaceMB],
					100 - (LogFileFreeSpaceMB / (LogSizeMB / 100)) AS [LogFileUsedPercent],
					100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100) AS [TotalLogFileUsedPercent]
				FROM #logFileInfoByDatabases lf
					LEFT JOIN (
						SELECT
							DatabaseName,
							SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
							SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
						FROM #logFileInfoByDatabases
						GROUP BY DatabaseName
					) totals ON lf.DatabaseName = totals.DatabaseName
				WHERE lf.DatabaseName = @databaseName
					AND LogFileCanGrow = 1
					AND (
						-- Место на диске меньше установленного порога, при этом файл лога заполнен более чем на указанный % в ограничениях
						(100 - (LogFileFreeSpaceMB / (LogSizeMB / 100))) >= @MaxLogUsagePercentThreshold AND [DiskFreeSpaceMB] <= @MinDiskFreeSpaceMB				
						OR
						-- Лог транзакций заполнен более чем на указанный % от максимального размер лога (с учетом автоприроста)
						(100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) >= @MaxLogUsagePercentThreshold
					)
			END
				
			DECLARE
				@logFileFreeSpaceMB numeric,
				@diskFreeSpaceMB numeric,
				@logFileUsedPercent numeric,
				@diskName nvarchar(max),
				@logFilePath nvarchar(max),
				@totalLogFileUsedPercent numeric;

			DECLARE checkLogFiles CURSOR FOR
			SELECT
				[Disk],
				[LogFilePath],
				[LogFileFreeSpaceMB],
				[DiskFreeSpaceMB],
				CASE WHEN [LogSizeMB] = 0 THEN 0 ELSE 100 - ([LogFileFreeSpaceMB] / ([LogSizeMB] / 100)) END AS [LogFileUsedPercent],
				CASE WHEN [TotalLogMaxSizeMB] = 0 THEN 0 ELSE 100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100) END AS [TotalLogFileUsedPercent]
			FROM #logFileInfoByDatabases lf
				LEFT JOIN (
					SELECT
						DatabaseName,
						SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
						SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
					FROM #logFileInfoByDatabases
					GROUP BY DatabaseName
				) totals ON lf.DatabaseName = totals.DatabaseName
			WHERE lf.DatabaseName = @databaseName
				AND LogFileCanGrow = 1
				AND (
					-- Место на диске меньше установленного порога, при этом файл лога заполнен более чем на указанный % в ограничениях
					CASE WHEN [LogSizeMB] = 0 THEN 0 ELSE (100 - ([LogFileFreeSpaceMB] / ([LogSizeMB] / 100))) END >= @MaxLogUsagePercentThreshold AND [DiskFreeSpaceMB] <= @MinDiskFreeSpaceMB				
					OR
					-- Лог транзакций заполнен более чем на 95% от максимального размер лога (с учетом автоприроста)
					CASE WHEN [TotalLogMaxSizeMB] = 0 THEN 0 ELSE (100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) END >= @MaxLogUsagePercentThreshold
				)
			OPEN checkLogFiles;

			FETCH NEXT FROM checkLogFiles 
			INTO @diskName, @logFilePath, @logFileFreeSpaceMB, @diskFreeSpaceMB, @logFileUsedPercent, @totalLogFileUsedPercent;
			WHILE @@FETCH_STATUS = 0  
			BEGIN
				IF(@totalLogFileUsedPercent >= @MaxLogUsagePercentThreshold)
				BEGIN
					SET @comment = 'Лог транзакций заполнен более чем на '
						+ CAST(@totalLogFileUsedPercent as nvarchar(max)) 
						+ '% от максимального размера лога транзакций с учетом автоприроста и ограничений размера файлов.'
				END ELSE BEGIN
					SET @comment = 'На диске ' + @diskName + ' осталось ' 
						+ CAST(@diskFreeSpaceMB as nvarchar(max)) 
						+ ' МБ, что меньше установленного ограничения в ' 
						+ CAST(@MinDiskFreeSpaceMB as nvarchar(max))
						+ ' МБ. При этом файл лога "'
						+ CAST(@logFilePath as nvarchar(max))
						+ '" заполнен уже на '
						+ CAST(@logFileUsedPercent as nvarchar(max))
						+ '%'
				END

				IF(@showDiagnosticMessages = 1)
				BEGIN
					SET @message = 'Обранужена проблема использования лога транзакций для базы ' 
						+ @databaseName 
						+ '. Описание: '
						+ @comment
					PRINT @message
				END


				IF(@showDiagnosticMessages = 1)
				BEGIN
					SET @message = 'Начало поиска соединений обслуживания для завершения. Поиск для базы: '
						+ @databaseName;
					PRINT @message
				END

				DECLARE @killCommand VARCHAR(15);
				DECLARE @badSessionId int;
				DECLARE badSessions CURSOR FOR
				SELECT  es.session_id
				FROM    sys.dm_exec_sessions es
					LEFT OUTER JOIN sys.dm_exec_requests rs ON (es.session_id = rs.session_id)  
					CROSS APPLY sys.dm_exec_sql_text(rs.sql_handle) AS sqltext
				WHERE (
						rs.command like '%ALTER INDEX%' 
						or (rs.command like '%DBCC%' AND sqltext.text like '%ALTER%INDEX%')
						or (rs.command like '%DBCC%' AND sqltext.text like '%EXECUTE%sp_IndexMaintenance%')
					  )
					AND es.database_id = DB_ID(@databaseName)
				OPEN badSessions;

				FETCH NEXT FROM badSessions 
				INTO @badSessionId;

				WHILE @@FETCH_STATUS = 0  
				BEGIN
					SET @killCommand = 'KILL ' + CAST(@badSessionId AS VARCHAR(5))

					IF(@showDiagnosticMessages = 1)
					BEGIN
						SET @message = 'Найденное проблемное соединение. Будет выполнена команда завершения: '
							+ @killCommand;
						PRINT @message
					END
				
					EXECUTE [dbo].[sp_add_maintenance_action_log]
					   ''
					  ,''
					  ,'TRANSACTION LOG CONTROL'
					  ,@RunDate
					  ,@startDate
					  ,@finishDate
					  ,@databaseName
					  ,0
					  ,@comment
					  ,0
					  ,0
					  ,@killCommand
					  ,@MaintenanceActionLogId OUTPUT;
						
					EXEC(@killCommand)

					FETCH NEXT FROM badSessions 
					INTO @badSessionId;
				END

				CLOSE badSessions;  
				DEALLOCATE badSessions;

				IF(@showDiagnosticMessages = 1)
				BEGIN
					SET @message = 'Окончание поиска соединений обслуживания для завершения. Поиск для базы: '
						+ @databaseName;
					PRINT @message
				END

				FETCH NEXT FROM checkLogFiles 
				INTO @diskName, @logFilePath, @logFileFreeSpaceMB, @diskFreeSpaceMB, @logFileUsedPercent, @totalLogFileUsedPercent;
			END

			CLOSE checkLogFiles;  
			DEALLOCATE checkLogFiles;

			IF(@showDiagnosticMessages = 1)
			BEGIN
					SET @message = 'Завершена проверка лога транзакций для базы ' 
					+ @databaseName 
					+ '. '
				PRINT @message
			END
		END

		FETCH NEXT FROM databasesUnderControl 
		INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold, @MinAllowDataFileFreeSpaceForResumableRebuildMb;
	END
	CLOSE databasesUnderControl;  
	DEALLOCATE databasesUnderControl;
	
	-- Проверка правил использования лога транзакций по соединениям
	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	)
	INSERT INTO @AllConnections EXEC sp_who2;

	DECLARE 
		@SPID int,
		@MaxLogUsagePercent int,
		@MaxLogUsageMb int,
		@curDatabaseName nvarchar(250),
		@TotalLogSizeMB int,
		@TotalUseLogSizeMB int,
		@curTotalLogFileUsedPercent int,
		@sql nvarchar(max),
		@msg nvarchar(max);
	DECLARE log_usage_session_cursor CURSOR FOR
	SELECT [AC].[SPID],
		[MaxLogUsagePercent], 
		[MaxLogUsageMb], 
		[SCS].[DatabaseName],
		-- Размер лога транзакций
		[TotalLogSizeMB],
		-- Использование лога транзакций в мегабайтах
		[TotalUseLogSizeMB],
		-- Процент использования файла лога транзакций
		[TotalUseLogSizeMB] / ([TotalLogSizeMB] / 100) AS [TotalLogFileUsedPercent]
	FROM @AllConnections AS [AC]
		FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
		ON [AC].[SPID] = [SCS].[SPID]
			AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
			AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
			AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		LEFT JOIN (
			SELECT
				DatabaseName,
				SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
				SUM(LogSizeMB) AS [TotalLogSizeMB],
				SUM(LogSizeMB - LogFileFreeSpaceMB) AS [TotalUseLogSizeMB],
				SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
			FROM #logFileInfoByDatabases
			GROUP BY DatabaseName
		) lf
		ON [SCS].DatabaseName = lf.DatabaseName
	WHERE -- Есть подходящие настройки ограничений для соединения
		[SCS].[SPID] IS NOT NULL	
		-- Исключаем статусы соединений
		AND NOT UPPER([Status]) IN (
			'BACKGROUND' -- Фоновые процессы
			,'SLEEPING' -- Ожидающие команды, не активные
		)		
		AND (
			-- Проверка % использования лога транзакций
			CASE
				WHEN ISNULL([MaxLogUsagePercent], 0) > 0
				THEN CASE
						WHEN [MaxLogUsagePercent] <= [TotalUseLogSizeMB] / ([TotalLogSizeMB] / 100)
						THEN 1
						ELSE 0
					END				
				ELSE 0
			END > 0

			OR

			-- Проверка использования лога транзакций в МБ
			CASE			
				WHEN ISNULL([MaxLogUsageMb], 0) > 0
				THEN CASE
						WHEN [MaxLogUsageMb] <= [TotalUseLogSizeMB]
						THEN 1
						ELSE 0
					END
				ELSE 0
			END > 0
		)
	OPEN log_usage_session_cursor;
	FETCH NEXT FROM log_usage_session_cursor INTO 		
		@SPID,
		@MaxLogUsagePercent,
		@MaxLogUsageMb,
		@curDatabaseName,
		@TotalLogSizeMB,
		@TotalUseLogSizeMB,
		@curTotalLogFileUsedPercent;
	WHILE @@FETCH_STATUS = 0  
	BEGIN		
		SET @msg = 'Соединение ''' + CAST(@SPID AS nvarchar(max)) + ''' завершено, т.к. превышено допустимое использование лога транзакций. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Текущее использование лога: ' + CAST(@TotalUseLogSizeMB  AS nvarchar(max))+ ', макс. доступно ' + CAST(@MaxLogUsageMb AS nvarchar(max)) + '. Текущий % использования: ' + CAST(@curTotalLogFileUsedPercent AS nvarchar(max)) + ' из макс. доступного ' + CAST(@MaxLogUsagePercent AS nvarchar(max)) + '.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			SET @msg = 'Не удалось завершить соединение. ' +  @msg
			PRINT @msg
		END CATCH
		
		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'TRANSACTION LOG CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@curDatabaseName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		EXEC [dbo].[sp_RemoveSessionControlSetting]
			@spid = @SPID;

		FETCH NEXT FROM log_usage_session_cursor INTO 		
			@SPID,
			@MaxLogUsagePercent,
			@MaxLogUsageMb,
			@curDatabaseName,
			@TotalLogSizeMB,
			@TotalUseLogSizeMB,
			@curTotalLogFileUsedPercent;
	END
	CLOSE log_usage_session_cursor;  
	DEALLOCATE log_usage_session_cursor;

	IF OBJECT_ID('tempdb..#dataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #dataFileInfoByDatabases;
	IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;

	-- Удаляем контроль для текущей сессии
	EXEC [dbo].[sp_RemoveSessionControlSetting];
END

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'LogTransactionControlSettings'))
BEGIN
	DECLARE @sql nvarchar(max)
			
		SET @sql = '
CREATE TABLE [dbo].[LogTransactionControlSettings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](250) NOT NULL,
	[MinDiskFreeSpace] [int] NOT NULL,
	[MaxLogUsagePercentThreshold] [int] NOT NULL,
	
	CONSTRAINT [PK_LogTransactionControlSettings] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]'
		EXECUTE sp_executesql @sql

		SET @sql = '
ALTER TABLE [dbo].[LogTransactionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_MinLogUsagePercentThreshold]  DEFAULT ((90)) FOR [MaxLogUsagePercentThreshold]'
		EXECUTE sp_executesql @sql
	
		SET @sql = '
CREATE UNIQUE NONCLUSTERED INDEX [IX_LogTransactionControlSettings_DatabaseName] ON [dbo].[LogTransactionControlSettings]
(
	[DatabaseName] ASC
) ON [PRIMARY]'
		EXECUTE sp_executesql @sql
END

SET @sql = '
IF EXISTS (
        SELECT type_desc, type
        FROM sys.procedures WITH(NOLOCK)
        WHERE NAME = ''sp_ControlTransactionLogUsage''
            AND type =''P''
      )
BEGIN
	DROP PROCEDURE [dbo].[sp_ControlTransactionLogUsage] 
END'
EXECUTE sp_executesql @sql

SET @sql = '
CREATE PROCEDURE [dbo].[sp_ControlTransactionLogUsage]
	@databaseNameFilter nvarchar(255) = null,
	@showDiagnosticMessages bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID(''tempdb..#logFileInfoByDatabases'') IS NOT NULL
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
		SELECT name FROM sys.databases;
	OPEN DatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM DatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;
		SET @SqlStatement = N''USE ''
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N''INSERT INTO #logFileInfoByDatabases
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
		size/128.0 - CAST(FILEPROPERTY(f.[name],''''SpaceUsed'''') AS INT)/128.0 AS [LogFileFreeSpaceMB]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	WHERE [type_desc] = ''''LOG''''
		and f.database_id = DB_ID();'';

		EXECUTE(@SqlStatement);
	
	END
	CLOSE DatabaseList;
	DEALLOCATE DatabaseList;

	DECLARE @databaseName sysname,
			@MinDiskFreeSpaceMB int,
			@MaxLogUsagePercentThreshold int,
			@currentTransactionLogSizeFreePercent int,
			@currentTransactionLogSizeFreeMB int,
			@logUsageBadStatus bit = 0,
			@RunDate datetime = GETDATE(),
			@comment nvarchar(255),
			@message nvarchar(max);

	DECLARE databasesUnderControl CURSOR  
	FOR SELECT
		[DatabaseName],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold]
	FROM [dbo].[LogTransactionControlSettings]
	WHERE DatabaseName = @databaseNameFilter or @databaseNameFilter IS NULL;
	OPEN databasesUnderControl;

	FETCH NEXT FROM databasesUnderControl 
	INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(@showDiagnosticMessages = 1)
		BEGIN
			SET @message = ''Запуск проверки лога транзакций для базы '' 
				+ @databaseName 
				+ ''. Мин. свободное место на диске должно быть '' 
				+ CAST(@MinDiskFreeSpaceMB AS nvarchar(max))
				+ '' МБ. Макс. занятый % лога транзакций при этом ''
				+ CAST(@MaxLogUsagePercentThreshold AS nvarchar(max))
				+ ''%.''
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
				-- Лог транзакций заполнен более чем на 95% от максимального размер лога (с учетом автоприроста)
				(100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) >= @MaxLogUsagePercentThreshold
			)
		OPEN checkLogFiles;

		FETCH NEXT FROM checkLogFiles 
		INTO @diskName, @logFilePath, @logFileFreeSpaceMB, @diskFreeSpaceMB, @logFileUsedPercent, @totalLogFileUsedPercent;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			IF(@totalLogFileUsedPercent >= @MaxLogUsagePercentThreshold)
			BEGIN
				SET @comment = ''Лог транзакций заполнен более чем на ''
					+ CAST(@totalLogFileUsedPercent as nvarchar(max)) 
					+ ''% от максимального размера лога транзакций с учетом автоприроста и ограничений размера файлов.''
			END ELSE BEGIN
				SET @comment = ''На диске '' + @diskName + '' осталось '' 
					+ CAST(@diskFreeSpaceMB as nvarchar(max)) 
					+ '' МБ, что меньше установленного ограничения в '' 
					+ CAST(@MinDiskFreeSpaceMB as nvarchar(max))
					+ '' МБ. При этом файл лога "''
					+ CAST(@logFilePath as nvarchar(max))
					+ ''" заполнен уже на ''
					+ CAST(@logFileUsedPercent as nvarchar(max))
					+ ''%''
			END

			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = ''Обранужена проблема использования лога транзакций для базы '' 
					+ @databaseName 
					+ ''. Описание: ''
					+ @comment
				PRINT @message
			END


			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = ''Начало поиска соединений обслуживания для завершения. Поиск для базы: ''
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
					rs.command like ''%ALTER INDEX%'' 
					or (rs.command like ''%DBCC%'' AND sqltext.text like ''%ALTER%INDEX%'')
					or (rs.command like ''%DBCC%'' AND sqltext.text like ''%EXECUTE%sp_IndexMaintenance%'')
				  )
				AND es.database_id = DB_ID(@databaseName)
			OPEN badSessions;

			FETCH NEXT FROM badSessions 
			INTO @badSessionId;

			WHILE @@FETCH_STATUS = 0  
			BEGIN
				SET @killCommand = ''KILL '' + CAST(@badSessionId AS VARCHAR(5))

				IF(@showDiagnosticMessages = 1)
				BEGIN
					SET @message = ''Найденное проблемное соединение. Будет выполнена команда завершения: ''
						+ @killCommand;
					PRINT @message
				END

				DECLARE @startDate datetime = GetDate(),
						@finishDate datetime = GetDate(),
						@MaintenanceActionLogId bigint;
				EXECUTE [dbo].[sp_add_maintenance_action_log]
				   ''''
				  ,''''
				  ,''TRANSACTION LOG CONTROL''
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
				SET @message = ''Окончание поиска соединений обслуживания для завершения. Поиск для базы: ''
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
				SET @message = ''Завершена проверка лога транзакций для базы '' 
				+ @databaseName 
				+ ''. ''
			PRINT @message
		END

		FETCH NEXT FROM databasesUnderControl 
		INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold;
	END
	CLOSE databasesUnderControl;  
	DEALLOCATE databasesUnderControl;

	IF OBJECT_ID(''tempdb..#logFileInfoByDatabases'') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;
END
'
EXECUTE sp_executesql @sql
DECLARE @DB_Name varchar(100)
DECLARE @Command nvarchar(max)
DECLARE database_cursor CURSOR FOR 
SELECT db.[name]
FROM MASTER.sys.sysdatabases db
-- Исключаем системные базы данных, а также те базы данных,
-- для которых имются собственные планы обслуживания
WHERE NOT db.[name] IN (
	-- Системные базы данных
	'master',
	'model',
	'msdb',
	'tempdb'
)

OPEN database_cursor

FETCH NEXT FROM database_cursor INTO @DB_Name

WHILE @@FETCH_STATUS = 0 
BEGIN
    -- Скрипт обслуживания индекса взят из "Обслуживание индексов (расширенный).sql"
    SELECT @Command = 'USE ' + @DB_Name + '; '
			+ '
			SET NOCOUNT ON;

			DECLARE -- Настройки
				-- Текущее время
				@timeNow TIME = CAST(GETDATE() AS TIME), 
				-- Начало доступного интервала времени обслуживания
				@timeFrom TIME = CAST(''22:00:00'' AS TIME),
				-- Окончание доступного интервала времени обслуживания
				@timeTo TIME = CAST(''07:00:00'' AS TIME),
				-- Процент фрагментации индекса, начиная с которого выполняется перестроение.
				-- В остальных случаях выполняется реорганизация индекса.
				@fragPercentForRebuild FLOAT = 30.0;

			-- Проверка доступен ли запуск обслуживания в текущее время
			IF (@timeTo >= @timeFrom) BEGIN
				IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
					RETURN;
			END ELSE BEGIN
				IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
					OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))		
				RETURN;
			END

			DECLARE -- Служебные переменные
				@DBID SMALLINT = DB_ID()
				,@SchemaName SYSNAME
				,@ObjectName SYSNAME
				,@ObjectID INT
				,@IndexID INT
				,@IndexName SYSNAME
				,@PartitionNum BIGINT
				,@PartitionCount BIGINT
				,@frag FLOAT
				,@Command NVARCHAR(4000)
				,@Operation NVARCHAR(128)
				,@RowModCtr BIGINT
				,@SQL nvarchar(4000)
				,@StartDate datetime
				,@FinishDate datetime;

			IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
				DROP TABLE #MaintenanceCommands;
			IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
				DROP TABLE #MaintenanceCommandsTemp;

			SELECT
				[object_id] AS [objectid],
				[index_id] AS [indexid],
				[partition_number] AS [partitionnum],
				MAX([avg_fragmentation_in_percent]) AS [frag],
				MAX(CAST([page_count] AS BIGINT)) AS [page_count],
				SUM(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr]
			INTO #MaintenanceCommandsTemp
			FROM sys.dm_db_index_physical_stats (@DBID, NULL, NULL , NULL, N''LIMITED'') dt
				LEFT JOIN sys.sysindexes si
				ON dt.object_id = si.id
			WHERE [avg_fragmentation_in_percent] > 10.0
				AND [index_id] > 0 -- игнорируем кучи (heap)
				AND [page_count] > 25 -- игнорируем небольшие таблицы
			GROUP BY [object_id]
			  ,[index_id]
			  ,[partition_number];

			CREATE TABLE #MaintenanceCommands
			(
				[Command] nvarchar(max),
				[Table] nvarchar(250),
				[Object] nvarchar(250),
				[Rowmodctr] BIGINT,
				[Avg_fragmentation_in_percent] INT,
				[Operation] nvarchar(max),
			)

			DECLARE partitions CURSOR FOR 
				SELECT [objectid], [indexid], [partitionnum], [frag], [rowmodctr]
			FROM #MaintenanceCommandsTemp;
			OPEN partitions;

			WHILE (1=1)
			BEGIN
				FETCH NEXT FROM partitions INTO @ObjectID, @IndexID, @PartitionNum, @frag, @RowModCtr;
				IF @@FETCH_STATUS < 0 BREAK;

				SELECT @ObjectName = QUOTENAME([o].[name]), @SchemaName = QUOTENAME([s].[name])
				FROM sys.objects AS o
					JOIN sys.schemas AS s ON [s].[schema_id] = [o].[schema_id]
				WHERE [o].[object_id] = @ObjectID;

				SELECT @IndexName = QUOTENAME(name)
				FROM sys.indexes
				WHERE [object_id] = @ObjectID AND [index_id] = @IndexID;

				SELECT @PartitionCount = count (*)
				FROM sys.partitions
				WHERE [object_id] = @ObjectID AND [index_id] = @IndexID;

				IF @frag < @fragPercentForRebuild BEGIN
					SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName + N'' REORGANIZE'';
					SET @Operation = ''REORGANIZE INDEX''
				END
				IF @frag >= @fragPercentForRebuild BEGIN
					SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName + N'' REBUILD'';
					SET @Operation = ''REBUILD INDEX''
				END

				IF @PartitionCount > 1
					SET @Command = @Command + N'' PARTITION='' + CAST(@PartitionNum AS nvarchar(10));

				INSERT #MaintenanceCommands
					([Command], [Table], [Object], [Rowmodctr], [Avg_fragmentation_in_percent], [Operation])
				VALUES
					(@Command, @ObjectName, @IndexName, @RowModCtr, @frag, @Operation);
			END

			CLOSE partitions;
			DEALLOCATE partitions;

			DECLARE todo CURSOR FOR
			SELECT
				[Command],
				[Table],
				[Object],
				[Operation]
			FROM #MaintenanceCommands
			ORDER BY 
				[Rowmodctr] DESC,
				[Avg_fragmentation_in_percent] DESC
			OPEN todo;

			WHILE 1=1 
			BEGIN 
				FETCH NEXT FROM todo INTO @SQL, @ObjectName, @IndexName, @Operation; 
         
				IF @@FETCH_STATUS != 0     
					BREAK; 

				-- Проверка доступен ли запуск обслуживания в текущее время
				SET @timeNow = CAST(GETDATE() AS TIME);
				IF (@timeTo >= @timeFrom) BEGIN
					IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
						RETURN;
				END ELSE BEGIN
					IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
						OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))		
					RETURN;
				END

				SET @StartDate = GetDate();
				BEGIN TRY 
					EXEC sp_executesql @SQL;
					SET @FinishDate = GetDate()        
		
					-- Здесь можно сохранить информацию о проведенной операции обслуживания
					--  @ObjectName - имя таблицы
					--  @IndexName - имя индекса
					--  @Operation - вид операции (перестроение или реорганизация)
					--  @RunDate - дата запуска операции обслуживания (начало запуска всего скрипта)
					--  @StartDate - начало конкретно этой операции
					--  @FinishDate - завершение конкретно этой операции

				END  TRY    
				BEGIN CATCH
					PRINT CAST(Error_message() AS NVARCHAR(250)) + '' '' + CAST(Error_Number() AS NVARCHAR(250)) + '' '' + CAST(Error_Line() AS NVARCHAR(250));
				END CATCH
			END 
    
			CLOSE todo; 
			DEALLOCATE todo;

			IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
				DROP TABLE #MaintenanceCommands;
			IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
				DROP TABLE #MaintenanceCommandsTemp;
			'
    EXEC sp_executesql @Command

    FETCH NEXT FROM database_cursor INTO @DB_Name
END

CLOSE database_cursor
DEALLOCATE database_cursor 
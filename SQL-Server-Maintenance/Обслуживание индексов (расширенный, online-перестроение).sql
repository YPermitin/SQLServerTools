SET NOCOUNT ON;

DECLARE -- Настройки
	-- Текущее время
	@timeNow TIME = CAST(GETDATE() AS TIME), 
	-- Начало доступного интервала времени обслуживания
	@timeFrom TIME = CAST('21:00:00' AS TIME),
	-- Окончание доступного интервала времени обслуживания
	@timeTo TIME = CAST('02:00:00' AS TIME),
    -- Процент фрагментации индекса, начиная с которого выполняется перестроение.
    -- В остальных случаях выполняется реорганизация индекса.
    @fragPercentForRebuild FLOAT = 30.0;

-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
    IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
		RETURN;
END ELSE BEGIN
    IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
        OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow)))		
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
    ,@RunDate DATETIME = GetDate()
    ,@SQL nvarchar(4000)
    ,@StartDate datetime
    ,@FinishDate datetime
    ,@MaxDop int
    ,@RebuildMaxWaitDurationMinutes int
    ,@RebuildAbortAfterWaitType nvarchar(50);

-- Степень параллелизма при перестроении индексов.
-- 0 - макс. степень, будут задействованы все доступные ядра CPU.
SET @MaxDop = 0;

-- Настройки online-перестроения индексов.
-- Подробнее: https://www.sqlshack.com/control-online-index-rebuild-locking-using-sql-server-2014-managed-lock-priority/
-- Максимальное время ожидания переключения индекса (удаление старого индекса и включение нового) в минутах.
SET @RebuildMaxWaitDurationMinutes = 5;
-- Действие при истечении таймаута ожидания переключения индекса
-- BLOCKERS - завершить сессии, мешающие перестроению индекса
-- SELF - завершить сессию перестроения индекса
-- NONE - ожидать завершения блокирующей транзакции. Значение по умолчанию.
SET @RebuildAbortAfterWaitType = 'BLOCKERS';

IF OBJECT_ID('tempdb..#MaintenanceCommands') IS NOT NULL
	DROP TABLE #MaintenanceCommands;
IF OBJECT_ID('tempdb..#MaintenanceCommandsTemp') IS NOT NULL
	DROP TABLE #MaintenanceCommandsTemp;

SELECT
    [object_id] AS [objectid],
    [index_id] AS [indexid],
    [partition_number] AS [partitionnum],
    MAX([avg_fragmentation_in_percent]) AS [frag],
    MAX(CAST([page_count] AS BIGINT)) AS [page_count],
    SUM(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr]
INTO #MaintenanceCommandsTemp
FROM sys.dm_db_index_physical_stats (@DBID, NULL, NULL , NULL, N'LIMITED') dt
    LEFT JOIN sys.sysindexes si ON dt.object_id = si.id
	LEFT JOIN (
		SELECT 
			 t.object_id AS [TableObjectId],
			 ind.index_id AS [IndexObjectId]
		FROM 
			 sys.indexes ind 
		INNER JOIN 
			 sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
		INNER JOIN 
			 sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
		INNER JOIN 
			 sys.tables t ON ind.object_id = t.object_id 
		LEFT JOIN
			INFORMATION_SCHEMA.COLUMNS tbsc ON t.schema_id = SCHEMA_ID(tbsc.TABLE_SCHEMA)
				AND t.name = tbsc.TABLE_NAME
		LEFT JOIN
			sys.types tps ON col.system_type_id = tps.system_type_id
				AND col.user_type_id = tps.user_type_id
		WHERE 
			 t.is_ms_shipped = 0 
			 AND CASE 
				WHEN ind.type_desc = 'CLUSTERED'
				THEN CASE WHEN tbsc.DATA_TYPE IN ('text', 'ntext', 'image', 'FILESTREAM') THEN 1 ELSE 0 END
				ELSE CASE WHEN tps.[name] IN ('text', 'ntext', 'image', 'FILESTREAM') THEN 1 ELSE 0 END
			 END > 0
		GROUP BY t.object_id, ind.index_id
	) AS objBadTypes
	ON objBadTypes.TableObjectId = dt.object_id
		AND objBadTypes.IndexObjectId = dt.index_id
WHERE [avg_fragmentation_in_percent] > 10.0
    AND [index_id] > 0 -- игнорируем кучи (heap)
    AND [page_count] > 25 -- игнорируем небольшие таблицы
	-- Исключаем индексы, содержащие типы text, ntext, image, filestream, т.к. они не подлежат онлайн перестроению
	AND objBadTypes.IndexObjectId IS NULL 
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
        SET @Command = N'ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @ObjectName + N' REORGANIZE';
        SET @Operation = 'REORGANIZE INDEX'
    END
    IF @frag >= @fragPercentForRebuild BEGIN
        SET @Command = N'ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @ObjectName 
            + N' REBUILD WITH (MAXDOP=' + CAST(@MaxDop AS nvarchar(10)) 
            + ', ONLINE = ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = ' + CAST(@RebuildMaxWaitDurationMinutes AS nvarchar(10)) 
            + ' MINUTES, ABORT_AFTER_WAIT = ' + @RebuildAbortAfterWaitType + ')))';
        SET @Operation = 'REBUILD INDEX'
    END

    IF @PartitionCount > 1
		SET @Command = @Command + N' PARTITION=' + CAST(@PartitionNum AS nvarchar(10));

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
        IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
            OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow)))		
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
        PRINT CAST(Error_message() AS NVARCHAR(250)) + ' ' + CAST(Error_Number() AS NVARCHAR(250)) + ' ' + CAST(Error_Line() AS NVARCHAR(250));
    END CATCH
END 
    
CLOSE todo; 
DEALLOCATE todo;

IF OBJECT_ID('tempdb..#MaintenanceCommands') IS NOT NULL
	DROP TABLE #MaintenanceCommands;
IF OBJECT_ID('tempdb..#MaintenanceCommandsTemp') IS NOT NULL
	DROP TABLE #MaintenanceCommandsTemp;
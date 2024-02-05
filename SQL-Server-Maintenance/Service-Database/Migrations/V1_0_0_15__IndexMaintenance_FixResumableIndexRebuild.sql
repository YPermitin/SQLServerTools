ALTER PROCEDURE [dbo].[sp_IndexMaintenance]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
    @fragmentationPercentMinForMaintenance FLOAT = 10.0,
    @fragmentationPercentForRebuild FLOAT = 30.0,
    @maxDop int = 8,
    @minIndexSizePages int = 0,
    @maxIndexSizePages int = 0,
    @useOnlineIndexRebuild int = 0,
	@useResumableIndexRebuildIfAvailable int = 0,
    @maxIndexSizeForReorganizingPages int = 6553600,
    @usePreparedInformationAboutObjectsStateIfExists bit = 0,
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
    @ConditionIndexName nvarchar(max) = 'LIKE ''%''',
    @onlineRebuildAbortAfterWaitMode int = 1,
    @onlineRebuildWaitMinutes int = 5,
    @maxTransactionLogSizeUsagePercent int = 100,  
    @maxTransactionLogSizeMB bigint = 0,
	@fillFactorForIndex int = 0
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @msg nvarchar(max),
            @abortAfterWaitOnlineRebuil nvarchar(25),
            @currentTransactionLogSizeUsagePercent int,
            @currentTransactionLogSizeMB int,
			@timeNow TIME = CAST(GETDATE() AS TIME),
			@useResumableIndexRebuild bit,
			@RunDate datetime = GETDATE(),
			@StartDate datetime,
			@FinishDate datetime,
			@MaintenanceActionLogId bigint,
			-- Список исключенных из обслуживания индексов.
			-- Например, если они были обслужены через механизм возобновляемых перестроений,
			-- еще до запуска основного обслуживания
			@excludeIndexes XML,
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

	IF(@fillFactorForIndex = 0)
	BEGIN
		select
			@fillFactorForIndex = CAST(value_in_use AS INT)
		from sys.configurations
		where name = 'fill factor (%)'
	END
	IF(@fillFactorForIndex = 0)
	BEGIN
		SET @fillFactorForIndex = 100
	END
 
    IF(@onlineRebuildAbortAfterWaitMode = 0)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'NONE'
    END ELSE IF(@onlineRebuildAbortAfterWaitMode = 1)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'SELF'
    END ELSE IF(@onlineRebuildAbortAfterWaitMode = 2)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'BLOCKERS'
    END ELSE
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'NONE'
    END
 
    IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END
 
    -- Информация о размере лога транзакций
    IF OBJECT_ID('tempdb..#tranLogInfo') IS NOT NULL
        DROP TABLE #tranLogInfo;
    CREATE TABLE #tranLogInfo
    (
        servername varchar(255) not null default @@servername,
        dbname varchar(255),
        logsize real,
        logspace real,
        stat int
    )
 
    -- Проверка процента занятого места в логе транзакций
    TRUNCATE TABLE #tranLogInfo;
    INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
    SELECT
        @currentTransactionLogSizeUsagePercent = logspace,
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM #tranLogInfo WHERE dbname = @databaseName
    IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
    BEGIN
        -- Процент занятого места в файлах лога транзакций превышает указанный порог
        RETURN 0;
    END
    IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
    BEGIN
        -- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
        RETURN 0;
    END

	EXECUTE [dbo].[sp_apply_maintenance_action_to_run] 
		@databaseName;
 
	-- Возобновляемое перестроение индексов
	DECLARE @LOCAL_ResumableIndexRebuilds TABLE
	(
		[object_id] int, 
		[object_name] nvarchar(255), 
		[index_id] int, 
		[name] sysname, 
		[sql_text] nvarchar(max), 
		[partition_number] int,
		[state] tinyint, 
		[state_desc] nvarchar(60),
		[start_time] datetime,
		[last_pause_time] datetime,
		[total_execution_time] int,
		[percent_complete] real,
		[page_count] bigint,
		[ResumeCmd] nvarchar(max)
	);
	-- Флаг использования возобновляемого перестроения индексов
	SET @useResumableIndexRebuild = 
		CASE
			WHEN (@useResumableIndexRebuildIfAvailable > 0)	-- Передан флаг использования возобновляемого перестроения
			-- Возобновляемое перестроение доступно для версии SQL Server
			AND [dbo].[fn_ResumableIndexMaintenanceAvailiable]() > 0
			-- Включено использование онлайн-перестроения для скрипта
			AND (@useOnlineIndexRebuild = 1 -- Только онлайн-перестроение
				OR @useOnlineIndexRebuild = 3) -- Для объектов где оно возможно
			THEN 1
			ELSE 0
		END;
	IF(@useResumableIndexRebuild > 0)
	BEGIN
		DECLARE @cmdResumableIndexRebuild nvarchar(max);
		SET @cmdResumableIndexRebuild = CAST('
		USE [' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;
		SELECT
			[object_id],
			OBJECT_NAME([object_id]) AS [TableName],
			[index_id], 
			[name], 
			[sql_text], 
			[partition_number],
			[state], 
			[state_desc],
			[start_time],
			[last_pause_time],
			[total_execution_time],
			[percent_complete],
			[page_count],
			''ALTER INDEX ['' + [name] + ''] ON ['' + OBJECT_SCHEMA_NAME([object_id]) + ''].['' + OBJECT_NAME([object_id]) + ''] RESUME'' AS [ResumeCmd]
		FROM sys.index_resumable_operations
		WHERE OBJECT_NAME([object_id]) ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
			AND [name] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST(';
		' AS nvarchar(max));
		INSERT @LOCAL_ResumableIndexRebuilds
		EXECUTE sp_executesql @cmdResumableIndexRebuild;

		DECLARE 
			@objectNameResumeRebuildForIndex nvarchar(255), 
			@indexNameResumeRebuildForIndex nvarchar(255), 
			@cmdResumeRebuildForIndex nvarchar(max);
		DECLARE resumableIndexRebuild_cursor CURSOR FOR				
		SELECT 
			[object_name],
			[name],
			[ResumeCmd]
		FROM @LOCAL_ResumableIndexRebuilds
		ORDER BY start_time;
		OPEN resumableIndexRebuild_cursor;		
		FETCH NEXT FROM resumableIndexRebuild_cursor 
		INTO @objectNameResumeRebuildForIndex, @indexNameResumeRebuildForIndex, @cmdResumeRebuildForIndex;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
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

			-- Проверки использования лога транзакций
			-- Проверка процента занятого места в логе транзакций
			TRUNCATE TABLE #tranLogInfo;
			INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
			SELECT
				@currentTransactionLogSizeUsagePercent = logspace,
				@currentTransactionLogSizeMB = logsize * (logspace / 100)
			FROM #tranLogInfo WHERE dbname = @databaseName
			IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
			BEGIN
				-- Процент занятого места в файлах лога транзакций превышает указанный порог
				RETURN 0;
			END
			IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
			BEGIN
				-- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
				RETURN 0;
			END
			
			BEGIN TRY
				-- Сохраняем предварительную информацию об операции обслуживания без даты завершения				
				IF(@useMonitoringDatabase = 1)
				BEGIN
					SET @StartDate = GETDATE();
					EXECUTE [dbo].[sp_add_maintenance_action_log]
						@objectNameResumeRebuildForIndex,
						@indexNameResumeRebuildForIndex,
						'REBUILD INDEX RESUME',
						@RunDate,
						@StartDate,
						null,
						@databaseName,
						1, -- @UseOnlineRebuild
						'',
						0, -- @AvgFragmentationPercent
						0, -- @RowModCtr
						@cmdResumeRebuildForIndex,
						@MaintenanceActionLogId OUTPUT;
				END

				SET @cmdResumeRebuildForIndex = CAST('
					USE [' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST(']
					SET NOCOUNT ON;
					' + CAST(@cmdResumeRebuildForIndex as nvarchar(max)) + '
				' AS nvarchar(max));
				EXECUTE sp_executesql @cmdResumeRebuildForIndex;
				SET @FinishDate = GetDate();

				-- Устанавливаем фактическую дату завершения операции
				IF(@useMonitoringDatabase = 1)
				BEGIN
					EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
						@MaintenanceActionLogId,
						@FinishDate;
				END				
			END TRY
			BEGIN CATCH		
				IF(@MaintenanceActionLogId <> 0)
				BEGIN
					SET @msg = 'Error: ' + CAST(Error_message() AS NVARCHAR(500)) + ', Code: ' + CAST(Error_Number() AS NVARCHAR(500)) + ', Line: ' + CAST(Error_Line() AS NVARCHAR(500))
					-- Устанавливаем текст ошибки при обслуживании индекса
					-- Дата завершения при этом остается незаполненной
					EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
						@MaintenanceActionLogId,
						@FinishDate,
						@msg;          
				END
			END CATCH

			FETCH NEXT FROM resumableIndexRebuild_cursor 
			INTO @objectNameResumeRebuildForIndex, @indexNameResumeRebuildForIndex, @cmdResumeRebuildForIndex;
		END
		CLOSE resumableIndexRebuild_cursor;  
		DEALLOCATE resumableIndexRebuild_cursor;
	END
	-- Сохраняем список индексов, для которых имеются ожидающие операции перестроения
	-- Они будут исключены из основного обслуживания
	SET @excludeIndexes = (SELECT
		[name]
	FROM @LOCAL_ResumableIndexRebuilds
	FOR XML RAW, ROOT('root'));
	
	--PRINT 'Прервано для отладки'
	--RETURN 0;
 
    DECLARE @cmd nvarchar(max);
    SET @cmd =
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;
DECLARE
    -- Текущее время
    @timeNow TIME = CAST(GETDATE() AS TIME),
    -- Текущий процент использования файла лога транзакций
    @currentTransactionLogSizeUsagePercent int,
    @currentTransactionLogSizeMB bigint;
 
-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
    IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
        RETURN;
    END ELSE BEGIN
        IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
            OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow))) 
                RETURN;
END
 
-- Служебные переменные
DECLARE
    @DBID SMALLINT = DB_ID()
    ,@DBNAME sysname = DB_NAME()
    ,@SchemaName SYSNAME
    ,@ObjectName SYSNAME
    ,@ObjectID INT
    ,@Priority INT
    ,@IndexID INT
    ,@IndexName SYSNAME
    ,@PartitionNum BIGINT
    ,@PartitionCount BIGINT
    ,@frag FLOAT
    ,@Command NVARCHAR(max)
    ,@CommandSpecial NVARCHAR(max)
    ,@Operation NVARCHAR(128)
    ,@RowModCtr BIGINT
    ,@AvgFragmentationPercent float
    ,@PageCount BIGINT
    ,@SQL nvarchar(max)
    ,@SQLSpecial nvarchar(max)
    ,@OnlineRebuildSupport int
    ,@UseOnlineRebuild int
    ,@StartDate datetime
    ,@FinishDate datetime
    ,@RunDate datetime = GETDATE()
    ,@MaintenanceActionLogId bigint
    ,@CurrentReorganizeIndexAllowPageLocks bit
	,@CurrentSqlDisableAllowPageLocksIfNeeded nvarchar(max)
	,@CurrentMaintenanceActionToRunId int;
 
IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
    DROP TABLE #MaintenanceCommands;
IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
    DROP TABLE #MaintenanceCommandsTemp;
 
CREATE TABLE #MaintenanceCommands
(
    [Command] nvarchar(max),
    [CommandSpecial] nvarchar(max),
    [Table] nvarchar(250),
    [Object] nvarchar(250),
    [page_count] BIGINT,
    [Rowmodctr] BIGINT,
    [Avg_fragmentation_in_percent] INT,
    [Operation] nvarchar(max),
    [Priority] INT,
    [OnlineRebuildSupport] INT,
    [UseOnlineRebuild] INT,
    [PartitionCount] BIGINT
)
 
IF OBJECT_ID(''tempdb..#tranLogInfo'') IS NOT NULL
    DROP TABLE #tranLogInfo;
CREATE TABLE #tranLogInfo
(
    servername varchar(255) not null default @@servername,
    dbname varchar(255),
    logsize real,
    logspace real,
    stat int
)
 
DECLARE @usedCacheAboutObjectsState bit = 0;
 
IF @usePreparedInformationAboutObjectsStateIfExists = 1
    AND EXISTS(SELECT *
          FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState]
          WHERE [DatabaseName] = @databaseName
            -- Информация должна быть собрана в рамках 12 часов от текущего запуска
            AND [Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate))
BEGIN  
    -- Получаем информацию через подготовленный сбор
    SET @usedCacheAboutObjectsState = 1;
 
    SELECT
      OBJECT_ID(dt.[TableName]) AS [objectid]
      ,ind.index_id as [indexid]
      ,1 AS [partitionnum]
      ,[AvgFragmentationPercent] AS [frag]
      ,[PageCount] AS [page_count]
      ,[Rowmodctr] AS [rowmodctr]
      ,ISNULL(prt.[Priority], 999) AS [Priority]
      ,ISNULL(prt.[Exclude], 0) AS Exclude
      ,dt.[OnlineRebuildSupport] AS [OnlineRebuildSupport]
      ,dt.[PartitionCount] AS [PartitionCount]
    INTO #MaintenanceCommandsTempCached
    FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState] dt
        LEFT JOIN sys.indexes ind
            ON OBJECT_ID(dt.[TableName]) = ind.object_id
                AND dt.[Object] = ind.[name]
        LEFT JOIN [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[MaintenanceIndexPriority] AS [prt]
            ON dt.DatabaseName = prt.[DatabaseName]
                AND dt.TableName = prt.TableName
                AND dt.[Object] = prt.Indexname
    WHERE dt.[DatabaseName] = @databaseName
        AND [Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate)
        -- Записи от последнего получения данных за прошедшие 12 часов
        AND [Period] IN (
            SELECT MAX([Period])
            FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState]
            WHERE [DatabaseName] = @databaseName
                AND dt.[Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate))
        AND [AvgFragmentationPercent] > @fragmentationPercentMinForMaintenance
        AND [PageCount] > 25 -- игнорируем небольшие таблицы
        -- Фильтр по мин. размеру индекса
        AND (@minIndexSizePages = 0 OR [PageCount] >= @minIndexSizePages)
        -- Фильтр по макс. размеру индекса
        AND (@maxIndexSizePages = 0 OR [PageCount] <= @maxIndexSizePages)
        -- Убираем обработку индексов, исключенных из обслуживания
        AND ISNULL(prt.[Exclude], 0) = 0
        -- Отбор по имени таблцы
        AND dt.[TableName] ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
        AND dt.[Object] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST('
		AND NOT dt.[Object] IN (
			SELECT 
				XC.value(''@name'', ''nvarchar(255)'') AS [IndexName]
			FROM @excludeIndexes.nodes(''/root/row'') AS XT(XC)
		)
END ELSE
BEGIN
    -- Получаем информацию через анализ базы данных
    SELECT
        dt.[object_id] AS [objectid],
        dt.index_id AS [indexid],
        [partition_number] AS [partitionnum],
        MAX([avg_fragmentation_in_percent]) AS [frag],
        MAX(CAST([page_count] AS BIGINT)) AS [page_count],
        SUM(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr],
        MAX(
            ISNULL(prt.[Priority], 999)
        ) AS [Priority],
        MAX(
            CAST(ISNULL(prt.[Exclude], 0) AS INT)
        ) AS [Exclude],
        MIN(CASE WHEN objBadTypes.IndexObjectId IS NULL THEN 1 ELSE 0 END) AS [OnlineRebuildSupport],
        MAX(p_count.[PartitionCount]) AS [PartitionCount]
    INTO #MaintenanceCommandsTemp
    FROM
        sys.dm_db_index_physical_stats (
            DB_ID(),
            NULL,
            NULL,
            NULL,
            N''LIMITED''
        ) dt
        LEFT JOIN sys.sysindexes si ON dt.object_id = si.id AND si.indid = dt.index_id
        LEFT JOIN (
            SELECT
            t.object_id AS [TableObjectId],
            ind.index_id AS [IndexObjectId]
            FROM
            sys.indexes ind
            INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id
            and ind.index_id = ic.index_id
            INNER JOIN sys.columns col ON ic.object_id = col.object_id
            and ic.column_id = col.column_id
            INNER JOIN sys.tables t ON ind.object_id = t.object_id
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS tbsc ON t.schema_id = SCHEMA_ID(tbsc.TABLE_SCHEMA)
            AND t.name = tbsc.TABLE_NAME
            LEFT JOIN sys.types tps ON col.system_type_id = tps.system_type_id
            AND col.user_type_id = tps.user_type_id
            WHERE
            t.is_ms_shipped = 0
            AND CASE WHEN ind.type_desc = ''CLUSTERED'' THEN CASE WHEN tbsc.DATA_TYPE IN (
                ''text'', ''ntext'', ''image'', ''FILESTREAM''
            ) THEN 1 ELSE 0 END ELSE CASE WHEN tps.[name] IN (
                ''text'', ''ntext'', ''image'', ''FILESTREAM''
            ) THEN 1 ELSE 0 END END > 0
            GROUP BY
            t.object_id,
            ind.index_id
        ) AS objBadTypes ON objBadTypes.TableObjectId = dt.object_id
        AND objBadTypes.IndexObjectId = dt.index_id
        LEFT JOIN (
            SELECT
            i.[object_id],
            i.[index_id],
            os.[Priority] AS [Priority],
            os.[Exclude] AS [Exclude]
            FROM sys.indexes i
                left join [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[MaintenanceIndexPriority] os
                ON i.object_id = OBJECT_ID(os.TableName)
                    AND i.Name = os.IndexName
            WHERE os.Id IS NOT NULL
                and os.DatabaseName = ''' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST('''
            ) prt ON si.id = prt.[object_id]
        AND dt.[index_id] = prt.[index_id]
        LEFT JOIN (
            SELECT
                object_id,
                index_id,
                COUNT(DISTINCT partition_number) AS [PartitionCount]
            FROM sys.partitions p
            GROUP BY object_id, index_id
        ) p_count
        ON dt.object_id = p_count.object_id AND dt.index_id = p_count.index_id
    WHERE
        [rowmodctr] IS NOT NULL -- Исключаем служебные объекты, по которым нет изменений
        AND [avg_fragmentation_in_percent] > @fragmentationPercentMinForMaintenance
        AND dt.[index_id] > 0 -- игнорируем кучи (heap)
        AND [page_count] > 25 -- игнорируем небольшие таблицы
        -- Фильтр по мин. размеру индекса
        AND (@minIndexSizePages = 0 OR [page_count] >= @minIndexSizePages)
        -- Фильтр по макс. размеру индекса
        AND (@maxIndexSizePages = 0 OR [page_count] <= @maxIndexSizePages)
        -- Убираем обработку индексов, исключенных из обслуживания
        AND ISNULL(prt.[Exclude], 0) = 0
        -- Отбор по имени таблцы
        AND OBJECT_NAME(dt.[object_id]) ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
        AND si.[name] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST('
		AND NOT si.[name] IN (
			SELECT 
				XC.value(''@name'', ''nvarchar(255)'') AS [IndexName]
			FROM @excludeIndexes.nodes(''/root/row'') AS XT(XC)
		)
    GROUP BY
        dt.[object_id],
        dt.[index_id],
        [partition_number];
END
 
IF(@usedCacheAboutObjectsState = 1)
BEGIN
    DECLARE partitions CURSOR FOR
    SELECT [objectid], [indexid], [partitionnum], [frag], [page_count], [rowmodctr], [Priority], [OnlineRebuildSupport], [PartitionCount]
    FROM #MaintenanceCommandsTempCached;
END ELSE
BEGIN
    DECLARE partitions CURSOR FOR
    SELECT [objectid], [indexid], [partitionnum], [frag], [page_count], [rowmodctr], [Priority], [OnlineRebuildSupport], [PartitionCount]
    FROM #MaintenanceCommandsTemp;
END
 
OPEN partitions;
WHILE (1=1)
BEGIN
    FETCH NEXT FROM partitions INTO @ObjectID, @IndexID, @PartitionNum, @frag, @PageCount, @RowModCtr, @Priority, @OnlineRebuildSupport, @PartitionCount;
    IF @@FETCH_STATUS < 0 BREAK;
     
    SELECT @ObjectName = QUOTENAME([o].[name]), @SchemaName = QUOTENAME([s].[name])
    FROM sys.objects AS o
        JOIN sys.schemas AS s ON [s].[schema_id] = [o].[schema_id]
    WHERE [o].[object_id] = @ObjectID;
    SELECT @IndexName = QUOTENAME(name)
    FROM sys.indexes
    WHERE [object_id] = @ObjectID AND [index_id] = @IndexID;
     
    SET @CommandSpecial = '''';
    SET @Command = '''';
    -- Реорганизация индекса
    IF @Priority > 10 -- Приоритет обслуживания не большой
        AND @frag <= @fragmentationPercentForRebuild -- Процент фрагментации небольшой
        AND (@maxIndexSizeForReorganizingPages = 0 OR @PageCount <= @maxIndexSizeForReorganizingPages) BEGIN -- Таблица меньше 50 ГБ
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName + N'' REORGANIZE'';
        SET @Operation = ''REORGANIZE INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 0) -- Не использовать онлайн-перестроение
    BEGIN
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF (@useOnlineIndexRebuild = 1 AND @OnlineRebuildSupport = 1) -- Только с поддержкой онлайн перестроения
    BEGIN
        SET @CommandSpecial = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '','' 
			+ (CASE WHEN @useResumableIndexRebuild > 0 THEN '' RESUMABLE = ON, '' ELSE '''' END) 
			+ '' ONLINE = ON (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = ' AS nvarchar(max)) + CAST(@onlineRebuildWaitMinutes  AS nvarchar(max)) + CAST(' MINUTES, ABORT_AFTER_WAIT = ' AS nvarchar(max)) + CAST(@abortAfterWaitOnlineRebuil  AS nvarchar(max)) + CAST(')))'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 2 AND @OnlineRebuildSupport = 0) -- Только без поддержки
    BEGIN
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 3) -- Использовать онлайн перестроение где возможно
    BEGIN
        if(@OnlineRebuildSupport = 1)
        BEGIN
            SET @CommandSpecial = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
                + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '','' 
                + (CASE WHEN @useResumableIndexRebuild > 0 THEN '' RESUMABLE = ON, '' ELSE '''' END) 
                + '' ONLINE = ON (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = ' AS nvarchar(max)) + CAST(@onlineRebuildWaitMinutes  AS nvarchar(max)) + CAST(' MINUTES, ABORT_AFTER_WAIT = ' AS nvarchar(max)) + CAST(@abortAfterWaitOnlineRebuil  AS nvarchar(max)) + CAST(')))'';        
        END ELSE
        BEGIN
            SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
                + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        END
        SET @Operation = ''REBUILD INDEX''
    END
    IF (@PartitionCount > 1 AND @Command <> '''')
        SET @Command = @Command + N'' PARTITION='' + CAST(@PartitionNum AS nvarchar(10));
 
    SET @Command = LTRIM(RTRIM(@Command));
    SET @CommandSpecial = LTRIM(RTRIM(@CommandSpecial));
    IF(LEN(@Command) > 0 OR LEN(@CommandSpecial) > 0)
    BEGIN      
        INSERT #MaintenanceCommands
            ([Command], [CommandSpecial], [Table], [Object], [Rowmodctr], [Avg_fragmentation_in_percent], [Operation], [Priority], [OnlineRebuildSupport])
        VALUES
            (@Command, @CommandSpecial, @ObjectName, @IndexName, @RowModCtr, @frag, @Operation, @Priority, @OnlineRebuildSupport);
    END
END
CLOSE partitions;
DEALLOCATE partitions;
DECLARE todo CURSOR FOR
SELECT
    [Command],
    [CommandSpecial],
    [Table],
    [Object],
    [Operation],
    [OnlineRebuildSupport],
    [Rowmodctr],
    [Avg_fragmentation_in_percent]
FROM #MaintenanceCommands
ORDER BY
    [Priority],
    [Rowmodctr] DESC,
    [Avg_fragmentation_in_percent] DESC
OPEN todo;
WHILE 1=1
BEGIN
    FETCH NEXT FROM todo INTO @SQL, @SQLSpecial, @ObjectName, @IndexName, @Operation, @OnlineRebuildSupport, @RowModCtr, @AvgFragmentationPercent;
          
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
 
    -- Проверка процента занятого места в логе транзакций
    TRUNCATE TABLE #tranLogInfo;
    INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec(''dbcc sqlperf(logspace)'');
    SELECT
        @currentTransactionLogSizeUsagePercent = logspace,
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM #tranLogInfo WHERE dbname = @databaseName
    IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
    BEGIN
        -- Процент занятого места в файлах лога транзакций превышает указанный порог
        RETURN;
    END
    IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
    BEGIN
        -- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
        RETURN;
    END
 
    SET @StartDate = GetDate();
    BEGIN TRY
        DECLARE @currentSQL nvarchar(max) = ''''
        SET @MaintenanceActionLogId = 0
        IF(@SQLSpecial = '''')
        BEGIN
            SET @currentSQL = @SQL
            SET @UseOnlineRebuild = 0;
        END ELSE
        BEGIN
            SET @UseOnlineRebuild = 1;
            SET @currentSQL = @SQLSpecial
        END

		SET @CurrentSqlDisableAllowPageLocksIfNeeded = null;
		IF(@Operation = ''REORGANIZE INDEX'')
		BEGIN
			DECLARE 
				@IndexNameNormalized nvarchar(255),
				@TableNameNormalized nvarchar(255),
				@SchemaNameNormalized nvarchar(255);
			SET @TableNameNormalized = REPLACE(@ObjectName, ''['', '''')
			SET @TableNameNormalized = REPLACE(@TableNameNormalized, '']'', '''')
			SET @IndexNameNormalized = REPLACE(@IndexName, ''['', '''')
			SET @IndexNameNormalized = REPLACE(@IndexNameNormalized, '']'', '''')

			SELECT
				@SchemaNameNormalized = SCHEMA_NAME(o.schema_id),	
				@CurrentReorganizeIndexAllowPageLocks = [allow_page_locks]
			FROM sys.indexes i
				left join sys.objects o
				on i.object_id = o.object_id
			WHERE i.[name] = @IndexNameNormalized
						
			IF(@CurrentReorganizeIndexAllowPageLocks = 0)
			BEGIN
				DECLARE @sqlEnableAllowPageLocks nvarchar(max);
				SET @sqlEnableAllowPageLocks = ''ALTER INDEX ['' + @IndexNameNormalized + ''] ON ['' + @SchemaNameNormalized + ''].['' + @TableNameNormalized + ''] SET (ALLOW_PAGE_LOCKS = ON);''
				SET @CurrentSqlDisableAllowPageLocksIfNeeded = ''ALTER INDEX ['' + @IndexNameNormalized + ''] ON ['' + @SchemaNameNormalized + ''].['' + @TableNameNormalized + ''] SET (ALLOW_PAGE_LOCKS = OFF);''
				EXEC sp_executesql @sqlEnableAllowPageLocks;

				EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_to_run]
					@DBNAME,
					@Operation,
					@CurrentSqlDisableAllowPageLocksIfNeeded,
					@CurrentMaintenanceActionToRunId OUTPUT;
					
			END
		END

        -- Сохраняем предварительную информацию об операции обслуживания без даты завершения
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_log]
               @ObjectName
              ,@IndexName
              ,@Operation
              ,@RunDate
              ,@StartDate
              ,null
              ,@DBNAME
              ,@UseOnlineRebuild
              ,''''
              ,@AvgFragmentationPercent
              ,@RowModCtr
              ,@currentSQL
              ,@MaintenanceActionLogId OUTPUT;
        END
        EXEC sp_executesql @currentSQL;

		IF(@Operation = ''REORGANIZE INDEX'' AND @CurrentSqlDisableAllowPageLocksIfNeeded IS NOT NULL)
		BEGIN
			EXEC sp_executesql @CurrentSqlDisableAllowPageLocksIfNeeded;
			EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_remove_maintenance_action_to_run]
				@CurrentMaintenanceActionToRunId;
		END

        SET @FinishDate = GetDate();
         
        -- Устанавливаем фактическую дату завершения операции
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
                @MaintenanceActionLogId,
                @FinishDate;
        END 
    END  TRY   
    BEGIN CATCH
        IF(@MaintenanceActionLogId <> 0)
        BEGIN
            DECLARE @msg nvarchar(500) = ''Error: '' + CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' + CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' + CAST(Error_Line() AS NVARCHAR(500))
            -- Устанавливаем текст ошибки при обслуживании индекса
            -- Дата завершения при этом остается незаполненной
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
                @MaintenanceActionLogId,
                @FinishDate,
                @msg;          
        END            
    END CATCH
END
     
CLOSE todo;
DEALLOCATE todo;
IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
    DROP TABLE #MaintenanceCommands;
IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
    DROP TABLE #MaintenanceCommandsTemp;
' AS nvarchar(max))
 
	-- Для отладки. Выводит в SSMS весь текст сформированной команды
	--exec [dbo].[sp_AdvancedPrint] @sql = @cmd

    EXECUTE sp_executesql
        @cmd,
        N'@timeFrom TIME, @timeTo TIME, @fragmentationPercentForRebuild FLOAT,
        @fragmentationPercentMinForMaintenance FLOAT, @maxDop int,
        @minIndexSizePages int, @maxIndexSizePages int, @useOnlineIndexRebuild int,
        @maxIndexSizeForReorganizingPages int,
        @useMonitoringDatabase bit, @monitoringDatabaseName sysname, @usePreparedInformationAboutObjectsStateIfExists bit,
        @databaseName sysname, @maxTransactionLogSizeUsagePercent int, @maxTransactionLogSizeMB bigint, @useResumableIndexRebuild bit,
		@excludeIndexes XML, @fillFactorForIndex int',
        @timeFrom, @timeTo, @fragmentationPercentForRebuild,
        @fragmentationPercentMinForMaintenance, @maxDop,
        @minIndexSizePages, @maxIndexSizePages, @useOnlineIndexRebuild,
        @maxIndexSizeForReorganizingPages,
        @useMonitoringDatabase, @monitoringDatabaseName, @usePreparedInformationAboutObjectsStateIfExists,
        @databaseName, @maxTransactionLogSizeUsagePercent, @maxTransactionLogSizeMB, @useResumableIndexRebuild,
		@excludeIndexes, @fillFactorForIndex;

    RETURN 0
END
ALTER PROCEDURE [dbo].[sp_StatisticMaintenance_Detailed]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59', 
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
	@ConditionIndexName nvarchar(max) = 'LIKE ''%''',
	@ConditionStatisticName nvarchar(max) = 'LIKE ''%''',
	@MinRowsChangedToMaintenance bigint = 1,
    @useMonitoringDatabase bit = 1,
    @monitoringDatabaseName sysname = 'SQLServerMonitoring'
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @msg nvarchar(max);
 
    IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END
 
    DECLARE @cmd nvarchar(max);
    SET @cmd =
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;
DECLARE
    -- Текущее время
    @timeNow TIME = CAST(GETDATE() AS TIME)
    -- Начало доступного интервала времени обслуживания
    -- @timeFrom TIME
    -- Окончание доступного интервала времени обслуживания
    -- @timeTo TIME
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
    ,@TableName SYSNAME
    ,@IndexName SYSNAME
    ,@Operation NVARCHAR(128) = ''UPDATE STATISTICS''
    ,@RunDate DATETIME = GETDATE()
    ,@StartDate DATETIME
    ,@FinishDate DATETIME
    ,@SQL NVARCHAR(500)
    ,@RowModCtr BIGINT
    ,@MaintenanceActionLogId bigint;
DECLARE todo CURSOR FOR
SELECT
    ''
    UPDATE STATISTICS ['' + SCHEMA_NAME([o].[schema_id]) + ''].['' + [o].[name] + ''] ['' + [s].[name] + '']
        WITH FULLSCAN'' + CASE WHEN [s].[no_recompute] = 1 THEN '', NORECOMPUTE'' ELSE '''' END + '';''
    , [o].[name]
    , [s].[name] AS [stat_name],
    [rowmodctr]
FROM (
    SELECT
        [object_id]
        ,[name]
        ,[stats_id]
        ,[no_recompute]
        ,[last_update] = STATS_DATE([object_id], [stats_id])
        ,[auto_created]
    FROM sys.stats WITH(NOLOCK)
    WHERE [is_temporary] = 0) s
        LEFT JOIN sys.objects o WITH(NOLOCK)
            ON [s].[object_id] = [o].[object_id]
        LEFT JOIN (
            SELECT
                [p].[object_id]
                ,[p].[index_id]
                ,[total_pages] = SUM([a].[total_pages])
            FROM sys.partitions p WITH(NOLOCK)
                JOIN sys.allocation_units a WITH(NOLOCK) ON [p].[partition_id] = [a].[container_id]
            GROUP BY
                [p].[object_id]
                ,[p].[index_id]) p
            ON [o].[object_id] = [p].[object_id] AND [p].[index_id] = [s].[stats_id]
        LEFT JOIN sys.sysindexes si
    ON [si].[id] = [s].[object_id] AND [si].[indid] = [s].[stats_id]
WHERE [o].[type] IN (''U'', ''V'')
    AND [o].[is_ms_shipped] = 0
    AND [rowmodctr] >= @MinRowsChangedToMaintenance
    AND [o].[name] ' AS nvarchar(max)) + CAST(@ConditionTableName AS nvarchar(max)) + CAST('
	AND CASE WHEN [si].[root] IS NULL THEN '''' ELSE [si].[name] END ' AS nvarchar(max)) + CAST(@ConditionIndexName AS nvarchar(max)) + CAST('
	AND [s].[name] ' AS nvarchar(max)) + CAST(@ConditionStatisticName AS nvarchar(max)) + CAST('
ORDER BY [rowmodctr] DESC;
OPEN todo;
WHILE 1=1
BEGIN
    FETCH NEXT FROM todo INTO @SQL, @TableName, @IndexName, @RowModCtr;
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
        -- Сохраняем предварительную информацию об операции обслуживания без даты завершения
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_log]
               @TableName
              ,@IndexName
              ,@Operation
              ,@RunDate
              ,@StartDate
              ,null
              ,@DBNAME
              ,0
              ,''''
              ,0
              ,@RowModCtr
              ,@SQL
              ,@MaintenanceActionLogId OUTPUT;
        END
        EXEC sp_executesql @SQL;
        SET @FinishDate = GetDate();
        -- Устанавливаем фактическую дату завершения операции
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
                @MaintenanceActionLogId,
                @FinishDate;
        END
    END TRY
    BEGIN CATCH
        IF(@MaintenanceActionLogId <> 0)
        BEGIN
            DECLARE @msg nvarchar(500) = ''Error: '' + CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' + CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' + CAST(Error_Line() AS NVARCHAR(500))
            -- Устанавливаем текст ошибки при обслуживании объекта статистики
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
' AS nvarchar(max))
 
    EXECUTE sp_executesql
        @cmd,
        N'@timeFrom TIME, @timeTo TIME,
        @useMonitoringDatabase bit, @monitoringDatabaseName sysname, @MinRowsChangedToMaintenance bigint',
        @timeFrom, @timeTo,
        @useMonitoringDatabase, @monitoringDatabaseName, @MinRowsChangedToMaintenance;
 
    RETURN 0
END
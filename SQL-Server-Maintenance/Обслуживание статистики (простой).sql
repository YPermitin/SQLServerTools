SET NOCOUNT ON;

DECLARE -- Служебные переменные
    @TableName SYSNAME
    ,@IndexName SYSNAME
    ,@SQL NVARCHAR(500);

DECLARE todo CURSOR FOR
SELECT
    '
    UPDATE STATISTICS [' + SCHEMA_NAME([o].[schema_id]) + '].[' + [o].[name] + '] [' + [s].[name] + ']
        WITH FULLSCAN' + CASE WHEN [s].[no_recompute] = 1 THEN ', NORECOMPUTE' ELSE '' END + ';'
    , [o].[name]
    , [s].[name] AS [stat_name]
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
WHERE [o].[type] IN ('U', 'V')
    AND [o].[is_ms_shipped] = 0
ORDER BY [rowmodctr] DESC;

OPEN todo;
WHILE 1=1
BEGIN
    FETCH NEXT FROM todo INTO @SQL, @TableName, @IndexName;

    IF @@FETCH_STATUS != 0
        BREAK;

    EXEC sp_executesql @SQL;
END

CLOSE todo;
DEALLOCATE todo;
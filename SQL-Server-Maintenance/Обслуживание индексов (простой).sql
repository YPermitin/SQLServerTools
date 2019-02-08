SET NOCOUNT ON;

DECLARE -- Служебные переменные
	@ObjectID INT
	,@IndexID INT
	,@PartitionCount BIGINT
	,@SchemaName SYSNAME
	,@ObjectName SYSNAME
	,@IndexName SYSNAME
	,@PartitionNum BIGINT
	,@frag FLOAT
	,@Command NVARCHAR(4000)
    ,@DBID SMALLINT = DB_ID();

IF OBJECT_ID('tempdb..#MaintenanceCommands') IS NOT NULL
	DROP TABLE #MaintenanceCommands;

SELECT
    [object_id] AS [objectid],
    [index_id] AS [indexid],
    [partition_number] AS [partitionnum],
    MAX([avg_fragmentation_in_percent]) AS [frag],
    MAX([page_count]) AS [page_count],
    SUM([si].[rowmodctr]) AS [rowmodctr]
INTO #MaintenanceCommands
FROM sys.dm_db_index_physical_stats (@DBID, NULL, NULL , NULL, N'LIMITED') dt
    LEFT JOIN sys.sysindexes si
    ON dt.object_id = si.id
WHERE [avg_fragmentation_in_percent] > 10.0
    AND [index_id] > 0
    AND [page_count] > 25
GROUP BY [object_id]
  ,[index_id]
  ,[partition_number];

DECLARE partitions CURSOR FOR SELECT objectid, indexid, partitionnum, frag
FROM #MaintenanceCommands;
OPEN partitions;

WHILE (1=1)
BEGIN
    FETCH NEXT FROM partitions INTO @objectid, @indexid, @partitionnum, @frag;
    
    IF @@FETCH_STATUS < 0 BREAK;

    SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
    FROM sys.objects AS o
        JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE o.object_id = @objectid;

    SELECT @indexname = QUOTENAME(name)
    FROM sys.indexes
    WHERE object_id = @objectid AND index_id = @indexid;
    
    SELECT @partitioncount = count (*)
    FROM sys.partitions
    WHERE object_id = @objectid AND index_id = @indexid;

    IF @frag < 30.0
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
    IF @frag >= 30.0
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
    IF @partitioncount > 1
        SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));

    EXEC (@command);
END;

CLOSE partitions;
DEALLOCATE partitions;

IF OBJECT_ID('tempdb..#MaintenanceCommands') IS NOT NULL
	DROP TABLE #MaintenanceCommands;
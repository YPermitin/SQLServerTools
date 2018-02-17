SET NOCOUNT ON;
DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130);
DECLARE @objectname nvarchar(130);
DECLARE @indexname nvarchar(130);
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000);
DECLARE @dbid smallint;

-- Выбираем индексы с уровнем фрагментации выше 10%
-- Определяем текущую БД

SET @dbid = DB_ID();
SELECT
    [object_id] AS objectid,
    index_id AS indexid,
    partition_number AS partitionnum,
    avg_fragmentation_in_percent AS frag, page_count
INTO #work_to_do
FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, N'LIMITED')
WHERE avg_fragmentation_in_percent > 10.0
    AND index_id > 0 -- игнорируем heap
    AND page_count > 25;
-- игнорируем маленькие таблицы

-- объявляем курсор для списка обрабатываемых partition
DECLARE partitions CURSOR FOR SELECT objectid, indexid, partitionnum, frag
FROM #work_to_do;

OPEN partitions;

-- цикл по partition
WHILE (1=1)
BEGIN
    FETCH NEXT
FROM partitions
INTO @objectid, @indexid, @partitionnum, @frag;
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

    -- 30% считаем пределом для определения типа обновления индекса.
    IF @frag < 30.0
    SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
    IF @frag >= 30.0
    SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD';
    IF @partitioncount > 1
    SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));

    EXEC (@command);
    PRINT N'Выполнено: ' + @command;
END;

CLOSE partitions;
DEALLOCATE partitions;

-- удаляем временную таблицу
DROP TABLE #work_to_do;
GO
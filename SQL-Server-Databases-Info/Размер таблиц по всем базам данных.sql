SET QUOTED_IDENTIFIER ON;

IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
	DROP TABLE #tableSizeResult;

DECLARE @sql nvarchar(max);

SET @sql = '
SELECT
	DB_NAME() AS [databaseName],
	a3.name AS [schemaname],
	a2.name AS [tablename],
	a1.rows as row_count,
	(a1.reserved + ISNULL(a4.reserved,0))* 8 AS [reserved], 
	a1.data * 8 AS [data],
	(CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS [index_size],
	(CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS [unused]
FROM
	(SELECT 
		ps.object_id,
		SUM (
			CASE
				WHEN (ps.index_id < 2) THEN row_count
				ELSE 0
			END
			) AS [rows],
		SUM (ps.reserved_page_count) AS reserved,
		SUM (
			CASE
				WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
				ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
			END
			) AS data,
		SUM (ps.used_page_count) AS used
	FROM sys.dm_db_partition_stats ps
	GROUP BY ps.object_id) AS a1
LEFT OUTER JOIN 
	(SELECT 
		it.parent_id,
		SUM(ps.reserved_page_count) AS reserved,
		SUM(ps.used_page_count) AS used
	 FROM sys.dm_db_partition_stats ps
	 INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
	 WHERE it.internal_type IN (202,204)
	 GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id)
INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
WHERE a2.type <> N''S'' and a2.type <> N''IT''
ORDER BY reserved DESC
';

CREATE TABLE #tableSizeResult (
	[DatabaseName] [nvarchar](255),
	[SchemaName] [nvarchar](5),
    [TableName] [nvarchar](255),
    [RowCnt] bigint,
    [Reserved] bigint,
    [Data] bigint,
    [IndexSize] bigint,
	[Unused] bigint
);


DECLARE @statement nvarchar(max);

SET @statement = (
SELECT 'EXEC ' + QUOTENAME(name) + '.sys.sp_executesql @sql; '
FROM sys.databases
WHERE DATABASEPROPERTY(name, 'IsSingleUser') = 0
      AND HAS_DBACCESS(name) = 1
      AND state_desc = 'ONLINE'
	  AND NOT database_id IN (
		DB_ID('tempdb'),
		DB_ID('master'),
		DB_ID('model'),
		DB_ID('msdb')
	  )
FOR XML PATH(''), TYPE
).value('.','nvarchar(max)');

INSERT #tableSizeResult
EXEC sp_executesql @statement, N'@sql nvarchar(max)', @sql;

DECLARE todo CURSOR FOR
SELECT 
	[DatabaseName],
	[SchemaName],
    [TableName],
    [RowCnt],
    [Reserved],
    [Data],
    [IndexSize],
	[Unused]
FROM #tableSizeResult;

DECLARE
	@DatabaseName nvarchar(255),
	@SchemaName nvarchar(5),
    @TableName nvarchar(255),
    @RowCnt bigint,
    @Reserved bigint,
    @Data bigint,
    @IndexSize bigint,
	@Unused bigint;
OPEN todo;

WHILE 1=1
BEGIN
    FETCH NEXT FROM todo INTO @DatabaseName, @SchemaName, @TableName, @RowCnt, @Reserved, @Data, @IndexSize, @Unused;
    IF @@FETCH_STATUS != 0
        BREAK;

	/*
    Здесь можно обработать результат, сохранить его или вывести в удобном виде
    */
	
END

CLOSE todo;
DEALLOCATE todo;

IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
	DROP TABLE #tableSizeResult;
ALTER PROCEDURE [dbo].[sp_FillDatabaseObjectsState]
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max),
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

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
INSERT INTO [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState](
	[Period]
	,[DatabaseName]
	,[TableName]
	,[Object]
	,[PageCount]
	,[Rowmodctr]
	,[AvgFragmentationPercent]
	,[OnlineRebuildSupport]
	,[Compression]
	,[PartitionCount]
)
SELECT
  GETDATE() AS [Period],
  ''' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(''' AS [DatabaseName],
  OBJECT_NAME(dt.[object_id]) AS [Table], 
  ISNULL(ind.name, '''') AS [Object],
  MAX(CAST([page_count] AS BIGINT)) AS [page_count], 
  MAX(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr],
  MAX([avg_fragmentation_in_percent]) AS [frag], 
  MIN(CASE WHEN objBadTypes.IndexObjectId IS NULL THEN 1 ELSE 0 END) AS [OnlineRebuildSupport],
  MAX(p.data_compression_desc) AS [Compression],
  MAX(p_count.[PartitionCount]) AS [PartitionCount]
FROM 
  sys.dm_db_index_physical_stats (
    DB_ID(), 
    NULL, 
    NULL, 
    NULL, 
    N''LIMITED''
  ) dt 
  LEFT JOIN sys.partitions p
	ON dt.object_id = p.object_id AND p.partition_number = dt.partition_number
	AND dt.index_id = p.index_id
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
	LEFT JOIN sys.indexes AS [ind]
		ON dt.object_id = [ind].object_id AND dt.index_id = [ind].[index_id]
	LEFT JOIN sys.sysindexes si ON dt.object_id = si.id 
		AND si.name = ind.name
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
  AND dt.[index_id] > 0 -- игнорируем кучи (heap)
GROUP BY
	dt.[object_id], 
	dt.[index_id],
	ind.[name],
	dt.[partition_number]
' AS nvarchar(max));

	EXECUTE sp_executesql @cmd;

    RETURN 0
END
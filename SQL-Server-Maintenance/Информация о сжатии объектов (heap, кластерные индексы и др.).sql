/*
Скрипт для анализа сжатия объектов базы данных:
	* Кучи (heap)
	* Кластерные индексы
	* Другие объекты

Дополнительная информация: https://stackoverflow.com/questions/16988326/query-all-table-data-and-index-compression
*/

SELECT
	[Table],
	[Index],
	[Compression]
FROM (
	SELECT 
		[t].[name] AS [Table], 
		null AS [Index],  
		[p].[partition_number] AS [Partition],
		[p].[data_compression_desc] AS [Compression]
	FROM [sys].[partitions] AS [p]
		INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
	WHERE [p].[index_id] = 0
	UNION
	SELECT 
		[t].[name] AS [Table], 
		[i].[name] AS [Index],   
		[p].[partition_number] AS [Partition],
		[p].[data_compression_desc] AS [Compression]
	FROM [sys].[partitions] AS [p]
		INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
		INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
	WHERE [p].[index_id] = 1
	UNION
	SELECT 
		[t].[name] AS [Table], 
		[i].[name] AS [Index],  
		[p].[partition_number] AS [Partition],
		[p].[data_compression_desc] AS [Compression]
	FROM [sys].[partitions] AS [p]
		INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
		INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
	WHERE [p].[index_id] > 0) dt
WHERE dt.Compression <> 'NONE'
ORDER BY dt.[Table]
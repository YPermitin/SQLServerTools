SELECT
	DB_NAME([IF].database_id) AS [Имя базы] 
	,OBJECT_NAME(object_id) AS [Имя таблицы]	
	,OBJECT_NAME([IF].index_id) AS [Имя индкса]	
	,[IF].*
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) AS [IF]
WHERE avg_fragmentation_in_percent > 30
ORDER BY avg_fragmentation_in_percent

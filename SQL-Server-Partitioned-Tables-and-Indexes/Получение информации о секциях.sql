SELECT 
	OBJECT_NAME(prt.object_id) [Имя объекта]
	,ind.name AS [Имя индекса]
	,partition_id AS [Идентификатор секции]
	,partition_number AS [Номер секции]
	,row_count AS [Количество строк в секции]
	,in_row_data_page_count AS [Количество используемых страниц]
	,in_row_used_page_count AS [Количество доступных страниц]
	,in_row_reserved_page_count AS [Количество резервных страниц]	
	,used_page_count AS [Число используемых страниц в секции]
	,reserved_page_count AS [Число зарезервированных страниц в секции]	
FROM sys.dm_db_partition_stats prt
	LEFT JOIN sys.indexes ind
	ON prt.object_id = ind.object_id
	AND prt.index_id = ind.index_id
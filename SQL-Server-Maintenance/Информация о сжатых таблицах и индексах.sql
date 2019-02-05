SELECT 
	st.name AS [Имя таблицы], 
	ISNULL(INDX.name, st.name) AS [Имя объекта], 
	sp.partition_id AS [Идентификатор секции], 
	sp.partition_number AS [Номер секции], 
	sp.data_compression AS [Тип сжатия], 
	sp.data_compression_desc AS [Имя типа сжатия]	
FROM sys.partitions SP
	INNER JOIN sys.tables ST	
		ON st.object_id = sp.object_id
	LEFT JOIN sys.indexes INDX
		ON INDX.object_id = ST.object_id
			AND INDX.index_id = SP.index_id
WHERE data_compression <> 0

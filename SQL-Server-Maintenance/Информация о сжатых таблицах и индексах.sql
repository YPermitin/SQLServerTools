SELECT 
	st.name AS [Имя таблицы], 
	OBJECT_NAME(st.object_id) AS [Имя объекта], 
	sp.partition_id AS [Идентификатор секции], 
	sp.partition_number AS [Номер секции], 
	sp.data_compression AS [Тип сжатия], 
	sp.data_compression_desc AS [Имя типа сжатия]
FROM sys.partitions SP
	INNER JOIN sys.tables ST 
	ON st.object_id = sp.object_id
WHERE data_compression <> 0

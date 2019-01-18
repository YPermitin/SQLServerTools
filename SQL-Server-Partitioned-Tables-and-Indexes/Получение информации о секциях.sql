-- Дополнительная информация https://docs.microsoft.com/ru-ru/sql/relational-databases/system-dynamic-management-views/sys-dm-db-partition-stats-transact-sql?view=sql-server-2017

SELECT 
	OBJECT_NAME(ps.[object_id]) AS [Имя таблицы]
	,indx.[name] AS [Имя индекса]
	,ps.[partition_id] AS [Идентификатор секции]
	,ps.[partition_number] AS [Номер секции]
	,ps.[in_row_data_page_count] AS [Количество страниц для хранения данных]
	/* Детальные поля по использованию страниц для каждой секции
	--,ps.[in_row_used_page_count] AS [Количество страниц для хранения и управления данными]
	--,ps.[in_row_reserved_page_count] AS [Количество страниц зарезервировано для хранения и управления данными]
	--,ps.[lob_used_page_count] AS [Количество страниц для хранения BLOB объектов]
	-- text, ntext, image, varchar(max), nvarchar(max), varbinary(max), и xml
	--,ps.[lob_reserved_page_count] AS [Количество страниц зарезервировано для хранения BLOB объектов]
	--,ps.[row_overflow_used_page_count] AS [Количество страниц, используемых для хранения и управления строками, превышающими varchar, nvarchar, varbinary, и sql_variant]
	--,ps.[row_overflow_reserved_page_count] AS [Общее число страниц, зарезервированных для хранения и управления ими строки, превышающие varchar, nvarchar, varbinary, и sql_variant]
	-- in_row_used_page_count + lob_used_page_count + row_overflow_used_page_count
	*/
	,ps.[used_page_count] AS [Общее количество страниц использовано]
	,ps.[reserved_page_count] AS [Общее количество страниц зарезервировано]
	,ps.[row_count] AS [Количество строк в секции]
FROM sys.dm_db_partition_stats ps
	LEFT JOIN sys.indexes indx
	ON ps.object_id = indx.object_id
		AND ps.index_id = indx.index_id
--WHERE 
	-- OBJECT_NAME(ps.object_id) = '<Имя таблицы>'
	-- indx.[name] = '<Имя индекса>'

IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
	DROP TABLE #tableSizeResult;

DECLARE @sql nvarchar(max);

-- Информация о хранимой процедуре
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-stored-procedures/sp-spaceused-transact-sql?view=sql-server-ver15
SET @sql = '
EXEC sp_spaceused null, false, ''ALL'', 1;
';

CREATE TABLE #tableSizeResult (
	[database_name] [nvarchar](255),
    [database_size] [nvarchar](255),
    [unallocated space] [nvarchar](255),
	[reserved] [nvarchar](255),
    [data] [nvarchar](255),
    [index_size] [nvarchar](255),
	[unused] [nvarchar](255)
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

SELECT
    -- Имя базы данных
	[database_name],
    -- Размер текущей базы данных в мегабайтах. Включает файлы данных и журналов.
	CAST(REPLACE([database_size], ' MB', '') AS decimal) * 1000 AS [DatabaseSizeKB],
    -- Место в базе данных, не зарезервированное для объектов базы данных.
	CAST(REPLACE([unallocated space], ' MB', '') AS decimal) * 1000 AS [UnallocatedSpaceKB],
    -- Объем зарезервированного места
	CAST(REPLACE([reserved], ' KB', '') AS decimal) AS [ReservedKB],
    -- Общий объем пространства, используемый данными.
	CAST(REPLACE([data], ' KB', '') AS decimal) AS [DataKB],
    -- Общий объем пространства, используемый индексами.
	CAST(REPLACE([index_size], ' KB', '') AS decimal) AS [IndexSizeKB],
    -- Общий объем пространства, зарезервированный для объектов в базе данных, но пока не используемый.
	CAST(REPLACE([unused], ' KB', '') AS decimal) AS [UnusedKB]
FROM #tableSizeResult

IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
	DROP TABLE #tableSizeResult;
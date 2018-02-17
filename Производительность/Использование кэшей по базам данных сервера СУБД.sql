SELECT DB_NAME(database_id) AS DB, COUNT(row_count)*8.00/1024.00 AS MB, COUNT(row_count)*8.00/1024.00/1024.00 AS GB
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY MB DESC
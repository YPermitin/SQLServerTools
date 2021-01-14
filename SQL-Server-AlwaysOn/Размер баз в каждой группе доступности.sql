-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SELECT
    Groups.name,
    SUM(CAST((CAST([master_files].[size] AS BIGINT )*8) AS MONEY)/1024/1024) AS TotalDBSize_GB
FROM master.sys.availability_groups Groups
    INNER JOIN Sys.availability_databases_cluster AGDatabases ON Groups.group_id = AGDatabases.group_id
    INNER JOIN sys.databases ON AGDatabases.database_name = databases.name
    INNER JOIN sys.master_files ON databases.database_id = master_files.database_id
GROUP BY Groups.name
ORDER BY Groups.name ASC
-- SQL Server 2014 +
-- https://blog.dbi-services.com/sql-server-2014-new-incremental-statistics/

SELECT
       stats_id,
       name AS stat_name,
       is_incremental
FROM sys.stats
WHERE is_incremental = 1

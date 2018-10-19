WITH DB_Disk_Reads_Stats

AS

(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_physical_reads) AS [physical_reads]

 FROM sys.dm_exec_query_stats AS qs

 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 

              FROM sys.dm_exec_plan_attributes(qs.plan_handle)

              WHERE attribute = N'dbid') AS F_DB

 GROUP BY DatabaseID)

SELECT ROW_NUMBER() OVER(ORDER BY [physical_reads] DESC) AS [row_num],

       DatabaseName, [physical_reads], 

       CAST([physical_reads] * 1.0 / SUM([physical_reads]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [Physical_Reads_Percent]

FROM DB_Disk_Reads_Stats

WHERE DatabaseID > 4 -- system databases

AND DatabaseID <> 32767 -- ResourceDB

ORDER BY row_num OPTION (RECOMPILE);
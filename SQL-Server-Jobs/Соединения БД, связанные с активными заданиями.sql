/*
Запрос для получения информации об активных заданиях агента SQL Server,
а также связанных с ними соединениями базы данных, плюс время выполнения задания.
*/

DECLARE @AllConnections TABLE(
    SPID INT,
    Status VARCHAR(MAX),
    LOGIN VARCHAR(MAX),
    HostName VARCHAR(MAX),
    BlkBy VARCHAR(MAX),
    DBName VARCHAR(MAX),
    Command VARCHAR(MAX),
    CPUTime INT,
    DiskIO INT,
    LastBatch VARCHAR(MAX),
    ProgramName VARCHAR(MAX),
    SPID_1 INT,
    REQUESTID INT
	)
INSERT INTO @AllConnections
EXEC sp_who2

SELECT
    sj.[job_id] AS [JobId],
    sj.[name] AS [JobName],
    DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) AS 'ExecutionDurationSec',
    c.SPID,
    c.Status,
    c.LOGIN,
    c.HostName,
    c.BlkBy,
    c.DBName,
    c.Command,
    c.CPUTime,
    c.DiskIO,
    c.LastBatch,
    c.ProgramName,
    c.SPID_1,
    c.REQUESTID
FROM @AllConnections c
    INNER JOIN [msdb].[dbo].[sysjobs] sj
    ON UPPER(c.ProgramName) LIKE '%Job 0x' + UPPER(CONVERT(VARCHAR(max), CAST(sj.job_id AS varbinary(max)), 2)) + '%'
    INNER JOIN [msdb].[dbo].[sysjobactivity] AS sja
    ON sja.job_id = sj.job_id
    INNER JOIN (
			SELECT
        [job_id],
        MAX([session_id]) AS [session_id]
    FROM [msdb].[dbo].[sysjobactivity]
    GROUP BY [job_id]) ls
    ON ls.job_id = sja.job_id
        AND ls.session_id = sja.session_id
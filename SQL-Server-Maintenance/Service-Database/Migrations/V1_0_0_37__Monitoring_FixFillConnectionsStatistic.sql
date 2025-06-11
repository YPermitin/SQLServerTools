ALTER PROCEDURE [dbo].[sp_FillConnectionsStatistic]
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @cmd nvarchar(max),
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

    SET @cmd =
CAST('
SET NOCOUNT ON;
 
INSERT INTO [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[ConnectionsStatistic]
           ([Period]
           ,[InstanceName]
           ,[QueryText]
           ,[RowCountSize]
           ,[SessionId]
           ,[Status]
           ,[Command]
           ,[CPU]
           ,[TotalElapsedTime]
           ,[StartTime]
           ,[DatabaseName]
           ,[BlockingSessionId]
           ,[WaitType]
           ,[WaitTime]
           ,[WaitResource]
           ,[OpenTransactionCount]
           ,[Reads]
           ,[Writes]
           ,[LogicalReads]
           ,[GrantedQueryMemory]
           ,[UserName]
)
SELECT
    GetDate() AS [Period],
    @@servername AS [HostName],
    sqltext.TEXT AS [QueryText],
    req.row_count AS [RowCountSize],
    req.session_id AS [SessionId],
    req.status AS [Status],
    req.command AS [Command],
    req.cpu_time AS [CPU],
    req.total_elapsed_time AS [TotalElapsedTime],
    req.start_time AS [StartTime],
    DB_NAME(req.database_id) AS [DatabaseName],
    req.blocking_session_id AS [BlockingSessionId],
    req.wait_type AS [WaitType],
    req.wait_time AS [WaitTime],
    req.wait_resource AS [WaitResource],
    req.open_transaction_count AS [OpenTransactionCount],
    req.reads as [Reads],
    req.reads as [Writes],
    req.logical_reads as [LogicalReads],
    req.granted_query_memory as [GrantedQueryMemory],
    SUSER_NAME(user_id) AS [UserName]
FROM sys.dm_exec_requests req
    OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
' AS nvarchar(max));
 
    EXECUTE sp_executesql @cmd;
 
    RETURN 0
END
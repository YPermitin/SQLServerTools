SELECT 
    @@Servername AS [Server],
    DB_NAME(database_id) [DatabaseName],
    command [Command],
    percent_complete [PercentComplete],
    session_id [ConnectionId],
    start_time [StartTime],
    status [Status],
    txtsql.text [QueryText],
    USER_NAME(user_id) [User],
    wait_type [WaitType]
FROM sys.dm_exec_requests der
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) txtsql
WHERE ISNULL(percent_complete,0) > 0

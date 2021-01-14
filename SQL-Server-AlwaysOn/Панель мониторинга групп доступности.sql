-- Подробная информация здесь:
-- https://sqlperformance.com/2015/08/monitoring/availability-group-replica-sync

/*
Запрос почти аналогичен тому, который выполняется в панели мониторинга групп доступности AlwaysOn в SSMS.
С помощью запроса можно получать размеры очереди повтора, скорость предполагаемой потери данных и информация об LSN.
*/

SET NOCOUNT ON;

DECLARE @AGname NVARCHAR(128);

DECLARE @SecondaryReplicasOnly BIT;

SET @AGname = NULL;
--SET AGname for a specific AG for SET to NULL for ALL AG's

IF OBJECT_ID('TempDB..#tmpag_availability_groups') IS NOT NULL
DROP TABLE [#tmpag_availability_groups];

SELECT *
INTO [#tmpag_availability_groups]
FROM [master].[sys].[availability_groups];

IF(@AGname IS NULL
    OR EXISTS
(
SELECT [Name]
    FROM [#tmpag_availability_groups]
    WHERE  [Name] = @AGname
))
BEGIN

    IF OBJECT_ID('TempDB..#tmpdbr_availability_replicas') IS NOT NULL
DROP TABLE [#tmpdbr_availability_replicas];

    IF OBJECT_ID('TempDB..#tmpdbr_database_replica_cluster_states') IS NOT NULL
DROP TABLE [#tmpdbr_database_replica_cluster_states];

    IF OBJECT_ID('TempDB..#tmpdbr_database_replica_states') IS NOT NULL
DROP TABLE [#tmpdbr_database_replica_states];

    IF OBJECT_ID('TempDB..#tmpdbr_database_replica_states_primary_LCT') IS NOT NULL
DROP TABLE [#tmpdbr_database_replica_states_primary_LCT];

    IF OBJECT_ID('TempDB..#tmpdbr_availability_replica_states') IS NOT NULL
DROP TABLE [#tmpdbr_availability_replica_states];

    SELECT [group_id],
        [replica_id],
        [replica_server_name],
        [availability_mode],
        [availability_mode_desc]
    INTO [#tmpdbr_availability_replicas]
    FROM [master].[sys].[availability_replicas];

    SELECT [replica_id],
        [group_database_id],
        [database_name],
        [is_database_joined],
        [is_failover_ready]
    INTO [#tmpdbr_database_replica_cluster_states]
    FROM [master].[sys].[dm_hadr_database_replica_cluster_states];

    SELECT *
    INTO [#tmpdbr_database_replica_states]
    FROM [master].[sys].[dm_hadr_database_replica_states];

    SELECT [replica_id],
        [role],
        [role_desc],
        [is_local]
    INTO [#tmpdbr_availability_replica_states]
    FROM [master].[sys].[dm_hadr_availability_replica_states];

    SELECT [ars].[role],
        [drs].[database_id],
        [drs].[replica_id],
        [drs].[last_commit_time]
    INTO [#tmpdbr_database_replica_states_primary_LCT]
    FROM [#tmpdbr_database_replica_states] AS [drs]
        LEFT JOIN [#tmpdbr_availability_replica_states] [ars] ON [drs].[replica_id] = [ars].[replica_id]
    WHERE  [ars].[role] = 1;

    SELECT [AG].[name] AS [AvailabilityGroupName],
        [AR].[replica_server_name] AS [AvailabilityReplicaServerName],
        [dbcs].[database_name] AS [AvailabilityDatabaseName],
        ISNULL([dbcs].[is_failover_ready],0) AS [IsFailoverReady],
        ISNULL([arstates].[role_desc],3) AS [ReplicaRole],
        [AR].[availability_mode_desc] AS [AvailabilityMode],
        CASE [dbcs].[is_failover_ready]
WHEN 1
THEN 0
ELSE ISNULL(DATEDIFF([ss],[dbr].[last_commit_time],[dbrp].[last_commit_time]),0)
END AS [EstimatedDataLoss_(Seconds)],
        ISNULL(CASE [dbr].[redo_rate]
WHEN 0
THEN-1
ELSE CAST([dbr].[redo_queue_size] AS FLOAT) / [dbr].[redo_rate]
END,-1) AS [EstimatedRecoveryTime_(Seconds)],
        ISNULL([dbr].[is_suspended],0) AS [IsSuspended],
        ISNULL([dbr].[suspend_reason_desc],'-') AS [SuspendReason],
        ISNULL([dbr].[synchronization_state_desc],0) AS [SynchronizationState],
        ISNULL([dbr].[last_received_time],0) AS [LastReceivedTime],
        ISNULL([dbr].[last_redone_time],0) AS [LastRedoneTime],
        ISNULL([dbr].[last_sent_time],0) AS [LastSentTime],
        ISNULL([dbr].[log_send_queue_size],-1) AS [LogSendQueueSize],
        ISNULL([dbr].[log_send_rate],-1) AS [LogSendRate_KB/S],
        ISNULL([dbr].[redo_queue_size],-1) AS [RedoQueueSize_KB],
        ISNULL([dbr].[redo_rate],-1) AS [RedoRate_KB/S],
        ISNULL(CASE [dbr].[log_send_rate]
WHEN 0
THEN-1
ELSE CAST([dbr].[log_send_queue_size] AS FLOAT) / [dbr].[log_send_rate]
END,-1) AS [SynchronizationPerformance],
        ISNULL([dbr].[filestream_send_rate],-1) AS [FileStreamSendRate],
        ISNULL([dbcs].[is_database_joined],0) AS [IsJoined],
        [arstates].[is_local] AS [IsLocal],
        ISNULL([dbr].[last_commit_lsn],0) AS [LastCommitLSN],
        ISNULL([dbr].[last_commit_time],0) AS [LastCommitTime],
        ISNULL([dbr].[last_hardened_lsn],0) AS [LastHardenedLSN],
        ISNULL([dbr].[last_hardened_time],0) AS [LastHardenedTime],
        ISNULL([dbr].[last_received_lsn],0) AS [LastReceivedLSN],
        ISNULL([dbr].[last_redone_lsn],0) AS [LastRedoneLSN]
    FROM [#tmpag_availability_groups] AS [AG]
        INNER JOIN [#tmpdbr_availability_replicas] AS [AR] ON [AR].[group_id] = [AG].[group_id]
        INNER JOIN [#tmpdbr_database_replica_cluster_states] AS [dbcs] ON [dbcs].[replica_id] = [AR].[replica_id]
        LEFT OUTER JOIN [#tmpdbr_database_replica_states] AS [dbr] ON [dbcs].[replica_id] = [dbr].[replica_id]
            AND [dbcs].[group_database_id] = [dbr].[group_database_id]
        LEFT OUTER JOIN [#tmpdbr_database_replica_states_primary_LCT] AS [dbrp] ON [dbr].[database_id] = [dbrp].[database_id]
        INNER JOIN [#tmpdbr_availability_replica_states] AS [arstates] ON [arstates].[replica_id] = [AR].[replica_id]
    WHERE  [AG].[name] = ISNULL(@AGname,[AG].[name])
    ORDER BY [AvailabilityReplicaServerName] ASC,
[AvailabilityDatabaseName] ASC;

/*********************/

END;
ELSE
BEGIN
    RAISERROR('Invalid AG name supplied, please correct and try again',12,0);
END;
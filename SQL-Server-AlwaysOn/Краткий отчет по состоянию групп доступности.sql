-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SELECT DISTINCT
    Groups.name AS AGname,
    Replicas.replica_server_name,
    States.role_desc,
    States.synchronization_health_desc,
    ISNULL(ReplicaStates.suspend_reason_desc,'N/A') AS suspend_reason_desc
FROM sys.availability_groups Groups
    INNER JOIN sys.dm_hadr_availability_replica_states as States ON States.group_id = Groups.group_id
    INNER JOIN sys.availability_replicas as Replicas ON States.replica_id = Replicas.replica_id
    INNER JOIN sys.dm_hadr_database_replica_states as ReplicaStates ON Replicas.replica_id = ReplicaStates.replica_id
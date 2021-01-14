-- Подробнее здесь:
-- https://sqlundercover.com/2017/09/19/7-ways-to-query-always-on-availability-groups-using-sql/

WITH AGStatus
AS
(
    SELECT
        name as AGname,
        replica_server_name,
        CASE 
            WHEN  (primary_replica  = replica_server_name) 
            THEN  1
            ELSE  '' 
        END AS IsPrimaryServer,
        secondary_role_allow_connections_desc AS ReadableSecondary,
        [availability_mode]  AS [Synchronous],
        failover_mode_desc
   FROM master.sys.availability_groups Groups
        INNER JOIN master.sys.availability_replicas Replicas 
            ON Groups.group_id = Replicas.group_id
        INNER JOIN master.sys.dm_hadr_availability_group_states States 
           ON Groups.group_id = States.group_id
)

Select
    [AGname],
    [Replica_server_name],
    [IsPrimaryServer],
    [Synchronous],
    [ReadableSecondary],
    [Failover_mode_desc]
FROM AGStatus
--WHERE
--  IsPrimaryServer = 1
--  AND Synchronous = 1
ORDER BY
    AGname ASC,
    IsPrimaryServer DESC;
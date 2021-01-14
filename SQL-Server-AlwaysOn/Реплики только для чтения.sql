-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SELECT
    PrimaryServer.replica_server_name AS PrimaryServer,
    Groups.name AS AGname,
    ReadOnlyReplica.replica_server_name AS ReadOnlyReplica,
    ReadOnlyReplica.read_only_routing_url AS RoutingURL,
    RoutingList.routing_priority AS RoutingPriority
FROM sys.availability_read_only_routing_lists RoutingList
    INNER JOIN sys.availability_replicas PrimaryServer ON RoutingList.replica_id = PrimaryServer.replica_id
    INNER JOIN sys.availability_replicas ReadOnlyReplica ON RoutingList.read_only_replica_id = ReadOnlyReplica.replica_id
    INNER JOIN sys.availability_groups Groups ON Groups.group_id = PrimaryServer.group_id
WHERE PrimaryServer.replica_server_name != ReadOnlyReplica.replica_server_name
ORDER BY
    PrimaryServer ASC,
    AGname ASC
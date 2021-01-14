-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SELECT
    Groups.name,
    COUNT([AGDatabases].[database_name]) AS DatabasesInAG
FROM master.sys.availability_groups Groups
    INNER JOIN Sys.availability_databases_cluster AGDatabases ON Groups.group_id = AGDatabases.group_id
GROUP BY Groups.name
ORDER BY Groups.name ASC
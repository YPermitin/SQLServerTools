-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SELECT 
    [Groups].[name]
FROM sys.dm_hadr_availability_group_states States
    INNER JOIN sys.availability_groups Groups 
        ON States.group_id = Groups.group_id
WHERE primary_replica = @@Servername
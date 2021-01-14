-- Подробнее здесь:
-- https://sqlundercover.com/2017/09/19/7-ways-to-query-always-on-availability-groups-using-sql/

-- Группы доступности, где текущий сервер является первичной репликой.
SELECT
    Groups.[Name] AS AGname
FROM sys.dm_hadr_availability_group_states States
    INNER JOIN master.sys.availability_groups Groups
    ON States.group_id = Groups.group_id
WHERE primary_replica = @@Servername;

-- Группы доступности, где текущий сервер является дополнительной репликой.
SELECT Groups.[Name] AS AGname
FROM sys.dm_hadr_availability_group_states States
    INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
WHERE primary_replica != @@Servername;

-- Группы доступности и базы данных, где текущий сервер является первичной репликой.
SELECT
    Groups.[Name] AS AGname,
    AGDatabases.database_name AS Databasename
FROM sys.dm_hadr_availability_group_states States
    INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
    INNER JOIN sys.availability_databases_cluster AGDatabases ON Groups.group_id = AGDatabases.group_id
WHERE primary_replica = @@Servername
ORDER BY
    AGname ASC,
    Databasename ASC;

-- Группы доступности и базы данных, где текущий сервер является дополнительной репликой.
SELECT
    Groups.[Name] AS AGname,
    AGDatabases.database_name AS Databasename
FROM sys.dm_hadr_availability_group_states States
    INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
    INNER JOIN sys.availability_databases_cluster AGDatabases ON Groups.group_id = AGDatabases.group_id
WHERE primary_replica != @@Servername
ORDER BY
    AGname ASC,
    Databasename ASC;

-- Все базы данных и группы доступности на сервере
SELECT Groups.[name] AS AGName ,
    Databaselist.[database_name] AS DatabaseName
FROM sys.availability_databases_cluster Databaselist
    INNER JOIN sys.availability_groups_cluster Groups ON Databaselist.group_id = Groups.group_id
ORDER BY
    AGName ,
    DatabaseName;
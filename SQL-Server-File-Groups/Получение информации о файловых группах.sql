-- Дополнительная информация:
--	Про файловые группы (https://docs.microsoft.com/ru-ru/sql/relational-databases/databases/database-files-and-filegroups?view=sql-server-2017)
--	Про файлы базы данных (https://docs.microsoft.com/ru-ru/sql/relational-databases/system-catalog-views/sys-database-files-transact-sql?view=sql-server-2017)
--	Про пространства данных (https://docs.microsoft.com/ru-ru/sql/relational-databases/system-catalog-views/sys-data-spaces-transact-sql?view=sql-server-2017)

SELECT
    OBJECT_NAME(i.id) AS [Table_Name]
    ,i.indid AS [Идентификатор индекса]
    ,i.[name] AS [Имя индекса]
    ,i.groupid AS [Идентификатор файловой группы]
    ,f.name AS [Имя файловой группы]
    ,d.physical_name AS [Путь к файлу]
    ,s.name AS [Пространство данных]
FROM sys.sysindexes i
    INNER JOIN sys.filegroups f ON  f.data_space_id = i.groupid
        AND f.data_space_id = i.groupid
    INNER JOIN sys.database_files d ON  f.data_space_id = d.data_space_id
    INNER JOIN sys.data_spaces s ON  f.data_space_id = s.data_space_id
WHERE OBJECTPROPERTY(i.id, 'IsUserTable') = 1
ORDER BY f.name, OBJECT_NAME(i.id), groupid

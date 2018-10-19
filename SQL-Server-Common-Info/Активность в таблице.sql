-- Чтение/запись таблицы
-- Кучи не рассматриваются, у них нет индексов
-- Только те таблицы, к которым обращались после запуска SQL Server

SELECT  @@ServerName AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_NAME(ddius.object_id) AS TableName ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups)
                                                               AS  Reads ,
        SUM(ddius.user_updates) AS Writes ,
        SUM(ddius.user_seeks + ddius.user_scans + ddius.user_lookups
            + ddius.user_updates) AS [Reads&Writes] ,
        ( SELECT    DATEDIFF(s, create_date, GETDATE()) / 86400.0
          FROM      master.sys.databases
          WHERE     name = 'tempdb'
        ) AS SampleDays ,
        ( SELECT    DATEDIFF(s, create_date, GETDATE()) AS SecoundsRunnig
          FROM      master.sys.databases
          WHERE     name = 'tempdb'
        ) AS SampleSeconds
FROM    sys.dm_db_index_usage_stats ddius
        INNER JOIN sys.indexes i ON ddius.object_id = i.object_id
                                     AND i.index_id = ddius.index_id
WHERE    OBJECTPROPERTY(ddius.object_id, 'IsUserTable') = 1
        AND ddius.database_id = DB_ID()
GROUP BY OBJECT_NAME(ddius.object_id)
ORDER BY [Reads&Writes] DESC;

GO

-- Операции чтения и записи
-- Кучи пропущены, у них нет индексов
-- Только таблицы, использовавшиеся после перезапуска SQL Server
-- В запросе используется курсор для получения информации во всех БД
-- Единый отчёт, хранится в tempdb

DECLARE DBNameCursor CURSOR
FOR
    SELECT  Name
    FROM    sys.databases
    WHERE    Name NOT IN ( 'master', 'model', 'msdb', 'tempdb',
                            'distribution' )
    ORDER BY Name; 

DECLARE @DBName NVARCHAR(128) 

DECLARE @cmd VARCHAR(4000) 

IF OBJECT_ID(N'tempdb..TempResults') IS NOT NULL
    BEGIN 
        DROP TABLE tempdb..TempResults 
    END 

CREATE TABLE tempdb..TempResults
    (
      ServerName NVARCHAR(128) ,
      DBName NVARCHAR(128) ,
      TableName NVARCHAR(128) ,
      Reads INT ,
      Writes INT ,
      ReadsWrites INT ,
      SampleDays DECIMAL(18, 8) ,
      SampleSeconds INT
    ) 

OPEN DBNameCursor 

FETCH NEXT FROM DBNameCursor INTO @DBName 
WHILE @@fetch_status = 0
    BEGIN 

---------------------------------------------------- 
-- Print @DBName 

        SELECT   @cmd = 'Use ' + @DBName + '; ' 
        SELECT   @cmd = @cmd + ' Insert Into tempdb..TempResults 
SELECT @@ServerName AS ServerName, 
DB_NAME() AS DBName, 
object_name(ddius.object_id) AS TableName , 
SUM(ddius.user_seeks 
+ ddius.user_scans 
+ ddius.user_lookups) AS Reads, 
SUM(ddius.user_updates) as Writes, 
SUM(ddius.user_seeks 
+ ddius.user_scans 
+ ddius.user_lookups 
+ ddius.user_updates) as ReadsWrites, 
(SELECT datediff(s,create_date, GETDATE()) / 86400.0 
FROM sys.databases WHERE name = ''tempdb'') AS SampleDays, 
(SELECT datediff(s,create_date, GETDATE()) 
FROM sys.databases WHERE name = ''tempdb'') as SampleSeconds 
FROM sys.dm_db_index_usage_stats ddius 
INNER JOIN sys.indexes i
ON ddius.object_id = i.object_id 
AND i.index_id = ddius.index_id 
WHERE objectproperty(ddius.object_id,''IsUserTable'') = 1 --True 
AND ddius.database_id = db_id() 
GROUP BY object_name(ddius.object_id) 
ORDER BY ReadsWrites DESC;' 

--PRINT @cmd 
        EXECUTE (@cmd) 

----------------------------------------------------- 

        FETCH NEXT FROM DBNameCursor INTO @DBName 
    END 

CLOSE DBNameCursor 

DEALLOCATE DBNameCursor 

SELECT  *
FROM    tempdb..TempResults
ORDER BY DBName ,
        TableName; 
--DROP TABLE tempdb..TempResults;
/*
Получение информации об использовании лога транзакций для всех баз на сервере с выводом дополнительной информации.

В итоге получим набор данных вида:
* База данных
* Имя файла лога
* Путь к файлу лога
* Диск, на котором хранится лог
* Свободное место на диске, МБ
* Размер файла лога
* Макс. размер файла лога
* Флаг, показывающий может ли файл лога еще расти (с учетом настроек)
* Размер свободного пространства в файле лога

Пример:
| DatabaseName        | LogFileName             | LogFilePath                               | Disk | DiskFreeSpaceMB | LogSizeMB | LogMaxSizeMB | LogFileCanGrow | LogFileFreeSpaceMB |
|---------------------|-------------------------|-------------------------------------------|------|-----------------|-----------|--------------|----------------|--------------------|
| master              | mastlog                 | F:\SQLLOGS\mastlog.ldf                    | F:\  | 1000000         | 1000      | 0            | 1              | 928                |
| tempdb              | templog                 | F:\SQLLOGS\templog.ldf                    | F:\  | 1000000         | 100000    | 400000       | 1              | 99999              |
| model               | modellog                | F:\SQLLOGS\modellog.ldf                   | F:\  | 1000000         | 8         | 0            | 1              | 7                  |
| msdb                | MSDBLog                 | F:\SQLLOGS\MSDBLog.ldf                    | F:\  | 1000000         | 300       | 2097152      | 1              | 290                |
| SQLServerMonitoring | SQLServerMonitoring_log | F:\SQLLOGS\SQLServerMonitoringLog.ldf     | F:\  | 1000000         | 1000      | 2097152      | 1              | 999                |
*/

IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
	DROP TABLE #logFileInfoByDatabases;
CREATE TABLE #logFileInfoByDatabases
(
	DatabaseName varchar(255) not null,
	LogFileName varchar(255),
	LogFilePath varchar(max),
	[Disk] varchar(25),
	[DiskFreeSpaceMB] numeric(15,0),
	[LogSizeMB] numeric(15,0),
	[LogMaxSizeMB] numeric(15,0),
	[LogFileCanGrow] bit,
	[LogFileFreeSpaceMB] numeric(15,0)
);

DECLARE
	@SqlStatement nvarchar(MAX)
	,@CurrentDatabaseName sysname;
DECLARE DatabaseList CURSOR LOCAL FAST_FORWARD FOR
	SELECT name FROM sys.databases;
OPEN DatabaseList;
WHILE 1 = 1
BEGIN
	FETCH NEXT FROM DatabaseList INTO @CurrentDatabaseName;
	IF @@FETCH_STATUS = -1 BREAK;
	SET @SqlStatement = N'USE '
		+ QUOTENAME(@CurrentDatabaseName)
		+ CHAR(13)+ CHAR(10)
		+ N'INSERT INTO #logFileInfoByDatabases
SELECT
	DB_NAME(f.database_id) AS [Database],
	f.[name] AS [LogFileName],
	f.physical_name AS [LogFilePath],
	volume_mount_point AS [Disk],
	available_bytes/1048576 as [DiskFreeSpaceMB],
	CAST(f.size AS bigint) * 8 / 1024 AS [LogSizeMB],
	CAST(f.max_size AS bigint) * 8 / 1024 AS [LogMaxSizeMB],
	CASE 
		WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
		THEN 0
		ELSE 1
	END AS [LogFileCanGrow],
	size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [LogFileFreeSpaceMB]
FROM sys.master_files AS f CROSS APPLY 
  sys.dm_os_volume_stats(f.database_id, f.file_id)
WHERE [type_desc] = ''LOG''
	and f.database_id = DB_ID();';

	EXECUTE(@SqlStatement);
	
END
CLOSE DatabaseList;
DEALLOCATE DatabaseList;

SELECT
	*
FROM #logFileInfoByDatabases

IF OBJECT_ID('tempdb..#tranLogInfo') IS NOT NULL
	DROP TABLE #tranLogInfo;
IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
	DROP TABLE #logFileInfoByDatabases;
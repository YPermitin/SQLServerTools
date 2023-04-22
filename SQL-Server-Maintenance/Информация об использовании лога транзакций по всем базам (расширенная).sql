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
| DatabaseName        | LogFileName             | LogFilePath                               | Disk | DiskFreeSpaceMB | LogSizeMB | LogMaxSizeMB | LogFileCanGrow | LogFileFreeSpaceMB | LogFileUsedPercent | TotalLogMaxSizeMB | TotalLogFileFreeMB | TotalLogFileUsedPercent |
|---------------------|-------------------------|-------------------------------------------|------|-----------------|-----------|--------------|----------------|--------------------|--------------------|-------------------|--------------------|-------------------------|
| master              | mastlog                 | F:\SQLLOGS\mastlog.ldf                    | F:\  | 1000000         | 1000      | 2097152      | 1              | 928                | 7                  | 2097152           | 2097152            | 0                       |
| tempdb              | templog                 | F:\SQLLOGS\templog.ldf                    | F:\  | 1000000         | 100000    | 400000       | 1              | 99999              | 0                  | 400000            | 300001             | 75                      |
| model               | modellog                | F:\SQLLOGS\modellog.ldf                   | F:\  | 1000000         | 8         | 2097152      | 1              | 7                  | 1                  | 2097152           | 2097151            | 0                       |
| msdb                | MSDBLog                 | F:\SQLLOGS\MSDBLog.ldf                    | F:\  | 1000000         | 300       | 2097152      | 1              | 290                | 3                  | 2097152           | 2097152            | 0                       |
| SQLServerMonitoring | SQLServerMonitoring_log | F:\SQLLOGS\SQLServerMonitoringLog.ldf     | F:\  | 1000000         | 1000      | 2097152      | 1              | 999                | 0                  | 2097152           | 2097151            | 0                       |
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
	[LogFileFreeSpaceMB] numeric(15,0),
	[LogFileUsedPercent] numeric(15,0)
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
	dt.[Database],
	dt.[LogFileName],
	dt.[LogFilePath],
	dt.[Disk],
	dt.[DiskFreeSpaceMB],
	dt.[LogSizeMB],
	dt.[LogMaxSizeMB],
	dt.[LogFileCanGrow],
	dt.[LogFileFreeSpaceMB],
	CASE 
		WHEN LogSizeMB / CAST(100.0 AS DECIMAL(25,2)) = 0
		THEN 0
		ELSE 100 - (LogFileFreeSpaceMB / (LogSizeMB / CAST(100.0 AS DECIMAL(25,2))))
	END AS LogFileUsedPercent
FROM (
		SELECT
			DB_NAME(f.database_id) AS [Database],
			f.[name] AS [LogFileName],
			f.physical_name AS [LogFilePath],
			volume_mount_point AS [Disk],
			available_bytes/1048576 as [DiskFreeSpaceMB],
			CAST(f.size AS bigint) * 8 / 1024 AS [LogSizeMB],
			CAST(CASE WHEN f.max_size <= 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024 AS [LogMaxSizeMB],
			CASE 
				WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
				THEN 0
				ELSE 1
			END AS [LogFileCanGrow],
			size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [LogFileFreeSpaceMB]
		FROM sys.master_files AS f CROSS APPLY 
		  sys.dm_os_volume_stats(f.database_id, f.file_id)
		WHERE [type_desc] = ''LOG''
			and f.database_id = DB_ID()
	) dt
';

	EXECUTE(@SqlStatement);
	
END
CLOSE DatabaseList;
DEALLOCATE DatabaseList;

SELECT
	-- Имя базы данных
	lf.[DatabaseName],
	-- Имя файла лога транзакций
	lf.[LogFileName],
	-- Путь к файлу лога транзакций
	lf.[LogFilePath],
	-- Имя диска, где находится файл лога
	lf.[Disk],
	-- Свободное место на диске с файлом лога
	lf.[DiskFreeSpaceMB],
	-- Размер файла лога транзакций
	lf.[LogSizeMB],
	-- Максимально возможный размер файла лога транзакций (с учетом ограничений настроек роста файла лога)
	lf.[LogMaxSizeMB],
	-- Файл лога транзакций может расти (с учетом ограничений настроек роста файла лога)
	lf.[LogFIleCanGrow],
	-- Свободное место в файле лога транзакций
	lf.[LogFileFreeSpaceMB],
	-- Процент использования файла лога транзакций
	lf.[LogFileUsedPercent],
	-- Максимальный размер лога транзакций для базы данных с учетом всех файлов логов и их настроек (общий для базы) 
	totals.[TotalLogMaxSizeMB],
	-- Свободно пространства для лога транзакций для базы данных с учетом всех файлов логов и их настроек (общий для базы)
	totals.[TotalLogFileFreeMB],
	-- Процент использования лога транзакций у четом общего макс. размера для базы данных с учетом всех файлов логов и их настроек (общий для базы)
	CASE
		WHEN ([TotalLogMaxSizeMB] / 100) = 0
		THEN 0
		ELSE 100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)
	END AS [TotalLogFileUsedPercent]
FROM #logFileInfoByDatabases lf
	LEFT JOIN (
		SELECT
			DatabaseName,
			SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
			SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
		FROM #logFileInfoByDatabases
		GROUP BY DatabaseName
	) totals ON lf.DatabaseName = totals.DatabaseName

IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
	DROP TABLE #logFileInfoByDatabases;
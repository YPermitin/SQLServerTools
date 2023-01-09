# Исправление системного кэша объектов для реплик AlwaysOn

При работе с асинхронными репликами AlwaysOn в режиме "только для чтения" может возникнуть ошибка вида:

```text
Не удалось найти статистику "_WA_Sys_00000007_7C1B37B1" в системных каталогах.DB-Lib error message 20018, severity 16:
General SQL Server error: Check messages from the SQL Server

или

Could not locate statistics "_WA_Sys_00000007_7C1B37B1" in the system catalogs. DB-Lib error message 20018, severity 16:
General SQL Server error: Check messages from the SQL Server


Примечание: _WA_Sys_00000007_7C1B37B1 - имя автоматически сгенерированного объекта статисти, которое может отличаться при появлении ошибки.
```

Причина проблемы - это активные транзакции, которые не позволяют применить записи журнала и обновить недействительный кэш объектов статистики на вторичной реплике. [Подробная информация есть в официальной документации](https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/availability-groups/error-2767-query-secondary-replica-fails).

## Решение проблемы

Есть несколько способов решени проблемы. Но перед этим обязательно убедитесь, что "битые" статистики действительно присутствуют.

```sql
SELECT 
	-- Идентификатор объекта
	s.object_id, 
	-- Идентификатор статистики
	s.stats_id, 
	-- Имя статистики
	s.[name] AS [StatisticName],
	-- Имя таблицы
	o.[name] AS [TableName],
	-- Дата создания таблицы
	o.create_date AS [TableCreated],
	-- Дата изменения таблицы
	o.modify_date AS [TableModified]
FROM sys.stats AS s
	JOIN sys.objects AS o
	ON s.object_id = o.object_id
WHERE s.auto_created = 1
	AND o.is_ms_shipped = 0
	AND NOT EXISTS(select *	from [sys].[dm_db_stats_properties] (s.object_id, s.stats_id))
```

Запрос необходимо выполнять в контексте базы данных, для которой понадобилась проверка.

### Очищаем кэш

Самый простой способ - это запустить очистку кэша.

```sql
DBCC FREESYSTEMCACHE('ALL')
GO
```

После чего кэш в том числе объектов статистики будет обновлен.

### Автоматизируем очистку кэша

Для автоматизации процесса можно выполнять очистку кэша для всех реплик AlwaysOn с асинхронной передачей данных, но с некоторой периодичностью. При этом обязательно нужно проверять наличие "битых" объектов статистики, чтобы не очищать кэш "на всякий случай" и минимизировать влияние на работу баз даных.

Для этих целей пригодиться скрипт ниже.

```sql
-- Фильтр по имени базы данных
-- Если установлено NULL, то проверяться будут все базы
DECLARE @databaseName sysname = null;

DECLARE @currentDatabaseName sysname;
DECLARE databases_cursor CURSOR  
	FOR SELECT
	[name]
FROM sys.databases
WHERE (@databaseName is null or [name] = @databaseName)
	AND [name] in (
			select distinct
		database_name
	from sys.dm_hadr_database_replica_cluster_states dhdrcs
		inner join sys.availability_replicas ar
		on dhdrcs.replica_id = ar.replica_id
	where availability_mode_desc = 'ASYNCHRONOUS_COMMIT'
		)
OPEN databases_cursor;
FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;

WHILE @@FETCH_STATUS = 0  
	BEGIN
	PRINT @currentDatabaseName;

	DECLARE @sql nvarchar(max);
	SET @sql = CAST('
		USE [' AS nvarchar(max)) + CAST(@currentDatabaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;

		DECLARE
			@objid int,
			@statsid INT,
			@NeedResetCache bit = 0,
			@dbname sysname = DB_NAME();
		DECLARE cur CURSOR FOR
 
		SELECT s.object_id, s.stats_id
		FROM sys.stats AS s
			JOIN sys.objects AS o
			ON s.object_id = o.object_id
		WHERE s.auto_created = 1
			AND o.is_ms_shipped = 0
		OPEN cur
		FETCH NEXT FROM cur INTO @objid, @statsid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if not exists (select *
			from [sys].[dm_db_stats_properties] (@objid, @statsid))
		BEGIN
 
				PRINT (convert(varchar(10), @objid) + ''|'' + convert(varchar(10), @statsid))
 
				IF(@useMonitoringDatabase = 1)
				BEGIN
					INSERT [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[AlwaysOnReplicaMissingStats]
					SELECT @dbname, o.[name], s.[name], GETDATE()
					FROM sys.stats AS s JOIN sys.objects AS o
						ON s.object_id = o.object_id
					WHERE o.object_id = @objid AND s.stats_id = @statsid
				END
				
				SET @NeedResetCache = 1
 
			END
			FETCH NEXT FROM cur INTO @objid, @statsid
		END
		CLOSE cur
		DEALLOCATE cur
 
		IF @NeedResetCache = 1
		BEGIN
			PRINT ''Был сброшен системный кэш для базы данных''
			PRINT @dbname
			DBCC FREESYSTEMCACHE(@dbname);
		END
		' AS nvarchar(max))

	EXECUTE sp_executesql
			@sql,
			N'@useMonitoringDatabase bit, @monitoringDatabaseName sysname',
			@useMonitoringDatabase, @monitoringDatabaseName

	FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;
END
CLOSE databases_cursor;
DEALLOCATE databases_cursor;
```

Таким образом, проблема с "битыми" статистиками может быть решена в абсолютном большинстве случаев.

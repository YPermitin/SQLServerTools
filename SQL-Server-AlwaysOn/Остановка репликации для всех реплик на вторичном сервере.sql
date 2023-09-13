/*
Остановка репликации для всех баз реплик на сервере в случаях:
    * Статус "Синхронизируется" или "Синхронизировано"
    * У реплики имеются ранее принятые транзакции. Необходимо проверять, т.к. у реплик
        в распределенных групп доступности статус "Синхронизировано" как у первичных баз.
Используется на вторичном сервере с репликами.
*/

DECLARE @databaseName sysname,
		@sql nvarchar(max);

DECLARE replicas_cursor CURSOR FOR 
SELECT 
    adc.database_name
FROM sys.dm_hadr_database_replica_states AS dhdrs
INNER JOIN sys.availability_databases_cluster AS adc 
    ON dhdrs.group_id = adc.group_id AND 
    dhdrs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
    ON ag.group_id = dhdrs.group_id
INNER JOIN sys.availability_replicas AS ar 
    ON dhdrs.group_id = ar.group_id AND 
    dhdrs.replica_id = ar.replica_id
WHERE 1 = 1
	AND dhdrs.synchronization_state_desc IN (
		'SYNCHRONIZING', -- Состояние "Синхронизируется", для обычных групп доступности
		'SYNCHRONIZED' -- Состояние "Синхронизировано", для распределенных групп доступности
	)
	-- У реплик должно быть заполнено поле last_received_lsn
	AND dhdrs.last_received_lsn is not null;
OPEN replicas_cursor;

FETCH NEXT FROM replicas_cursor INTO @databaseName;

WHILE @@FETCH_STATUS = 0  
BEGIN
	PRINT @databaseName;

	SET @sql = '
USE [master];
ALTER DATABASE [' + @databaseName + '] SET HADR SUSPEND;'

	EXEC sp_executesql @sql

	FETCH NEXT FROM replicas_cursor INTO @databaseName;
END
CLOSE replicas_cursor;  
DEALLOCATE replicas_cursor;
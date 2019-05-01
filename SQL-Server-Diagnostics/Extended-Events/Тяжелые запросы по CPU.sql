-- Анализ тяжелых запросов по CPU

CREATE EVENT SESSION [HeavyQueryByCPU] ON SERVER
-- Класс событий RPC:Completed указывает, что удаленный вызов процедуры завершен.
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/event-classes/rpc-completed-event-class?view=sql-server-2017
ADD EVENT sqlserver.rpc_completed(
    ACTION(
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.client_pid,
        sqlserver.database_id,
        sqlserver.nt_username,
        sqlserver.server_principal_name,
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.transaction_id,
        sqlserver.username)
    WHERE ([duration]>(5000000))),
-- Класс событий SQL:BatchCompleted указывает на завершение выполнения пакета языка Transact-SQL.
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/event-classes/sql-batchcompleted-event-class?view=sql-server-2017
ADD EVENT sqlserver.sql_batch_completed(
    ACTION (
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.client_pid,
        sqlserver.database_id,
        sqlserver.nt_username,
        sqlserver.server_principal_name,
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.transaction_id,
        sqlserver.username)
    WHERE ([duration]>(5000000)))
ADD TARGET package0.event_file(SET 
    -- Путь к файлу хранения логов. Если не указан, то используется путь к каталогу логов SQL Server
    filename=N'HeavyQueryByCPU.xel',
    -- Максимальный размер файла в мегабайтах
    max_file_size=(1024),
    -- Максимальное количество файлов, после чего начнется перезапись логов в более старых файлах.
    max_rollover_files=(5)                                                        
    metadatafile=N'HeavyQueryByCPU.xem')
WITH (
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=15 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF)



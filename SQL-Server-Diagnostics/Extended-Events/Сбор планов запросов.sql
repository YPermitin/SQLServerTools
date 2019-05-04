-- Внимание!!! Это только пример настройки.
-- Включение данной сессии может снизить производительность сервера.
-- Используйте с осторожность и пониманием что делайте.

CREATE EVENT SESSION QueryPlanAnalyze
ON SERVER
ADD EVENT sqlserver.query_pre_execution_showplan(
    ACTION (sqlserver.database_name,sqlserver.client_hostname,sqlserver.client_app_name,
            sqlserver.plan_handle,
            sqlserver.sql_text,
            sqlserver.tsql_stack,
            package0.callstack,
			sqlserver.query_hash,
			sqlserver.session_id,
            sqlserver.request_id)),
ADD EVENT sqlserver.query_post_execution_showplan(
    ACTION (sqlserver.database_name,sqlserver.client_hostname,sqlserver.client_app_name,
            sqlserver.plan_handle,
            sqlserver.sql_text,
            sqlserver.tsql_stack,
            package0.callstack,
			sqlserver.query_hash,
			sqlserver.session_id,
            sqlserver.request_id))
ADD TARGET package0.event_file(SET 
    -- Путь к файлу хранения логов. Если не указан, то используется путь к каталогу логов SQL Server
    filename=N'QueryPlanAnalyze.xel',
    -- Максимальный размер файла в мегабайтах
    max_file_size=(1024),
    -- Максимальное количество файлов, после чего начнется перезапись логов в более старых файлах.
    max_rollover_files=(5),
    metadatafile=N'QueryPlanAnalyze.xem')
WITH (
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=15 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF
)
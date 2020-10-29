-- Анализ событий входа и выхода учетных записей

CREATE EVENT SESSION [LoginAndLogoff] ON SERVER 
-- Класс событий Audit Login сообщает об успешном входе пользователя в Microsoft SQL Server. 
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/event-classes/audit-login-event-class?view=sql-server-2017
ADD EVENT sqlserver.login(
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
),
-- Класс событий Audit Logout показывает, что пользователь выполнил выход из (отсоединился от) Microsoft SQL Server.
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/event-classes/audit-logout-event-class?view=sql-server-2017
ADD EVENT sqlserver.logout(
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
)
ADD TARGET package0.event_file(SET 
    filename=N'LoginAndLogoff.xel',
    max_file_size=(10),
    max_rollover_files=(5))
WITH (
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=15 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF)
GO



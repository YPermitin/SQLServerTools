-- Списки удерживаемых и запрошенных блокировок.
-- https://docs.microsoft.com/ru-ru/openspecs/sql_server_protocols/ms-ssas/566ef60a-3491-4a21-9b01-caad1365fdf3

SELECT
    SPID AS [ID сессии],
    LOCK_ID AS [Идентификатор блокировки],
    LOCK_TRANSACTION_ID AS [Идентификатор транзакции],
    LOCK_OBJECT_ID AS [Идентификатор блокируемого объекта],
    -- 0 - блокировка установлена
    -- 1 - ожидание установки блокировки
    LOCK_STATUS AS [Статус блокировки],
    /*
    LOCK_NONE (0x0000000) - No lock.
    LOCK_SESSION_LOCK (0x0000001) - Inactive session; does not interfere with other locks.
    LOCK_READ (0x0000002) - Read lock during processing.
    LOCK_WRITE (0x0000004) - Write lock during processing.
    LOCK_COMMIT_READ (0x0000008) - Commit lock, shared.
    LOCK_COMMIT_WRITE (0x0000010) - Commit lock, exclusive.
    LOCK_COMMIT_ABORTABLE (0x0000020) - Abort at commit progress.
    LOCK_COMMIT_INPROGRESS (0x0000040) - Commit in progress.
    LOCK_INVALID (0x0000080) Invalid lock.
    */
    LOCK_TYPE AS [Тип блокировки],
    LOCK_CREATION_TIME AS [Дата создания блокировки],
    LOCK_GRANT_TIME AS [Дата установки блокировки]
FROM $system.discover_locks
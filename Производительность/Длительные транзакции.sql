DECLARE @curr_date as DATETIME
SET @curr_date = GETDATE()
select --SESSION_TRAN.*,
    SESSION_TRAN.session_id AS connectID, -- "Соединение с СУБД"
    --TRAN_INFO.*,
    TRAN_INFO.transaction_begin_time,
    DateDiff(MINUTE, TRAN_INFO.transaction_begin_time, @curr_date) AS Duration, -- Длительность в минутах
    TRAN_INFO.transaction_type, -- 1 = транзакция чтения-записи; 2 = транзакция только для чтения; 3 = системная транзакция; 4 = распределенная транзакция.
    TRAN_INFO.transaction_state,
    -- 0 = Транзакция еще не была полностью инициализирована;
    -- 1 = Транзакция была инициализирована, но еще не началась;
    -- 2 = Транзакция активна;
    -- 3 = Транзакция закончилась. Используется для транзакций «только для чтения»;
    -- 4 = Фиксирующий процесс был инициализирован на распределенной транзакции. Предназначено только для распределенных транзакций. Распределенная транзакция все еще активна, но дальнейшая обработка не может иметь место;
    -- 5 = Транзакция находится в готовом состоянии и ожидает разрешения;
    -- 6 = Транзакция зафиксирована;
    -- 7 = Производится откат транзакции;
    -- 8 = откат транзакции был выполнен.
    --CONN_INFO.*,
    CONN_INFO.connect_time,
    CONN_INFO.num_reads,
    CONN_INFO.num_writes,
    CONN_INFO.last_read,
    CONN_INFO.last_write,
    CONN_INFO.client_net_address,
    CONN_INFO.most_recent_sql_handle,
    --SQL_TEXT.*,
    SQL_TEXT.dbid,
    db_name(SQL_TEXT.dbid) AS IB_NAME,
    SQL_TEXT.text,
    --QUERIES_INFO.*,
    QUERIES_INFO.start_time,
    QUERIES_INFO.status,
    QUERIES_INFO.command,
    QUERIES_INFO.wait_type,
    QUERIES_INFO.wait_time,
    PLAN_INFO.query_plan
FROM sys.dm_tran_session_transactions AS SESSION_TRAN
    JOIN sys.dm_tran_active_transactions AS TRAN_INFO
    ON SESSION_TRAN.transaction_id = TRAN_INFO.transaction_id
    LEFT JOIN sys.dm_exec_connections AS CONN_INFO
    ON SESSION_TRAN.session_id = CONN_INFO.session_id
CROSS APPLY sys.dm_exec_sql_text(CONN_INFO.most_recent_sql_handle) AS SQL_TEXT
    LEFT JOIN sys.dm_exec_requests AS QUERIES_INFO
    ON SESSION_TRAN.session_id = QUERIES_INFO.session_id
    LEFT JOIN (
SELECT VL_SESSION_TRAN.session_id AS session_id,
        VL_PLAN_INFO.query_plan AS query_plan
    FROM sys.dm_tran_session_transactions AS VL_SESSION_TRAN
        INNER JOIN sys.dm_exec_requests AS VL_QUERIES_INFO
        ON VL_SESSION_TRAN.session_id = VL_QUERIES_INFO.session_id
CROSS APPLY sys.dm_exec_text_query_plan(VL_QUERIES_INFO.plan_handle, VL_QUERIES_INFO.statement_start_offset, VL_QUERIES_INFO.statement_end_offset) AS VL_PLAN_INFO) AS PLAN_INFO
    ON SESSION_TRAN.session_id = PLAN_INFO.session_id
ORDER BY transaction_begin_time ASC
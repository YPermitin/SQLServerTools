/*
Краткий отчет по использованию TembDB соединениями СУБД.

Оригинальный запрос: https://www.sqlservercentral.com/scripts/tempdb-usage-per-active-session
*/

WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT -- Сессия СУБД
       TSU.session_id,
       -- Количество страниц памяти, зарезервированных или выделенных для внутренних объектов в данной задаче.
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       -- Количество страниц памяти, освобожденных и более не резервируемых для внутренних объектов в данной задаче.
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       -- Текст запроса
       EST.text,
       -- Конкретное выражение из запроса
       ISNULL(
           NULLIF(
               SUBSTRING(
                   EST.text, 
                   ERQ.statement_start_offset / 2, 
                   CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset THEN 0 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC, 5 DESC
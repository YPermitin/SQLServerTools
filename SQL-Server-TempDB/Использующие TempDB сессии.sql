SELECT
    st.dbid AS QueryExecutionContextDBID,
    DB_NAME(st.dbid) AS QueryExecContextDBNAME,
    st.objectid AS ModuleObjectId,
    SUBSTRING(st.TEXT,
        dmv_er.statement_start_offset/2 + 1,
        (CASE WHEN dmv_er.statement_end_offset = -1
        THEN LEN(CONVERT(NVARCHAR(MAX),st.TEXT)) * 2
        ELSE dmv_er.statement_end_offset
        END - dmv_er.statement_start_offset)/2) AS Query_Text,
    dmv_tsu.session_id ,
    dmv_tsu.request_id,
    dmv_tsu.exec_context_id,
    (dmv_tsu.user_objects_alloc_page_count - dmv_tsu.user_objects_dealloc_page_count) AS OutStanding_user_objects_page_counts,
    (dmv_tsu.internal_objects_alloc_page_count - dmv_tsu.internal_objects_dealloc_page_count) AS OutStanding_internal_objects_page_counts,
    dmv_er.start_time,
    dmv_er.command,
    dmv_er.open_transaction_count,
    dmv_er.percent_complete,
    dmv_er.estimated_completion_time,
    dmv_er.cpu_time,
    dmv_er.total_elapsed_time,
    dmv_er.reads, dmv_er.writes,
    dmv_er.logical_reads,
    dmv_er.granted_query_memory,
    dmv_es.HOST_NAME,
    dmv_es.login_name,
    dmv_es.program_name
FROM sys.dm_db_task_space_usage dmv_tsu
    INNER JOIN sys.dm_exec_requests dmv_er
    ON (dmv_tsu.session_id = dmv_er.session_id AND dmv_tsu.request_id = dmv_er.request_id)
    INNER JOIN sys.dm_exec_sessions dmv_es
    ON (dmv_tsu.session_id = dmv_es.session_id)
CROSS APPLY sys.dm_exec_sql_text(dmv_er.sql_handle) st
WHERE (dmv_tsu.internal_objects_alloc_page_count + dmv_tsu.user_objects_alloc_page_count) > 0
ORDER BY (dmv_tsu.user_objects_alloc_page_count - dmv_tsu.user_objects_dealloc_page_count) + (dmv_tsu.internal_objects_alloc_page_count - dmv_tsu.internal_objects_dealloc_page_count) DESC
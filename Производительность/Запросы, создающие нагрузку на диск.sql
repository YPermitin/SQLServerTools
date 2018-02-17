set transaction isolation level read uncommitted

IF OBJECT_ID('tempdb..#T1') IS NOT NULL
	DROP TABLE #T1;
IF OBJECT_ID('tempdb..#T2') IS NOT NULL
    DROP TABLE #T2;

SELECT
    SUM(qs.total_physical_reads) as physical_reads,
    SUM(qs.total_logical_reads) as logical_reads
into #T1
FROM (
select top 100000
        *
    from
        sys.dm_exec_query_stats qs
    where qs.last_execution_time > (CURRENT_TIMESTAMP - '01:00:00.000')
    order by qs.total_physical_reads desc
) as qs;
select top 100
    (qs.total_physical_reads) as physical_reads,
    (qs.total_logical_reads) as logical_reads,
    qp.query_plan,
    st.text,
    dtb.name,
    qs.*,
    st.dbid
INTO #T2
FROM
    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    left outer join sys.databases as dtb on st.dbid = dtb.database_id
where qs.last_execution_time > (CURRENT_TIMESTAMP - '01:00:00.000')
order by qs.total_physical_reads desc;
select
    (T2.physical_reads*100/T1.physical_reads) as percent_physical_reads,
    (T2.logical_reads*100/T1.logical_reads) as percent_logical_reads,
    T2.*
from
    #T2 as T2
    INNER JOIN #T1 as T1
    ON 1=1
order by T2.total_physical_reads desc
;

IF OBJECT_ID('tempdb..#T1') IS NOT NULL
	DROP TABLE #T1;
IF OBJECT_ID('tempdb..#T2') IS NOT NULL
    DROP TABLE #T2;
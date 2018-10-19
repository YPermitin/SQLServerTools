SELECT
   s.login_name as [Login],
   s.host_name as [Hostname],
   t.text as [QueryText],
   wt.wait_type as [WaitType],
   wt.wait_duration_ms as [WaitDurationMs],
   wt.resource_description as [ResourceTypeWaiting],
   s.session_id as [Session],
   wt.blocking_session_id as [BlockingSession],
   bs.login_name as 'LoginOfBlocker',
   bt.text as [BlockerQuery],
   cast(p.query_plan as xml) as [QueryPlan]

FROM sys.dm_exec_requests r
     inner join sys.dm_exec_sessions s on s.session_id = r.session_id
	 left join  sys.dm_os_waiting_tasks wt on wt.session_id = r.session_id
	 left join  sys.dm_exec_sessions bs on bs.session_id = wt.blocking_session_id
	 left join  sys.dm_exec_requests br on br.session_id = bs.session_id
	 cross apply sys.dm_exec_sql_text (r.sql_handle) t
	 cross apply sys.dm_exec_text_query_plan (r.plan_handle, r.statement_start_offset, r.statement_end_offset) as p
	 outer apply sys.dm_exec_sql_text (br.sql_handle) bt
WHERE
    r.session_id>50
	AND r.status in ('running', 'suspended')
SELECT 
	sqltext.TEXT AS [Текст запроса],
	req.session_id AS [Сессия],
	req.status AS [Состояние],
	req.command AS [Тип команды],
	req.cpu_time AS [CPU],
	req.total_elapsed_time AS [Время выполнения],
	qerPlan.query_plan AS [План запроса]
FROM sys.dm_exec_requests req
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
	CROSS APPLY sys.dm_exec_query_plan(req.plan_handle) qerPlan

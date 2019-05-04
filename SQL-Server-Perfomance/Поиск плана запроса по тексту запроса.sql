SELECT
	T.[text]
	,T.[creation_time]
	,T.[execution_count]
	,T.[last_execution_time]
	,qp.query_plan
FROM
(SELECT
     st.[text]	 
	 ,qs.plan_handle
	 ,MAX(qs.creation_time) AS [creation_time]
	 ,MAX(qs.last_execution_time) AS [last_execution_time]
	 ,SUM(qs.execution_count) AS [execution_count]
FROM
	sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
	
WHERE 
    -- Фильтр по дате последнего выполнения для оптимизации
    -- По умолчанию фильтруются запросы за последний час
    qs.last_execution_time > (CURRENT_TIMESTAMP - '01:00:00.000')
	-- Поиск по частям текста запроса
	AND st.[text] LIKE '%SELECT%'
	AND st.[text] LIKE '%TOP 45%'
	AND st.[text] LIKE '%_InfoRg123456%'
GROUP BY
     st.[text]
	 ,qs.plan_handle) T
	CROSS APPLY sys.dm_exec_query_plan(T.plan_handle) qp
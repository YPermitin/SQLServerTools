ALTER VIEW [dbo].[v_CommonStatsByDay]
AS
SELECT 
	CAST([RunDate] AS DATE) AS "День",
      COUNT(DISTINCT [TableName]) AS "Кол-во таблиц, для объектов которых выполнено обслуживание",
      COUNT(DISTINCT [IndexName]) AS "Количество индексов, для объектов которых выполнено обслуживание",
      SUM(CASE 
		WHEN [Operation] LIKE '%STAT%'
		THEN 1
		ELSE 0
	  END) AS "Обновлено статистик",
	  SUM(CASE 
		WHEN [Operation] LIKE '%INDEX%'
		THEN 1
		ELSE 0
	  END) AS "Обслужено индексов"      
  FROM [dbo].[MaintenanceActionsLog]
  GROUP BY CAST([RunDate] AS DATE)
ALTER PROCEDURE [dbo].[sp_ControlJobsExecutionTimeout]
AS
BEGIN
	SET NOCOUNT ON;

	-- Очистка устаревших настроек контроля соединений
	EXEC [dbo].[sp_ClearOldSessionControlSettings];

	DECLARE @msg nvarchar(max), @sql nvarchar(max);
	DECLARE @startDate datetime = GetDate(),
			@finishDate datetime = GetDate(),
			@timeNow time = CAST(GetDate() AS TIME),
			@runDate datetime = GetDate(),
			@MaintenanceActionLogId bigint;

	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	)
	INSERT INTO @AllConnections EXEC sp_who2

	DECLARE
		@executionTimeSec int,
		@timeoutSec int,
		@SPID int,
		@programName nvarchar(max),
		@DBName VARCHAR(MAX),
		@WorkFrom time,
		@WorkTo time,
		@WorkTimeoutSec int,
		@CurrentWorkTimeoutSec int;

	-- Проверка таймаута работы заданий
	DECLARE timeout_jobs_cursor CURSOR FOR 
	SELECT 
		DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) AS 'ExecutionDurationSec',
		jtime.TimeoutSec,
		SPID,
		ProgramName,
		DBName
	FROM @AllConnections c
		INNER JOIN [msdb].[dbo].[sysjobs] sj
			ON UPPER(c.ProgramName) LIKE '%Job 0x' + UPPER(CONVERT(VARCHAR(max), CAST(job_id AS varbinary(max)), 2)) + '%'
		INNER JOIN [msdb].[dbo].[sysjobactivity] AS sja
			ON sja.job_id = sj.job_id
		INNER JOIN [dbo].[JobTimeouts] jtime
			ON jtime.JobName = sj.[name]
		INNER JOIN (
			SELECT
				[job_id],
				MAX([session_id]) AS [session_id]
			FROM [msdb].[dbo].[sysjobactivity]
			GROUP BY [job_id]) ls
			ON ls.job_id = sja.job_id
				AND ls.session_id = sja.session_id
	WHERE jtime.TimeoutSec > 0
		AND DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) > jtime.TimeoutSec;
	OPEN timeout_jobs_cursor;
	FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName, @DBName;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @msg = 'Задание ''' + @programName + ''' завершено по таймауту. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Время работы: ' + CAST(@executionTimeSec  AS nvarchar(max))+ '. Таймаут: ' + CAST(@timeoutSec AS nvarchar(max)) + '.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			PRINT @msg
		END CATCH

		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'JOB EXECUTION TIME CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@DBName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName, @DBName;
	END
	CLOSE timeout_jobs_cursor;  
	DEALLOCATE timeout_jobs_cursor;



	-- Проверка времени работы соединений
	DECLARE timeout_session_cursor CURSOR FOR
	SELECT [AC].[SPID], [WorkFrom], [WorkTo], [SCS].[DatabaseName],
		ISNULL([SCS].[WorkTimeoutSec],0) AS [WorkTimeoutSec],
		queryExecution.[QueryActiveTimeSec] AS [CurrentWorkTimeoutSec]
	FROM @AllConnections AS [AC]
		FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
		ON [AC].[SPID] = [SCS].[SPID]
			AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
			AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
			AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		LEFT JOIN (
			SELECT 
				req.session_id AS [SessionId],
				req.total_elapsed_time / 1000 AS [QueryActiveTimeSec]
			FROM sys.dm_exec_requests req
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
		) queryExecution
		ON [AC].[SPID] = queryExecution.SessionId
	WHERE -- Есть подходящие настройки ограничений для соединения
		[SCS].[SPID] IS NOT NULL	
		-- Исключаем статусы соединений
		AND NOT UPPER([Status]) IN (
			'BACKGROUND' -- Фоновые процессы
			,'SLEEPING' -- Ожидающие команды, не активные
		)
		-- Проверка превышения таймаута времени выполнения в разрешенном диапазоне времени
		AND CASE
				WHEN ISNULL([SCS].[WorkTimeoutSec],0) <= 0
				THEN 1
				WHEN ISNULL([SCS].[WorkTimeoutSec],0) <= queryExecution.[QueryActiveTimeSec]
				THEN 1
				ELSE 0
			END > 0
		AND (
			-- Проверка времени запуска
			CASE
				-- Ограничения не заданы
				WHEN [WorkFrom] IS NULL OR [WorkTo] IS NULL
				THEN 0
				-- Время окончания больше времени начала. Текущее время выходит за рамки диапазона.
				WHEN [WorkTo] >= [WorkFrom]
				THEN 
					CASE
						WHEN NOT ([WorkFrom] <= @timeNow AND [WorkTo] >= @timeNow)
						THEN 1
						ELSE 0
					END
				-- Время окончания меньше времени начала. 
				-- Текущее время выходит за рамки диапазона.
				WHEN [WorkTo] >= [WorkFrom]
				THEN 
					CASE
						WHEN NOT (([WorkFrom] <= @timeNow AND '23:59:59' >= @timeNow)
								OR ([WorkTo] >= @timeNow AND '00:00:00' <= @timeNow))
						THEN 1
						ELSE 0
					END
				ELSE 0
			END >= 1
		)
	OPEN timeout_session_cursor;
	FETCH NEXT FROM timeout_session_cursor INTO @SPID, @WorkFrom, @WorkTo, @DBName, @WorkTimeoutSec, @CurrentWorkTimeoutSec;
	WHILE @@FETCH_STATUS = 0  
	BEGIN		
		SET @msg = 'Завершено, т.к. время выполнения выходит за допущенный диапазон времени. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Текущее время: ' + CAST(@timeNow  AS nvarchar(max))+ '. Разрешенный диапазон времени: ' + CAST(@WorkFrom AS nvarchar(max)) + ' - ' + CAST(@WorkTo AS nvarchar(max)) + '. Таймаут выполнения текущий ' + CAST(@CurrentWorkTimeoutSec AS nvarchar(max)) + ' сек., максимальный ' + CAST(@WorkTimeoutSec AS nvarchar(max)) + ' сек.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			SET @msg = 'Не удалось завершить соединение. ' +  @msg
			PRINT @msg
		END CATCH
		
		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'JOB EXECUTION TIME CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@DBName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		EXEC [dbo].[sp_RemoveSessionControlSetting]
			@spid = @SPID;

		FETCH NEXT FROM timeout_session_cursor INTO @SPID, @WorkFrom, @WorkTo, @DBName, @WorkTimeoutSec, @CurrentWorkTimeoutSec;
	END
	CLOSE timeout_session_cursor;  
	DEALLOCATE timeout_session_cursor;
END

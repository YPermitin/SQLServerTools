declare @job_name sysname = '<Имя задания>'
declare @job_id uniqueidentifier = (select top 1 job_id from msdb..sysjobs where name = @job_name);
declare @job_owner sysname = (SELECT SUSER_SNAME());
declare @xp_results TABLE (
    job_id                UNIQUEIDENTIFIER NOT NULL,
    last_run_date         INT              NOT NULL,
    last_run_time         INT              NOT NULL,
    next_run_date         INT              NOT NULL,
    next_run_time         INT              NOT NULL,
    next_run_schedule_id  INT              NOT NULL,
    requested_to_run      INT              NOT NULL, -- BOOL
    request_source        INT              NOT NULL,
    request_source_id     sysname          COLLATE database_default NULL,
    running               INT              NOT NULL, -- BOOL
    current_step          INT              NOT NULL,
    current_retry_attempt INT              NOT NULL,
    job_state             INT              NOT NULL);

INSERT INTO @xp_results
    EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id

SELECT 
    -- Имя задания
	sj.name,
    -- Активность (1 - активное, 0 не активное)
	CASE WHEN xpr.job_state <> 4 THEN 1 ELSE 0 END AS [Active],
    -- Текущее время работы задания (0 - значит не запущено в данный момент)
	CASE 
		WHEN xpr.job_state = 4
		THEN 0
		ELSE datediff(second, msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time]), getdate()) 
	END AS [CurrentRunTimeSec],
    -- Дата последнего запуска
	msdb.dbo.agent_datetime(xpr.[last_run_date], xpr.[last_run_time]) AS [LastRunDateTime],
    -- Времени прошло с последнего запуска (за вычетом времени текущей работы задания)
	datediff(second, msdb.dbo.agent_datetime(xpr.[last_run_date], xpr.[last_run_time]),getdate()) 
		- (
		CASE 
			WHEN xpr.job_state = 4
			THEN 0
			ELSE datediff(second, msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time]), getdate()) 
		END
		)
	AS [LastRunTimeLeftSec],
    -- Дата следующего запуска
	msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time]) AS [NextRunDateTime],
    -- Времени до следующего запуска
	CASE 
		WHEN datediff(second, getdate(), msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time])) > 0
		THEN datediff(second, getdate(), msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time]))
		ELSE 0
	END AS [NextRunTimeToStartSec],	
    -- Обычное время между запусками задания
	datediff(second, msdb.dbo.agent_datetime(xpr.[last_run_date], xpr.[last_run_time]), msdb.dbo.agent_datetime(xpr.[next_run_date], xpr.[next_run_time])) AS [DelayBetweenRunSec]
FROM @xp_results                          xpr
inner join msdb..sysjobs sj on xpr.job_id = sj.job_id
LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON ((xpr.job_id = sjs.job_id) AND (xpr.current_step = sjs.step_id)),
    msdb.dbo.sysjobs_view                sjv
WHERE (sjv.job_id = xpr.job_id)
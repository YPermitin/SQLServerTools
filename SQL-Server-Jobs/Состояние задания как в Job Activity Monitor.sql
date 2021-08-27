declare @job_name sysname = '<Имя задания>';
declare @job_id uniqueidentifier = (select top 1
    job_id
from msdb..sysjobs
where name = @job_name);
declare @job_owner sysname = (SELECT SUSER_SNAME());
declare @xp_results TABLE (
    job_id UNIQUEIDENTIFIER NOT NULL,
    last_run_date INT NOT NULL,
    last_run_time INT NOT NULL,
    next_run_date INT NOT NULL,
    next_run_time INT NOT NULL,
    next_run_schedule_id INT NOT NULL,
    requested_to_run INT NOT NULL,
    -- BOOL
    request_source INT NOT NULL,
    request_source_id sysname COLLATE database_default NULL,
    running INT NOT NULL,
    -- BOOL
    current_step INT NOT NULL,
    current_retry_attempt INT NOT NULL,
    job_state INT NOT NULL);

INSERT INTO @xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id

SELECT sj.name,
    case xpr.job_state when 1 then 'Executing: ' + cast(sjs.step_id as nvarchar(2)) + ' (' + sjs.step_name + ')'
        when 2  then 'Waiting for thread'
        when 3 then 'Between retries'
        when 4  then 'Idle'
        when 5  then 'Suspended'
        when 7  then 'Performing completion actions'
    end as [status],
    xpr.[job_id],
    xpr.[job_id],
    xpr.[last_run_date],
    xpr.[last_run_time],
    xpr.[next_run_date],
    xpr.[next_run_time],
    sjv.[enabled]
-- Все поля
--*
FROM @xp_results                          xpr
    inner join msdb..sysjobs sj on xpr.job_id = sj.job_id
    LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON ((xpr.job_id = sjs.job_id) AND (xpr.current_step = sjs.step_id)),
    msdb.dbo.sysjobs_view                sjv
WHERE (sjv.job_id = xpr.job_id)
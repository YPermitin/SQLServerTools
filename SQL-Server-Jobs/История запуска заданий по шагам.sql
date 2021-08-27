select
        j.name as 'JobName',
        s.step_id as 'Step',
        s.step_name as 'StepName',
        msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
        ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
         as 'RunDurationMinutes'
From msdb.dbo.sysjobs j
        INNER JOIN msdb.dbo.sysjobsteps s
        ON j.job_id = s.job_id
        INNER JOIN msdb.dbo.sysjobhistory h
        ON s.job_id = h.job_id
                AND s.step_id = h.step_id
                AND h.step_id <> 0
where j.enabled = 1
--Only Enabled Jobs
--and j.name = 'TestJob' -- Фильтр по заданию
/*
and msdb.dbo.agent_datetime(run_date, run_time) 
BETWEEN '12/08/2012' and '12/10/2012'  -- Фильтр по периоду
*/
order by JobName, RunDateTime desc
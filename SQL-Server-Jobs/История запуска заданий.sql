select
        j.name as 'JobName',
        msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
        ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
         as 'RunDurationMinutes'
From msdb.dbo.sysjobs j
        INNER JOIN msdb.dbo.sysjobhistory h
        ON j.job_id = h.job_id
where j.enabled = 1
--Only Enabled Jobs
--and j.name = 'TestJob' -- Фильтр по заданию
/*
and msdb.dbo.agent_datetime(run_date, run_time) 
BETWEEN '12/08/2012' and '12/10/2012'  -- Фильтр по периоду
*/
order by JobName, RunDateTime desc
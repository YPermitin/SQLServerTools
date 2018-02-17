DECLARE 
	  @memory_usage_percent FLOAT
	, @memory_usage_kb FLOAT
    , @cpu_usage_percent FLOAT

SET @memory_usage_percent = ( SELECT    1.0 - ( available_physical_memory_kb / ( total_physical_memory_kb * 1.0 ) ) memory_usage
                        FROM      sys.dm_os_sys_memory
                    )
SET @memory_usage_kb = ( SELECT    (total_physical_memory_kb - available_physical_memory_kb) memory_usage_kb
                        FROM      sys.dm_os_sys_memory
                    )

SET @cpu_usage_percent = ( SELECT TOP ( 1 )
                            [CPU] / 100.0 AS [CPU_usage]
                    FROM     ( SELECT    record.value('(./Record/@id)[1]', 'int') AS record_id
                                        , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [CPU]
                                FROM      ( SELECT    [timestamp]
                                                    , CONVERT(XML, record) AS [record]
                                            FROM      sys.dm_os_ring_buffers WITH ( NOLOCK )
                                            WHERE     ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                                                    AND record LIKE N'%<SystemHealth>%'
                                        ) AS x
                            ) AS y
                    ORDER BY record_id DESC
                    )


SELECT  GETDATE() as period
		, @memory_usage_percent [memory_usage_percent]
		, @memory_usage_kb [memory_usage_kb]
        , @cpu_usage_percent [cpu_usage_percent]
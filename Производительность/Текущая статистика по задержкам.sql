SELECT TOP 10
[Wait type] = wait_type,
[Wait time (s)] = wait_time_ms / 1000,
[% waiting] = CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 
             / SUM(wait_time_ms) OVER())
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' 
ORDER BY wait_time_ms DESC;

-- http://msdn.microsoft.com/ru-ru/library/ms179984.aspx - расшифровка задержек на MSDN
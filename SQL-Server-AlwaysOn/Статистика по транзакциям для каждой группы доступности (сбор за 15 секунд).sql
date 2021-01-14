-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

SET NOCOUNT ON;

IF OBJECT_ID('tempdb.dbo.#performance_counters') IS NOT NULL
DROP TABLE #performance_counters;

CREATE TABLE #performance_counters
(
    DatetimeChecked DATETIME,
    instance_name NVARCHAR(128),
    counter_name NVARCHAR(128),
    cntr_value BIGINT
);

INSERT INTO #performance_counters
    (DatetimeChecked,instance_name,counter_name,cntr_value)
SELECT
    GETDATE() AS DatetimeChecked,
    instance_name,
    counter_name,
    cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Write Transactions/sec','Transactions/sec')
    AND instance_name != '_Total'

--Wait for 15 seconds then get the deltas
WAITFOR DELAY '00:00:15';

SELECT
    Groups.name AS AGname,
    PerSecondDeltas.counter_name,
    SUM(cntr_delta_per_second) AS Total_per_second
FROM
    (
SELECT
        PerfmonNow.instance_name,
        PerfmonNow.counter_name,
        PerfmonNow.cntr_value
, CAST((PerfmonNow.cntr_value - PerfmonSnapShot.cntr_value) * 1.0 / DATEDIFF(SECOND, PerfmonSnapShot.DatetimeChecked, GETDATE()) AS MONEY) AS cntr_delta_per_second
    FROM sys.dm_os_performance_counters PerfmonNow
        INNER JOIN #performance_counters PerfmonSnapShot ON PerfmonNow.instance_name = PerfmonSnapShot.instance_name
            AND PerfmonNow.counter_name = PerfmonSnapShot.counter_name
    WHERE PerfmonNow.counter_name IN ('Write Transactions/sec','Transactions/sec')
        AND PerfmonNow.instance_name != '_Total'
) PerSecondDeltas
    INNER JOIN sys.availability_databases_cluster AGDatabases ON PerSecondDeltas.instance_name = AGDatabases.database_name
    INNER JOIN sys.availability_groups Groups ON AGDatabases.group_id = Groups.group_id
GROUP BY Groups.name,counter_name
ORDER BY
    Groups.name ASC,
    counter_name ASC
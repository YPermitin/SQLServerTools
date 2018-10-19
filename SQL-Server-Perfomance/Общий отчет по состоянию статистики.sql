select
    o.name AS [TableName],
    a.name AS [StatName],
    a.rowmodctr AS [RowsChanged],
    STATS_DATE(s.object_id, s.stats_id) AS [LastUpdate],
    o.is_ms_shipped,
    s.is_temporary,
    p.*
from sys.sysindexes a
    inner join sys.objects o
    on a.id = o.object_id
        and o.type = 'U'
        and a.id > 100
        and a.indid > 0
    left join sys.stats s
    on a.name = s.name
    left join (
SELECT
        p.[object_id]
, p.index_id
, total_pages = SUM(a.total_pages)
    FROM sys.partitions p WITH(NOLOCK)
        JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
    GROUP BY 
p.[object_id]
, p.index_id
) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
order by
    a.rowmodctr desc,
    STATS_DATE(s.object_id, s.stats_id) ASC
DECLARE @DateNow DATETIME
SELECT @DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = (
    SELECT '
    UPDATE STATISTICS [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] [' + s.name + ']
        WITH FULLSCAN' + CASE WHEN s.no_recompute = 1 THEN ', NORECOMPUTE' ELSE '' END + ';'
    FROM (
        SELECT
            [object_id]
            , name
            , stats_id
            , no_recompute
            , last_update = STATS_DATE([object_id], stats_id)
			, auto_created
        FROM sys.stats WITH(NOLOCK)
        WHERE -- auto_created = 0 AND
            is_temporary = 0
    ) s
        LEFT JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
        LEFT JOIN (
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
        LEFT JOIN sys.sysindexes si
        ON si.id = s.object_id AND si.indid = s.stats_id
    WHERE o.[type] IN ('U', 'V')
        AND o.is_ms_shipped = 0 -- не были созданы системой (служебные статистики MS)
        AND (
			  -- никогда ранее не обновлялись и есть данные для создания статистики 
              last_update IS NULL AND p.total_pages > 0
        OR
        -- есть данные о строках для создания  статистики, а также:
        --	а) Если размер страниц более 4 МБ, то статистика была обновлена более 3 дней назад
        --	б) Если размер страниц менее или равен 4 МБ, то статистика была обновлена вчера или позже.
        (p.total_pages IS NOT NULL AND last_update <= DATEADD(dd, 
                CASE WHEN p.total_pages > 4096 -- > 4 MB
                    THEN -2 -- updated 3 days ago
                    ELSE 0 
                END, @DateNow))
        OR
        -- если нет данных о строках (как для служебных статистик)
        -- и последнее обновление статистик было выполнено более 6 дней назад
        -- и количество модифицированных строк с последнего обновления более 1000
        (p.total_pages IS NULL
        AND (last_update <= DATEADD(dd, -5, @DateNow) OR last_update IS NULL) -- updated 6 days ago or NULL
        AND rowmodctr > 1000) -- row modified after last update        
		)
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')

PRINT @SQL
EXEC sys.sp_executesql @SQL
SELECT
    T.name,
    T.[object_id],
    AU.type_desc,
    AU.first_page,
    AU.data_pages,
    P.[rows]
FROM tempdb.sys.tables AS T
JOIN tempdb.sys.partitions AS P
    ON P.[object_id] = T.[object_id]
JOIN tempdb.sys.system_internals_allocation_units AS AU
ON  (
        AU.type_desc = N'IN_ROW_DATA'
        AND AU.container_id = P.partition_id
    )
    OR
    (
        AU.type_desc = N'ROW_OVERFLOW_DATA'
        AND AU.container_id = P.partition_id
    )
    OR
    (
        AU.type_desc = N'LOB_DATA' 
        AND AU.container_id = P.hobt_id
    )
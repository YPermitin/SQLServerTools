SELECT SUM(unallocated_extent_page_count) AS [free pages],
    (SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;
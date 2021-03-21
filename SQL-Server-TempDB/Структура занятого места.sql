-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-dynamic-management-views/sys-dm-db-file-space-usage-transact-sql?view=sql-server-ver15

SELECT 
    -- Сколько выделено под версии
    SUM(version_store_reserved_page_count)*8 as version_store_kb,
    -- Сколько выделено под пользовательские объекты
    SUM(user_object_reserved_page_count)*8 as usr_obj_kb,
    -- Сколько выделено под внутренние объекты
    SUM(internal_object_reserved_page_count)*8 as internal_obj_kb,
    -- Свободное место
    SUM(unallocated_extent_page_count)*8 as freespace_kb,
    -- Сколько выделено под смешанные экстенты
    SUM(mixed_extent_page_count)*8 as mixedextent_kb
FROM tempdb.sys.dm_db_file_space_usage
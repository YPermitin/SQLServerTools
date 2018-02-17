select OBJECT_NAME(object_id) name, * from sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null)
where avg_fragmentation_in_percent > 30
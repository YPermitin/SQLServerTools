/*
Информация о файлах баз данных на сервере, в том числе текущий LSN базы.
Можно по этим данным определить следующие файлы бэкапов, которые можно восстановить в базу данных.
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-master-files-transact-sql?redirectedfrom=MSDN&view=sql-server-ver16
*/

SELECT
	database_id,
	DB_NAME(database_id) AS [database_name],
	[name] as [file_name],
	physical_name,
	file_id,
	file_guid,
	type,
	type_desc,
	data_space_id,
	state,
	state_desc,
	size,
	max_size,
	growth,
	is_media_read_only,
	is_read_only,
	is_sparse,
	is_percent_growth,
	is_name_reserved,
	create_lsn,
	drop_lsn,
	read_only_lsn,
	read_write_lsn,
	differential_base_lsn,
	differential_base_guid,
	differential_base_time,
	redo_start_lsn,
	redo_start_fork_guid,
	redo_target_lsn,
	redo_target_fork_guid,
	backup_lsn,
	credential_id
FROM sys.master_files
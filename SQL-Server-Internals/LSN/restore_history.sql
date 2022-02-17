-- Determine LSN of database in NORECOVERY mode
-- https://serverfault.com/questions/276330/determine-lsn-of-database-in-norecovery-mode

SELECT TOP 1
	b.type, 
	b.first_lsn, 
	b.last_lsn,
	b.checkpoint_lsn, 
	b.database_backup_lsn
FROM msdb..restorehistory a
INNER JOIN msdb..backupset b ON a.backup_set_id = b.backup_set_id
--WHERE a.destination_database_name = '<database_name>'
ORDER BY restore_date DESC
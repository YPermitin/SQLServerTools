/*
Получение данных заголовка файла резервных копий

https://docs.microsoft.com/ru-ru/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver15
https://www.mssqltips.com/sqlservertutorial/105/how-to-get-the-contents-of-a-sql-server-backup-file/

*/

-- Путь к полному бэкапу, дифференциальному  или логу транзакций
RESTORE HEADERONLY FROM DISK = 'C:\BackupFile.BAK'

/*
В следующих колонках можно узнать информацию о LSN данных бэкапов: 
FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN
О назначении колонок смонтире документацию Microsoft (ссылка выше).
*/
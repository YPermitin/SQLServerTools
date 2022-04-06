/*
Настройка доступности сетевого пути для SQL Server.
Например, с целью восстановления или формирования бэкапа на сетевой ресурс.

Дополнительные материалы:
https://www.mssqltips.com/sqlservertip/3499/make-network-path-visible-for-sql-server-backup-and-restore-in-ssms/
*/

EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO

EXEC XP_CMDSHELL 'net use H: \\RemoteServerName\ShareName'
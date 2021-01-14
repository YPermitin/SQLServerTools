-- Подробная информация здесь:
-- https://sqlundercover.com/2019/02/19/7-more-ways-to-query-always-on-availability-groups/

/*
USE [master];
 
--Set Backup preference to Primary replica only
ALTER AVAILABILITY GROUP [AG name here] SET(AUTOMATED_BACKUP_PREFERENCE = PRIMARY);
 
--Set Backup preference to Secondary only
ALTER AVAILABILITY GROUP [AG name here] SET(AUTOMATED_BACKUP_PREFERENCE = SECONDARY_ONLY);
 
--Set Backup preference to Prefer secondary
ALTER AVAILABILITY GROUP [AG name here] SET(AUTOMATED_BACKUP_PREFERENCE = SECONDARY);
 
--Set Backup preference to Any replica (no preference)
ALTER AVAILABILITY GROUP [AG name here] SET(AUTOMATED_BACKUP_PREFERENCE = NONE);
 */

--Backup preference via TSQL can be found here
SELECT
    name AS AGname,
    automated_backup_preference_desc
FROM sys.availability_groups;
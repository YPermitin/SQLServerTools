/*
Для использования скрипта нужно разрешить использвоание xp_cmdshell
https://docs.microsoft.com/ru-ru/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql?view=sql-server-ver16

EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO
*/

-- Каталог с файлами бэкапов для анализа
DECLARE @backupPath NVARCHAR(1024) = 'D:\backups';
DECLARE @fileList TABLE (backupFile NVARCHAR(1024));
DECLARE @cmd NVARCHAR(1024);
DECLARE @currentFilePath nvarchar(max);

SET @cmd = 'DIR /b "' + @backupPath + '"'
INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd;

DECLARE @fileName nvarchar(max);

DECLARE files_cursor CURSOR  
FOR SELECT
	backupFile
FROM @fileList
WHERE backupFile IS NOT NULL;
OPEN files_cursor;

FETCH NEXT FROM files_cursor INTO @fileName;

IF OBJECT_ID(N'tempdb..#databaseItems') IS NOT NULL
	DROP TABLE #databaseItems;

create table #databaseItems
(
	BackupName nvarchar(128) null,
	BackupDescription nvarchar(255) null,
	BackupType smallint null,
	ExpirationDate datetime null,
	Compressed bit null,
	Position smallint null,
	DeviceType tinyint null,
	UserName nvarchar(128) null,
	ServerName nvarchar(128) null,
	DatabaseName nvarchar(128) null,
    DatabaseVersion int null,
    DatabaseCreationDate datetime null,
    BackupSize numeric(20,0) null,
    FirstLSN numeric(25,0) null,
    LastLSN	numeric(25,0) null,
    CheckpointLSN numeric(25,0) null,
    DatabaseBackupLSN numeric(25,0),
    BackupStartDate	datetime null,
    BackupFinishDate datetime null,
    SortOrder smallint null,
    CodePage smallint null,
    UnicodeLocaleId	int null,
    UnicodeComparisonStyle int null,
    CompatibilityLevel tinyint null,
    SoftwareVendorId int null,
    SoftwareVersionMajor int null,
    SoftwareVersionMinor int null,
    SoftwareVersionBuild int null,
    MachineName	nvarchar(128),
    Flags int null,
    BindingID uniqueidentifier null,
    RecoveryForkID uniqueidentifier null,
    Collation nvarchar(128) null,
    FamilyGUID uniqueidentifier null,
    HasBulkLoggedData bit null,
    IsSnapshot bit null,
    IsReadOnly bit null,
    IsSingleUser bit null,
    HasBackupChecksums bit null,
    IsDamaged bit null,
    BeginsLogChain bit null,
    HasIncompleteMetaData bit null,
    IsForceOffline bit null,
    IsCopyOnly bit null,
    FirstRecoveryForkID uniqueidentifier null,
    ForkPointLSN numeric(25,0) null,
    RecoveryModel nvarchar(60) null,
    DifferentialBaseLSN numeric(25,0) null,
    DifferentialBaseGUID uniqueidentifier null,
    BackupTypeDescription nvarchar(60) null,
    BackupSetGUID uniqueidentifier null,
    CompressedBackupSize bigint null,
    containment	tinyint null,
    KeyAlgorithm nvarchar(32) null,
    EncryptorThumbprint varbinary(20) null,
    EncryptorType nvarchar(32) null
)

WHILE @@FETCH_STATUS = 0  
BEGIN	
	SET @currentFilePath = @backupPath + '\' + @fileName;
	INSERT INTO #databaseItems
	EXEC('RESTORE HEADERONLY FROM DISK = ''' + @currentFilePath + '''');

	FETCH NEXT FROM files_cursor INTO @fileName;
END
CLOSE files_cursor;  
DEALLOCATE files_cursor;

/* Описание всех полей
-- https://docs.microsoft.com/ru-ru/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver16
Порядок бэкапов в разрезе базы данных определяется полями FirstLSN и LastLSN.
Подходящий файл определяется по принципу, где FirstLSN равен предыдущему LastLSN 
(предыдущий файл лога транзакций, диф. бэкапа, полного бэкапа или текущей базы, на которую применяется бэкап)
*/
SELECT
	-- Имя базы данных, для которой была создана резервная копия.
	DatabaseName,
	-- Дата и время начала операции резервного копирования базы данных.
	BackupStartDate,
	-- Дата и время завершения операции резервного копирования базы данных.
	BackupFinishDate,
	-- Регистрационный номер транзакции из первой записи журнала в резервном наборе данных.
	FirstLSN,
	-- Регистрационный номер транзакции в журнале для следующей записи журнала после резервного набора данных.
	LastLSN,
	-- Регистрационный номер транзакции в журнале для последней контрольной точки на момент создания резервной копии.
	CheckpointLSN,
	-- Регистрационный номер транзакции в журнале для последней полной резервной копии базы данных.
	DatabaseBackupLSN,
	/* Для разностной резервной копии с одной основой это значение равно FirstLSN базовой копии для разностного копирования. 
	Изменения, у которых номера LSN больше или равны DifferentialBaseLSN, включаются в разностную резервную копию.*/
	DifferentialBaseLSN,
	-- Имя пользователя, выполнившего операцию резервного копирования.	
	UserName,
	-- Имя сервера, записавшего резервный набор данных.
	ServerName,
	-- Размер резервной копии, в байтах.
	BackupSize,
	-- Имя компьютера, выполнившего операцию резервного копирования.
	MachineName,
	BackupName,
	BackupDescription,
	BackupType,
	ExpirationDate,
	Compressed,
	Position,
	DeviceType,	
    DatabaseVersion,
    DatabaseCreationDate,
    SortOrder,
    CodePage,
    UnicodeLocaleId,
    UnicodeComparisonStyle,
    CompatibilityLevel,
    SoftwareVendorId ,
    SoftwareVersionMajor,
    SoftwareVersionMinor,
    SoftwareVersionBuild,    
    Flags,
    BindingID,
    RecoveryForkID,
    Collation,
    FamilyGUID,
    HasBulkLoggedData,
    IsSnapshot,
    IsReadOnly,
    IsSingleUser,
    HasBackupChecksums,
    IsDamaged,
    BeginsLogChain,
    HasIncompleteMetaData,
    IsForceOffline,
    IsCopyOnly,
    FirstRecoveryForkID,
    ForkPointLSN,
    RecoveryModel,
    DifferentialBaseLSN,
    DifferentialBaseGUID,
    BackupTypeDescription,
    BackupSetGUID,
    CompressedBackupSize,
    containment,
    KeyAlgorithm,
    EncryptorThumbprint,
    EncryptorType
FROM #databaseItems
ORDER BY DatabaseName, FirstLSN

IF OBJECT_ID(N'tempdb..#databaseItems') IS NOT NULL
	DROP TABLE #databaseItems;
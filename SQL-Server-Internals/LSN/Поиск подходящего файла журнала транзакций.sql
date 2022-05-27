/*
Поиск подходящих файлов бэкапов лога транзакций для базы.

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

-- Имя базы данных, с которой был снят бэкап
DECLARE @sourceDatabaseName sysname = 'DatabaseName';
-- Имя базы данных, на которую нужно
DECLARE @destinationDatabaseName sysname = 'DatabaseName';
-- Каталог с файлами бэкапов для анализа
DECLARE @backupPath NVARCHAR(1024) = 'D:\BackupsFolderPath';
DECLARE @fileList TABLE (backupFile NVARCHAR(1024));
DECLARE @cmd NVARCHAR(1024);
DECLARE @currentFilePath nvarchar(max);
DECLARE @currentDatabaseLSN numeric(25,0);
DECLARE @msg nvarchar(max);

PRINT 'Database: ' + @destinationDatabaseName;
IF DB_ID(@destinationDatabaseName) IS NULL
BEGIN
	SET @msg = 'Database ' + @destinationDatabaseName + ' is not exists.';
	THROW 51000, @msg, 1;
	RETURN;
END

-- Определяем текущий LSN базы
SELECT
	@currentDatabaseLSN = MAX(redo_start_lsn)
FROM sys.master_files
where DB_NAME(database_id) = @destinationDatabaseName
	AND type_desc = 'ROWS';
PRINT 'Current LSN: ' + CAST(@currentDatabaseLSN AS nvarchar(max));

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

SELECT
	*
FROM #databaseItems AS t
where t.FirstLSN >= @currentDatabaseLSN
	and t.DatabaseName = @sourceDatabaseName
ORDER BY t.DatabaseName, t.FirstLSN

IF OBJECT_ID(N'tempdb..#databaseItems') IS NOT NULL
	DROP TABLE #databaseItems;
CREATE PROCEDURE [dbo].[sp_BackupDatabase]
	@databaseName sysname,
	@backupDirectory nvarchar(max),
	@backupType nvarchar(10) = 'FULL',	
	@useSubdirectory bit = 1,
	@showScriptOnly bit = 0,
	@backupCompressionType nvarchar(10) = 'AUTO',	
	@copyOnly bit = 0,
	@checksum bit = 0,
	@continiueOnError bit = 0,
	@blockSize int = 0,
	@maxTransferSize int = 0,
	@bufferCount int = 0,
	@verify bit = 0
	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@backupExtension nvarchar(5),
		@fileName nvarchar(max),
		@backupFileFullName nvarchar(max),
		@useCompression bit,
		@msg nvarchar(max),
		@sql nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END

	IF(NOT UPPER(@backupType) IN ('FULL', 'DIFF', 'TRN'))
	BEGIN
	    SET @msg = 'Backup type is incorrect. Valid values: FULL, DIFF, TRN.';
        THROW 51000, @msg, 1;
        RETURN -1;
	END

	IF(NOT UPPER(@backupCompressionType) IN ('AUTO', 'ENABLE', 'DISABLE'))
	BEGIN
	    SET @msg = 'Backup compression type is incorrect. Valid values: AUTO, ENABLE, DISABLE.';
        THROW 51000, @msg, 1;
        RETURN -1;
	END  

	SET @backupExtension = 
		CASE 
			WHEN @backupType = 'FULL' THEN 'bak'
			WHEN @backupType = 'DIFF' THEN 'diff'
			WHEN @backupType = 'TRN' THEN 'trn'
		END

	if(@backupCompressionType = 'AUTO')
	BEGIN
		SELECT @useCompression = CAST(value AS bit)
		FROM sys.configurations   
		WHERE name = 'backup compression default';
	END ELSE IF(@backupCompressionType = 'ENABLE')
	BEGIN
		SET @useCompression = 1
	END ELSE IF(@backupCompressionType = 'DISABLE') 
	BEGIN
		SET @useCompression = 0
	END

	SET @fileName = @databaseName + '_backup_' + FORMAT(sysdatetime(), 'yyyy_MM_dd_HHmmss_ffffff');

	SET @backupFileFullName =
		CASE WHEN SUBSTRING(@backupDirectory, LEN(@backupDirectory), 1) = '\' THEN SUBSTRING(@backupDirectory, 1, LEN(@backupDirectory) - 1) ELSE @backupDirectory END + 
		'\' + 
		CASE WHEN @useSubdirectory = 1 THEN @databaseName + '\' ELSE '' END;

	if(@showScriptOnly = 0)
	BEGIN
		SET @sql = 'EXEC master.sys.xp_create_subdir N''' + @backupFileFullName + ''''
		EXECUTE sp_executesql @sql
	END

	SET @backupFileFullName = @backupFileFullName + @fileName + '.' + @backupExtension;

	SET @sql = 
'BACKUP ' + CASE WHEN @backupType = 'TRN' THEN 'LOG' ELSE 'DATABASE' END + ' [' + @databaseName + ']
TO DISK = N''' + @backupFileFullName + ''' WITH NOFORMAT,
NOINIT,
NAME = N''' + @fileName + ''',
SKIP, REWIND, NOUNLOAD' +
	CASE WHEN @backupType = 'DIFF' THEN ', DIFFERENTIAL' ELSE '' END + 
	CASE WHEN @useCompression = 1 THEN ', COMPRESSION' ELSE '' END + 
	CASE WHEN @copyOnly = 1 THEN ', COPY_ONLY' ELSE '' END +
	CASE WHEN @checksum = 1 THEN ', CHECKSUM' ELSE '' END +
	CASE WHEN @continiueOnError = 1 THEN ', CONTINUE_AFTER_ERROR' ELSE '' END +
	CASE WHEN @blockSize > 0 THEN ', BLOCKSIZE = ' + CAST(@blockSize as nvarchar(max)) ELSE '' END +
	CASE WHEN @maxTransferSize > 0 THEN ', MAXTRANSFERSIZE = ' + CAST(@maxTransferSize as nvarchar(max)) ELSE '' END +
	CASE WHEN @bufferCount > 0 THEN ', BUFFERCOUNT = ' + CAST(@bufferCount as nvarchar(max)) ELSE '' END + ', STATS = 10;'

	if(@verify = 1)
	BEGIN
		DECLARE @backupSetId as int;

		SELECT @backupSetId = position from msdb..backupset 
		WHERE [database_name] = @databaseName and backup_set_id = (
			select max(backup_set_id) 
			from msdb..backupset
			where [database_name] = @databaseName
		)

		IF @backupSetId is null AND @showScriptOnly = 0
		BEGIN
			raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных не найдены.', 16, 1) 
		END

		SET @sql = @sql + '

RESTORE VERIFYONLY FROM  DISK = N''' + @backupFileFullName + ''' WITH  FILE = ' + CAST(@backupSetId AS nvarchar(max)) + ',  NOUNLOAD,  NOREWIND;'
	END

	if(@showScriptOnly = 1)
	BEGIN
		PRINT @sql
	END ELSE
	BEGIN
		EXECUTE sp_executesql @sql
	END
END
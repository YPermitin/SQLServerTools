CREATE PROCEDURE [dbo].[sp_CompressDatabaseObjects]
	@databaseName sysname,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@useOnlineRebuild bit = 1,
	@userResumableRebuild bit = 1,
	@maxDop int = 4
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE		
	   @sql nvarchar(max)
	   ,@msg nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + ISNULL(@databaseName, '') + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	-- Включаем контроль потребления ресурсов текущим соединением
	if(@timeFrom is not null and @timeTo is not null)
	BEGIN
		EXEC [SQLServerMonitoring].[dbo].[sp_AddSessionControlSetting]
			@databaseName = @databaseName,
			@workFrom = @timeFrom,
			@workTo = @timeTo,
			@timeTimeoutSec = 60,
			@abortIfLockOtherSessions = 1,
			@abortIfLockOtherSessionsTimeoutSec = 0;
	END

	IF OBJECT_ID('tempdb..#dataToCompress') IS NOT NULL
		DROP TABLE #dataToCompress;
	CREATE TABLE #dataToCompress
	(
		[SchemaName] varchar(255) not null,
		[Table] varchar(255),
		[Index] varchar(255),
		[Compression] varchar(25),
		[IndexType] numeric(15,0),
		[IndexsizeKB] numeric(15,0),
		[SqlCommandBase] nvarchar(max),
		[SqlCommandWithoutOnline] nvarchar(max)
	);

	SET @sql = CAST('
	USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST(']
	INSERT INTO #dataToCompress (
		[SchemaName],
		[Table],
		[Index],
		[Compression],
		[IndexType],
		[IndexsizeKB],
		[SqlCommandBase],
		[SqlCommandWithoutOnline]
	)
	SELECT
		dt.[SchemaName],
		dt.[Table],
		dt.[Index],
		dt.[Compression],
		dt.[IndexType],
		dtsz.[IndexsizeKB],
		''USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
		alter index '' + dt.[Index] 
			+ '' on ['' + dt.[SchemaName] + ''].['' + dt.[Table] + ''] rebuild with (data_compression = page, maxdop='' 
			+ CAST(@maxDop as nvarchar(max)) + '', online='' + 
			+ CASE WHEN @useOnlineRebuild = 1 THEN ''ON'' ELSE ''OFF'' END +
			+ '', RESUMABLE = '' +
			+ CASE WHEN @userResumableRebuild = 1 THEN ''ON'' ELSE ''OFF'' END +
			+ '')'' AS [SqlCommandBase],
		''USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
		alter index '' + dt.[Index] 
			+ '' on ['' + dt.[SchemaName] + ''].['' + dt.[Table] + ''] rebuild with (data_compression = page, maxdop='' 
			+ CAST(@maxDop as nvarchar(max)) + '', online=off)'' AS [SqlCommandWithoutOnline]
	FROM (
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			null AS [Index],  
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			-1 AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
		WHERE [p].[index_id] = 0
		UNION
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			[i].[name] AS [Index],   
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			[i].[type] AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
			INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
		WHERE [p].[index_id] = 1
		UNION
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			[i].[name] AS [Index],  
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			[i].[type] AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
			INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
		WHERE [p].[index_id] > 0) dt
		LEFT JOIN (
			SELECT
				OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
				OBJECT_NAME(i.OBJECT_ID) AS TableName,
				i.name AS IndexName,
				i.index_id AS IndexID,
				8 * SUM(a.used_pages) AS ''IndexsizeKB''
			FROM sys.indexes AS i
				JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
				JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			GROUP BY i.OBJECT_ID,i.index_id,i.name
		) dtsz
		ON dt.SchemaName = dtsz.SchemaName
			AND dt.[Table] = dtsz.TableName
			AND dt.[Index] = dtsz.[IndexName]
	WHERE [Compression] = ''NONE''
		AND [Index] IS NOT NULL
		AND ISNULL(dtsz.[IndexsizeKB], -1) <> 0
	ORDER BY dt.[IndexType], [IndexsizeKB]' AS nvarchar(max));

	EXECUTE sp_executesql
			@sql,
			N'@maxDop INT, @useOnlineRebuild bit, @userResumableRebuild bit',
			@maxDop, @useOnlineRebuild, @userResumableRebuild;

	DECLARE 
		@sqlCompressObject nvarchar(max),
		@sqlCompressObjectWitoutOnline nvarchar(max);

	DECLARE objectsToCompress CURSOR FOR 
	SELECT
		dt.SqlCommandBase,
		dt.SqlCommandWithoutOnline
	FROM #dataToCompress dt
	ORDER BY dt.[IndexType], dt.IndexsizeKB;
	OPEN objectsToCompress;

	FETCH NEXT FROM objectsToCompress INTO @sqlCompressObject, @sqlCompressObjectWitoutOnline;

	WHILE @@FETCH_STATUS = 0  
	BEGIN	

		BEGIN TRY
			exec(@sqlCompressObject)
			PRINT 'Объект сжат командой:'
			PRINT @sqlCompressObject;
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось сжать объект командой:'
			PRINT @sqlCompressObject

			BEGIN TRY
				exec(@sqlCompressObjectWitoutOnline)
				PRINT 'Объект сжат командой:'
				PRINT @sqlCompressObject;
			END TRY
			BEGIN CATCH
				PRINT 'Не удалось сжать объект командой:'
				PRINT @sqlCompressObjectWitoutOnline
			END CATCH
		END CATCH

		FETCH NEXT FROM objectsToCompress INTO @sqlCompressObject, @sqlCompressObjectWitoutOnline;
	END
	CLOSE objectsToCompress;  
	DEALLOCATE objectsToCompress;

	IF OBJECT_ID('tempdb..#dataToCompress') IS NOT NULL
			DROP TABLE #dataToCompress;

	-- Удаляем контроль для текущей сессии
	EXEC [SQLServerMonitoring].[dbo].[sp_RemoveSessionControlSetting];
END
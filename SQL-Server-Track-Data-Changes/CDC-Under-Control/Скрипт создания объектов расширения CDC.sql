/*
Полный скрипт создания объектов для расширенного управления
механизмом CDC
*/

CREATE SCHEMA [yy] AUTHORIZATION [dbo]
GO

CREATE TABLE [yy].[MaintenanceSettingsCDC](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SchemaName] [nvarchar](255) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[UseCDC] [bit] NOT NULL,
	[SchemaNameCDC] [nvarchar](255) NULL,
	[TableNameCDC] [nvarchar](255) NULL,
	[TableNameCDCHistory] [nvarchar](255) NULL,
	[CaptureInstanceCDC] [nvarchar](255) NULL,
	[TableObjectId] [int] NULL,
	[TableSchemaLastChangeDate] [datetime2](7) NULL,
	CONSTRAINT [PK_MaintenanceSettingsCDC] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Индекс для защиты уникальности настроек. На одну таблицу в схеме данных
-- может быть только одна настройка.
CREATE UNIQUE NONCLUSTERED INDEX [UX_MaintenanceSettingsCDC_BySchemaAndTableName] 
ON [yy].[MaintenanceSettingsCDC]
(
	[SchemaName] ASC,
	[TableName] ASC
) ON [PRIMARY]
GO

- Функция возвращает имя схемы данных CDC по умолчанию.
-- Маловероятно, что Вам придется как-то эту часть изменять.
CREATE FUNCTION [yy].[GetCDCSchemeName]()
RETURNS nvarchar(255)
AS
BEGIN
	RETURN N'cdc';
END
GO

-- Функция возвращает имя схемы данных, где будут находится служебные объекты.
-- Вы можете изменить ее под свои нужны. Только не забудьте исправить имя схемы
-- в DDL-скрипах создания объектов базы данных.
CREATE FUNCTION [yy].[GetMainSchemeName]()
RETURNS nvarchar(255)
AS
BEGIN
	RETURN N'yy';
END
GO

-- Процедура для обновления служебных полей настроек CDC
CREATE PROCEDURE [yy].[UpdateServiceMaintenanceSettingsCDC]
	@settingId int,
	@schemaNameCDC nvarchar(255) = null output,
	@tableNameCDC nvarchar(255) = null output,
	@tableNameCDCHistory nvarchar(255) = null output,
	@captureInstanceCDC nvarchar(255) = null output,
	@tableObjectId int = null output,
	@tableSchemaLastChangeDate datetime2(0) = null output
AS
BEGIN
	DECLARE
		@schameName nvarchar(255),
		@tableName nvarchar(255);

	SET NOCOUNT ON;

	BEGIN TRAN;

	SELECT
		@schameName = SchemaName,
		@tableName = TableName
	FROM [yy].[MaintenanceSettingsCDC]
	WHERE ID = @settingId

	-- Получаем идентификатор исходной таблицы,
	-- а также дату последнего изменения таблицы DDL-командами
	DECLARE @currentCDCEnabled bit = 0;
	SELECT 
		@tableObjectId = object_id,
		@tableSchemaLastChangeDate = 
			CASE WHEN create_date > modify_date THEN create_date
				ELSE modify_date
			END
	FROM sys.tables tb
		INNER JOIN sys.schemas s 
		on s.schema_id = tb.schema_id
	WHERE s.name = @schameName AND tb.name = @tableName

	-- Сохраняем информацию о CDC:
	--	* Имя схемы CDC
	--	* Имя таблицы CDC
	--	* Имя переопредленной таблицы CDC. Внимание! Имя формируется заново
	--		при каждом вызове. Это нужно учитывать при использвоании процедуры
	--	* Имя экземпляра объекта сбора данных
	SELECT 
		  @schemaNameCDC = [yy].[GetCDCSchemeName](),
		  @tableNameCDC = OBJECT_NAME([object_id]),
		  @tableNameCDCHistory = OBJECT_NAME([object_id]) + '_' 
			+ replace(convert(varchar, getdate(),101),'/','') + '_' 
			+ replace(convert(varchar, getdate(),108),':',''),
		  @captureInstanceCDC = capture_instance
	FROM [cdc].[change_tables]
	WHERE source_object_id = @tableObjectId

	-- Обновляем настройку
	UPDATE [yy].[MaintenanceSettingsCDC]
	SET
		[SchemaNameCDC] = @schemaNameCDC,
		[TableNameCDC] = @tableNameCDC,
		[TableNameCDCHistory] = @tableNameCDCHistory,
		[CaptureInstanceCDC] = @captureInstanceCDC,
		[TableObjectId] = @tableObjectId,
		[TableSchemaLastChangeDate] = @tableSchemaLastChangeDate
	WHERE ID = @settingId

	COMMIT TRAN;

	RETURN 0;
END
GO

-- Процедура переопределения потока данных в таблицу CDC на наши собственные
-- таблицы. Переопределение выполняется для конкретной настройки в таблице MaintenanceSettingsCDC
CREATE PROCEDURE [yy].[OverrideDataFlowForCDC]
	@settingId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @originalTableName sysname;
	DECLARE @destinationTableName sysname;

	-- Читаем данные переданной настройки CDC
	SELECT
		@destinationTableName = [TableNameCDCHistory],
		@originalTableName = [TableNameCDC]
	FROM [yy].[MaintenanceSettingsCDC]
	WHERE ID = @settingId

	DECLARE @originalSchemaName sysname = [yy].[GetCDCSchemeName]();
	DECLARE @destinationSchemaName sysname = [yy].[GetMainSchemeName]();
	DECLARE @destinationObjectFullName nvarchar(max) = @destinationSchemaName + '.' + @destinationTableName;

	-- Формируем список таблиц для генерации скриптов создания копий таблиц и индексов,
	-- триггеров и их пересоздание
	DECLARE @tableName sysname;
	DECLARE tables_cursor CURSOR  
	FOR SELECT
		s.[name]
	FROM SYSOBJECTS s LEFT JOIN sys.objects objs on s.id = objs.object_id
	WHERE s.xtype = 'U'
		and SCHEMA_NAME(objs.schema_id) = @originalSchemaName
		AND s.[name] IN (
			@originalTableName
		);
	OPEN tables_cursor;

	FETCH NEXT FROM tables_cursor INTO @tableName;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		DECLARE @tableNameFull SYSNAME
		SELECT @tableNameFull = @originalSchemaName + '.' + @tableName

		DECLARE 
			  @object_name SYSNAME
			, @object_id INT

		-- Подготовка к формированию скриптов по таблицам и индексам
		SELECT 
			  @object_name = '[' + s.name + '].[' + o.name + ']'
			, @object_id = o.[object_id]
		FROM sys.objects o WITH (NOWAIT)
		JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
		WHERE s.name + '.' + o.name = @tableNameFull
			AND o.[type] = 'U'

		DECLARE @SQL NVARCHAR(MAX) = '';	
		DECLARE @SQLTRANSFER NVARCHAR(MAX) = '';	
		DECLARE @SQLTRANSFERTRIGGER NVARCHAR(MAX) = '';
		DECLARE @SQLTRANSFERTRIGGERDROP NVARCHAR(MAX) = '';

		WITH index_column AS 
		(
			SELECT 
				  ic.[object_id]
				, ic.index_id
				, ic.is_descending_key
				, ic.is_included_column
				, c.name
			FROM sys.index_columns ic WITH (NOWAIT)
			JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
			WHERE ic.[object_id] = @object_id
		),
		fk_columns AS 
		(
			 SELECT 
				  k.constraint_object_id
				, cname = c.name
				, rcname = rc.name
			FROM sys.foreign_key_columns k WITH (NOWAIT)
			JOIN sys.columns rc WITH (NOWAIT) ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id 
			JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
			WHERE k.parent_object_id = @object_id
		)

		-- Скрипт создания новой таблицы
		SELECT @SQL = '
		IF EXISTS (SELECT * FROM SYSOBJECTS s LEFT JOIN sys.objects objs on s.id = objs.object_id
				   WHERE s.name=''' + CAST(@destinationTableName as nvarchar(max)) + ''' 
						AND xtype=''U'' 
						AND SCHEMA_NAME(objs.schema_id) = ''' + CAST(@destinationSchemaName as nvarchar(max)) + ''')
		BEGIN
			DROP TABLE ' + CAST(@destinationObjectFullName as nvarchar(max)) + ';
		END
			CREATE TABLE ' + @destinationObjectFullName + CHAR(13) + '(' + CHAR(13) + STUFF((
			SELECT CHAR(9) + ', [' + c.name + '] ' + 
				CASE WHEN c.is_computed = 1
					THEN 'AS ' + cc.[definition] 
					ELSE UPPER(tp.name) + 
						CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
							   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
							 WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')
							   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
							 WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
							   THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
							 WHEN tp.name = 'decimal' 
							   THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
							ELSE ''
						END +
						CASE WHEN c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
						CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
						CASE WHEN dc.[definition] IS NOT NULL THEN ' DEFAULT' + dc.[definition] ELSE '' END + 
						CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') AS CHAR(1)) + ',' + CAST(ISNULL(ic.increment_value, '1') AS CHAR(1)) + ')' ELSE '' END 
				END + CHAR(13)
			FROM sys.columns c WITH (NOWAIT)
			JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
			LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
			LEFT JOIN sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
			LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
			WHERE c.[object_id] = @object_id
			ORDER BY c.column_id
			FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
			+ ISNULL((SELECT CHAR(9) + ', CONSTRAINT [' + k.name + '] PRIMARY KEY (' + 
							(SELECT STUFF((
								 SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
								 FROM sys.index_columns ic WITH (NOWAIT)
								 JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
								 WHERE ic.is_included_column = 0
									 AND ic.[object_id] = k.parent_object_id 
									 AND ic.index_id = k.unique_index_id     
								 FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
					+ ')' + CHAR(13)
					FROM sys.key_constraints k WITH (NOWAIT)
					WHERE k.parent_object_id = @object_id 
						AND k.[type] = 'PK'), '') + ')'  + CHAR(13)
			+ ISNULL((SELECT (
				SELECT CHAR(13) +
					 'ALTER TABLE ' + @object_name + ' WITH' 
					+ CASE WHEN fk.is_not_trusted = 1 
						THEN ' NOCHECK' 
						ELSE ' CHECK' 
					  END + 
					  ' ADD CONSTRAINT [' + fk.name  + '] FOREIGN KEY(' 
					  + STUFF((
						SELECT ', [' + k.cname + ']'
						FROM fk_columns k
						WHERE k.constraint_object_id = fk.[object_id]
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
					   + ')' +
					  ' REFERENCES [' + SCHEMA_NAME(ro.[schema_id]) + '].[' + ro.name + '] ('
					  + STUFF((
						SELECT ', [' + k.rcname + ']'
						FROM fk_columns k
						WHERE k.constraint_object_id = fk.[object_id]
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
					   + ')'
					+ CASE 
						WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE' 
						WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
						WHEN fk.delete_referential_action = 3 THEN ' ON DELETE SET DEFAULT' 
						ELSE '' 
					  END
					+ CASE 
						WHEN fk.update_referential_action = 1 THEN ' ON UPDATE CASCADE'
						WHEN fk.update_referential_action = 2 THEN ' ON UPDATE SET NULL'
						WHEN fk.update_referential_action = 3 THEN ' ON UPDATE SET DEFAULT'  
						ELSE '' 
					  END 
					+ CHAR(13) + 'ALTER TABLE ' + @object_name + ' CHECK CONSTRAINT [' + fk.name  + ']' + CHAR(13)
				FROM sys.foreign_keys fk WITH (NOWAIT)
				JOIN sys.objects ro WITH (NOWAIT) ON ro.[object_id] = fk.referenced_object_id
				WHERE fk.parent_object_id = @object_id
				FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)')), '')
			+ ISNULL(((SELECT
				 CHAR(13) + 'CREATE' + CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END 
						+ ' NONCLUSTERED INDEX [' + i.name + '] ON ' + @destinationObjectFullName + ' (' +
						STUFF((
						SELECT ', [' + c.name + ']' + CASE WHEN c.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
						FROM index_column c
						WHERE c.is_included_column = 0
							AND c.index_id = i.index_id
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')'  
						+ ISNULL(CHAR(13) + 'INCLUDE (' + 
							STUFF((
							SELECT ', [' + c.name + ']'
							FROM index_column c
							WHERE c.is_included_column = 1
								AND c.index_id = i.index_id
							FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')', '')  + CHAR(13)
				FROM sys.indexes i WITH (NOWAIT)
				WHERE i.[object_id] = @object_id
					--AND i.is_primary_key = 0
					--AND i.[type] = 2
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
			), '')

		-- Скрипт для переноса накопившихся данных в новую таблицу
		SELECT
			@SQLTRANSFER = 
		N'
		INSERT INTO [' + CAST(@destinationSchemaName as nvarchar(max)) + '].[' + CAST(@destinationTableName as nvarchar(max)) + '] 
		(' + 
		STUFF(
		(SELECT N',' + c.name
		FROM
			sys.columns AS c
			INNER JOIN sys.types tp ON tp.system_type_id = c.system_type_id AND tp.user_type_id = c.user_type_id
		WHERE 
			c.OBJECT_ID = OBJECT_ID(@tableNameFull)
			AND NOT tp.name = 'timestamp'
		ORDER BY
			column_id
		FOR XML PATH(''), TYPE).value('.',N'nvarchar(max)')
		,1,1,N'')
		+ N') 
		SELECT 
		' + 
		STUFF(
		(SELECT N',' + c.name
		FROM
			sys.columns AS c
			INNER JOIN sys.types tp ON tp.system_type_id = c.system_type_id AND tp.user_type_id = c.user_type_id
		WHERE 
			c.OBJECT_ID = OBJECT_ID(@tableNameFull)
			AND NOT tp.name = 'timestamp'
		ORDER BY
			column_id
		FOR XML PATH(''), TYPE).value('.',N'nvarchar(max)')
		,1,1,N'')
		+ N'
		FROM [' + CAST(@originalSchemaName as nvarchar(max)) + '].[' + CAST(@tablename as nvarchar(max)) + '];

		';

		-- Скрипт создания триггера для перенаправления потока данных в новую таблицу
		SELECT
			@SQLTRANSFERTRIGGER = 
		N'
	CREATE TRIGGER [' + CAST(@originalSchemaName as nvarchar(max)) + '].[tr_AfterInsert_MoveToTable_' + CAST(@destinationTableName as nvarchar(max)) + ']
	   ON [' + CAST(@originalSchemaName as nvarchar(max)) + '].[' + CAST(@tablename as nvarchar(max)) + ']
	   INSTEAD OF INSERT
	AS 
	BEGIN
		SET NOCOUNT ON;

		INSERT INTO [' + CAST(@destinationSchemaName as nvarchar(max)) + '].[' + CAST(@destinationTableName as nvarchar(max)) + '] 
		(' + 
		STUFF(
		(SELECT N',' + c.name
		FROM
			sys.columns AS c
			INNER JOIN sys.types tp ON tp.system_type_id = c.system_type_id AND tp.user_type_id = c.user_type_id
		WHERE 
			c.OBJECT_ID = OBJECT_ID(@tableNameFull)
			AND NOT tp.name = 'timestamp'
		ORDER BY
			column_id
		FOR XML PATH(''), TYPE).value('.',N'nvarchar(max)')
		,1,1,N'')
		+ N') 
		SELECT 
		' + 
		STUFF(
		(SELECT N',' + c.name
		FROM
			sys.columns AS c
			INNER JOIN sys.types tp ON tp.system_type_id = c.system_type_id AND tp.user_type_id = c.user_type_id
		WHERE 
			c.OBJECT_ID = OBJECT_ID(@tableNameFull)
			AND NOT tp.name = 'timestamp'
		ORDER BY
			column_id
		FOR XML PATH(''), TYPE).value('.',N'nvarchar(max)')
		,1,1,N'')
		+ N'
		FROM INSERTED;
	END
		';

		-- Скрипт удаления триггера, если он существует перед созданием
		SELECT
			@SQLTRANSFERTRIGGERDROP = '
	IF EXISTS (SELECT * FROM sys.objects 
				WHERE [name] = ''tr_AfterInsert_MoveToTable_' + CAST(@destinationTableName as nvarchar(max)) + '''
				AND [type] = ''TR''
				AND SCHEMA_NAME(schema_id) = ''' + CAST(@originalSchemaName as nvarchar(max)) + ''')
	BEGIN
		  DROP TRIGGER [' + CAST(@originalSchemaName as nvarchar(max)) + '].[tr_AfterInsert_MoveToTable_' + CAST(@destinationTableName as nvarchar(max)) + '];
	END;
	';

		-- Выполняем команды создания собственного объекта
		EXECUTE sp_executesql @SQL

		-- Создаем триггер для перенаправления изменений в собственную таблицу
		EXECUTE sp_executesql @SQLTRANSFERTRIGGERDROP
		EXECUTE sp_executesql @SQLTRANSFERTRIGGER

		-- Затем переносим данные из исходной таблицы в созданную
		EXECUTE sp_executesql @SQLTRANSFER

		FETCH NEXT FROM tables_cursor INTO @tableName;
	END
	CLOSE tables_cursor;  
	DEALLOCATE tables_cursor;
END
GO

-- Процедура позволяет определить доступность применения настроек CDC в данный момент
CREATE PROCEDURE [yy].[ApplySettingsCDCAvailable]
	@availableResult int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	-- По умолчанию всегда разрешено
	SET @availableResult = 1
END
GO

-- Применение настроек CDC по настройкам из табилцы MaintenanceSettingsCDC
CREATE PROCEDURE [yy].[ApplySettingsCDC]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@settingId int,
		@schemaName nvarchar(255),
		@tableName nvarchar(255),
		@useCDC bit,
		@schemaNameCDC nvarchar(255),
		@tableNameCDC nvarchar(255),
		@tableNameCDCHistory nvarchar(255),
		@captureInstanceCDC nvarchar(255),
		@tableObjectId int,
		@tableSchemaLastChangeDate datetime2(0),
		@availableResult int;

	-- Проверяем, доступно ли применение настроек CDC в данный момент
	-- Этот момент описан ниже
	EXECUTE [yy].[ApplySettingsCDCAvailable] 
		@availableResult OUTPUT
	IF(@availableResult = 0)
	BEGIN
		RETURN 0;
	END

	-- Получаем все активные настройки
	DECLARE settingsCursor CURSOR  
	FOR SELECT 
		   [ID]
		  ,[SchemaName]
		  ,[TableName]
		  ,[UseCDC]
		  ,[SchemaNameCDC]
		  ,[TableNameCDC]
		  ,[TableNameCDCHistory]
		  ,[CaptureInstanceCDC]
		  ,[TableObjectId]
		  ,[TableSchemaLastChangeDate]
	FROM [yy].[MaintenanceSettingsCDC]
	WHERE [UseCDC] = 1;
	OPEN settingsCursor;

	FETCH NEXT FROM settingsCursor 
	INTO @settingId, @schemaName, @tableName, @useCDC, 
		@schemaNameCDC, @tableNameCDC, @tableNameCDCHistory, 
		@captureInstanceCDC, @tableObjectId, @tableSchemaLastChangeDate;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		-- Проверяем, доступно ли применение настроек CDC в данный момент
		-- Этот момент описан ниже
		EXECUTE [yy].[ApplySettingsCDCAvailable] 
			@availableResult OUTPUT
		IF(@availableResult = 0)
		BEGIN
			RETURN 0;
		END

		-- Получаем текущие данные о таблице:
		--	* Используется для нее CDC
		--	* Идентификатор объекта
		--	* Дата последнего изменения объекта
		DECLARE 
			@currentCDCEnabled bit = 0,
			@currentTableObjectId int,
			@currentTableSchemaLastChangeDate datetime2(0);
		SELECT 
			@currentCDCEnabled = tb.is_tracked_by_cdc,
			@currentTableObjectId = tb.object_id,
			@currentTableSchemaLastChangeDate = 			
				CASE WHEN create_date > modify_date THEN create_date
					ELSE modify_date
				END
		FROM sys.tables tb
			INNER JOIN sys.schemas s 
			on s.schema_id = tb.schema_id
		WHERE s.name = @schemaName AND tb.name = @tableName
		
		-- Вариант действий если CDC для объекта уже включен
		IF(@currentCDCEnabled = 1)
		BEGIN
			PRINT 'Для таблицы уже используется CDC: ' + @tableName

			-- Есть изменения в структуре таблицы или объект был пересоздан,
			-- то нужно пересоздать объекты CDC
			IF(-- Структура таблицы изменилась
			   (NOT ISNULL(@tableSchemaLastChangeDate, CAST('2000-01-01 00:00:00' AS datetime2(0))) = @currentTableSchemaLastChangeDate)
			   OR 
			   -- Идентификатор базы данных изменился
			   (NOT ISNULL(@tableObjectId,0) = @currentTableObjectId))
			BEGIN
				PRINT 'Зафиксировано изменение таблицы. Пересоздаем настройки CDC: ' + @tableName

				-- Отключение CDC для таблицы
				EXEC [sys].[sp_cdc_disable_table]
					@source_schema = @schemaName
					,@source_name = @tableName
					,@capture_instance = @captureInstanceCDC

				-- Включаем CDC заново
				EXEC sys.sp_cdc_enable_table
					-- Схема исходной таблицы
					@source_schema = @schemaName,
					-- Имя исходной таблицы
					@source_name   = @tableName,
					-- Имя роли для доступа к данным изменений оставляем по умолчанию
					@role_name     = NULL,
					-- Поддержку запросов для суммарных изменений не используем,
					-- чтобы снизить размеры таблиц CDC и иметь возможность его использования,
					-- даже если у таблицы нет уникального ключа
					@supports_net_changes = 0;
					-- Остальные параметры не используются, т.к. не нужны явно
					-- Имя уникального индекса для идентификации строк (не обязателен)
					--@index_name    = N'<index_name,sysname,index_name>',
					-- Файловая группа для хранения таблиц изменений (не обязателен)
					--@filegroup_name = N'<filegroup_name,sysname,filegroup_name>'

				-- Обновляем служебные поля настроек CDC
				EXECUTE [yy].[UpdateServiceMaintenanceSettingsCDC] 
					@settingId,
					@schemaNameCDC OUTPUT,
					@tableNameCDC OUTPUT,
					@tableNameCDCHistory OUTPUT,
					@captureInstanceCDC OUTPUT;

				-- Переопределяем поток изменнений из стандартной таблицы CDC в собственную
				EXECUTE [yy].[OverrideDataFlowForCDC] 
					@settingId

				PRINT 'Для таблицы включен CDC: ' + @tableName
			END
		END ELSE -- Вариант действий, если CDC для объекта еще не был включен
		BEGIN
			-- Включаем CDC для таблицы, т.к. ранее он не был включен
			EXEC sys.sp_cdc_enable_table
				-- Схема исходной таблицы
				@source_schema = @schemaName,
				-- Имя исходной таблицы
				@source_name   = @tableName,
				-- Имя роли для доступа к данным изменений оставляем по умолчанию
				@role_name     = NULL,
				-- Поддержку запросов для суммарных изменений не используем,
				-- чтобы снизить размеры таблиц CDC и иметь возможность его использования,
				-- даже если у таблицы нет уникального ключа
				@supports_net_changes = 0;
				-- Остальные параметры не используются, т.к. не нужны явно
				-- Имя уникального индекса для идентификации строк (не обязателен)
				--@index_name    = N'<index_name,sysname,index_name>',
				-- Файловая группа для хранения таблиц изменений (не обязателен)
				--@filegroup_name = N'<filegroup_name,sysname,filegroup_name>'

			-- Обновляем служебные поля настроек CDC
			EXECUTE [yy].[UpdateServiceMaintenanceSettingsCDC] 
				@settingId,
				@schemaNameCDC OUTPUT,
				@tableNameCDC OUTPUT,
				@tableNameCDCHistory OUTPUT,
				@captureInstanceCDC OUTPUT;

			-- Переопределяем поток изменнений из стандартной таблицы CDC в собственную
			EXECUTE [yy].[OverrideDataFlowForCDC] 
				@settingId

			PRINT 'Для таблицы включен CDC: ' + @tableName
		END

		FETCH NEXT FROM settingsCursor 
		INTO @settingId, @schemaName, @tableName, @useCDC, 
			@schemaNameCDC, @tableNameCDC, @tableNameCDCHistory, 
			@captureInstanceCDC, @tableObjectId, @tableSchemaLastChangeDate;
	END
	CLOSE settingsCursor;  
	DEALLOCATE settingsCursor;

	-- Обрабатываем настройки, для которых настройка CDC выключена или отсутствует (при этом CDC включен для объекта).
	-- CDC для них должен быть выключен
	DECLARE
		@deleteSchamaName nvarchar(255),
		@deleteTableName nvarchar(255),
		@deleteCaptureInstance nvarchar(255);

	-- Список объектов, для которых CDC включен, но при этом
	-- настройки в таблице MaintenanceSettingsCDC нет
	DECLARE disableCDCObjectsCursor CURSOR  
	FOR
	SELECT
		  SCHEMA_NAME(o.schema_id) AS [SchemaName]
		  ,OBJECT_NAME(ct.[source_object_id]) AS [TableName]
		  ,[capture_instance]
	FROM [cdc].[change_tables] ct
		LEFT JOIN sys.objects o
			ON ct.source_object_id = o.object_id
		LEFT JOIN [yy].MaintenanceSettingsCDC st
			ON SCHEMA_NAME(o.schema_id) = st.SchemaName
				AND OBJECT_NAME(ct.[source_object_id]) = st.TableName
				AND st.UseCDC = 1
	WHERE st.ID IS NULL
	OPEN disableCDCObjectsCursor;

	FETCH NEXT FROM disableCDCObjectsCursor 
	INTO @deleteSchamaName, @deleteTableName, @deleteCaptureInstance;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		-- Проверяем, доступно ли применение настроек CDC в данный момент
		-- Этот момент описан ниже
		EXECUTE [yy].[ApplySettingsCDCAvailable] 
			@availableResult OUTPUT
		IF(@availableResult = 0)
		BEGIN
			RETURN 0;
		END

		PRINT 'Отключение CDC для таблицы, т.к. настройка уже не актуальна: ' + @deleteTableName

		-- Отключение CDC для таблицы
		EXEC [sys].[sp_cdc_disable_table]
			@source_schema = @deleteSchamaName
			,@source_name = @deleteTableName
			,@capture_instance = @deleteCaptureInstance

		FETCH NEXT FROM disableCDCObjectsCursor 
		INTO @deleteSchamaName, @deleteTableName, @deleteCaptureInstance;
	END

	CLOSE disableCDCObjectsCursor;  
	DEALLOCATE disableCDCObjectsCursor;
END
GO
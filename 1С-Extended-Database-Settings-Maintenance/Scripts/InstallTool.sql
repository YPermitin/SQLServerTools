-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Установка и начальная настройка инструмента
-- =============================================================================================================

USE [master]
GO

-- 1. Создание и настройка базы данных

CREATE DATABASE [ExtendedSettingsFor1C]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ExtendedSettingsFor1C', FILENAME = N'E:\Bases\ExtendedSettingsFor1C.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'ExtendedSettingsFor1C_log', FILENAME = N'E:\Bases\ExtendedSettingsFor1C_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE [ExtendedSettingsFor1C]
GO

GRANT SELECT TO [public]
GRANT EXECUTE TO [public]
GRANT CONNECT TO [public]
GO

-- 2. Создание хранимых процедур

CREATE PROCEDURE [dbo].[CompressionSettingsMaintenanceOnIndexCreate] @DatabaseName SYSNAME,
@SchemaName SYSNAME,
@TableName SYSNAME,
@IndexName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @cmd NVARCHAR(MAX)
         ,@msg NVARCHAR(MAX)
         ,@CompressionType NVARCHAR(MAX);

  -- В случае возникновения ошибок продолжаем работу
  SET XACT_ABORT OFF;

  DECLARE compression_settings CURSOR FOR SELECT
    CT.[Name] AS CompressionType
  FROM [dbo].[CompressionSettingsMaintenance] AS T
  LEFT JOIN [dbo].[CompressionType] CT
    ON T.CompressionType = CT.ID
  WHERE
  -- Отбор по базе данных
  (@DatabaseName LIKE DatabaseName)
  -- Отбор по имени таблицы
  -- В ситуациях с реструктуризацией таблиц платформой 1С новые таблицы изначально создаются в окончанием NG в имени.
  -- Поэтому искать настройки со связанной таблицей необходимо с учетом этого окончания в именах таблиц.
  AND (@TableName LIKE TableName
  OR @TableName LIKE TableName + 'NG')
  -- Отбор по имени индекса. Для сжатия таблицы он должен быть пустым
  AND (@IndexName LIKE IndexName
  OR @IndexName LIKE IndexName + 'NG')
  AND IndexName NOT LIKE ''
  -- Только активные правила
  AND IsActive = 1;

  OPEN compression_settings;

  FETCH NEXT FROM compression_settings
  INTO @CompressionType;

  WHILE @@FETCH_STATUS = 0
  BEGIN

  BEGIN TRY

    SET @cmd =
    'USE ' + @DatabaseName + ';' + '
	
				ALTER INDEX [' + @IndexName + '] ON [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + @CompressionType + ')
				';

    EXEC sp_executesql @cmd;

    SELECT
      @msg = 'Trigger CompressionSettingsMaintenanceOnIndexCreate executed!';

    EXEC [dbo].[LogInfo] @DatabaseName
                        ,@TableName
                        ,@IndexName
                        ,@msg
                        ,@cmd

  END TRY
  BEGIN CATCH
    SELECT
      @msg = 'Trigger CompressionSettingsMaintenanceOnIndexCreate failed! Error: ' + ERROR_MESSAGE()
    EXEC [dbo].[LogError] @DatabaseName
                         ,@TableName
                         ,@IndexName
                         ,@msg
                         ,@cmd

  END CATCH

  FETCH NEXT FROM compression_settings
  INTO @CompressionType;
  END

  CLOSE compression_settings;
  DEALLOCATE compression_settings;

  -- Возвращаем значение по умолчанию для ситуаций с ошибками в транзакции
  SET XACT_ABORT ON;

END
GO

CREATE PROCEDURE [dbo].[CompressionSettingsMaintenanceOnTableCreate]
	@DatabaseName SYSNAME,
	@SchemaName SYSNAME,
	@TableName SYSNAME	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @cmd nvarchar(max)
			,@msg nvarchar(max)
			,@CompressionType nvarchar(max);

	-- В случае возникновения ошибок продолжаем работу
	SET XACT_ABORT OFF;
	
	DECLARE compression_settings CURSOR FOR 
	SELECT CT.[Name] AS CompressionType
	FROM [dbo].[CompressionSettingsMaintenance] AS T
		LEFT JOIN [dbo].[CompressionType] CT
		ON T.CompressionType = CT.ID
	WHERE 
		-- Отбор по базе данных
		(@DatabaseName LIKE DatabaseName)
		-- Отбор по имени таблицы
		-- В ситуациях с реструктуризацией таблиц платформой 1С новые таблицы изначально создаются в окончанием NG в имени.
		-- Поэтому искать настройки со связанной таблицей необходимо с учетом этого окончания в именах таблиц.
		AND (@TableName LIKE TableName OR @TableName LIKE TableName + 'NG')
		-- Отбор по имени индекса. Для сжатия таблицы он должен быть пустым
		AND IndexName = ''
		-- Только активные правила
		AND IsActive = 1;

	OPEN compression_settings;  

	FETCH NEXT FROM compression_settings   
	INTO @CompressionType;

	WHILE @@FETCH_STATUS = 0  
	BEGIN 
			
		BEGIN TRY
				
			SET @cmd = 
				'USE ' + @DatabaseName + ';' + '
	
				ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + @CompressionType + ')
				';
						
			EXEC sp_executesql @cmd;				

			SELECT @msg = 'Trigger CompressionSettingsMaintenanceOnTableCreate executed!';

			EXEC [dbo].[LogInfo] 
					@DatabaseName
					,@TableName
					,''
					,@msg
					,@cmd
												
		END TRY
		BEGIN CATCH 
			SELECT @msg = 'Trigger CompressionSettingsMaintenanceOnTableCreate failed! Error: ' + ERROR_MESSAGE()
			EXEC [dbo].[LogError] 
				@DatabaseName
				,@TableName
				,''
				,@msg
				,@cmd
				
		END CATCH

		FETCH NEXT FROM compression_settings   
		INTO @CompressionType;
	END

	CLOSE compression_settings;  
	DEALLOCATE compression_settings; 

	-- Возвращаем значение по умолчанию для ситуаций с ошибками в транзакции
	SET XACT_ABORT ON;

END
GO

CREATE PROCEDURE [dbo].[CustomSettingsMaintenanceOnIndexCreate] @DatabaseName SYSNAME,
@SchemaName SYSNAME,
@TableName SYSNAME,
@IndexName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @UnplatformIndex INT = 0;
  EXECUTE [dbo].[IsUnplatformIndex] @DatabaseName
                                   ,@SchemaName
                                   ,@TableName
                                   ,@IndexName
                                   ,@UnplatformIndex OUTPUT;

  IF (@UnplatformIndex = 0)
  BEGIN
    EXECUTE [dbo].[CustomSettingsMaintenanceRebuildDisabledIndexes] @DatabaseName
                                                                   ,@SchemaName
                                                                   ,@TableName;
  END

  DECLARE @cmd NVARCHAR(1000)
         ,@msg NVARCHAR(MAX)
         ,@RuleID INT = 0
         ,@EventType INT = 5; -- Событие "При создании индекса"

  -- В случае возникновения ошибок продолжаем работу
  SET XACT_ABORT OFF;

  DECLARE index_rules_on_index_create CURSOR FOR SELECT
    Command
   ,ID
  FROM [dbo].[CustomSettingsMaintenance] AS T
  WHERE
  -- Отбор по базе данных
  (@DatabaseName LIKE DatabaseName)
  -- Отбор по имени таблицы
  -- В ситуациях с реструктуризацией таблиц платформой 1С новые таблицы изначально создаются в окончанием NG в имени.
  -- Поэтому искать настройки со связанной таблицей необходимо с учетом этого окончания в именах таблиц.
  AND (@TableName LIKE TableName
  OR @TableName LIKE TableName + 'NG')
  -- Фильтр по имени индекса (опционально)
  AND (@IndexName LIKE IndexName
  OR @IndexName LIKE IndexName + 'NG')
  -- Только активные правила
  AND IsActive = 1
  -- Фильтр по событию (создания таблицы, создания индекса и т.д.)
  AND EventType = @EventType
  ORDER BY [Priority], [ID];

  OPEN index_rules_on_index_create;

  FETCH NEXT FROM index_rules_on_index_create
  INTO @cmd, @RuleID;

  EXEC xp_logevent 60000
                  ,'OO'
                  ,informational;

  WHILE @@FETCH_STATUS = 0
  BEGIN

  EXEC xp_logevent 60000
                  ,'GO'
                  ,informational;

  BEGIN TRY

    SET @cmd =
    'USE ' + @DatabaseName + ';' + '
				
				' + @cmd + '
				';

    SET @cmd = REPLACE(@cmd, '{TableName}', @TableName)
    SET @cmd = REPLACE(@cmd, '{IndexName}', @IndexName)

    EXEC sp_executesql @cmd;

    SELECT
      @msg = 'Trigger CustomSettingsMaintenanceOnIndexCreate executed!';

    EXEC [dbo].[LogInfo] @DatabaseName
                        ,@TableName
                        ,@IndexName
                        ,@msg
                        ,@cmd;

    IF (@RuleID > 0)
    BEGIN
      UPDATE [dbo].[CustomSettingsMaintenance]
      SET [LastAction] = @msg
         ,[LastActionDate] = GETDATE()
      WHERE [ID] = @RuleID;
    END
  END TRY
  BEGIN CATCH
    SELECT
      @msg = 'Trigger CustomSettingsMaintenanceOnIndexCreate failed! Error: ' + ERROR_MESSAGE()
    EXEC [dbo].[LogError] @DatabaseName
                         ,@TableName
                         ,@IndexName
                         ,@msg
                         ,@cmd

    -- Если есть идентификатор обрабатываемого правила,
    -- то автоматически отключаем его из-за возникновения ошибки
    IF (@RuleID > 0)
    BEGIN
      UPDATE [dbo].[CustomSettingsMaintenance]
      SET [IsActive] = 0
         ,[LastAction] = @msg
         ,[LastActionDate] = GETDATE()
      WHERE [ID] = @RuleID;
    END

  END CATCH

  FETCH NEXT FROM index_rules_on_index_create
  INTO @cmd, @RuleID;
  END

  CLOSE index_rules_on_index_create;
  DEALLOCATE index_rules_on_index_create;

  -- Возвращаем значение по умолчанию для ситуаций с ошибками в транзакции
  SET XACT_ABORT ON;

  EXECUTE [dbo].[CompressionSettingsMaintenanceOnIndexCreate] @DatabaseName
                                                             ,@SchemaName
                                                             ,@TableName
                                                             ,@IndexName

END
GO

CREATE PROCEDURE [dbo].[CustomSettingsMaintenanceOnTableCreate] @DatabaseName SYSNAME,
@SchemaName SYSNAME,
@TableName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @cmd NVARCHAR(MAX)
         ,@msg NVARCHAR(MAX)
         ,@RuleID INT = 0
         ,@EventType INT = 4
         ,@IndexName SYSNAME = NULL; -- Событие "При создании таблицы"

  -- В случае возникновения ошибок продолжаем работу
  SET XACT_ABORT OFF;

  DECLARE index_rules_on_table_create CURSOR FOR SELECT
    Command
   ,IndexName
   ,ID
  FROM [dbo].[CustomSettingsMaintenance] AS T
  WHERE
  -- Отбор по базе данных
  (@DatabaseName LIKE DatabaseName)
  -- Отбор по имени таблицы
  -- В ситуациях с реструктуризацией таблиц платформой 1С новые таблицы изначально создаются в окончанием NG в имени.
  -- Поэтому искать настройки со связанной таблицей необходимо с учетом этого окончания в именах таблиц.
  AND (@TableName LIKE TableName
  OR @TableName LIKE TableName + 'NG')
  -- Только активные правила
  AND IsActive = 1
  -- Фильтр по событию (создания таблицы, создания индекса и т.д.)
  AND EventType = @EventType
  ORDER BY [Priority], [ID];

  OPEN index_rules_on_table_create;

  FETCH NEXT FROM index_rules_on_table_create
  INTO @cmd, @IndexName, @RuleID;

  WHILE @@FETCH_STATUS = 0
  BEGIN

  BEGIN TRY

    SET @cmd =
    'USE ' + @DatabaseName + ';' + '
				' + @cmd + '
				
				IF EXISTS(SELECT [name]
						FROM sys.indexes 
						WHERE [name] LIKE ''{IndexName}'' 
						AND OBJECT_NAME(object_id) = ''{TableName}'')
				BEGIN
					ALTER INDEX [{IndexName}] ON [dbo].[{TableName}] DISABLE;
				END
				';

    SET @cmd = REPLACE(@cmd, '{TableName}', @TableName)
    SET @cmd = REPLACE(@cmd, '{IndexName}', @IndexName)

    EXEC sp_executesql @cmd;

    SELECT
      @msg = 'Trigger CustomSettingsMaintenanceOnTableCreate executed!';

    EXEC [dbo].[LogInfo] @DatabaseName
                        ,@TableName
                        ,@IndexName
                        ,@msg
                        ,@cmd

    IF (@RuleID > 0)
    BEGIN
      UPDATE [dbo].[CustomSettingsMaintenance]
      SET [LastAction] = @msg
         ,[LastActionDate] = GETDATE()
      WHERE [ID] = @RuleID;
    END

  END TRY
  BEGIN CATCH
    SELECT
      @msg = 'Trigger CustomSettingsMaintenanceOnTableCreate failed! Error: ' + ERROR_MESSAGE()
    EXEC [dbo].[LogError] @DatabaseName
                         ,@TableName
                         ,@IndexName
                         ,@msg
                         ,@cmd

    -- Если есть идентификатор обрабатываемого правила,
    -- то автоматически отключаем его из-за возникновения ошибки
    IF (@RuleID > 0)
    BEGIN
      UPDATE [dbo].[CustomSettingsMaintenance]
      SET [IsActive] = 0
         ,[LastAction] = @msg
         ,[LastActionDate] = GETDATE()
      WHERE [ID] = @RuleID;
    END

  END CATCH

  FETCH NEXT FROM index_rules_on_table_create
  INTO @cmd, @IndexName, @RuleID;
  END

  CLOSE index_rules_on_table_create;
  DEALLOCATE index_rules_on_table_create;

  -- Возвращаем значение по умолчанию для ситуаций с ошибками в транзакции
  SET XACT_ABORT ON;

  EXECUTE [dbo].[CompressionSettingsMaintenanceOnTableCreate] @DatabaseName
                                                             ,@SchemaName
                                                             ,@TableName

END
GO

CREATE PROCEDURE [dbo].[CustomSettingsMaintenanceRebuildDisabledIndexes] @DatabaseName SYSNAME,
@SchemaName SYSNAME,
@TableName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @IndexName SYSNAME
         ,@cmd NVARCHAR(MAX);

  DECLARE index_to_enable CURSOR FOR SELECT
    IndexName
  FROM [dbo].[CustomSettingsMaintenance]
  WHERE DatabaseName = @DatabaseName
  AND (@TableName LIKE TableName
  OR @TableName LIKE TableName + 'NG')
  AND IsActive = 1
  -- Индексы созданные при создании таблиц
  AND EventType = 4;

  OPEN index_to_enable;

  FETCH NEXT FROM index_to_enable
  INTO @IndexName;

  WHILE @@FETCH_STATUS = 0
  BEGIN

  SET @cmd =
  'USE ' + @DatabaseName + ';' + '
			IF EXISTS(SELECT i.name AS Index_Name
				FROM sys.indexes i
				INNER JOIN sys.objects o ON i.object_id = o.object_id
				INNER JOIN sys.schemas sc ON o.schema_id = sc.schema_id
				WHERE o.name = ''{TableName}''
					AND i.name IS NOT NULL
					AND o.type = ''U''
					AND i.is_disabled = 1)
			BEGIN
				ALTER INDEX [{IndexName}] ON [dbo].[{TableName}] REBUILD;
			END
			';
  SET @cmd = REPLACE(@cmd, '{TableName}', @TableName)
  SET @cmd = REPLACE(@cmd, '{IndexName}', @IndexName)

  EXEC sp_executesql @cmd;

  FETCH NEXT FROM index_to_enable
  INTO @IndexName;
  END

  CLOSE index_to_enable;
  DEALLOCATE index_to_enable;

END
GO

CREATE PROCEDURE [dbo].[IsUnplatformIndex] @DatabaseName SYSNAME,
@SchemaName SYSNAME,
@TableName SYSNAME,
@IndexName SYSNAME,
@UnplatformIndex INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  SET @UnplatformIndex = 0;
  IF EXISTS (SELECT
        IndexName
      FROM [dbo].[CustomSettingsMaintenance]
      WHERE DatabaseName = @DatabaseName
      AND (@TableName LIKE TableName
      OR @TableName LIKE TableName + 'NG')
      AND IsActive = 1
      AND (@IndexName = IndexName
      OR @IndexName = IndexName + 'NG')
      -- Индексы созданные при создании таблиц
      AND EventType = 4)
  BEGIN
    SET @UnplatformIndex = 1;
  END
END
GO

CREATE PROCEDURE [dbo].[LogError] @DatabaseName NVARCHAR(250),
@TableName NVARCHAR(250),
@IndexName NVARCHAR(250),
@message NVARCHAR(MAX),
@command NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO [dbo].[EventLog] ([DatabaseName]
  , [TableName]
  , [Message]
  , [Command]
  , [Severity]
  , [Period]
  , [IndexName])
    VALUES (@DatabaseName, @TableName, @message, @command, 'ERROR', GETDATE(), @IndexName)
END
GO

CREATE PROCEDURE [dbo].[LogInfo] @DatabaseName NVARCHAR(250),
@TableName NVARCHAR(250),
@IndexName NVARCHAR(250),
@message NVARCHAR(MAX),
@command NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO [dbo].[EventLog] ([DatabaseName]
  , [TableName]
  , [Message]
  , [Command]
  , [Severity]
  , [Period]
  , [IndexName])
    VALUES (@DatabaseName, @TableName, @message, @command, 'INFORMATIONAL', GETDATE(), @IndexName)
END
GO

CREATE PROCEDURE [dbo].[LogWarn] @DatabaseName NVARCHAR(250),
@TableName NVARCHAR(250),
@IndexName NVARCHAR(250),
@message NVARCHAR(MAX),
@command NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO [dbo].[EventLog] ([DatabaseName]
  , [TableName]
  , [Message]
  , [Command]
  , [Severity]
  , [Period]
  , [IndexName])
    VALUES (@DatabaseName, @TableName, @message, @command, 'WARNING', GETDATE(), @IndexName)
END
GO

-- 3. Создание таблиц

CREATE TABLE [dbo].[EventType] (
  [ID] [int] NOT NULL,
  [Name] [nvarchar](250) NOT NULL,
  CONSTRAINT [PK_EventType] PRIMARY KEY CLUSTERED ([ID])
)
ON [PRIMARY]
GO

INSERT [dbo].[EventType] ([ID], [Name]) VALUES (4, N'On Table Create')
GO
INSERT [dbo].[EventType] ([ID], [Name]) VALUES (5, N'On Index Create')
GO

CREATE TRIGGER [EventType_Block_Cnanges]
ON [dbo].[EventType]
FOR INSERT, UPDATE
AS
	RAISERROR('Запрещено добавлять / изменять значения!', 16, 10)
GO

CREATE TABLE [dbo].[CustomSettingsMaintenance] (
  [DatabaseName] [nvarchar](250) NOT NULL,
  [TableName] [nvarchar](250) NOT NULL,
  [IndexName] [nvarchar](250) NOT NULL,
  [IsActive] [numeric](1) NOT NULL,
  [Command] [nvarchar](max) NOT NULL,
  [ID] [int] IDENTITY,
  [Description] [nvarchar](max) NULL,
  [LastAction] [nvarchar](150) NULL,
  [EventType] [int] NULL,
  [LastActionDate] [datetime] NULL,
  [Priority] [int] NULL,
  CONSTRAINT [PK_UnplatformIndexMaintenance] PRIMARY KEY NONCLUSTERED ([ID]),
  CONSTRAINT [Combinations of DatabaseName, TableName, IndexName must be unique for create indexs setting] UNIQUE ([DatabaseName], [TableName], [IndexName])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [UnplatformIndexMaintenanceByDims]
  ON [dbo].[CustomSettingsMaintenance] ([DatabaseName], [TableName], [IndexName], [IsActive], [ID])
  ON [PRIMARY]
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]
  ADD CONSTRAINT [FK_UnplatformIndexMaintenance_To_EventType] FOREIGN KEY ([EventType]) REFERENCES [dbo].[EventType] ([ID])
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]  WITH CHECK ADD  CONSTRAINT [CkeckIndexNameTemplate] CHECK  (([Command] like '%{IndexName}%'))
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]  WITH CHECK ADD  CONSTRAINT [CkeckTableNameTemplate] CHECK  (([Command] like '%{TableName}%'))
GO

CREATE TABLE [dbo].[CompressionType] (
  [ID] [int] NOT NULL,
  [Name] [nvarchar](150) NOT NULL,
  CONSTRAINT [PK_CompressionType] PRIMARY KEY CLUSTERED ([ID])
)
ON [PRIMARY]
GO

INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (1, N'None')
GO
INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (2, N'Row')
GO
INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (3, N'Page')
GO

CREATE TRIGGER [CompressionType_Block_Cnanges]
ON [dbo].[CompressionType]
FOR INSERT, UPDATE
AS
	RAISERROR('Запрещено добавлять / изменять значения!', 16, 10)
GO

CREATE TABLE [dbo].[CompressionSettingsMaintenance] (
  [ID] [int] IDENTITY,
  [DatabaseName] [nvarchar](100) NOT NULL,
  [TableName] [nvarchar](100) NOT NULL,
  [IndexName] [nvarchar](100) NOT NULL,
  [CompressionType] [int] NOT NULL,
  [IsActive] [int] NOT NULL,
  CONSTRAINT [PK_CompressionSettingsMaintenance] PRIMARY KEY NONCLUSTERED ([ID])
)
ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [CompressionSettingsMaintenanceByDims]
  ON [dbo].[CompressionSettingsMaintenance] ([DatabaseName], [TableName], [IndexName])
  ON [PRIMARY]
GO

ALTER TABLE [dbo].[CompressionSettingsMaintenance]
  ADD CONSTRAINT [FK_CompressionSettingsMaintenance_To_CompressionType] FOREIGN KEY ([CompressionType]) REFERENCES [dbo].[CompressionType] ([ID])
GO

CREATE TABLE [dbo].[EventLog] (
  [ID] [int] IDENTITY,
  [DatabaseName] [nvarchar](250) NOT NULL,
  [TableName] [nvarchar](250) NOT NULL,
  [Message] [nvarchar](max) NOT NULL,
  [Command] [nvarchar](max) NOT NULL,
  [Severity] [nvarchar](25) NOT NULL,
  [Period] [datetime] NOT NULL,
  [IndexName] [nvarchar](250) NOT NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndexByDims]
  ON [dbo].[EventLog] ([Period], [DatabaseName], [Severity], [TableName], [ID])
  ON [PRIMARY]
GO

-- 4. Создание представлений

CREATE VIEW [dbo].[CompressionSettingsMaintenanceCommands]
WITH SCHEMABINDING
AS
	SELECT
	  [DatabaseName]
	 ,[TableName]
	 ,[IndexName]
	 ,ct.[Name] AS [CompressionType]
	 ,[IsActive]
	 ,CASE
		WHEN IndexName = '' THEN 'ALTER TABLE [dbo].[' + [TableName] + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + ct.[Name] + ')'
		ELSE 'ALTER INDEX [' + [IndexName] + '] ON [dbo].[' + [TableName] + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + ct.[Name] + ')'
	  END AS [Command]
	FROM [dbo].[CompressionSettingsMaintenance] c
	LEFT JOIN [dbo].[CompressionType] ct
	  ON c.[CompressionType] = ct.ID
GO

CREATE VIEW [dbo].[CustomSettingsMaintenanceCommands]
WITH SCHEMABINDING
AS
	SELECT
	  [DatabaseName]
	 ,[TableName]
	 ,[IndexName]
	 ,[Description]
	 ,[IsActive]
	 ,'/*
		  Будет создан индекс ''' + [IndexName] + ''' для таблицы ''' + [TableName] + '''
		  Описание: ' + COALESCE([Description], '--') + '
		  */' + '
		  IF NOT EXISTS(
			SELECT TOP 1
				1
			FROM SYS.INDEXES i
			where i.Name = ''' + [IndexName] + '''
				and I.Object_id = OBJECT_ID(''' + [TableName] + '''))	
			BEGIN
		  ' + LTRIM(RTRIM(REPLACE(REPLACE([Command], '{TableName}', [TableName]), '{IndexName}', [IndexName]))) + '
		  END
		  GO' AS [CreateIndexCommand]
 	,'/*
		  Проверка индекса ''' + [IndexName] + ''' для таблицы ''' + [TableName] + '''
		  Описание: ' + COALESCE([Description], '--') + '
		  */' + '
		  IF NOT EXISTS(
			SELECT TOP 1
				1
			FROM SYS.INDEXES i
			where i.Name = ''' + [IndexName] + '''
				and I.Object_id = OBJECT_ID(''' + [TableName] + '''))	
				PRINT ''Будет создан индекс ' + [IndexName] + ' для таблицы ' + [TableName] + '''					
			GO' AS [CheckIndexCommand]
FROM [dbo].[CustomSettingsMaintenance]
GO

CREATE VIEW [dbo].[ErrorLog]
AS
SELECT
  [ID]
 ,[DatabaseName]
 ,[TableName]
 ,[Message]
 ,[Command]
 ,[Severity]
 ,[Period]
 ,[IndexName]
FROM [dbo].[EventLog]
WHERE [Severity] = 'ERROR'
GO

CREATE VIEW [dbo].[InfoLog]
AS
SELECT
  [ID]
 ,[DatabaseName]
 ,[TableName]
 ,[Message]
 ,[Command]
 ,[Severity]
 ,[Period]
 ,[IndexName]
FROM [dbo].[EventLog]
WHERE [Severity] = 'INFORMATIONAL'
GO

CREATE VIEW [dbo].[WarningLog]
AS
SELECT
  [ID]
 ,[DatabaseName]
 ,[TableName]
 ,[Message]
 ,[Command]
 ,[Severity]
 ,[Period]
 ,[IndexName]
FROM [dbo].[EventLog]
WHERE [Severity] = 'WARNING'
GO

-- 5. Создание глобальных триггеров

USE [master]
GO

CREATE TRIGGER [CustomSettingsMaintenance_OnIndexCreate]
ON ALL SERVER
AFTER CREATE_INDEX
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SchemaName SYSNAME,
		@TableName SYSNAME,
		@DatabaseName SYSNAME,
		@IndexName SYSNAME;

    	SELECT @TableName = EVENTDATA().value('(/EVENT_INSTANCE/TargetObjectName)[1]','SYSNAME')
    	SELECT @SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]','SYSNAME')
	SELECT @IndexName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','SYSNAME')
	SELECT @DatabaseName = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','SYSNAME');

	EXEC [ExtendedSettingsFor1C].[dbo].[CustomSettingsMaintenanceOnIndexCreate]
		@DatabaseName = @DatabaseName,
		@SchemaName = @SchemaName,
		@TableName = @TableName,
		@IndexName = @IndexName

END
GO

ENABLE TRIGGER [CustomSettingsMaintenance_OnIndexCreate] ON ALL SERVER
GO

CREATE TRIGGER [CustomSettingsMaintenance_OnTableCreate]
ON ALL SERVER 
AFTER CREATE_TABLE 
AS

BEGIN
	SET NOCOUNT ON

	DECLARE @SchemaName SYSNAME,
		@TableName SYSNAME,
		@DatabaseName SYSNAME,
		@cmd nvarchar(max)

    	SELECT @TableName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','SYSNAME')
   	SELECT @SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]','SYSNAME')
	SELECT @DatabaseName = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','SYSNAME');

	EXEC [ExtendedSettingsFor1C].[dbo].[CustomSettingsMaintenanceOnTableCreate]
		@DatabaseName = @DatabaseName,
		@SchemaName = @SchemaName,
		@TableName = @TableName

END
GO

ENABLE TRIGGER [CustomSettingsMaintenance_OnTableCreate] ON ALL SERVER
GO

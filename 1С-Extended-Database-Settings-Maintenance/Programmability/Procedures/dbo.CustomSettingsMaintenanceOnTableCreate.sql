-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Обработчик произвольных правил объектов баз данных при возникновении события создания таблиц
-- =============================================================================================================
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

  -- Если курсор уже существует, значит событие сгенерировано рекурсивно
  -- В этом случае пропускаем обработку события
  IF CURSOR_STATUS('global','index_rules_on_table_create')>=-1
  BEGIN
    RETURN
  END

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

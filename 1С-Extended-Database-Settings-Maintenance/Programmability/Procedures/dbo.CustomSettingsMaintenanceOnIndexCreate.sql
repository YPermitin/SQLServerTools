-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Обработчик произвольных правил объектов баз данных при возникновении события создания индекса
-- =============================================================================================================
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

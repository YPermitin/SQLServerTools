SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Процедура для включения индексов, которые были созданы по произвольным правилам
-- =============================================================================================================
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
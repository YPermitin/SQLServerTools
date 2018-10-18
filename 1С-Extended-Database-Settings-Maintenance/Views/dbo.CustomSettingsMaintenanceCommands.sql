-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Представление для формирования команд произвольных правил объектов баз данных
-- =============================================================================================================
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

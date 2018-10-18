-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Представление для формирования списка команд поддержки сжатия объектов баз данных
-- =============================================================================================================
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

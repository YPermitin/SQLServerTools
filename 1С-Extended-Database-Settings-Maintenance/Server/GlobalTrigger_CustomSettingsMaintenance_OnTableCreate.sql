-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Глобальный тригер на сервере для события создания таблицы
-- =============================================================================================================
USE [master]
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



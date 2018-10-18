-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Глобальный тригер на сервере для события создания индексов
-- =============================================================================================================
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



-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Процедура для определения был ли индекс создан по произвольным правилам
-- =============================================================================================================
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

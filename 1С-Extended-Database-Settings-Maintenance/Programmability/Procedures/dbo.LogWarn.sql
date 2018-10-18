-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Процедура для создания записи с предупреждением в таблице логов
-- =============================================================================================================
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

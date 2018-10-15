SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Представление для просмотра информации в логах
-- =============================================================================================================
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
FROM [ExtendedSettings].[dbo].[EventLog]
WHERE [Severity] = 'INFORMATIONAL'
GO
-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для записей логов
-- =============================================================================================================
CREATE TABLE [dbo].[EventLog] (
  [ID] [int] IDENTITY,
  [DatabaseName] [nvarchar](250) NOT NULL,
  [TableName] [nvarchar](250) NOT NULL,
  [Message] [nvarchar](max) NOT NULL,
  [Command] [nvarchar](max) NOT NULL,
  [Severity] [nvarchar](25) NOT NULL,
  [Period] [datetime] NOT NULL,
  [IndexName] [nvarchar](250) NOT NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndexByDims]
  ON [dbo].[EventLog] ([Period], [DatabaseName], [Severity], [TableName], [ID])
  ON [PRIMARY]
GO
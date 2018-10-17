-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для хранения списка доступных методов сжатия объектов баз данных
-- =============================================================================================================
CREATE TABLE [dbo].[CompressionType] (
  [ID] [int] NOT NULL,
  [Name] [nvarchar](150) NOT NULL,
  CONSTRAINT [PK_CompressionType] PRIMARY KEY CLUSTERED ([ID])
)
ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

SET IDENTITY_INSERT [dbo].[CompressionType] ON 
GO
INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (1, N'None')
GO
INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (2, N'Row')
GO
INSERT [dbo].[CompressionType] ([ID], [Name]) VALUES (3, N'Page')
GO
SET IDENTITY_INSERT [dbo].[CompressionType] OFF

CREATE TRIGGER [CompressionType_Block_Cnanges]
ON [dbo].[CompressionType]
FOR INSERT, UPDATE
AS
	RAISERROR('Запрещено добавлять / изменять значения!', 16, 10)
GO
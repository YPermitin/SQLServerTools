-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для хранения списка доступных методов сжатия объектов баз данных
-- =============================================================================================================
CREATE TABLE [dbo].[CompressionType] (
  [ID] [int] IDENTITY,
  [Name] [nvarchar](150) NOT NULL,
  CONSTRAINT [PK_CompressionType] PRIMARY KEY CLUSTERED ([ID])
)
ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE TRIGGER [CompressionType_Block_Cnanges]
ON [dbo].[CompressionType]
FOR INSERT, UPDATE
AS
	RAISERROR('Запрещено добавлять / изменять значения!', 16, 10)
GO
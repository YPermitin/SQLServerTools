-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для хранения списка возможных типов событий записей логов
-- =============================================================================================================
CREATE TABLE [dbo].[EventType] (
  [ID] [int] IDENTITY,
  [Name] [nvarchar](250) NOT NULL,
  CONSTRAINT [PK_EventType] PRIMARY KEY CLUSTERED ([ID])
)
ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE TRIGGER [EventType_Block_Cnanges]
ON [dbo].[EventType]
FOR INSERT, UPDATE
AS
	RAISERROR('Запрещено добавлять / изменять значения!', 16, 10)
GO
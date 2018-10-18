/* =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для хранения произвольных правил для объектов баз данных
-- =============================================================================================================*/
CREATE TABLE [dbo].[CustomSettingsMaintenance] (
  [DatabaseName] [nvarchar](250) NOT NULL,
  [TableName] [nvarchar](250) NOT NULL,
  [IndexName] [nvarchar](250) NOT NULL,
  [IsActive] [numeric](1) NOT NULL,
  [Command] [nvarchar](max) NOT NULL,
  [ID] [int] IDENTITY,
  [Description] [nvarchar](max) NULL,
  [LastAction] [nvarchar](150) NULL,
  [EventType] [int] NULL,
  [LastActionDate] [datetime] NULL,
  [Priority] [int] NULL,
  CONSTRAINT [PK_UnplatformIndexMaintenance] PRIMARY KEY NONCLUSTERED ([ID]),
  CONSTRAINT [Combinations of DatabaseName, TableName, IndexName must be unique for create indexs setting] UNIQUE ([DatabaseName], [TableName], [IndexName])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [UnplatformIndexMaintenanceByDims]
  ON [dbo].[CustomSettingsMaintenance] ([DatabaseName], [TableName], [IndexName], [IsActive], [ID])
  ON [PRIMARY]
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]
  ADD CONSTRAINT [FK_UnplatformIndexMaintenance_To_EventType] FOREIGN KEY ([EventType]) REFERENCES [dbo].[EventType] ([ID])
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]  WITH CHECK ADD  CONSTRAINT [CkeckIndexNameTemplate] CHECK  (([Command] like '%{IndexName}%'))
GO

ALTER TABLE [dbo].[CustomSettingsMaintenance]  WITH CHECK ADD  CONSTRAINT [CkeckTableNameTemplate] CHECK  (([Command] like '%{TableName}%'))
GO

-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Таблица для хранения настроек сжатия для объектов баз данных
-- =============================================================================================================
CREATE TABLE [dbo].[CompressionSettingsMaintenance] (
  [ID] [int] IDENTITY,
  [DatabaseName] [nvarchar](100) NOT NULL,
  [TableName] [nvarchar](100) NOT NULL,
  [IndexName] [nvarchar](100) NOT NULL,
  [CompressionType] [int] NOT NULL,
  [IsActive] [int] NOT NULL,
  CONSTRAINT [PK_CompressionSettingsMaintenance] PRIMARY KEY NONCLUSTERED ([ID])
)
ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [CompressionSettingsMaintenanceByDims]
  ON [dbo].[CompressionSettingsMaintenance] ([DatabaseName], [TableName], [IndexName])
  ON [PRIMARY]
GO

ALTER TABLE [dbo].[CompressionSettingsMaintenance]
  ADD CONSTRAINT [FK_CompressionSettingsMaintenance_To_CompressionType] FOREIGN KEY ([CompressionType]) REFERENCES [dbo].[CompressionType] ([ID])
GO
-- =============================================================================================================
-- Author:		Carlo I.V. (suckawaythepen@gmail.com)
-- Create date: 2020-05-20
-- Description:	Скрипт для заполнения таблицы CompressionSettingsMaintenance всеми таблицами определенной БД
-- OurDB - замените на название вашей БД для сжатия
-- =============================================================================================================
USE [ExtendedSettingsFor1C]

INSERT INTO [ExtendedSettingsFor1C].dbo.CompressionSettingsMaintenance ([DatabaseName], [TableName], [IndexName], [CompressionType], [IsActive])
SELECT 'OurDB', [name], '', '3', '1' -- OurDB заменить на наименование вашей БД для сжатия, Индекс не указываем, 3 - соответствует сжатию PAGE, 1 - признак активности
FROM [OurDB].sys.objects WHERE type in (N'U') -- OurDB заменить на наименование вашей БД для сжатия
GO

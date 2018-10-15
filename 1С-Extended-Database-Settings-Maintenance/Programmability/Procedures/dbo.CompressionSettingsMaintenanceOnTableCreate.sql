SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Обработчик правил сжатия объектов баз данных при возникновении события создания таблицы
-- =============================================================================================================
CREATE PROCEDURE [dbo].[CompressionSettingsMaintenanceOnTableCreate]
	@DatabaseName SYSNAME,
	@SchemaName SYSNAME,
	@TableName SYSNAME	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @cmd nvarchar(max)
			,@msg nvarchar(max)
			,@CompressionType nvarchar(max);

	-- В случае возникновения ошибок продолжаем работу
	SET XACT_ABORT OFF;
	
	DECLARE compression_settings CURSOR FOR 
	SELECT CT.[Name] AS CompressionType
	FROM [dbo].[CompressionSettingsMaintenance] AS T
		LEFT JOIN [dbo].[CompressionType] CT
		ON T.CompressionType = CT.ID
	WHERE 
		-- Отбор по базе данных
		(@DatabaseName LIKE DatabaseName)
		-- Отбор по имени таблицы
		-- В ситуациях с реструктуризацией таблиц платформой 1С новые таблицы изначально создаются в окончанием NG в имени.
		-- Поэтому искать настройки со связанной таблицей необходимо с учетом этого окончания в именах таблиц.
		AND (@TableName LIKE TableName OR @TableName LIKE TableName + 'NG')
		-- Отбор по имени индекса. Для сжатия таблицы он должен быть пустым
		AND IndexName = ''
		-- Только активные правила
		AND IsActive = 1;

	OPEN compression_settings;  

	FETCH NEXT FROM compression_settings   
	INTO @CompressionType;

	WHILE @@FETCH_STATUS = 0  
	BEGIN 
			
		BEGIN TRY
				
			SET @cmd = 
				'USE ' + @DatabaseName + ';' + '
	
				ALTER TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ' + @CompressionType + ')
				';
						
			EXEC sp_executesql @cmd;				

			SELECT @msg = 'Trigger CompressionSettingsMaintenanceOnTableCreate executed!';

			EXEC [dbo].[LogInfo] 
					@DatabaseName
					,@TableName
					,''
					,@msg
					,@cmd
												
		END TRY
		BEGIN CATCH 
			SELECT @msg = 'Trigger CompressionSettingsMaintenanceOnTableCreate failed! Error: ' + ERROR_MESSAGE()
			EXEC [dbo].[LogError] 
				@DatabaseName
				,@TableName
				,''
				,@msg
				,@cmd
				
		END CATCH

		FETCH NEXT FROM compression_settings   
		INTO @CompressionType;
	END

	CLOSE compression_settings;  
	DEALLOCATE compression_settings; 

	-- Возвращаем значение по умолчанию для ситуаций с ошибками в транзакции
	SET XACT_ABORT ON;

END
GO
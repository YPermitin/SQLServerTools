ALTER PROCEDURE [dbo].[sp_CreateOrUpdateJobsBySettings]
	@force bit = 0,
	@createDisabled bit = 0,
	@filterTemplateName nvarchar(max) = '%',
	@createGeneralJobs bit = 1,
	@templateGroupName nvarchar(max) = '%',
	@createDatabaseSpecificJobs bit = 1,
	@filterDatabaseSpecificName nvarchar(max) = '%',
	@useDisabledTempletes bit = 0,
	@ignoreDatabaseNameFilter bit = 0,
	@debugMode bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- Поля шаблона
	DECLARE
		@Id int,
		@Enable bit,
		@ApplyTemplateQuery nvarchar(max),
		@Name nvarchar(250),
		@Description nvarchar(512),
		@JobAction nvarchar(max),
		@ScheduleEnable bit,
		@ScheduleFreqType int,
		@ScheduleFreqInterval int,
		@ScheduleFreqSubdayType int,
		@ScheduleFreqSubdayInterval int,
		@ScheduleFreqRelativeInterval int,
		@ScheduleFreqRecurrenceFactor int,
		@ScheduleActiveStartDay int,
		@ScheduleActiveEndDay int,
		@ScheduleActiveStartTime int,
		@ScheduleActiveEndTime int,		
		@VersionDate datetime,
		@TimeoutSec int,
		@SchedulesAdditional nvarchar(max);

	DECLARE
		@jobName nvarchar(250),
		@jobDescription nvarchar(513),
		@jobScript nvarchar(max),
		@currentjobVersionDate datetime,
		@currentJobId uniqueidentifier,
		@JobAlreadyExists bit = 0,
		@msg nvarchar(max);

	IF(@ignoreDatabaseNameFilter = 1
		AND (SELECT COUNT(*) FROM sys.databases WHERE [name] LIKE @filterDatabaseSpecificName) <> 1)
	BEGIN
		SET @msg = 'Для использования параметра @ignoreDatabaseNameFilter нужно указать фильтр @filterDatabaseSpecificName так, чтобы в выборку попадала только одна база данных.';
		THROW 51000, @msg, 1;
	END

	-- Служебные переменные
	DECLARE
		@sql nvarchar(max),
		@currentDatabaseName nvarchar(250);

	DECLARE job_templates_cursor CURSOR  
	FOR SELECT
		   [Id]
		  ,CASE WHEN @createDisabled = 1 THEN 0 ELSE [Enable] END AS [Enable]
		  ,[ApplyTemplateQuery]
		  ,[Name]
		  ,[Description]
		  ,[JobAction]
		  ,[ScheduleEnable]
		  ,[ScheduleFreqType]
		  ,[ScheduleFreqInterval]
		  ,[ScheduleFreqSubdayType]
		  ,[ScheduleFreqSubdayInterval]
		  ,[ScheduleFreqRelativeInterval]
		  ,[ScheduleFreqRecurrenceFactor]
		  ,[ScheduleActiveStartDay]
		  ,[ScheduleActiveEndDay]
		  ,[ScheduleActiveStartTime]
		  ,[ScheduleActiveEndTime]		  
		  ,[VersionDate]
		  ,[TimeoutSec]
		  ,[SchedulesAdditional]
	FROM [dbo].[JobTemplates]
	WHERE ([UseSetting] = 1 OR @useDisabledTempletes = 1)
		-- Фильтр по имени шаблона
		AND [Name] LIKE @filterTemplateName
		-- Создаем общие задания (не привязаны к базам или другим параметрам)
		AND CASE WHEN [ApplyTemplateQuery] IS NULL THEN @createGeneralJobs ELSE 1 END = 1
		-- Создаем задания для конкретных баз данных
		AND CASE WHEN ISNULL([ApplyTemplateQuery],'') LIKE '%AS%[DatabaseName]%' THEN @createDatabaseSpecificJobs ELSE 1 END = 1
		AND ISNULL([TemplateGroupName], '') LIKE @templateGroupName;
	OPEN job_templates_cursor;

	FETCH NEXT FROM job_templates_cursor 
	INTO @Id, @Enable, @ApplyTemplateQuery, @Name, @Description, @JobAction, @ScheduleEnable,
		@ScheduleFreqType,	@ScheduleFreqInterval, @ScheduleFreqSubdayType, @ScheduleFreqSubdayInterval,
		@ScheduleFreqRelativeInterval, @ScheduleFreqRecurrenceFactor, @ScheduleActiveStartDay,
		@ScheduleActiveEndDay, @ScheduleActiveStartTime, @ScheduleActiveEndTime, @VersionDate, @TimeoutSec,
		@SchedulesAdditional;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @Description = @Description + ' (Version date:' + CAST(@VersionDate AS nvarchar(max)) + ')';

		IF(@ApplyTemplateQuery IS NOT NULL)
		BEGIN
			-- Задания создаются по базам данных
			IF(NOT EXISTS(SELECT 
				[name] 
			FROM sys.dm_exec_describe_first_result_set (@ApplyTemplateQuery, NULL, 0)
			WHERE [name] = 'DatabaseName'))
			BEGIN
				PRINT @Name;
				THROW 51000, 'Запрос шаблона не содержит поля DatabaseName.', 1;   
			END

			IF (OBJECT_ID('tempdb..##databasesForJobs') IS NOT NULL)
				DROP Table ##databasesForJobs;
			IF(1 = 0)
			BEGIN
				-- !!! Костыль для поддержания корректного поведения редактора SQL кода,
				-- иначе ругается на несуществующую глобавльную временную таблицу
				--CREATE TABLE ##databasesForJobs (DatabaseName nvarchar(255));
				PRINT 1;
			END
			IF(@ignoreDatabaseNameFilter = 1)
			BEGIN				
				SELECT [name] AS [DatabaseName] INTO ##databasesForJobs  FROM sys.databases WHERE [name] LIKE @filterDatabaseSpecificName;
			END ELSE BEGIN
				SET @sql = CAST('SELECT [DatabaseName] INTO ##databasesForJobs FROM (' AS nvarchar(max)) 
					+ CAST(@ApplyTemplateQuery AS nvarchar(max)) 
					+ CAST(') AS T' AS nvarchar(max))
				EXEC sp_executesql @sql
			END

			DECLARE job_templates_databases_cursor CURSOR FOR
			SELECT [DatabaseName] 
			FROM ##databasesForJobs
			WHERE [DatabaseName] LIKE @filterDatabaseSpecificName;
			OPEN job_templates_databases_cursor;
			FETCH NEXT FROM job_templates_databases_cursor INTO @currentDatabaseName;
			WHILE @@FETCH_STATUS = 0  
			BEGIN
				SET @jobName = REPLACE(@Name, '{DatabaseName}', @currentDatabaseName);
				SET @jobDescription = REPLACE(@Description, '{DatabaseName}', @currentDatabaseName);
				DECLARE @currentJobAction nvarchar(max) = REPLACE(@JobAction, '{DatabaseName}', @currentDatabaseName);
			
				SET @jobAlreadyExists = 0;
				SET @currentJobId = null;
				SET @currentjobVersionDate = null;

				SELECT
					@jobAlreadyExists = 1,
					@currentJobId = sj.job_id,
					@currentjobVersionDate = CASE WHEN sj.date_modified > sj.date_created THEN sj.date_modified ELSE sj.date_created END
				FROM [msdb].[dbo].[sysjobs] sj
				WHERE sj.[name] = @jobName

				-- Если задание уже существует, но в настройках содержится более новая версия,
				-- то удаляем старое задание и создаем заново
				IF(@jobAlreadyExists = 1 AND (@force = 1 OR @VersionDate > @currentjobVersionDate))
				BEGIN
					EXEC msdb.dbo.sp_delete_job 
						@job_id = @currentJobId, 
						@delete_unused_schedule = 1;
					SET @msg = 'Удалено задание: ' + @jobName;
					PRINT @msg;
					SET @jobAlreadyExists = 0;
				END
				
				IF(@jobAlreadyExists = 0)
				BEGIN
					EXECUTE [dbo].[sp_CreateSimpleJob] 
					   @jobName = @jobName
					  ,@jobDescription = @jobDescription
					  ,@jobEnabled = @Enable
					  ,@databaseName = @currentDatabaseName
					  ,@jobAction = @currentJobAction
					  ,@scheduleEnabled = @ScheduleEnable
					  ,@scheduleFreqType = @ScheduleFreqType
					  ,@scheduleFreqInterval = @ScheduleFreqInterval
					  ,@scheduleFreqSubdayType = @ScheduleFreqSubdayType
					  ,@scheduleFreqSubdayInterval = @ScheduleFreqSubdayInterval
					  ,@scheduleFreqRelativeInterval = @ScheduleFreqRelativeInterval
					  ,@scheduleFreqRecurrenceFactor = @ScheduleFreqRecurrenceFactor
					  ,@scheduleActiveStartDate = @ScheduleActiveStartDay
					  ,@scheduleActiveEndDate = @ScheduleActiveEndDay
					  ,@scheduleActiveStartTime = @ScheduleActiveStartTime
					  ,@scheduleActiveEndTime = @ScheduleActiveEndTime
					  ,@jobTimeoutSec = @TimeoutSec
					  ,@schedulesAdditional = @SchedulesAdditional
					  ,@debugMode = @debugMode

					SET @msg = 'Создано задание: ' + @jobName;
					PRINT @msg;
				END

				FETCH NEXT FROM job_templates_databases_cursor INTO @currentDatabaseName;
			END
			CLOSE job_templates_databases_cursor;  
			DEALLOCATE job_templates_databases_cursor;
		END ELSE BEGIN	
			
			SET @jobAlreadyExists = 0;
			SET @currentJobId = null;
			SET @currentjobVersionDate = null;

			SELECT
				@jobAlreadyExists = 1,
				@currentJobId = sj.job_id,
				@currentjobVersionDate = CASE WHEN sj.date_modified > sj.date_created THEN sj.date_modified ELSE sj.date_created END
			FROM [msdb].[dbo].[sysjobs] sj
			WHERE sj.[name] = @Name
			
			-- Если задание уже существует, но в настройках содержится более новая версия,
			-- то удаляем старое задание и создаем заново
			IF(@jobAlreadyExists = 1 AND (@force = 1 OR @VersionDate > @currentjobVersionDate))
			BEGIN
				EXEC msdb.dbo.sp_delete_job 
					@job_id = @currentJobId, 
					@delete_unused_schedule = 1;
				SET @msg = 'Удалено задание: ' + @Name;
				PRINT @msg;
				SET @jobAlreadyExists = 0;
			END

			IF(@jobAlreadyExists = 0)
			BEGIN
				DECLARE @currentDatabase nvarchar(max) = DB_NAME();
				-- Задание создается единое на весь сервер
				EXECUTE [dbo].[sp_CreateSimpleJob] 
					@jobName = @Name
					,@jobDescription = @Description
					,@jobEnabled = @Enable
					,@databaseName = @currentDatabase
					,@jobAction = @JobAction
					,@scheduleEnabled = @ScheduleEnable
					,@scheduleFreqType = @ScheduleFreqType
					,@scheduleFreqInterval = @ScheduleFreqInterval
					,@scheduleFreqSubdayType = @ScheduleFreqSubdayType
					,@scheduleFreqSubdayInterval = @ScheduleFreqSubdayInterval
					,@scheduleFreqRelativeInterval = @ScheduleFreqRelativeInterval
					,@scheduleFreqRecurrenceFactor = @ScheduleFreqRecurrenceFactor
					,@scheduleActiveStartDate = @ScheduleActiveStartDay
					,@scheduleActiveEndDate = @ScheduleActiveEndDay
					,@scheduleActiveStartTime = @ScheduleActiveStartTime
					,@scheduleActiveEndTime = @ScheduleActiveEndTime
					,@jobTimeoutSec = @TimeoutSec
					,@schedulesAdditional = @SchedulesAdditional
					,@debugMode = @debugMode

				SET @msg = 'Создано задание: ' + @Name;
				PRINT @msg;
			END
			
		END

		FETCH NEXT FROM job_templates_cursor 
		INTO @Id, @Enable, @ApplyTemplateQuery, @Name, @Description, @JobAction, @ScheduleEnable,
			@ScheduleFreqType,	@ScheduleFreqInterval, @ScheduleFreqSubdayType, @ScheduleFreqSubdayInterval,
			@ScheduleFreqRelativeInterval, @ScheduleFreqRecurrenceFactor, @ScheduleActiveStartDay,
			@ScheduleActiveEndDay, @ScheduleActiveStartTime, @ScheduleActiveEndTime, @VersionDate, @TimeoutSec,
			@SchedulesAdditional;
	END
	CLOSE job_templates_cursor;  
	DEALLOCATE job_templates_cursor;
END
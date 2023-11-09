ALTER PROCEDURE [dbo].[sp_CreateOrUpdateJobsBySettings]
	@force bit = 0
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
		@TimeoutSec int;

	DECLARE
		@jobName nvarchar(250),
		@jobDescription nvarchar(513),
		@jobScript nvarchar(max),
		@currentjobVersionDate datetime,
		@currentJobId uniqueidentifier,
		@JobAlreadyExists bit = 0;

	-- Служебные переменные
	DECLARE
		@sql nvarchar(max),
		@currentDatabaseName nvarchar(250);

	DECLARE job_templates_cursor CURSOR  
	FOR SELECT
		   [Id]
		  ,[Enable]
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
	FROM [dbo].[JobTemplates]
	WHERE [UseSetting] = 1;
	OPEN job_templates_cursor;

	FETCH NEXT FROM job_templates_cursor 
	INTO @Id, @Enable, @ApplyTemplateQuery, @Name, @Description, @JobAction, @ScheduleEnable,
		@ScheduleFreqType,	@ScheduleFreqInterval, @ScheduleFreqSubdayType, @ScheduleFreqSubdayInterval,
		@ScheduleFreqRelativeInterval, @ScheduleFreqRecurrenceFactor, @ScheduleActiveStartDay,
		@ScheduleActiveEndDay, @ScheduleActiveStartTime, @ScheduleActiveEndTime, @VersionDate, @TimeoutSec;

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
				CREATE TABLE ##databasesForJobs (DatabaseName nvarchar(255));
			END
			SET @sql = CAST('SELECT [DatabaseName] INTO ##databasesForJobs FROM (' AS nvarchar(max)) 
				+ CAST(@ApplyTemplateQuery AS nvarchar(max)) 
				+ CAST(') AS T' AS nvarchar(max))
			EXEC sp_executesql @sql

			DECLARE job_templates_databases_cursor CURSOR  
			FOR	SELECT [DatabaseName] FROM ##databasesForJobs;
			OPEN job_templates_databases_cursor;
			FETCH NEXT FROM job_templates_databases_cursor INTO @currentDatabaseName;
			WHILE @@FETCH_STATUS = 0  
			BEGIN
				SET @jobName = REPLACE(@Name, '{DatabaseName}', @currentDatabaseName);
				SET @jobDescription = REPLACE(@Description, '{DatabaseName}', @currentDatabaseName);
				DECLARE @currentJobAction nvarchar(max) = REPLACE(@JobAction, '{DatabaseName}', @currentDatabaseName);

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
				END

				FETCH NEXT FROM job_templates_databases_cursor INTO @currentDatabaseName;
			END
			CLOSE job_templates_databases_cursor;  
			DEALLOCATE job_templates_databases_cursor;
		END ELSE BEGIN			
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
				SET @jobAlreadyExists = 0;
			END

			IF(@jobAlreadyExists = 0)
			BEGIN
				-- Задание создается единое на весь сервер
				EXECUTE [dbo].[sp_CreateSimpleJob] 
					@jobName = @Name
					,@jobDescription = @Description
					,@jobEnabled = @Enable
					,@databaseName = 'SQLServerMaintenance'
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
			END
		END

		FETCH NEXT FROM job_templates_cursor 
		INTO @Id, @Enable, @ApplyTemplateQuery, @Name, @Description, @JobAction, @ScheduleEnable,
			@ScheduleFreqType,	@ScheduleFreqInterval, @ScheduleFreqSubdayType, @ScheduleFreqSubdayInterval,
			@ScheduleFreqRelativeInterval, @ScheduleFreqRecurrenceFactor, @ScheduleActiveStartDay,
			@ScheduleActiveEndDay, @ScheduleActiveStartTime, @ScheduleActiveEndTime, @VersionDate, @TimeoutSec;
	END
	CLOSE job_templates_cursor;  
	DEALLOCATE job_templates_cursor;
END
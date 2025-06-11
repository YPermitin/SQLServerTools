ALTER PROCEDURE [dbo].[sp_CreateSimpleJob]
	@jobName nvarchar(250),
	@jobDescription nvarchar(max),
	@jobEnabled bit = 1,
	@databaseName sysname,
	@jobAction nvarchar(max),
	@scheduleEnabled bit = 1,
	@scheduleFreqType int = 4,
	@scheduleFreqInterval int = 1,
	@scheduleFreqSubdayType int = 2,
	@scheduleFreqSubdayInterval int = 60,
	@scheduleFreqRelativeInterval int = 0,
	@scheduleFreqRecurrenceFactor int = 0,
	@scheduleActiveStartDate int = 20000101,
	@scheduleActiveEndDate int = 99991231,
	@scheduleActiveStartTime int = 0,
	@scheduleActiveEndTime int = 235959,
	@jobTimeoutSec int = 0,
	@schedulesAdditional nvarchar(max) = NULL,
	@debugMode bit = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE 
		@ReturnCode INT,
		@msg nvarchar(max);

	SET @jobName = REPLACE(@jobName, '{DatabaseName}', @databaseName);
	SET @jobDescription = REPLACE(@jobDescription, '{DatabaseName}', @databaseName);				

	BEGIN TRANSACTION
	
	SELECT @ReturnCode = 0
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories
				   WHERE name=N'[Uncategorized (Local)]' 
				   AND category_class=1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category 
			@class=N'JOB', 
			@type=N'LOCAL', 
			@name=N'[Uncategorized (Local)]'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
	END

	DECLARE @jobId BINARY(16);
	EXEC @ReturnCode =  msdb.dbo.sp_add_job 
		@job_name = @jobName, 
		@enabled = @jobEnabled, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description = @jobDescription, 
		@category_name=N'[Uncategorized (Local)]', 
		@job_id = @jobId OUTPUT

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback
	
	BEGIN TRY
		DECLARE 
			@jobActionXml xml,
			@stepName nvarchar(250),
			@stepScript nvarchar(max),
			@totalSteps int,
			@currentOnSuccessAction int,
			@currentOnFailAction int,
			@stepNumber int = 0,
			@onSuccessAction int = 0,
			@onFailAction int = 0;
		SET @jobActionXml = @jobAction;
		
		IF(@debugMode = 1)
		BEGIN
			SET @msg = '[' + @jobName + '] Содержимое поля с описанием действий задания'
			PRINT @msg
			PRINT @jobAction
		END

		SELECT 
			@totalSteps = COUNT(*)
		FROM @jobActionXml.nodes('/steps/step') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') IS NOT NULL
			AND ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') IS NOT NULL
		IF(@totalSteps = 0)
		BEGIN
			SET @msg = '[' + @jobName + '] Для информации. Описание шага не распознано как XML-структура. Используем скрипт как есть в единственном шаге.';			
			THROW 50000, @msg, 1; 
		END

		IF(CURSOR_STATUS('global','job_steps_cursor')>=-1)
		BEGIN
			DEALLOCATE job_steps_cursor;
		END

		DECLARE job_steps_cursor CURSOR  
		FOR	SELECT 
			ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') AS [StepName],
			ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') AS [Script],
			ISNULL(ActionInfo.Step.value('(on_success_action)[1]', 'nvarchar(max)'), -1) AS [OnSuccessAction],
			ISNULL(ActionInfo.Step.value('(on_fail_action)[1]', 'nvarchar(max)'), -1) AS [OnFailAction]
		FROM @jobActionXml.nodes('/steps/step') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') IS NOT NULL
			AND ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') IS NOT NULL;
		OPEN job_steps_cursor;
		FETCH NEXT FROM job_steps_cursor INTO @stepName, @stepScript, @onSuccessAction, @onFailAction;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @stepNumber = @stepNumber + 1;

			IF(@onSuccessAction = -1)
			BEGIN
				IF(@stepNumber = @totalSteps)
				BEGIN
					SET @currentOnSuccessAction = 1;
				END ELSE BEGIN
					SET @currentOnSuccessAction = 3;
				END
			END ELSE BEGIN
				SET @currentOnSuccessAction = @onSuccessAction
			END

			IF(@onFailAction = -1)
			BEGIN
				SET @currentOnFailAction = 2;
			END ELSE BEGIN
				SET @currentOnFailAction = @onFailAction
			END

			SET @stepName = REPLACE(@stepName, '{DatabaseName}', @databaseName);
			

			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				@job_id = @jobId, 
				@step_name = @stepName, 
				@step_id = @stepNumber, 
				@on_success_action = @currentOnSuccessAction,
				@on_fail_action = @onFailAction,
				@subsystem=N'TSQL', 
				@command = @stepScript, 
				@database_name = @databaseName

			FETCH NEXT FROM job_steps_cursor INTO @stepName, @stepScript, @onSuccessAction, @onFailAction;
		END
		CLOSE job_steps_cursor;  
		DEALLOCATE job_steps_cursor;
	END TRY
	BEGIN CATCH
		SET @msg = '[' + @jobName + '] Не удалось разобрать XML. Работа продолжится с данными как со скриптом.';
		if(@debugMode = 1)
		BEGIN
			PRINT @msg;
			PRINT ERROR_MESSAGE();
		END
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = @jobName, 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0,
			@subsystem=N'TSQL', 
			@command = @jobAction, 
			@database_name = @databaseName, 
			@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
			GOTO QuitWithRollback
	END CATCH

	EXEC @ReturnCode = msdb.dbo.sp_update_job 
		@job_id = @jobId,
		@start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name = @jobName, 
		@enabled = @scheduleEnabled, 
		@freq_type = @scheduleFreqType,
		@freq_interval = @scheduleFreqInterval, 
		@freq_subday_type = @scheduleFreqSubdayType, 
		@freq_subday_interval = @scheduleFreqSubdayInterval, 
		@freq_relative_interval = @scheduleFreqRelativeInterval, 
		@freq_recurrence_factor = @scheduleFreqRecurrenceFactor, 
		@active_start_date = @scheduleActiveStartDate, 
		@active_end_date = @scheduleActiveEndDate, 
		@active_start_time = @scheduleActiveStartTime, 
		@active_end_time = @scheduleActiveEndTime
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback

	IF(@schedulesAdditional IS NOT NULL)
	BEGIN
		DECLARE 
			@jobSchedulesAdditionalXml xml,
			@jobScheduleName nvarchar(max);
		SET @jobSchedulesAdditionalXml = @schedulesAdditional;

		IF(CURSOR_STATUS('global','job_schedules_additional_cursor')>=-1)
		BEGIN
			DEALLOCATE job_schedules_additional_cursor;
		END

		DECLARE job_schedules_additional_cursor CURSOR  
		FOR	SELECT 
			ScheduleInfo.Schedule.value('(scheduleEnabled)[1]', 'int') AS [ScheduleEnabled],
			ScheduleInfo.Schedule.value('(scheduleName)[1]', 'nvarchar(max)') AS [ScheduleName],
			ScheduleInfo.Schedule.value('(scheduleFreqType)[1]', 'int') AS [ScheduleFreqType],
			ScheduleInfo.Schedule.value('(scheduleFreqInterval)[1]', 'int') AS [ScheduleFreqInterval],
			ScheduleInfo.Schedule.value('(scheduleFreqSubdayType)[1]', 'int') AS [ScheduleFreqSubdayType],
			ScheduleInfo.Schedule.value('(scheduleFreqSubdayInterval)[1]', 'int') AS [ScheduleFreqSubdayInterval],
			ScheduleInfo.Schedule.value('(scheduleFreqRelativeInterval)[1]', 'int') AS [ScheduleFreqRelativeInterval],
			ScheduleInfo.Schedule.value('(scheduleFreqRecurrenceFactor)[1]', 'int') AS [ScheduleFreqRecurrenceFactor],
			ScheduleInfo.Schedule.value('(scheduleActiveStartDate)[1]', 'int') AS [ScheduleActiveStartDate],
			ScheduleInfo.Schedule.value('(scheduleActiveEndDate)[1]', 'int') AS [ScheduleActiveEndDate],
			ScheduleInfo.Schedule.value('(scheduleActiveStartTime)[1]', 'int') AS [ScheduleActiveStartTime],
			ScheduleInfo.Schedule.value('(scheduleActiveEndTime)[1]', 'int') AS [ScheduleActiveEndTime]
		FROM @jobSchedulesAdditionalXml.nodes('/schedules/schedule') AS ScheduleInfo(Schedule)
		WHERE ScheduleInfo.Schedule.value('(scheduleEnabled)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleName)[1]', 'nvarchar(max)') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqType)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqInterval)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqSubdayType)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqSubdayInterval)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqRelativeInterval)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleFreqRecurrenceFactor)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleActiveStartDate)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleActiveEndDate)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleActiveStartTime)[1]', 'int') IS NOT NULL
			AND ScheduleInfo.Schedule.value('(scheduleActiveEndTime)[1]', 'int') IS NOT NULL
		OPEN job_schedules_additional_cursor;
		FETCH NEXT FROM job_schedules_additional_cursor INTO
			@scheduleEnabled, @jobScheduleName, @scheduleFreqType, @scheduleFreqInterval,
			@scheduleFreqSubdayType, @scheduleFreqSubdayInterval, @scheduleFreqRelativeInterval,
			@scheduleFreqRecurrenceFactor, @scheduleActiveStartDate, @scheduleActiveEndDate, 
			@scheduleActiveStartTime, @scheduleActiveEndTime;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @jobScheduleName = REPLACE(@jobScheduleName, '{DatabaseName}', @databaseName);

			EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name = @jobScheduleName, 
				@enabled = @scheduleEnabled, 
				@freq_type = @scheduleFreqType,
				@freq_interval = @scheduleFreqInterval, 
				@freq_subday_type = @scheduleFreqSubdayType, 
				@freq_subday_interval = @scheduleFreqSubdayInterval, 
				@freq_relative_interval = @scheduleFreqRelativeInterval, 
				@freq_recurrence_factor = @scheduleFreqRecurrenceFactor, 
				@active_start_date = @scheduleActiveStartDate, 
				@active_end_date = @scheduleActiveEndDate, 
				@active_start_time = @scheduleActiveStartTime, 
				@active_end_time = @scheduleActiveEndTime
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
				GOTO QuitWithRollback
			
			
			FETCH NEXT FROM job_schedules_additional_cursor INTO
				@scheduleEnabled, @jobScheduleName, @scheduleFreqType, @scheduleFreqInterval,
				@scheduleFreqSubdayType, @scheduleFreqSubdayInterval, @scheduleFreqRelativeInterval,
				@scheduleFreqRecurrenceFactor, @scheduleActiveStartDate, @scheduleActiveEndDate, 
				@scheduleActiveStartTime, @scheduleActiveEndTime;
		END
		CLOSE job_schedules_additional_cursor;  
		DEALLOCATE job_schedules_additional_cursor;
		
		SELECT 
			@totalSteps = COUNT(*)
		FROM @jobActionXml.nodes('/steps/step') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') IS NOT NULL
			AND ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') IS NOT NULL
	END

	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver
		@job_id = @jobId, 
		@server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
		GOTO QuitWithRollback

	IF(@jobTimeoutSec > 0)
	BEGIN
		EXECUTE [dbo].[sp_AddOrUpdateJobTimeout]
			@jobName = @jobName,
			@timeoutSec = @jobTimeoutSec
	END

	COMMIT TRANSACTION
	GOTO EndSave

	QuitWithRollback:
	IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION

	EndSave:
END
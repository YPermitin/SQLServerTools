IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'JobTemplates'))
BEGIN
    DECLARE @sql nvarchar(max);

	SET @sql = '
CREATE TABLE [dbo].[JobTimeouts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](250) NULL,
	[TimeoutSec] [int] NOT NULL,
	CONSTRAINT [PK_JobTimeouts] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
'
	EXECUTE sp_executesql @sql

	SET @sql = '
CREATE PROCEDURE [dbo].[sp_AddOrUpdateJobTimeout]
	@jobName nvarchar(250) NULL,
	@timeoutSec int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @currentId int;

	SELECT 
		@currentId = [Id]
	FROM [dbo].[JobTimeouts] jt
	WHERE (
		jt.JobName = @jobName
		OR (
			jt.JobName IS NULL AND @jobName IS NULL
		)
	)

    IF(@currentId IS NOT NULL)
	BEGIN
		UPDATE [dbo].[JobTimeouts]
		SET TimeoutSec = @timeoutSec
		WHERE [Id] = @currentId;
	END ELSE BEGIN
		INSERT INTO [dbo].[JobTimeouts] (JobName, TimeoutSec)
		VALUES (@jobName, @timeoutSec)
	END
END
'
	EXECUTE sp_executesql @sql
			
	SET @sql = '
CREATE TABLE [dbo].[JobTemplates](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UseSetting] [bit] NOT NULL,
	[Enable] [bit] NOT NULL,
	[ApplyTemplateQuery] [nvarchar](max) NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](512) NOT NULL,
	[JobAction] [nvarchar](max) NOT NULL,
	[ScheduleEnable] [bit] NOT NULL,
	[ScheduleFreqType] [int] NOT NULL,
	[ScheduleFreqInterval] [int] NOT NULL,
	[ScheduleFreqSubdayType] [int] NOT NULL,
	[ScheduleFreqSubdayInterval] [int] NOT NULL,
	[ScheduleFreqRelativeInterval] [int] NOT NULL,
	[ScheduleFreqRecurrenceFactor] [int] NOT NULL,
	[ScheduleActiveStartDay] [int] NOT NULL,
	[ScheduleActiveEndDay] [int] NOT NULL,
	[ScheduleActiveStartTime] [int] NOT NULL,
	[ScheduleActiveEndTime] [int] NOT NULL,
	[VersionDate] [datetime] NOT NULL,
	[TimeoutSec] [int] NOT NULL,
	CONSTRAINT [PK_JobTemplates] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
	EXECUTE sp_executesql @sql

	SET @sql = '
ALTER TABLE [dbo].[JobTemplates] ADD  CONSTRAINT [DF_JobTemplates_VersionDate]  DEFAULT (getdate()) FOR [VersionDate]
'
	EXECUTE sp_executesql @sql

	SET @sql = '
CREATE TRIGGER [dbo].[tg_JobTemplate_AfterUpdate] 
   ON  [dbo].[JobTemplates]
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    UPDATE [dbo].[JobTemplates]
	SET [VersionDate] = GETDATE()
	FROM [dbo].[JobTemplates] jt
		INNER JOIN inserted i
			ON jt.Id = i.Id
END
'
	EXECUTE sp_executesql @sql

	SET @sql = '
CREATE PROCEDURE [dbo].[sp_CreateSimpleJob]
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
	@jobTimeoutSec int = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ReturnCode INT;

	BEGIN TRANSACTION
	
	SELECT @ReturnCode = 0
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories
				   WHERE name=N''[Uncategorized (Local)]'' 
				   AND category_class=1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category 
			@class=N''JOB'', 
			@type=N''LOCAL'', 
			@name=N''[Uncategorized (Local)]''
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
		@category_name=N''[Uncategorized (Local)]'', 
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
			@stepNumber int = 0;
		SET @jobActionXml = @jobAction;
		
		SELECT 
			@totalSteps = COUNT(*)
		FROM @jobActionXml.nodes(''/steps/step'') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value(''(name)[1]'', ''nvarchar(max)'') IS NOT NULL
			AND ActionInfo.Step.value(''(script)[1]'', ''nvarchar(max)'') IS NOT NULL

		IF(@totalSteps = 0)
		BEGIN
			THROW 50000, ''Для информации. Описание шага не распознано как XML-структура. Используем скрипт как есть в единственном шаге.'', 1; 
		END

		DECLARE job_steps_cursor CURSOR  
		FOR	SELECT 
			ActionInfo.Step.value(''(name)[1]'', ''nvarchar(max)'') AS [StepName],
			ActionInfo.Step.value(''(script)[1]'', ''nvarchar(max)'') AS [Script]
		FROM @jobActionXml.nodes(''/steps/step'') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value(''(name)[1]'', ''nvarchar(max)'') IS NOT NULL
			AND ActionInfo.Step.value(''(script)[1]'', ''nvarchar(max)'') IS NOT NULL;
		OPEN job_steps_cursor;
		FETCH NEXT FROM job_steps_cursor INTO @stepName, @stepScript;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @stepNumber = @stepNumber + 1;
			IF(@stepNumber = @totalSteps)
			BEGIN
				SET @currentOnSuccessAction = 1;
			END ELSE BEGIN
				SET @currentOnSuccessAction = 3;
			END

			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				@job_id = @jobId, 
				@step_name = @stepName, 
				@step_id = @stepNumber, 
				@on_success_action = @currentOnSuccessAction,
				@subsystem=N''TSQL'', 
				@command = @stepScript, 
				@database_name = @databaseName

			FETCH NEXT FROM job_steps_cursor INTO @stepName, @stepScript;
		END
		CLOSE job_steps_cursor;  
		DEALLOCATE job_steps_cursor;
	END TRY
	BEGIN CATCH		
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
			@subsystem=N''TSQL'', 
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver
		@job_id = @jobId, 
		@server_name = N''(local)''
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
'
	EXECUTE sp_executesql @sql

	SET @sql = '
CREATE PROCEDURE [dbo].[sp_CreateOrUpdateJobsBySettings]
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
		SET @Description = @Description + '' (Version date:'' + CAST(@VersionDate AS nvarchar(max)) + '')'';

		IF(@ApplyTemplateQuery IS NOT NULL)
		BEGIN
			-- Задания создаются по базам данных
			IF(NOT EXISTS(SELECT 
				[name] 
			FROM sys.dm_exec_describe_first_result_set (@ApplyTemplateQuery, NULL, 0)
			WHERE [name] = ''DatabaseName''))
			BEGIN
				PRINT @Name;
				THROW 51000, ''Запрос шаблона не содержит поля DatabaseName.'', 1;   
			END

			IF (OBJECT_ID(''tempdb..##databasesForJobs'') IS NOT NULL)
				DROP Table ##databasesForJobs;
			IF(1 = 0)
			BEGIN
				-- !!! Костыль для поддержания корректного поведения редактора SQL кода,
				-- иначе ругается на несуществующую глобавльную временную таблицу
				CREATE TABLE ##databasesForJobs (DatabaseName nvarchar(255));
			END
			SET @sql = CAST(''SELECT [DatabaseName] INTO ##databasesForJobs FROM ('' AS nvarchar(max)) 
				+ CAST(@ApplyTemplateQuery AS nvarchar(max)) 
				+ CAST('') AS T'' AS nvarchar(max))
			EXEC sp_executesql @sql

			DECLARE job_templates_databases_cursor CURSOR  
			FOR	SELECT [DatabaseName] FROM ##databasesForJobs;
			OPEN job_templates_databases_cursor;
			FETCH NEXT FROM job_templates_databases_cursor INTO @currentDatabaseName;
			WHILE @@FETCH_STATUS = 0  
			BEGIN
				SET @jobName = REPLACE(@Name, ''{DatabaseName}'', @currentDatabaseName);
				SET @jobDescription = REPLACE(@Description, ''{DatabaseName}'', @currentDatabaseName);
				SET @JobAction = REPLACE(@JobAction, ''{DatabaseName}'', @currentDatabaseName);

				SELECT
					@jobAlreadyExists = 1,
					@currentJobId = sj.job_id,
					@currentjobVersionDate = CASE WHEN sj.date_modified > sj.date_created THEN sj.date_modified ELSE sj.date_created END
				FROM [msdb].[dbo].[sysjobs] sj
				WHERE sj.[name] = @jobName

				-- Если задание уже существует, но в настройках содержится более новая версия,
				-- то удаляем старое задание и создаем заново
				IF(@jobAlreadyExists = 1 AND @VersionDate > @currentjobVersionDate)
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
			IF(@jobAlreadyExists = 1 AND @VersionDate > @currentjobVersionDate)
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
					,@databaseName = ''SQLServerMaintenance''
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
'
	EXECUTE sp_executesql @sql

	SET @sql = '
INSERT [dbo].[JobTemplates] ([UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [TimeoutSec]) 
VALUES (1, 1, NULL, N''SQLServerMaintenance.ControlTransactionLogUsage'', N''Контроль заполнения лога транзакций'', N''EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlTransactionLogUsage] '', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, 0);

INSERT [dbo].[JobTemplates] ([UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [TimeoutSec]) 
VALUES (1, 1, NULL, N''SQLServerMaintenance.ControlJobsExecutionTimeout'', N''Контроль таймаутов выполнения заданий'', N''EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlJobsExecutionTimeout] '', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, 0);

INSERT [dbo].[JobTemplates] ([UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [TimeoutSec]) 
VALUES (1, 0, 
N''SELECT
	[name] AS [DatabaseName]
FROM sys.databases
WHERE NOT [name] IN (''''master'''', ''''msdb'''', ''''model'''', ''''tempdb'''')'', 
N''SQLServerMaintenance.FullMaintenance_{DatabaseName}'',
N''Полное обслуживание базы данных {DatabaseName}'', 
N''<steps>
	<step>
		<name>Index Maintenance</name>
		<script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''''{DatabaseName}''''
		</script>
	</step>
	<step>
		<name>Statistic Maintenance</name>
		<script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
   @databaseName = ''''{DatabaseName}''''
		</script>
	</step>
</steps>'', 1, 4, 1, 1, 60, 0, 0, 20231021, 99991231, 200000, 235959, 10800);
'
	EXECUTE sp_executesql @sql

	SET @sql = '
CREATE PROCEDURE [dbo].[sp_ControlJobsExecutionTimeout]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime INT,
		DiskIO INT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	)
	INSERT INTO @AllConnections EXEC sp_who2

	DECLARE
		@executionTimeSec int,
		@timeoutSec int,
		@SPID int,
		@programName nvarchar(max);

	DECLARE timeout_jobs_cursor CURSOR FOR 
	SELECT 
		DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) AS ''ExecutionDurationSec'',
		jtime.TimeoutSec,
		SPID,
		ProgramName
	FROM @AllConnections c
		INNER JOIN [msdb].[dbo].[sysjobs] sj
			ON UPPER(c.ProgramName) LIKE ''%Job 0x'' + UPPER(CONVERT(VARCHAR(max), CAST(job_id AS varbinary(max)), 2)) + ''%''
		INNER JOIN [msdb].[dbo].[sysjobactivity] AS sja
			ON sja.job_id = sj.job_id
		INNER JOIN [dbo].[JobTimeouts] jtime
			ON jtime.JobName = sj.[name]
		INNER JOIN (
			SELECT
				[job_id],
				MAX([session_id]) AS [session_id]
			FROM [msdb].[dbo].[sysjobactivity]
			GROUP BY [job_id]) ls
			ON ls.job_id = sja.job_id
				AND ls.session_id = sja.session_id
	WHERE jtime.TimeoutSec > 0
		AND DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) > jtime.TimeoutSec;
	OPEN timeout_jobs_cursor;
	FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		DECLARE @msg nvarchar(max), @sql nvarchar(max);
		SET @msg = ''Задание '''''' + @programName + '''''' завершено по таймауту. Соединение: '' + CAST(@SPID AS nvarchar(max)) + ''. Время работы: '' + CAST(@executionTimeSec  AS nvarchar(max))+ ''. Таймаут: '' + CAST(@timeoutSec AS nvarchar(max)) + ''.'';
		PRINT @msg;

		SET @sql = ''KILL '' + CAST(@SPID as nvarchar(max));
		EXEC sp_executesql @sql;

		FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName;
	END
	CLOSE timeout_jobs_cursor;  
	DEALLOCATE timeout_jobs_cursor;
END
'
	EXECUTE sp_executesql @sql
END
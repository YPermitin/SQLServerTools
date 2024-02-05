/*
Скрипт для создания служебной базы данных для управления обслуживанием и мониторингом.
*/

-- По умолчанию служебную базу называем "SQLServerMaintenance"
USE [SQLServerMaintenance]
GO

CREATE FUNCTION [dbo].[fn_ResumableIndexMaintenanceAvailiable]()
RETURNS bit
AS
BEGIN
	DECLARE @checkResult bit;

	SELECT
	-- Возобновляемые операции обслуживания индексов доступны со SQL Server 2017
	@checkResult = CASE
						WHEN CAST(SUBSTRING(CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')), 0,  3) AS INT) > 13
						THEN 1
						ELSE 0
					END
	
	RETURN @checkResult

END
GO

CREATE TABLE [dbo].[MaintenanceActionsLog](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Period] [datetime2](0) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[IndexName] [nvarchar](255) NOT NULL,
	[Operation] [nvarchar](100) NOT NULL,
	[RunDate] [datetime2](0) NOT NULL,
	[StartDate] [datetime2](0) NOT NULL,
	[FinishDate] [datetime2](0) NULL,
	[DatabaseName] [nvarchar](500) NOT NULL,
	[UseOnlineRebuild] [bit] NOT NULL,
	[Comment] [nvarchar](255) NOT NULL,
	[IndexFragmentation] [float] NOT NULL,
	[RowModCtr] [bigint] NOT NULL,
	[SQLCommand] [nvarchar](max) NOT NULL,
	[TransactionLogUsageBeforeMB] [bigint] NOT NULL,
	[TransactionLogUsageAfterMB] [bigint] NULL,
 CONSTRAINT [PK__Maintena__3214EC074E078F4E] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE VIEW [dbo].[v_CommonStatsByDay]
AS
SELECT 
	CAST([RunDate] AS DATE) AS "День",
      COUNT(DISTINCT [TableName]) AS "Кол-во таблиц, для объектов которых выполнено обслуживание",
      COUNT(DISTINCT [IndexName]) AS "Количество индексов, для объектов которых выполнено обслуживание",
      SUM(CASE 
		WHEN [Operation] LIKE '%STAT%'
		THEN 1
		ELSE 0
	  END) AS "Обновлено статистик",
	  SUM(CASE 
		WHEN [Operation] LIKE '%INDEX%'
		THEN 1
		ELSE 0
	  END) AS "Обслужено индексов"      
  FROM [dbo].[MaintenanceActionsLog]
  GROUP BY CAST([RunDate] AS DATE)
GO

CREATE TABLE [dbo].[AlwaysOnReplicaMissingStats](
	[DatabaseName] [nvarchar](255) NULL,
	[TableName] [nvarchar](255) NULL,
	[StatsName] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [UK_AlwaysOnReplicaMissingStats_CreatedDate_DatabaseName_TableName] ON [dbo].[AlwaysOnReplicaMissingStats]
(
	[CreatedDate] ASC,
	[DatabaseName] ASC,
	[TableName] ASC
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[changelog](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[type] [tinyint] NULL,
	[version] [varchar](50) NULL,
	[description] [varchar](200) NOT NULL,
	[name] [varchar](300) NOT NULL,
	[checksum] [varchar](32) NULL,
	[installed_by] [varchar](100) NOT NULL,
	[installed_on] [datetime] NOT NULL,
	[success] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ConnectionsStatistic](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Period] [datetime2](7) NOT NULL,
	[InstanceName] [nvarchar](255) NULL,
	[QueryText] [nvarchar](max) NULL,
	[RowCountSize] [bigint] NULL,
	[SessionId] [bigint] NULL,
	[Status] [nvarchar](255) NULL,
	[Command] [nvarchar](255) NULL,
	[CPU] [bigint] NULL,
	[TotalElapsedTime] [bigint] NULL,
	[StartTime] [datetime2](7) NULL,
	[DatabaseName] [nvarchar](255) NULL,
	[BlockingSessionId] [bigint] NULL,
	[WaitType] [nvarchar](255) NULL,
	[WaitTime] [bigint] NULL,
	[WaitResource] [nvarchar](255) NULL,
	[OpenTransactionCount] [bigint] NULL,
	[Reads] [bigint] NULL,
	[Writes] [bigint] NULL,
	[LogicalReads] [bigint] NULL,
	[GrantedQueryMemory] [bigint] NULL,
	[UserName] [nvarchar](255) NULL,
 CONSTRAINT [PK_ConnectionsStatistic] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[Period] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[DatabaseObjectsState](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Period] [datetime2](0) NOT NULL,
	[DatabaseName] [nvarchar](150) NOT NULL,
	[TableName] [nvarchar](250) NOT NULL,
	[Object] [nvarchar](250) NOT NULL,
	[PageCount] [bigint] NOT NULL,
	[Rowmodctr] [bigint] NOT NULL,
	[AvgFragmentationPercent] [int] NOT NULL,
	[OnlineRebuildSupport] [int] NOT NULL,
	[Compression] [nvarchar](10) NULL,
	[PartitionCount] [bigint] NULL,
 CONSTRAINT [PK__DatabaseObjectsState__3214EC074E078F4E] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[DatabasesTablesStatistic](
	[Period] [datetime2](7) NOT NULL,
	[DatabaseName] [nvarchar](255) NOT NULL,
	[SchemaName] [nvarchar](5) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[RowCnt] [bigint] NOT NULL,
	[Reserved] [bigint] NOT NULL,
	[Data] [bigint] NOT NULL,
	[IndexSize] [bigint] NOT NULL,
	[Unused] [bigint] NOT NULL
) ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [UK_DatabasesTablesStatistic_Period_DatabaseName_TableName] ON [dbo].[DatabasesTablesStatistic]
(
	[Period] ASC,
	[DatabaseName] ASC,
	[SchemaName] ASC,
	[TableName] ASC
) ON [PRIMARY]
GO

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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[JobTimeouts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](250) NULL,
	[TimeoutSec] [int] NOT NULL,
 CONSTRAINT [PK_JobTimeouts] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[LogTransactionControlSettings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](250) NOT NULL,
	[MinDiskFreeSpace] [int] NOT NULL,
	[MaxLogUsagePercentThreshold] [int] NOT NULL,
 CONSTRAINT [PK_LogTransactionControlSettings] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[MaintenanceActionsToRun](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](255) NOT NULL,
	[Period] [datetime2](0) NOT NULL,
	[Operation] [nvarchar](100) NOT NULL,
	[SQLCommand] [nvarchar](max) NOT NULL,
	[RunAttempts] [int] NOT NULL,
	[Comment] [nvarchar](255) NULL,
	[SourceConnectionId] [smallint] NOT NULL,
 CONSTRAINT [PK_MaintenanceActionsToRun] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[MaintenanceIndexPriority](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](255) NOT NULL,
	[TableName] [nvarchar](255) NOT NULL,
	[IndexName] [nvarchar](255) NOT NULL,
	[Priority] [int] NOT NULL,
	[Exclude] [bit] NULL,
 CONSTRAINT [PK_MaintenanceIndexPriority] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO

SET IDENTITY_INSERT [dbo].[changelog] ON 
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (1, 2, N'0', N'Empty schema found: dbo.', N'dbo', N'', N'sa', CAST(N'2023-10-31T21:52:06.830' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (2, 0, N'1.0.0.0', N'Initializing (74 ms)', N'V1_0_0_0__Initializing.sql', N'E29CBD2E2588AD0496EAD6531C63CC7F', N'sa', CAST(N'2023-10-31T21:52:06.937' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (3, 0, N'1.0.0.1', N'FixView CommonStatsByDay (7 ms)', N'V1_0_0_1__FixView_CommonStatsByDay.sql', N'E148A3049C07BE2692277AAF1FF1EEAC', N'sa', CAST(N'2023-10-31T21:52:06.947' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (4, 0, N'1.0.0.2', N'MaintainanceActionLog AddTranLogSizeInfo (19 ms)', N'V1_0_0_2__MaintainanceActionLog_AddTranLogSizeInfo.sql', N'A8B95D18EE751AC15A2DFF3601538ADE', N'sa', CAST(N'2023-10-31T21:52:06.967' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (5, 0, N'1.0.0.3', N'IndexMaintenance FixQueryRetriveIndexListForMaintenance (13 ms)', N'V1_0_0_3__IndexMaintenance_FixQueryRetriveIndexListForMaintenance.sql', N'55E540697C7AFFEDB68D8FC815091F61', N'sa', CAST(N'2023-10-31T21:52:06.983' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (6, 0, N'1.0.0.4', N'TransactionLogControl AddTableWithSettingsAndProc (20 ms)', N'V1_0_0_4__TransactionLogControl_AddTableWithSettingsAndProc.sql', N'655D9D4645CBA6710081AB9846140A0F', N'sa', CAST(N'2023-10-31T21:52:07.003' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (7, 0, N'1.0.0.5', N'IndexMaintenance AddSupportIndexReorganizeWithoutPageLocks copy (27 ms)', N'V1_0_0_5__IndexMaintenance_AddSupportIndexReorganizeWithoutPageLocks copy.sql', N'E22174E62CA8468BF1AA629DBDEA3CB3', N'sa', CAST(N'2023-10-31T21:52:07.033' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (8, 0, N'1.0.0.6', N'IndexMaintenance ImproveReorganizeIndexes (14 ms)', N'V1_0_0_6__IndexMaintenance_ImproveReorganizeIndexes.sql', N'D0D4BA4F63B28FDFDFA3847ACD5D4C29', N'sa', CAST(N'2023-10-31T21:52:07.050' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (9, 0, N'1.0.0.7', N'IndexMaintenance ImproveReorganizeIndexes v2 (12 ms)', N'V1_0_0_7__IndexMaintenance_ImproveReorganizeIndexes_v2.sql', N'36937240442EEBAB330DA107755213C1', N'sa', CAST(N'2023-10-31T21:52:07.063' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (10, 0, N'1.0.0.8', N'Backup AddProcBackupDatabase (10 ms)', N'V1_0_0_8__Backup_AddProcBackupDatabase.sql', N'8D060910FFC1AE7D67B7A6758F8DEE94', N'sa', CAST(N'2023-10-31T21:52:07.073' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (11, 0, N'1.0.0.9', N'Backup AddProcClearFiles (7 ms)', N'V1_0_0_9__Backup_AddProcClearFiles.sql', N'A8A4CA79BA41288175A164A32D606AD0', N'sa', CAST(N'2023-10-31T21:52:07.083' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (12, 0, N'1.0.0.10', N'Jobs AddSettingsAndControlFunctions (26 ms)', N'V1_0_0_10__Jobs_AddSettingsAndControlFunctions.sql', N'882BB44E8B3B6D443958089B08BCA066', N'sa', CAST(N'2023-10-31T21:52:07.113' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (13, 0, N'1.0.0.11', N'Refactoring (24 ms)', N'V1_0_0_11__Refactoring.sql', N'F32BC5B3DCA7EFEB049F1C7A032C30F3', N'sa', CAST(N'2023-10-31T21:52:07.140' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (14, 0, N'1.0.0.12', N'Jobs FixCreateOrUPdateJobsBySettingsProc (72 ms)', N'V1_0_0_12__Jobs_FixCreateOrUPdateJobsBySettingsProc.sql', N'830D32CAB88A1ACC673F515AA8D5B96D', N'sa', CAST(N'2023-11-09T18:58:14.717' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (1014, 0, N'1.0.0.13', N'Jobs FixCreateOrUPdateJobsBySettingsProcV2 (33 ms)', N'V1_0_0_13__Jobs_FixCreateOrUPdateJobsBySettingsProcV2.sql', N'20830460B9482F8F0E072F0258C2C246', N'sa', CAST(N'2023-11-10T10:20:16.897' AS DateTime), 1)
GO
SET IDENTITY_INSERT [dbo].[changelog] OFF
GO

SET IDENTITY_INSERT [dbo].[JobTemplates] ON 
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec]) VALUES (1, 1, 1, NULL, N'SQLServerMaintenance.ControlTransactionLogUsage', N'Контроль заполнения лога транзакций', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlTransactionLogUsage] ', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2023-10-31T21:52:07.110' AS DateTime), 0)
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec]) VALUES (2, 1, 1, NULL, N'SQLServerMaintenance.ControlJobsExecutionTimeout', N'Контроль таймаутов выполнения заданий', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlJobsExecutionTimeout] ', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2023-10-31T21:52:07.110' AS DateTime), 0)
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec]) VALUES (3, 1, 0, N'SELECT
	[name] AS [DatabaseName]
FROM sys.databases
WHERE NOT [name] IN (''master'', ''msdb'', ''model'', ''tempdb'')', N'SQLServerMaintenance.FullMaintenance_{DatabaseName}', N'Полное обслуживание базы данных {DatabaseName}', N'<steps>
	<step>
		<name>Index Maintenance</name>
		<script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
		</script>
	</step>
	<step>
		<name>Statistic Maintenance</name>
		<script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
   @databaseName = ''{DatabaseName}''
		</script>
	</step>
</steps>', 1, 4, 1, 1, 60, 0, 0, 20231021, 99991231, 200000, 235959, CAST(N'2023-10-31T21:52:07.110' AS DateTime), 10800)
GO
SET IDENTITY_INSERT [dbo].[JobTemplates] OFF
GO

CREATE NONCLUSTERED INDEX [UK_Table_Object_Period] ON [dbo].[DatabaseObjectsState]
(
	[DatabaseName] ASC,
	[TableName] ASC,
	[Object] ASC,
	[Period] ASC
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_LogTransactionControlSettings_DatabaseName] ON [dbo].[LogTransactionControlSettings]
(
	[DatabaseName] ASC
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [UK_RunDate_Table_Index_Period_Operation] ON [dbo].[MaintenanceActionsLog]
(
	[RunDate] ASC,
	[DatabaseName] ASC,
	[TableName] ASC,
	[IndexName] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[changelog] ADD  DEFAULT (getdate()) FOR [installed_on]
GO
ALTER TABLE [dbo].[JobTemplates] ADD  CONSTRAINT [DF_JobTemplates_VersionDate]  DEFAULT (getdate()) FOR [VersionDate]
GO
ALTER TABLE [dbo].[LogTransactionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_MinLogUsagePercentThreshold]  DEFAULT ((90)) FOR [MaxLogUsagePercentThreshold]
GO
ALTER TABLE [dbo].[MaintenanceActionsLog] ADD  CONSTRAINT [DF_MaintenanceActionsLog_TransactionLogUsageBeforeMB]  DEFAULT ((0)) FOR [TransactionLogUsageBeforeMB]
GO
ALTER TABLE [dbo].[MaintenanceActionsToRun] ADD  CONSTRAINT [DF_MaintenanceActionsToRun_RunAttempts]  DEFAULT ((0)) FOR [RunAttempts]
GO

CREATE PROCEDURE [dbo].[sp_add_maintenance_action_log]
	@TableName sysname,
	@IndexName sysname,
	@Operation nvarchar(100),
	@RunDate datetime2(0),
	@StartDate datetime2(0),
	@FinishDate datetime2(0),
	@DatabaseName sysname,
	@UseOnlineRebuild bit,
	@Comment nvarchar(255),
	@IndexFragmentation float,
	@RowModCtr bigint,
	@SQLCommand nvarchar(max),
	@MaintenanceActionLogId bigint OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @currentTransactionLogSizeMB int;
	DECLARE @IdentityOutput TABLE ( Id bigint )

	-- Информация о размере лога транзакций
    DECLARE @tranLogInfo TABLE
    (
        servername varchar(250) not null default @@servername,
        dbname varchar(250),
        logsize real,
        logspace real,
        stat int
    ) 
	-- Проверка процента занятого места в логе транзакций
    INSERT INTO @tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
    SELECT
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM @tranLogInfo WHERE dbname = @databaseName

	SET @TableName = REPLACE(@TableName, '[', '')
	SET @TableName = REPLACE(@TableName, ']', '')
	SET @IndexName = REPLACE(@IndexName, '[', '')
	SET @IndexName = REPLACE(@IndexName, ']', '')
	SET @DatabaseName = REPLACE(@DatabaseName, '[', '')
	SET @DatabaseName = REPLACE(@DatabaseName, ']', '')

	SET @RowModCtr = ISNULL(@RowModCtr,0);
	
	SET @SQLCommand = LTRIM(RTRIM((REPLACE(REPLACE(@SQLCommand, CHAR(13), ''), CHAR(10), ''))));

	INSERT INTO [dbo].[MaintenanceActionsLog]
	(
		[Period]
		,[TableName]
		,[IndexName]
		,[Operation]
		,[RunDate]
		,[StartDate]
		,[FinishDate]
		,[DatabaseName]
		,[UseOnlineRebuild]
		,[Comment]
		,[IndexFragmentation]
		,[RowModCtr]
		,[SQLCommand]
		,[TransactionLogUsageBeforeMB]
		,[TransactionLogUsageAfterMB]
	)
	OUTPUT inserted.Id into @IdentityOutput
	VALUES
	(
		GETDATE()
		,@TableName
		,@IndexName
		,@Operation
		,@RunDate
		,@StartDate
		,@FinishDate
		,@DatabaseName
		,@UseOnlineRebuild
		,@Comment
		,@IndexFragmentation
		,@RowModCtr
		,@SQLCommand
		,@currentTransactionLogSizeMB
		,NULL
	)

	SET @MaintenanceActionLogId = (SELECT MAX(Id) FROM @IdentityOutput)

	RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_add_maintenance_action_to_run]
	@DatabaseName sysname,
	@Operation nvarchar(100),
	@SQLCommand nvarchar(max),
	@MaintenanceActionToRunId bigint OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IdentityOutput TABLE ( Id bigint );
	DECLARE @RunDate datetime2(0) = GetDate();

	SET @DatabaseName = REPLACE(@DatabaseName, '[', '')
	SET @DatabaseName = REPLACE(@DatabaseName, ']', '')

	INSERT INTO [dbo].[MaintenanceActionsToRun]
	(
		[DatabaseName],
		[Period],
		[Operation],
		[SQLCommand],
		[SourceConnectionId]
	)
	OUTPUT inserted.Id into @IdentityOutput
	VALUES
	(
		@DatabaseName,
		@RunDate,
		@Operation,
		@SQLCommand,
		@@SPID
	)

	SET @MaintenanceActionToRunId = (SELECT MAX(Id) FROM @IdentityOutput)

	RETURN 0
END
GO

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
GO

CREATE PROCEDURE [dbo].[sp_AdvancedPrint]
    @sql varchar(max)
AS
BEGIN
    declare
        @n int,
        @i int = 0,
        @s int = 0,
        @l int;

    set @n = ceiling(len(@sql) / 8000.0);

    while @i < @n
    begin
        set @l = 8000 - charindex(char(13), reverse(substring(@sql, @s, 8000)));
        print substring(@sql, @s, @l);
        set @i = @i + 1;
        set @s = @s + @l + 2;
    end

    return 0
END
GO

CREATE PROCEDURE [dbo].[sp_apply_maintenance_action_to_run]
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRAN;

	DECLARE 
		@period datetime2(0),
		@operation nvarchar(100),
		@id int,
		@sqlCommand nvarchar(max),
		@fullSqlCommand nvarchar(max),
		@sourceConnectionId smallint,
		@operationFull nvarchar(max),
		@RunDate datetime2(0) = GetDate(),
		@StartDate datetime2(0),
		@FinishDate datetime2(0),
		@MaintenanceActionLogId bigint;

	DECLARE commands_to_run_cursor CURSOR  
	FOR SELECT
		[Id], [Period], [Operation], [SQLCommand], [SourceConnectionId]
	FROM [dbo].[MaintenanceActionsToRun] WITH (READPAST, UPDLOCK)
	WHERE [DatabaseName] = @databaseName
		AND [RunAttempts] < 3
	ORDER BY [Period], [Id]
	OPEN commands_to_run_cursor;

	FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(EXISTS(
			SELECT  *
			FROM    sys.dm_exec_sessions es
				LEFT OUTER JOIN sys.dm_exec_requests rs ON (es.session_id = rs.session_id)  
				CROSS APPLY sys.dm_exec_sql_text(rs.sql_handle) AS sqltext
			WHERE (
					rs.command like '%ALTER INDEX%' 
					or (rs.command like '%DBCC%' AND sqltext.text like '%ALTER%INDEX%')
					or (rs.command like '%DBCC%' AND sqltext.text like '%EXECUTE%sp_IndexMaintenance%')
				  )
				and es.session_id = @sourceConnectionId))
		BEGIN
			FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;
			CONTINUE;
		END
						
		SET @fullSqlCommand = CAST('USE [' as nvarchar(max)) + CAST(@databaseName  as nvarchar(max)) + CAST('];
		' as nvarchar(max)) + CAST(@sqlCommand as nvarchar(max));
		
		UPDATE [dbo].[MaintenanceActionsToRun]
		SET 
			[RunAttempts] = [RunAttempts] + 1,
			[SourceConnectionId] = @@SPID
		WHERE [Id] = @id
		
		SET @StartDate = GetDate()
		SET @operationFull = 'MAINTENANCE ACTION TO RUN (' + @Operation + ')'

		DECLARE @msg nvarchar(500);
        EXECUTE [dbo].[sp_add_maintenance_action_log]
			''
            ,''
            ,@operationFull
            ,@RunDate
            ,@StartDate
            ,null
            ,@databaseName
            ,0
            ,''
            ,0
            ,0
            ,@sqlCommand
            ,@MaintenanceActionLogId OUTPUT;

		BEGIN TRY
			EXEC sp_executesql @fullSqlCommand;

			execute [dbo].[sp_remove_maintenance_action_to_run]
				@id

			SET @msg = ''
		END TRY
		BEGIN CATCH
			SET @msg = 'Error: '
				+ CAST(Error_message() AS NVARCHAR(500)) + ', Code: ' 
				+ CAST(Error_Number() AS NVARCHAR(500)) + ', Line: ' 
				+ CAST(Error_Line() AS NVARCHAR(500))			
			UPDATE [dbo].[MaintenanceActionsToRun]
			SET [Comment] = @msg
			WHERE [Id] = @id
		END CATCH
		
		SET @FinishDate = GetDate()
        EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
			@MaintenanceActionLogId,
            @FinishDate,
			@msg;   

		FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;
	END
	CLOSE commands_to_run_cursor;  
	DEALLOCATE commands_to_run_cursor;

	COMMIT TRAN;
END
GO

CREATE PROCEDURE [dbo].[sp_BackupDatabase]
	@databaseName sysname,
	@backupDirectory nvarchar(max),
	@backupType nvarchar(10) = 'FULL',	
	@useSubdirectory bit = 1,
	@showScriptOnly bit = 0,
	@backupCompressionType nvarchar(10) = 'AUTO',	
	@copyOnly bit = 0,
	@checksum bit = 0,
	@continiueOnError bit = 0,
	@blockSize int = 0,
	@maxTransferSize int = 0,
	@bufferCount int = 0,
	@verify bit = 0
	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@backupExtension nvarchar(5),
		@fileName nvarchar(max),
		@backupFileFullName nvarchar(max),
		@useCompression bit,
		@msg nvarchar(max),
		@sql nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END

	IF(NOT UPPER(@backupType) IN ('FULL', 'DIFF', 'TRN'))
	BEGIN
	    SET @msg = 'Backup type is incorrect. Valid values: FULL, DIFF, TRN.';
        THROW 51000, @msg, 1;
        RETURN -1;
	END

	IF(NOT UPPER(@backupCompressionType) IN ('AUTO', 'ENABLE', 'DISABLE'))
	BEGIN
	    SET @msg = 'Backup compression type is incorrect. Valid values: AUTO, ENABLE, DISABLE.';
        THROW 51000, @msg, 1;
        RETURN -1;
	END  

	SET @backupExtension = 
		CASE 
			WHEN @backupType = 'FULL' THEN 'bak'
			WHEN @backupType = 'DIFF' THEN 'diff'
			WHEN @backupType = 'TRN' THEN 'trn'
		END

	if(@backupCompressionType = 'AUTO')
	BEGIN
		SELECT @useCompression = CAST(value AS bit)
		FROM sys.configurations   
		WHERE name = 'backup compression default';
	END ELSE IF(@backupCompressionType = 'ENABLE')
	BEGIN
		SET @useCompression = 1
	END ELSE IF(@backupCompressionType = 'DISABLE') 
	BEGIN
		SET @useCompression = 0
	END

	SET @fileName = @databaseName + '_backup_' + FORMAT(sysdatetime(), 'yyyy_MM_dd_HHmmss_ffffff');

	SET @backupFileFullName =
		CASE WHEN SUBSTRING(@backupDirectory, LEN(@backupDirectory), 1) = '\' THEN SUBSTRING(@backupDirectory, 1, LEN(@backupDirectory) - 1) ELSE @backupDirectory END + 
		'\' + 
		CASE WHEN @useSubdirectory = 1 THEN @databaseName + '\' ELSE '' END;

	if(@showScriptOnly = 0)
	BEGIN
		SET @sql = 'EXEC master.sys.xp_create_subdir N''' + @backupFileFullName + ''''
		EXECUTE sp_executesql @sql
	END

	SET @backupFileFullName = @backupFileFullName + @fileName + '.' + @backupExtension;

	SET @sql = 
'BACKUP ' + CASE WHEN @backupType = 'TRN' THEN 'LOG' ELSE 'DATABASE' END + ' [' + @databaseName + ']
TO DISK = N''' + @backupFileFullName + ''' WITH NOFORMAT,
NOINIT,
NAME = N''' + @fileName + ''',
SKIP, REWIND, NOUNLOAD' +
	CASE WHEN @backupType = 'DIFF' THEN ', DIFFERENTIAL' ELSE '' END + 
	CASE WHEN @useCompression = 1 THEN ', COMPRESSION' ELSE '' END + 
	CASE WHEN @copyOnly = 1 THEN ', COPY_ONLY' ELSE '' END +
	CASE WHEN @checksum = 1 THEN ', CHECKSUM' ELSE '' END +
	CASE WHEN @continiueOnError = 1 THEN ', CONTINUE_AFTER_ERROR' ELSE '' END +
	CASE WHEN @blockSize > 0 THEN ', BLOCKSIZE = ' + CAST(@blockSize as nvarchar(max)) ELSE '' END +
	CASE WHEN @maxTransferSize > 0 THEN ', MAXTRANSFERSIZE = ' + CAST(@maxTransferSize as nvarchar(max)) ELSE '' END +
	CASE WHEN @bufferCount > 0 THEN ', BUFFERCOUNT = ' + CAST(@bufferCount as nvarchar(max)) ELSE '' END + ', STATS = 10;'

	if(@verify = 1)
	BEGIN
		DECLARE @backupSetId as int;

		SELECT @backupSetId = position from msdb..backupset 
		WHERE [database_name] = @databaseName and backup_set_id = (
			select max(backup_set_id) 
			from msdb..backupset
			where [database_name] = @databaseName
		)

		IF @backupSetId is null AND @showScriptOnly = 0
		BEGIN
			raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных не найдены.', 16, 1) 
		END

		SET @sql = @sql + '

RESTORE VERIFYONLY FROM  DISK = N''' + @backupFileFullName + ''' WITH  FILE = ' + CAST(@backupSetId AS nvarchar(max)) + ',  NOUNLOAD,  NOREWIND;'
	END

	if(@showScriptOnly = 1)
	BEGIN
		PRINT @sql
	END ELSE
	BEGIN
		EXECUTE sp_executesql @sql
	END
END
GO

CREATE PROCEDURE [dbo].[sp_ClearFiles]
	@folderPath nvarchar(max),
	@fileType bit = 0,	
	@fileExtension nvarchar(10) = null,
	@cutoffDate datetime = null,
	@cutoffDateDays int = null,
	@includeSubfolders bit = 1,
	@scriptOnly bit = 0	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max);

	IF(@cutoffDate is not null AND @cutoffDateDays is not null)
	BEGIN
		SET @msg = 'You should setup only one parameter: @cutoffDate or @cutoffDateDays';
        THROW 51000, @msg, 1;
        RETURN -1;
	END

	IF(@cutoffDateDays IS NOT NULL)
	BEGIN
		SET @cutoffDate = DATEADD(day, -@cutoffDateDays, GETDATE())
	END ELSE IF(@cutoffDate is null)
	BEGIN
		SET @cutoffDate = GETDATE()
	END

	DECLARE @sql nvarchar(max);
	SET @sql = 'EXECUTE master.dbo.xp_delete_file ' + 
		CAST(@fileType AS nvarchar(max)) + 
		',N''' + @folderPath + '''' +
		',N''' + @fileExtension + 
		''',N''' + FORMAT(@cutoffDate, 'yyyy-MM-ddTHH:mm:ss') + ''',' + 
		CAST(@includeSubfolders AS nvarchar(max))

	IF(@scriptOnly = 1)
	BEGIN
		PRINT @sql
	END ELSE
	BEGIN
		EXECUTE sp_executesql @sql
	END	
END
GO

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
		DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) AS 'ExecutionDurationSec',
		jtime.TimeoutSec,
		SPID,
		ProgramName
	FROM @AllConnections c
		INNER JOIN [msdb].[dbo].[sysjobs] sj
			ON UPPER(c.ProgramName) LIKE '%Job 0x' + UPPER(CONVERT(VARCHAR(max), CAST(job_id AS varbinary(max)), 2)) + '%'
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
		SET @msg = 'Задание ''' + @programName + ''' завершено по таймауту. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Время работы: ' + CAST(@executionTimeSec  AS nvarchar(max))+ '. Таймаут: ' + CAST(@timeoutSec AS nvarchar(max)) + '.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		EXEC sp_executesql @sql;

		FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName;
	END
	CLOSE timeout_jobs_cursor;  
	DEALLOCATE timeout_jobs_cursor;
END
GO

CREATE PROCEDURE [dbo].[sp_ControlTransactionLogUsage]
	@databaseNameFilter nvarchar(255) = null,
	@showDiagnosticMessages bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;
	CREATE TABLE #logFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		LogFileName varchar(255),
		LogFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[LogSizeMB] numeric(15,0),
		[LogMaxSizeMB] numeric(15,0),
		[LogFileCanGrow] bit,
		[LogFileFreeSpaceMB] numeric(15,0)
	);

	DECLARE
		@SqlStatement nvarchar(MAX)
		,@CurrentDatabaseName sysname;
	DECLARE DatabaseList CURSOR LOCAL FAST_FORWARD FOR
		SELECT name FROM sys.databases;
	OPEN DatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM DatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'INSERT INTO #logFileInfoByDatabases
	SELECT
		DB_NAME(f.database_id) AS [Database],
		f.[name] AS [LogFileName],
		f.physical_name AS [LogFilePath],
		volume_mount_point AS [Disk],
		available_bytes/1048576 as [DiskFreeSpaceMB],
		CAST(f.size AS bigint) * 8 / 1024 AS [LogSizeMB],
		CAST(CASE WHEN f.max_size <= 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024 AS [LogMaxSizeMB],
		CASE 
			WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
			THEN 0
			ELSE 1
		END AS [LogFileCanGrow],
		size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [LogFileFreeSpaceMB]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	WHERE [type_desc] = ''LOG''
		and f.database_id = DB_ID();';

		EXECUTE(@SqlStatement);
	
	END
	CLOSE DatabaseList;
	DEALLOCATE DatabaseList;

	DECLARE @databaseName sysname,
			@MinDiskFreeSpaceMB int,
			@MaxLogUsagePercentThreshold int,
			@currentTransactionLogSizeFreePercent int,
			@currentTransactionLogSizeFreeMB int,
			@logUsageBadStatus bit = 0,
			@RunDate datetime = GETDATE(),
			@comment nvarchar(255),
			@message nvarchar(max);

	DECLARE databasesUnderControl CURSOR  
	FOR SELECT
		[DatabaseName],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold]
	FROM [dbo].[LogTransactionControlSettings]
	WHERE DatabaseName = @databaseNameFilter or @databaseNameFilter IS NULL;
	OPEN databasesUnderControl;

	FETCH NEXT FROM databasesUnderControl 
	INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(@showDiagnosticMessages = 1)
		BEGIN
			SET @message = 'Запуск проверки лога транзакций для базы ' 
				+ @databaseName 
				+ '. Мин. свободное место на диске должно быть ' 
				+ CAST(@MinDiskFreeSpaceMB AS nvarchar(max))
				+ ' МБ. Макс. занятый % лога транзакций при этом '
				+ CAST(@MaxLogUsagePercentThreshold AS nvarchar(max))
				+ '%.'
			PRINT @message

			SELECT
				[Disk],
				[LogFilePath],
				[LogFileFreeSpaceMB],
				[DiskFreeSpaceMB],
				100 - (LogFileFreeSpaceMB / (LogSizeMB / 100)) AS [LogFileUsedPercent],
				100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100) AS [TotalLogFileUsedPercent]
			FROM #logFileInfoByDatabases lf
				LEFT JOIN (
					SELECT
						DatabaseName,
						SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
						SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
					FROM #logFileInfoByDatabases
					GROUP BY DatabaseName
				) totals ON lf.DatabaseName = totals.DatabaseName
			WHERE lf.DatabaseName = @databaseName
				AND LogFileCanGrow = 1
				AND (
					-- Место на диске меньше установленного порога, при этом файл лога заполнен более чем на указанный % в ограничениях
					(100 - (LogFileFreeSpaceMB / (LogSizeMB / 100))) >= @MaxLogUsagePercentThreshold AND [DiskFreeSpaceMB] <= @MinDiskFreeSpaceMB				
					OR
					-- Лог транзакций заполнен более чем на указанный % от максимального размер лога (с учетом автоприроста)
					(100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) >= @MaxLogUsagePercentThreshold
				)
		END

		DECLARE
			@logFileFreeSpaceMB numeric,
			@diskFreeSpaceMB numeric,
			@logFileUsedPercent numeric,
			@diskName nvarchar(max),
			@logFilePath nvarchar(max),
			@totalLogFileUsedPercent numeric;

		DECLARE checkLogFiles CURSOR FOR
		SELECT
			[Disk],
			[LogFilePath],
			[LogFileFreeSpaceMB],
			[DiskFreeSpaceMB],
			100 - (LogFileFreeSpaceMB / (LogSizeMB / 100)) AS [LogFileUsedPercent],
			100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100) AS [TotalLogFileUsedPercent]
		FROM #logFileInfoByDatabases lf
			LEFT JOIN (
				SELECT
					DatabaseName,
					SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
					SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
				FROM #logFileInfoByDatabases
				GROUP BY DatabaseName
			) totals ON lf.DatabaseName = totals.DatabaseName
		WHERE lf.DatabaseName = @databaseName
			AND LogFileCanGrow = 1
			AND (
				-- Место на диске меньше установленного порога, при этом файл лога заполнен более чем на указанный % в ограничениях
				(100 - (LogFileFreeSpaceMB / (LogSizeMB / 100))) >= @MaxLogUsagePercentThreshold AND [DiskFreeSpaceMB] <= @MinDiskFreeSpaceMB				
				OR
				-- Лог транзакций заполнен более чем на 95% от максимального размер лога (с учетом автоприроста)
				(100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) >= @MaxLogUsagePercentThreshold
			)
		OPEN checkLogFiles;

		FETCH NEXT FROM checkLogFiles 
		INTO @diskName, @logFilePath, @logFileFreeSpaceMB, @diskFreeSpaceMB, @logFileUsedPercent, @totalLogFileUsedPercent;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			IF(@totalLogFileUsedPercent >= @MaxLogUsagePercentThreshold)
			BEGIN
				SET @comment = 'Лог транзакций заполнен более чем на '
					+ CAST(@totalLogFileUsedPercent as nvarchar(max)) 
					+ '% от максимального размера лога транзакций с учетом автоприроста и ограничений размера файлов.'
			END ELSE BEGIN
				SET @comment = 'На диске ' + @diskName + ' осталось ' 
					+ CAST(@diskFreeSpaceMB as nvarchar(max)) 
					+ ' МБ, что меньше установленного ограничения в ' 
					+ CAST(@MinDiskFreeSpaceMB as nvarchar(max))
					+ ' МБ. При этом файл лога "'
					+ CAST(@logFilePath as nvarchar(max))
					+ '" заполнен уже на '
					+ CAST(@logFileUsedPercent as nvarchar(max))
					+ '%'
			END

			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = 'Обранужена проблема использования лога транзакций для базы ' 
					+ @databaseName 
					+ '. Описание: '
					+ @comment
				PRINT @message
			END


			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = 'Начало поиска соединений обслуживания для завершения. Поиск для базы: '
					+ @databaseName;
				PRINT @message
			END

			DECLARE @killCommand VARCHAR(15);
			DECLARE @badSessionId int;
			DECLARE badSessions CURSOR FOR
			SELECT  es.session_id
			FROM    sys.dm_exec_sessions es
				LEFT OUTER JOIN sys.dm_exec_requests rs ON (es.session_id = rs.session_id)  
				CROSS APPLY sys.dm_exec_sql_text(rs.sql_handle) AS sqltext
			WHERE (
					rs.command like '%ALTER INDEX%' 
					or (rs.command like '%DBCC%' AND sqltext.text like '%ALTER%INDEX%')
					or (rs.command like '%DBCC%' AND sqltext.text like '%EXECUTE%sp_IndexMaintenance%')
				  )
				AND es.database_id = DB_ID(@databaseName)
			OPEN badSessions;

			FETCH NEXT FROM badSessions 
			INTO @badSessionId;

			WHILE @@FETCH_STATUS = 0  
			BEGIN
				SET @killCommand = 'KILL ' + CAST(@badSessionId AS VARCHAR(5))

				IF(@showDiagnosticMessages = 1)
				BEGIN
					SET @message = 'Найденное проблемное соединение. Будет выполнена команда завершения: '
						+ @killCommand;
					PRINT @message
				END

				DECLARE @startDate datetime = GetDate(),
						@finishDate datetime = GetDate(),
						@MaintenanceActionLogId bigint;
				EXECUTE [dbo].[sp_add_maintenance_action_log]
				   ''
				  ,''
				  ,'TRANSACTION LOG CONTROL'
				  ,@RunDate
				  ,@startDate
				  ,@finishDate
				  ,@databaseName
				  ,0
				  ,@comment
				  ,0
				  ,0
				  ,@killCommand
				  ,@MaintenanceActionLogId OUTPUT;
						
				EXEC(@killCommand)

				FETCH NEXT FROM badSessions 
				INTO @badSessionId;
			END

			CLOSE badSessions;  
			DEALLOCATE badSessions;

			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = 'Окончание поиска соединений обслуживания для завершения. Поиск для базы: '
					+ @databaseName;
				PRINT @message
			END

			FETCH NEXT FROM checkLogFiles 
			INTO @diskName, @logFilePath, @logFileFreeSpaceMB, @diskFreeSpaceMB, @logFileUsedPercent, @totalLogFileUsedPercent;
		END

		CLOSE checkLogFiles;  
		DEALLOCATE checkLogFiles;

		IF(@showDiagnosticMessages = 1)
		BEGIN
				SET @message = 'Завершена проверка лога транзакций для базы ' 
				+ @databaseName 
				+ '. '
			PRINT @message
		END

		FETCH NEXT FROM databasesUnderControl 
		INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold;
	END
	CLOSE databasesUnderControl;  
	DEALLOCATE databasesUnderControl;

	IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;
END
GO

CREATE PROCEDURE [dbo].[sp_CreateOrUpdateJobsBySettings]
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

				SET @jobAlreadyExists = 0;
				SET @currentJobId = NULL;
				SET @currentjobVersionDate = NULL;

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
			SET @jobAlreadyExists = 0;
			SET @currentJobId = NULL;
			SET @currentjobVersionDate = NULL;

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
GO

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
			@stepNumber int = 0;
		SET @jobActionXml = @jobAction;
		
		SELECT 
			@totalSteps = COUNT(*)
		FROM @jobActionXml.nodes('/steps/step') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') IS NOT NULL
			AND ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') IS NOT NULL

		IF(@totalSteps = 0)
		BEGIN
			THROW 50000, 'Для информации. Описание шага не распознано как XML-структура. Используем скрипт как есть в единственном шаге.', 1; 
		END

		DECLARE job_steps_cursor CURSOR  
		FOR	SELECT 
			ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') AS [StepName],
			ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') AS [Script]
		FROM @jobActionXml.nodes('/steps/step') AS ActionInfo(Step)
		WHERE ActionInfo.Step.value('(name)[1]', 'nvarchar(max)') IS NOT NULL
			AND ActionInfo.Step.value('(script)[1]', 'nvarchar(max)') IS NOT NULL;
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
				@subsystem=N'TSQL', 
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
GO

CREATE PROCEDURE [dbo].[sp_FillConnectionsStatistic]
	@monitoringDatabaseName sysname = 'SQLServerMaintenance'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @cmd nvarchar(max);
	SET @cmd = 
CAST('
SET NOCOUNT ON;

INSERT INTO [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[ConnectionsStatistic]
           ([Period]
           ,[InstanceName]
           ,[QueryText]
           ,[RowCountSize]
           ,[SessionId]
           ,[Status]
           ,[Command]
           ,[CPU]
           ,[TotalElapsedTime]
           ,[StartTime]
           ,[DatabaseName]
           ,[BlockingSessionId]
           ,[WaitType]
           ,[WaitTime]
           ,[WaitResource]
           ,[OpenTransactionCount]
           ,[Reads]
           ,[Writes]
           ,[LogicalReads]
           ,[GrantedQueryMemory]
           ,[UserName]
)
SELECT 
	GetDate() AS [Period],
	@@servername AS [HostName],
	sqltext.TEXT AS [QueryText],
	req.row_count AS [RowCountSize],
	req.session_id AS [SessionId],
	req.status AS [Status],
	req.command AS [Command],
	req.cpu_time AS [CPU],
	req.total_elapsed_time AS [TotalElapsedTime],
	req.start_time AS [StartTime],
	DB_NAME(req.database_id) AS [DatabaseName],
	req.blocking_session_id AS [BlockingSessionId],
	req.wait_type AS [WaitType],
	req.wait_time AS [WaitTime],
	req.wait_resource AS [WaitResource],
	req.open_transaction_count AS [OpenTransactionCount],
	req.reads as [Reads],
	req.reads as [Writes],
	req.logical_reads as [LogicalReads],
	req.granted_query_memory as [GrantedQueryMemory],
	SUSER_NAME(user_id) AS [UserName]
FROM sys.dm_exec_requests req
	OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
' AS nvarchar(max));

	EXECUTE sp_executesql @cmd;

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_FillDatabaseObjectsState]
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@msg nvarchar(max),
		@monitoringDatabaseName sysname = DB_NAME();

    IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + @databaseName + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	DECLARE @cmd nvarchar(max);
	SET @cmd = 
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;

INSERT INTO [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState](
	[Period]
	,[DatabaseName]
	,[TableName]
	,[Object]
	,[PageCount]
	,[Rowmodctr]
	,[AvgFragmentationPercent]
	,[OnlineRebuildSupport]
	,[Compression]
	,[PartitionCount]
)
SELECT
  GETDATE() AS [Period],
  ''' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(''' AS [DatabaseName],
  OBJECT_NAME(dt.[object_id]) AS [Table], 
  ind.name AS [Object],
  MAX(CAST([page_count] AS BIGINT)) AS [page_count], 
  SUM(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr],
  MAX([avg_fragmentation_in_percent]) AS [frag], 
  MIN(CASE WHEN objBadTypes.IndexObjectId IS NULL THEN 1 ELSE 0 END) AS [OnlineRebuildSupport],
  MAX(p.data_compression_desc) AS [Compression],
  MAX(p_count.[PartitionCount]) AS [PartitionCount]
FROM 
  sys.dm_db_index_physical_stats (
    DB_ID(), 
    NULL, 
    NULL, 
    NULL, 
    N''LIMITED''
  ) dt 
  LEFT JOIN sys.partitions p
	ON dt.object_id = p.object_id and p.partition_number = 1
  LEFT JOIN sys.sysindexes si ON dt.object_id = si.id 
  LEFT JOIN (
		SELECT 
		  t.object_id AS [TableObjectId], 
		  ind.index_id AS [IndexObjectId]
		FROM 
		  sys.indexes ind 
		  INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id 
		  and ind.index_id = ic.index_id 
		  INNER JOIN sys.columns col ON ic.object_id = col.object_id 
		  and ic.column_id = col.column_id 
		  INNER JOIN sys.tables t ON ind.object_id = t.object_id 
		  LEFT JOIN INFORMATION_SCHEMA.COLUMNS tbsc ON t.schema_id = SCHEMA_ID(tbsc.TABLE_SCHEMA) 
		  AND t.name = tbsc.TABLE_NAME 
		  LEFT JOIN sys.types tps ON col.system_type_id = tps.system_type_id 
		  AND col.user_type_id = tps.user_type_id 
		WHERE 
		  t.is_ms_shipped = 0 
		  AND CASE WHEN ind.type_desc = ''CLUSTERED'' THEN CASE WHEN tbsc.DATA_TYPE IN (
			''text'', ''ntext'', ''image'', ''FILESTREAM''
		  ) THEN 1 ELSE 0 END ELSE CASE WHEN tps.[name] IN (
			''text'', ''ntext'', ''image'', ''FILESTREAM''
		  ) THEN 1 ELSE 0 END END > 0 
		GROUP BY 
		  t.object_id, 
		  ind.index_id
	  ) AS objBadTypes ON objBadTypes.TableObjectId = dt.object_id 
	  AND objBadTypes.IndexObjectId = dt.index_id
	LEFT JOIN sys.indexes AS [ind]
		ON dt.object_id = [ind].object_id AND dt.index_id = [ind].[index_id]
	LEFT JOIN (
		SELECT
			object_id,
			index_id,
			COUNT(DISTINCT partition_number) AS [PartitionCount]
		FROM sys.partitions p
		GROUP BY object_id, index_id
	) p_count
	ON dt.object_id = p_count.object_id AND dt.index_id = p_count.index_id
WHERE 
  [rowmodctr] IS NOT NULL -- Исключаем служебные объекты, по которым нет изменений
  AND dt.[index_id] > 0 -- игнорируем кучи (heap)
GROUP BY
	dt.[object_id], 
	dt.[index_id],
	ind.[name],
	dt.[partition_number]
' AS nvarchar(max));

	EXECUTE sp_executesql @cmd;

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_FixMissingStatisticOnAlwaysOnReplica]
	@databaseName sysname = null
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@msg nvarchar(max),
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;

    IF @databaseName IS NOT NULL AND DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END

	DECLARE @currentDatabaseName sysname;

	DECLARE databases_cursor CURSOR  
	FOR SELECT
		[name]
	FROM sys.databases
	WHERE (@databaseName is null or [name] = @databaseName)
		AND [name] in (
			select distinct
				database_name
			from sys.dm_hadr_database_replica_cluster_states dhdrcs
				inner join sys.availability_replicas ar
				on dhdrcs.replica_id = ar.replica_id
			where availability_mode_desc = 'ASYNCHRONOUS_COMMIT'
		)
	OPEN databases_cursor;
	FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT @currentDatabaseName;

		DECLARE @sql nvarchar(max);
		SET @sql = CAST('
		USE [' AS nvarchar(max)) + CAST(@currentDatabaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;

		DECLARE
			@objid int,
			@statsid INT,
			@NeedResetCache bit = 0,
			@dbname sysname = DB_NAME();
		DECLARE cur CURSOR FOR
 
		SELECT s.object_id, s.stats_id
		FROM sys.stats AS s
			JOIN sys.objects AS o
			ON s.object_id = o.object_id
		WHERE s.auto_created = 1
			AND o.is_ms_shipped = 0
		OPEN cur
		FETCH NEXT FROM cur INTO @objid, @statsid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if not exists (select *
			from [sys].[dm_db_stats_properties] (@objid, @statsid))
		BEGIN
 
				PRINT (convert(varchar(10), @objid) + ''|'' + convert(varchar(10), @statsid))
 
				IF(@useMonitoringDatabase = 1)
				BEGIN
					INSERT [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[AlwaysOnReplicaMissingStats]
					SELECT @dbname, o.[name], s.[name], GETDATE()
					FROM sys.stats AS s JOIN sys.objects AS o
						ON s.object_id = o.object_id
					WHERE o.object_id = @objid AND s.stats_id = @statsid
				END
				
				SET @NeedResetCache = 1
 
			END
			FETCH NEXT FROM cur INTO @objid, @statsid
		END
		CLOSE cur
		DEALLOCATE cur
 
		IF @NeedResetCache = 1
		BEGIN
			PRINT ''Был сброшен системный кэш для базы данных''
			PRINT @dbname
			DBCC FREESYSTEMCACHE(@dbname);
		END
		' AS nvarchar(max))

		EXECUTE sp_executesql
			@sql,
			N'@useMonitoringDatabase bit, @monitoringDatabaseName sysname',
			@useMonitoringDatabase, @monitoringDatabaseName

		FETCH NEXT FROM databases_cursor INTO @currentDatabaseName;
	END
	CLOSE databases_cursor;  
	DEALLOCATE databases_cursor;
END
GO

CREATE PROCEDURE [dbo].[sp_GetCurrentResumableIndexRebuilds] 
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END

	DECLARE @LOCAL_ResumableIndexRebuilds TABLE
	(
		[object_id] int, 
		[index_id] int, 
		[name] sysname, 
		[sql_text] nvarchar(max), 
		[partition_number] int,
		[state] tinyint, 
		[state_desc] nvarchar(60),
		[start_time] datetime,
		[last_pause_time] datetime,
		[total_execution_time] int,
		[percent_complete] real,
		[page_count] bigint
	);

	IF([dbo].[fn_ResumableIndexMaintenanceAvailiable]() > 0)
	BEGIN
		DECLARE @cmd nvarchar(max);
		SET @cmd = CAST('
		USE [' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;
		SELECT
			[object_id], 
			[index_id], 
			[name], 
			[sql_text], 
			[partition_number],
			[state], 
			[state_desc],
			[start_time],
			[last_pause_time],
			[total_execution_time],
			[percent_complete],
			[page_count]
		FROM sys.index_resumable_operations;
		' AS nvarchar(max));
		INSERT @LOCAL_ResumableIndexRebuilds
		EXECUTE sp_executesql @cmd;
	END

	SELECT
		[object_id], 
		[index_id], 
		[name], 
		[sql_text], 
		[partition_number],
		[state], 
		[state_desc],
		[start_time],
		[last_pause_time],
		[total_execution_time],
		[percent_complete],
		[page_count]
	FROM @LOCAL_ResumableIndexRebuilds
END
GO

CREATE PROCEDURE [dbo].[sp_IndexMaintenance]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
    @fragmentationPercentMinForMaintenance FLOAT = 10.0,
    @fragmentationPercentForRebuild FLOAT = 30.0,
    @maxDop int = 8,
    @minIndexSizePages int = 0,
    @maxIndexSizePages int = 0,
    @useOnlineIndexRebuild int = 0,
	@useResumableIndexRebuildIfAvailable int = 0,
    @maxIndexSizeForReorganizingPages int = 6553600,
    @usePreparedInformationAboutObjectsStateIfExists bit = 0,
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
    @ConditionIndexName nvarchar(max) = 'LIKE ''%''',
    @onlineRebuildAbortAfterWaitMode int = 1,
    @onlineRebuildWaitMinutes int = 5,
    @maxTransactionLogSizeUsagePercent int = 100,  
    @maxTransactionLogSizeMB bigint = 0,
	@fillFactorForIndex int = 0
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @msg nvarchar(max),
            @abortAfterWaitOnlineRebuil nvarchar(25),
            @currentTransactionLogSizeUsagePercent int,
            @currentTransactionLogSizeMB int,
			@timeNow TIME = CAST(GETDATE() AS TIME),
			@useResumableIndexRebuild bit,
			@RunDate datetime = GETDATE(),
			@StartDate datetime,
			@FinishDate datetime,
			@MaintenanceActionLogId bigint,
			-- Список исключенных из обслуживания индексов.
			-- Например, если они были обслужены через механизм возобновляемых перестроений,
			-- еще до запуска основного обслуживания
			@excludeIndexes XML,
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

	IF(@fillFactorForIndex = 0)
	BEGIN
		select
			@fillFactorForIndex = CAST(value_in_use AS INT)
		from sys.configurations
		where name = 'fill factor (%)'
	END
	IF(@fillFactorForIndex = 0)
	BEGIN
		SET @fillFactorForIndex = 100
	END
 
    IF(@onlineRebuildAbortAfterWaitMode = 0)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'NONE'
    END ELSE IF(@onlineRebuildAbortAfterWaitMode = 1)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'SELF'
    END ELSE IF(@onlineRebuildAbortAfterWaitMode = 2)
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'BLOCKERS'
    END ELSE
    BEGIN
        SET @abortAfterWaitOnlineRebuil = 'NONE'
    END
 
    IF DB_ID(@databaseName) IS NULL
    BEGIN
        SET @msg = 'Database ' + @databaseName + ' is not exists.';
        THROW 51000, @msg, 1;
        RETURN -1;
    END
 
    -- Информация о размере лога транзакций
    IF OBJECT_ID('tempdb..#tranLogInfo') IS NOT NULL
        DROP TABLE #tranLogInfo;
    CREATE TABLE #tranLogInfo
    (
        servername varchar(255) not null default @@servername,
        dbname varchar(255),
        logsize real,
        logspace real,
        stat int
    )
 
    -- Проверка процента занятого места в логе транзакций
    TRUNCATE TABLE #tranLogInfo;
    INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
    SELECT
        @currentTransactionLogSizeUsagePercent = logspace,
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM #tranLogInfo WHERE dbname = @databaseName
    IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
    BEGIN
        -- Процент занятого места в файлах лога транзакций превышает указанный порог
        RETURN 0;
    END
    IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
    BEGIN
        -- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
        RETURN 0;
    END

	EXECUTE [dbo].[sp_apply_maintenance_action_to_run] 
		@databaseName;
 
	-- Возобновляемое перестроение индексов
	DECLARE @LOCAL_ResumableIndexRebuilds TABLE
	(
		[object_id] int, 
		[object_name] nvarchar(255), 
		[index_id] int, 
		[name] sysname, 
		[sql_text] nvarchar(max), 
		[partition_number] int,
		[state] tinyint, 
		[state_desc] nvarchar(60),
		[start_time] datetime,
		[last_pause_time] datetime,
		[total_execution_time] int,
		[percent_complete] real,
		[page_count] bigint,
		[ResumeCmd] nvarchar(max)
	);
	-- Флаг использования возобновляемого перестроения индексов
	SET @useResumableIndexRebuild = 
		CASE
			WHEN (@useResumableIndexRebuildIfAvailable > 0)	-- Передан флаг использования возобновляемого перестроения
			-- Возобновляемое перестроение доступно для версии SQL Server
			AND [dbo].[fn_ResumableIndexMaintenanceAvailiable]() > 0
			-- Включено использование онлайн-перестроения для скрипта
			AND (@useOnlineIndexRebuild = 1 -- Только онлайн-перестроение
				OR @useOnlineIndexRebuild = 3) -- Для объектов где оно возможно
			THEN 1
			ELSE 0
		END;
	IF(@useResumableIndexRebuild > 0)
	BEGIN
		DECLARE @cmdResumableIndexRebuild nvarchar(max);
		SET @cmdResumableIndexRebuild = CAST('
		USE [' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST(']
		SET NOCOUNT ON;
		SELECT
			[object_id],
			OBJECT_NAME([object_id]) AS [TableName],
			[index_id], 
			[name], 
			[sql_text], 
			[partition_number],
			[state], 
			[state_desc],
			[start_time],
			[last_pause_time],
			[total_execution_time],
			[percent_complete],
			[page_count],
			''ALTER INDEX ['' + [name] + ''] ON ['' + OBJECT_SCHEMA_NAME([object_id]) + ''].['' + OBJECT_NAME([object_id]) + ''] RESUME'' AS [ResumeCmd]
		FROM sys.index_resumable_operations
		WHERE OBJECT_NAME([object_id]) ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
			AND [name] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST(';
		' AS nvarchar(max));
		INSERT @LOCAL_ResumableIndexRebuilds
		EXECUTE sp_executesql @cmdResumableIndexRebuild;

		DECLARE 
			@objectNameResumeRebuildForIndex nvarchar(255), 
			@indexNameResumeRebuildForIndex nvarchar(255), 
			@cmdResumeRebuildForIndex nvarchar(max);
		DECLARE resumableIndexRebuild_cursor CURSOR FOR				
		SELECT 
			[object_name],
			[name],
			[ResumeCmd]
		FROM @LOCAL_ResumableIndexRebuilds
		ORDER BY start_time;
		OPEN resumableIndexRebuild_cursor;		
		FETCH NEXT FROM resumableIndexRebuild_cursor 
		INTO @objectNameResumeRebuildForIndex, @indexNameResumeRebuildForIndex, @cmdResumeRebuildForIndex;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			-- Проверка доступен ли запуск обслуживания в текущее время
			SET @timeNow = CAST(GETDATE() AS TIME);
			IF (@timeTo >= @timeFrom) BEGIN
				IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
					RETURN;
				END ELSE BEGIN
					IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
						OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow))) 
							RETURN;
			END

			-- Проверки использования лога транзакций
			-- Проверка процента занятого места в логе транзакций
			TRUNCATE TABLE #tranLogInfo;
			INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
			SELECT
				@currentTransactionLogSizeUsagePercent = logspace,
				@currentTransactionLogSizeMB = logsize * (logspace / 100)
			FROM #tranLogInfo WHERE dbname = @databaseName
			IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
			BEGIN
				-- Процент занятого места в файлах лога транзакций превышает указанный порог
				RETURN 0;
			END
			IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
			BEGIN
				-- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
				RETURN 0;
			END
			
			BEGIN TRY
				-- Сохраняем предварительную информацию об операции обслуживания без даты завершения				
				IF(@useMonitoringDatabase = 1)
				BEGIN
					SET @StartDate = GETDATE();
					EXECUTE [dbo].[sp_add_maintenance_action_log]
						@objectNameResumeRebuildForIndex,
						@indexNameResumeRebuildForIndex,
						'REBUILD INDEX RESUME',
						@RunDate,
						@StartDate,
						null,
						@databaseName,
						1, -- @UseOnlineRebuild
						'',
						0, -- @AvgFragmentationPercent
						0, -- @RowModCtr
						@cmdResumeRebuildForIndex,
						@MaintenanceActionLogId OUTPUT;
				END

				SET @cmdResumeRebuildForIndex = CAST('
					USE [' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST(']
					SET NOCOUNT ON;
					' + CAST(@cmdResumeRebuildForIndex as nvarchar(max)) + '
				' AS nvarchar(max));
				EXECUTE sp_executesql @cmdResumeRebuildForIndex;
				SET @FinishDate = GetDate();

				-- Устанавливаем фактическую дату завершения операции
				IF(@useMonitoringDatabase = 1)
				BEGIN
					EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
						@MaintenanceActionLogId,
						@FinishDate;
				END				
			END TRY
			BEGIN CATCH		
				IF(@MaintenanceActionLogId <> 0)
				BEGIN
					SET @msg = 'Error: ' + CAST(Error_message() AS NVARCHAR(500)) + ', Code: ' + CAST(Error_Number() AS NVARCHAR(500)) + ', Line: ' + CAST(Error_Line() AS NVARCHAR(500))
					-- Устанавливаем текст ошибки при обслуживании индекса
					-- Дата завершения при этом остается незаполненной
					EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
						@MaintenanceActionLogId,
						@FinishDate,
						@msg;          
				END
			END CATCH

			FETCH NEXT FROM resumableIndexRebuild_cursor 
			INTO @objectNameResumeRebuildForIndex, @indexNameResumeRebuildForIndex, @cmdResumeRebuildForIndex;
		END
		CLOSE resumableIndexRebuild_cursor;  
		DEALLOCATE resumableIndexRebuild_cursor;
	END
	-- Сохраняем список индексов, для которых имеются ожидающие операции перестроения
	-- Они будут исключены из основного обслуживания
	SET @excludeIndexes = (SELECT
		[name]
	FROM @LOCAL_ResumableIndexRebuilds
	FOR XML RAW, ROOT('root'));
	
	--PRINT 'Прервано для отладки'
	--RETURN 0;
 
    DECLARE @cmd nvarchar(max);
    SET @cmd =
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;
DECLARE
    -- Текущее время
    @timeNow TIME = CAST(GETDATE() AS TIME),
    -- Текущий процент использования файла лога транзакций
    @currentTransactionLogSizeUsagePercent int,
    @currentTransactionLogSizeMB bigint;
 
-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
    IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
        RETURN;
    END ELSE BEGIN
        IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
            OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow))) 
                RETURN;
END
 
-- Служебные переменные
DECLARE
    @DBID SMALLINT = DB_ID()
    ,@DBNAME sysname = DB_NAME()
    ,@SchemaName SYSNAME
    ,@ObjectName SYSNAME
    ,@ObjectID INT
    ,@Priority INT
    ,@IndexID INT
    ,@IndexName SYSNAME
    ,@PartitionNum BIGINT
    ,@PartitionCount BIGINT
    ,@frag FLOAT
    ,@Command NVARCHAR(max)
    ,@CommandSpecial NVARCHAR(max)
    ,@Operation NVARCHAR(128)
    ,@RowModCtr BIGINT
    ,@AvgFragmentationPercent float
    ,@PageCount BIGINT
    ,@SQL nvarchar(max)
    ,@SQLSpecial nvarchar(max)
    ,@OnlineRebuildSupport int
    ,@UseOnlineRebuild int
    ,@StartDate datetime
    ,@FinishDate datetime
    ,@RunDate datetime = GETDATE()
    ,@MaintenanceActionLogId bigint
    ,@CurrentReorganizeIndexAllowPageLocks bit
	,@CurrentSqlDisableAllowPageLocksIfNeeded nvarchar(max)
	,@CurrentMaintenanceActionToRunId int;
 
IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
    DROP TABLE #MaintenanceCommands;
IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
    DROP TABLE #MaintenanceCommandsTemp;
 
CREATE TABLE #MaintenanceCommands
(
    [Command] nvarchar(max),
    [CommandSpecial] nvarchar(max),
    [Table] nvarchar(250),
    [Object] nvarchar(250),
    [page_count] BIGINT,
    [Rowmodctr] BIGINT,
    [Avg_fragmentation_in_percent] INT,
    [Operation] nvarchar(max),
    [Priority] INT,
    [OnlineRebuildSupport] INT,
    [UseOnlineRebuild] INT,
    [PartitionCount] BIGINT
)
 
IF OBJECT_ID(''tempdb..#tranLogInfo'') IS NOT NULL
    DROP TABLE #tranLogInfo;
CREATE TABLE #tranLogInfo
(
    servername varchar(255) not null default @@servername,
    dbname varchar(255),
    logsize real,
    logspace real,
    stat int
)
 
DECLARE @usedCacheAboutObjectsState bit = 0;
 
IF @usePreparedInformationAboutObjectsStateIfExists = 1
    AND EXISTS(SELECT *
          FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState]
          WHERE [DatabaseName] = @databaseName
            -- Информация должна быть собрана в рамках 12 часов от текущего запуска
            AND [Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate))
BEGIN  
    -- Получаем информацию через подготовленный сбор
    SET @usedCacheAboutObjectsState = 1;
 
    SELECT
      OBJECT_ID(dt.[TableName]) AS [objectid]
      ,ind.index_id as [indexid]
      ,1 AS [partitionnum]
      ,[AvgFragmentationPercent] AS [frag]
      ,[PageCount] AS [page_count]
      ,[Rowmodctr] AS [rowmodctr]
      ,ISNULL(prt.[Priority], 999) AS [Priority]
      ,ISNULL(prt.[Exclude], 0) AS Exclude
      ,dt.[OnlineRebuildSupport] AS [OnlineRebuildSupport]
      ,dt.[PartitionCount] AS [PartitionCount]
    INTO #MaintenanceCommandsTempCached
    FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState] dt
        LEFT JOIN sys.indexes ind
            ON OBJECT_ID(dt.[TableName]) = ind.object_id
                AND dt.[Object] = ind.[name]
        LEFT JOIN [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[MaintenanceIndexPriority] AS [prt]
            ON dt.DatabaseName = prt.[DatabaseName]
                AND dt.TableName = prt.TableName
                AND dt.[Object] = prt.Indexname
    WHERE dt.[DatabaseName] = @databaseName
        AND [Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate)
        -- Записи от последнего получения данных за прошедшие 12 часов
        AND [Period] IN (
            SELECT MAX([Period])
            FROM [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[DatabaseObjectsState]
            WHERE [DatabaseName] = @databaseName
                AND dt.[Period] BETWEEN DATEADD(hour, -12, @RunDate) AND DATEADD(hour, 12, @RunDate))
        AND [AvgFragmentationPercent] > @fragmentationPercentMinForMaintenance
        AND [PageCount] > 25 -- игнорируем небольшие таблицы
        -- Фильтр по мин. размеру индекса
        AND (@minIndexSizePages = 0 OR [PageCount] >= @minIndexSizePages)
        -- Фильтр по макс. размеру индекса
        AND (@maxIndexSizePages = 0 OR [PageCount] <= @maxIndexSizePages)
        -- Убираем обработку индексов, исключенных из обслуживания
        AND ISNULL(prt.[Exclude], 0) = 0
        -- Отбор по имени таблцы
        AND dt.[TableName] ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
        AND dt.[Object] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST('
		AND NOT dt.[Object] IN (
			SELECT 
				XC.value(''@name'', ''nvarchar(255)'') AS [IndexName]
			FROM @excludeIndexes.nodes(''/root/row'') AS XT(XC)
		)
END ELSE
BEGIN
    -- Получаем информацию через анализ базы данных
    SELECT
        dt.[object_id] AS [objectid],
        dt.index_id AS [indexid],
        [partition_number] AS [partitionnum],
        MAX([avg_fragmentation_in_percent]) AS [frag],
        MAX(CAST([page_count] AS BIGINT)) AS [page_count],
        SUM(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr],
        MAX(
            ISNULL(prt.[Priority], 999)
        ) AS [Priority],
        MAX(
            CAST(ISNULL(prt.[Exclude], 0) AS INT)
        ) AS [Exclude],
        MIN(CASE WHEN objBadTypes.IndexObjectId IS NULL THEN 1 ELSE 0 END) AS [OnlineRebuildSupport],
        MAX(p_count.[PartitionCount]) AS [PartitionCount]
    INTO #MaintenanceCommandsTemp
    FROM
        sys.dm_db_index_physical_stats (
            DB_ID(),
            NULL,
            NULL,
            NULL,
            N''LIMITED''
        ) dt
        LEFT JOIN sys.sysindexes si ON dt.object_id = si.id AND si.indid = dt.index_id
        LEFT JOIN (
            SELECT
            t.object_id AS [TableObjectId],
            ind.index_id AS [IndexObjectId]
            FROM
            sys.indexes ind
            INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id
            and ind.index_id = ic.index_id
            INNER JOIN sys.columns col ON ic.object_id = col.object_id
            and ic.column_id = col.column_id
            INNER JOIN sys.tables t ON ind.object_id = t.object_id
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS tbsc ON t.schema_id = SCHEMA_ID(tbsc.TABLE_SCHEMA)
            AND t.name = tbsc.TABLE_NAME
            LEFT JOIN sys.types tps ON col.system_type_id = tps.system_type_id
            AND col.user_type_id = tps.user_type_id
            WHERE
            t.is_ms_shipped = 0
            AND CASE WHEN ind.type_desc = ''CLUSTERED'' THEN CASE WHEN tbsc.DATA_TYPE IN (
                ''text'', ''ntext'', ''image'', ''FILESTREAM''
            ) THEN 1 ELSE 0 END ELSE CASE WHEN tps.[name] IN (
                ''text'', ''ntext'', ''image'', ''FILESTREAM''
            ) THEN 1 ELSE 0 END END > 0
            GROUP BY
            t.object_id,
            ind.index_id
        ) AS objBadTypes ON objBadTypes.TableObjectId = dt.object_id
        AND objBadTypes.IndexObjectId = dt.index_id
        LEFT JOIN (
            SELECT
            i.[object_id],
            i.[index_id],
            os.[Priority] AS [Priority],
            os.[Exclude] AS [Exclude]
            FROM sys.indexes i
                left join [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[MaintenanceIndexPriority] os
                ON i.object_id = OBJECT_ID(os.TableName)
                    AND i.Name = os.IndexName
            WHERE os.Id IS NOT NULL
                and os.DatabaseName = ''' AS nvarchar(max)) + CAST(@databaseName AS nvarchar(max)) + CAST('''
            ) prt ON si.id = prt.[object_id]
        AND dt.[index_id] = prt.[index_id]
        LEFT JOIN (
            SELECT
                object_id,
                index_id,
                COUNT(DISTINCT partition_number) AS [PartitionCount]
            FROM sys.partitions p
            GROUP BY object_id, index_id
        ) p_count
        ON dt.object_id = p_count.object_id AND dt.index_id = p_count.index_id
    WHERE
        [rowmodctr] IS NOT NULL -- Исключаем служебные объекты, по которым нет изменений
        AND [avg_fragmentation_in_percent] > @fragmentationPercentMinForMaintenance
        AND dt.[index_id] > 0 -- игнорируем кучи (heap)
        AND [page_count] > 25 -- игнорируем небольшие таблицы
        -- Фильтр по мин. размеру индекса
        AND (@minIndexSizePages = 0 OR [page_count] >= @minIndexSizePages)
        -- Фильтр по макс. размеру индекса
        AND (@maxIndexSizePages = 0 OR [page_count] <= @maxIndexSizePages)
        -- Убираем обработку индексов, исключенных из обслуживания
        AND ISNULL(prt.[Exclude], 0) = 0
        -- Отбор по имени таблцы
        AND OBJECT_NAME(dt.[object_id]) ' AS nvarchar(max)) + CAST(@ConditionTableName  AS nvarchar(max)) + CAST('
        AND si.[name] ' AS nvarchar(max)) + CAST(@ConditionIndexName  AS nvarchar(max)) + CAST('
		AND NOT si.[name] IN (
			SELECT 
				XC.value(''@name'', ''nvarchar(255)'') AS [IndexName]
			FROM @excludeIndexes.nodes(''/root/row'') AS XT(XC)
		)
    GROUP BY
        dt.[object_id],
        dt.[index_id],
        [partition_number];
END
 
IF(@usedCacheAboutObjectsState = 1)
BEGIN
    DECLARE partitions CURSOR FOR
    SELECT [objectid], [indexid], [partitionnum], [frag], [page_count], [rowmodctr], [Priority], [OnlineRebuildSupport], [PartitionCount]
    FROM #MaintenanceCommandsTempCached;
END ELSE
BEGIN
    DECLARE partitions CURSOR FOR
    SELECT [objectid], [indexid], [partitionnum], [frag], [page_count], [rowmodctr], [Priority], [OnlineRebuildSupport], [PartitionCount]
    FROM #MaintenanceCommandsTemp;
END
 
OPEN partitions;
WHILE (1=1)
BEGIN
    FETCH NEXT FROM partitions INTO @ObjectID, @IndexID, @PartitionNum, @frag, @PageCount, @RowModCtr, @Priority, @OnlineRebuildSupport, @PartitionCount;
    IF @@FETCH_STATUS < 0 BREAK;
     
    SELECT @ObjectName = QUOTENAME([o].[name]), @SchemaName = QUOTENAME([s].[name])
    FROM sys.objects AS o
        JOIN sys.schemas AS s ON [s].[schema_id] = [o].[schema_id]
    WHERE [o].[object_id] = @ObjectID;
    SELECT @IndexName = QUOTENAME(name)
    FROM sys.indexes
    WHERE [object_id] = @ObjectID AND [index_id] = @IndexID;
     
    SET @CommandSpecial = '''';
    SET @Command = '''';
    -- Реорганизация индекса
    IF @Priority > 10 -- Приоритет обслуживания не большой
        AND @frag <= @fragmentationPercentForRebuild -- Процент фрагментации небольшой
        AND (@maxIndexSizeForReorganizingPages = 0 OR @PageCount <= @maxIndexSizeForReorganizingPages) BEGIN -- Таблица меньше 50 ГБ
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName + N'' REORGANIZE'';
        SET @Operation = ''REORGANIZE INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 0) -- Не использовать онлайн-перестроение
    BEGIN
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF (@useOnlineIndexRebuild = 1 AND @OnlineRebuildSupport = 1) -- Только с поддержкой онлайн перестроения
    BEGIN
        SET @CommandSpecial = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '','' 
			+ (CASE WHEN @useResumableIndexRebuild > 0 THEN '' RESUMABLE = ON, '' ELSE '''' END) 
			+ '' ONLINE = ON (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = ' AS nvarchar(max)) + CAST(@onlineRebuildWaitMinutes  AS nvarchar(max)) + CAST(' MINUTES, ABORT_AFTER_WAIT = ' AS nvarchar(max)) + CAST(@abortAfterWaitOnlineRebuil  AS nvarchar(max)) + CAST(')))'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 2 AND @OnlineRebuildSupport = 0) -- Только без поддержки
    BEGIN
        SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
            + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        SET @Operation = ''REBUILD INDEX''
    END ELSE IF(@useOnlineIndexRebuild = 3) -- Использовать онлайн перестроение где возможно
    BEGIN
        if(@OnlineRebuildSupport = 1)
        BEGIN
            SET @CommandSpecial = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
                + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '','' 
				+ (CASE WHEN @useResumableIndexRebuild > 0 THEN '' RESUMABLE = ON, '' ELSE '''' END) 
				+ '' ONLINE = ON (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = ' AS nvarchar(max)) + CAST(@onlineRebuildWaitMinutes  AS nvarchar(max)) + CAST(' MINUTES, ABORT_AFTER_WAIT = ' AS nvarchar(max)) + CAST(@abortAfterWaitOnlineRebuil  AS nvarchar(max)) + CAST(')))'';
        END ELSE
        BEGIN
            SET @Command = N''ALTER INDEX '' + @IndexName + N'' ON '' + @SchemaName + N''.'' + @ObjectName
                + N'' REBUILD WITH (FILLFACTOR='' + CAST(@fillFactorForIndex AS nvarchar(10)) + '', MAXDOP='' + CAST(@MaxDop AS nvarchar(10)) + '')'';
        END
        SET @Operation = ''REBUILD INDEX''
    END
    IF (@PartitionCount > 1 AND @Command <> '''')
        SET @Command = @Command + N'' PARTITION='' + CAST(@PartitionNum AS nvarchar(10));
 
    SET @Command = LTRIM(RTRIM(@Command));
    SET @CommandSpecial = LTRIM(RTRIM(@CommandSpecial));
    IF(LEN(@Command) > 0 OR LEN(@CommandSpecial) > 0)
    BEGIN      
        INSERT #MaintenanceCommands
            ([Command], [CommandSpecial], [Table], [Object], [Rowmodctr], [Avg_fragmentation_in_percent], [Operation], [Priority], [OnlineRebuildSupport])
        VALUES
            (@Command, @CommandSpecial, @ObjectName, @IndexName, @RowModCtr, @frag, @Operation, @Priority, @OnlineRebuildSupport);
    END
END
CLOSE partitions;
DEALLOCATE partitions;
DECLARE todo CURSOR FOR
SELECT
    [Command],
    [CommandSpecial],
    [Table],
    [Object],
    [Operation],
    [OnlineRebuildSupport],
    [Rowmodctr],
    [Avg_fragmentation_in_percent]
FROM #MaintenanceCommands
ORDER BY
    [Priority],
    [Rowmodctr] DESC,
    [Avg_fragmentation_in_percent] DESC
OPEN todo;
WHILE 1=1
BEGIN
    FETCH NEXT FROM todo INTO @SQL, @SQLSpecial, @ObjectName, @IndexName, @Operation, @OnlineRebuildSupport, @RowModCtr, @AvgFragmentationPercent;
          
    IF @@FETCH_STATUS != 0    
        BREAK;
    -- Проверка доступен ли запуск обслуживания в текущее время
    SET @timeNow = CAST(GETDATE() AS TIME);
    IF (@timeTo >= @timeFrom) BEGIN
        IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
            RETURN;
    END ELSE BEGIN
        IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
            OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow))) 
        RETURN;
    END
 
    -- Проверка процента занятого места в логе транзакций
    TRUNCATE TABLE #tranLogInfo;
    INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec(''dbcc sqlperf(logspace)'');
    SELECT
        @currentTransactionLogSizeUsagePercent = logspace,
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM #tranLogInfo WHERE dbname = @databaseName
    IF(@currentTransactionLogSizeUsagePercent >= @maxTransactionLogSizeUsagePercent)
    BEGIN
        -- Процент занятого места в файлах лога транзакций превышает указанный порог
        RETURN;
    END
    IF(@maxTransactionLogSizeMB > 0 AND @currentTransactionLogSizeMB > @maxTransactionLogSizeMB)
    BEGIN
        -- Размер занятого места в файлах лога транзакций превышает указанный порог в МБ
        RETURN;
    END
 
    SET @StartDate = GetDate();
    BEGIN TRY
        DECLARE @currentSQL nvarchar(max) = ''''
        SET @MaintenanceActionLogId = 0
        IF(@SQLSpecial = '''')
        BEGIN
            SET @currentSQL = @SQL
            SET @UseOnlineRebuild = 0;
        END ELSE
        BEGIN
            SET @UseOnlineRebuild = 1;
            SET @currentSQL = @SQLSpecial
        END

		SET @CurrentSqlDisableAllowPageLocksIfNeeded = null;
		IF(@Operation = ''REORGANIZE INDEX'')
		BEGIN
			DECLARE 
				@IndexNameNormalized nvarchar(255),
				@TableNameNormalized nvarchar(255),
				@SchemaNameNormalized nvarchar(255);
			SET @TableNameNormalized = REPLACE(@ObjectName, ''['', '''')
			SET @TableNameNormalized = REPLACE(@TableNameNormalized, '']'', '''')
			SET @IndexNameNormalized = REPLACE(@IndexName, ''['', '''')
			SET @IndexNameNormalized = REPLACE(@IndexNameNormalized, '']'', '''')

			SELECT
				@SchemaNameNormalized = SCHEMA_NAME(o.schema_id),	
				@CurrentReorganizeIndexAllowPageLocks = [allow_page_locks]
			FROM sys.indexes i
				left join sys.objects o
				on i.object_id = o.object_id
			WHERE i.[name] = @IndexNameNormalized
						
			IF(@CurrentReorganizeIndexAllowPageLocks = 0)
			BEGIN
				DECLARE @sqlEnableAllowPageLocks nvarchar(max);
				SET @sqlEnableAllowPageLocks = ''ALTER INDEX ['' + @IndexNameNormalized + ''] ON ['' + @SchemaNameNormalized + ''].['' + @TableNameNormalized + ''] SET (ALLOW_PAGE_LOCKS = ON);''
				SET @CurrentSqlDisableAllowPageLocksIfNeeded = ''ALTER INDEX ['' + @IndexNameNormalized + ''] ON ['' + @SchemaNameNormalized + ''].['' + @TableNameNormalized + ''] SET (ALLOW_PAGE_LOCKS = OFF);''
				EXEC sp_executesql @sqlEnableAllowPageLocks;

				EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_to_run]
					@DBNAME,
					@Operation,
					@CurrentSqlDisableAllowPageLocksIfNeeded,
					@CurrentMaintenanceActionToRunId OUTPUT;
					
			END
		END

        -- Сохраняем предварительную информацию об операции обслуживания без даты завершения
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_log]
               @ObjectName
              ,@IndexName
              ,@Operation
              ,@RunDate
              ,@StartDate
              ,null
              ,@DBNAME
              ,@UseOnlineRebuild
              ,''''
              ,@AvgFragmentationPercent
              ,@RowModCtr
              ,@currentSQL
              ,@MaintenanceActionLogId OUTPUT;
        END
        EXEC sp_executesql @currentSQL;

		IF(@Operation = ''REORGANIZE INDEX'' AND @CurrentSqlDisableAllowPageLocksIfNeeded IS NOT NULL)
		BEGIN
			EXEC sp_executesql @CurrentSqlDisableAllowPageLocksIfNeeded;
			EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_remove_maintenance_action_to_run]
				@CurrentMaintenanceActionToRunId;
		END

        SET @FinishDate = GetDate();
         
        -- Устанавливаем фактическую дату завершения операции
        IF(@useMonitoringDatabase = 1)
        BEGIN
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
                @MaintenanceActionLogId,
                @FinishDate;
        END 
    END  TRY   
    BEGIN CATCH
        IF(@MaintenanceActionLogId <> 0)
        BEGIN
            DECLARE @msg nvarchar(500) = ''Error: '' + CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' + CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' + CAST(Error_Line() AS NVARCHAR(500))
            -- Устанавливаем текст ошибки при обслуживании индекса
            -- Дата завершения при этом остается незаполненной
            EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
                @MaintenanceActionLogId,
                @FinishDate,
                @msg;          
        END            
    END CATCH
END
     
CLOSE todo;
DEALLOCATE todo;
IF OBJECT_ID(''tempdb..#MaintenanceCommands'') IS NOT NULL
    DROP TABLE #MaintenanceCommands;
IF OBJECT_ID(''tempdb..#MaintenanceCommandsTemp'') IS NOT NULL
    DROP TABLE #MaintenanceCommandsTemp;
' AS nvarchar(max))
 
	-- Для отладки. Выводит в SSMS весь текст сформированной команды
	--exec [dbo].[sp_AdvancedPrint] @sql = @cmd

    EXECUTE sp_executesql
        @cmd,
        N'@timeFrom TIME, @timeTo TIME, @fragmentationPercentForRebuild FLOAT,
        @fragmentationPercentMinForMaintenance FLOAT, @maxDop int,
        @minIndexSizePages int, @maxIndexSizePages int, @useOnlineIndexRebuild int,
        @maxIndexSizeForReorganizingPages int,
        @useMonitoringDatabase bit, @monitoringDatabaseName sysname, @usePreparedInformationAboutObjectsStateIfExists bit,
        @databaseName sysname, @maxTransactionLogSizeUsagePercent int, @maxTransactionLogSizeMB bigint, @useResumableIndexRebuild bit,
		@excludeIndexes XML, @fillFactorForIndex int',
        @timeFrom, @timeTo, @fragmentationPercentForRebuild,
        @fragmentationPercentMinForMaintenance, @maxDop,
        @minIndexSizePages, @maxIndexSizePages, @useOnlineIndexRebuild,
        @maxIndexSizeForReorganizingPages,
        @useMonitoringDatabase, @monitoringDatabaseName, @usePreparedInformationAboutObjectsStateIfExists,
        @databaseName, @maxTransactionLogSizeUsagePercent, @maxTransactionLogSizeMB, @useResumableIndexRebuild,
		@excludeIndexes, @fillFactorForIndex;

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_remove_maintenance_action_to_run]
	@Id int
AS
BEGIN
	SET NOCOUNT ON;

    DELETE FROM [dbo].[MaintenanceActionsToRun]
	WHERE [Id] = @Id
END
GO

CREATE PROCEDURE [dbo].[sp_SaveDatabasesTablesStatistic]
AS
BEGIN
	SET NOCOUNT ON;
	SET QUOTED_IDENTIFIER ON;

	IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
		DROP TABLE #tableSizeResult;

	DECLARE @sql nvarchar(max);

	SET @sql = '
	SELECT
		DB_NAME() AS [databaseName],
		a3.name AS [schemaname],
		a2.name AS [tablename],
		a1.rows as row_count,
		(a1.reserved + ISNULL(a4.reserved,0))* 8 AS [reserved], 
		a1.data * 8 AS [data],
		(CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS [index_size],
		(CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS [unused]
	FROM
		(SELECT 
			ps.object_id,
			SUM (
				CASE
					WHEN (ps.index_id < 2) THEN row_count
					ELSE 0
				END
				) AS [rows],
			SUM (ps.reserved_page_count) AS reserved,
			SUM (
				CASE
					WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
					ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
				END
				) AS data,
			SUM (ps.used_page_count) AS used
		FROM sys.dm_db_partition_stats ps
		GROUP BY ps.object_id) AS a1
	LEFT OUTER JOIN 
		(SELECT 
			it.parent_id,
			SUM(ps.reserved_page_count) AS reserved,
			SUM(ps.used_page_count) AS used
		 FROM sys.dm_db_partition_stats ps
		 INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
		 WHERE it.internal_type IN (202,204)
		 GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id)
	INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
	INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
	WHERE a2.type <> N''S'' and a2.type <> N''IT''
	ORDER BY reserved DESC
	';

	CREATE TABLE #tableSizeResult (
		[DatabaseName] [nvarchar](255),
		[SchemaName] [nvarchar](255),
		[TableName] [nvarchar](255),
		[RowCnt] bigint,
		[Reserved] bigint,
		[Data] bigint,
		[IndexSize] bigint,
		[Unused] bigint
	);


	DECLARE @statement nvarchar(max);

	SET @statement = (
	SELECT 'EXEC ' + QUOTENAME(name) + '.sys.sp_executesql @sql; '
	FROM sys.databases
	WHERE NOT DATABASEPROPERTYEX(name, 'UserAccess') = 'SINGLE_USER' 
		  AND HAS_DBACCESS(name) = 1
		  AND state_desc = 'ONLINE'
		  AND NOT database_id IN (
			DB_ID('tempdb'),
			DB_ID('master'),
			DB_ID('model'),
			DB_ID('msdb')
		  )
	FOR XML PATH(''), TYPE
	).value('.','nvarchar(max)');

	PRINT @statement

	INSERT #tableSizeResult
	EXEC sp_executesql @statement, N'@sql nvarchar(max)', @sql;

	DECLARE todo CURSOR FOR
	SELECT 
		[DatabaseName],
		[SchemaName],
		[TableName],
		[RowCnt],
		[Reserved],
		[Data],
		[IndexSize],
		[Unused]
	FROM #tableSizeResult;

	DECLARE
		@DatabaseName nvarchar(255),
		@SchemaName nvarchar(5),
		@TableName nvarchar(255),
		@RowCnt bigint,
		@Reserved bigint,
		@Data bigint,
		@IndexSize bigint,
		@Unused bigint,
		@currentDate datetime2(7);
	OPEN todo;

	WHILE 1=1
	BEGIN
		FETCH NEXT FROM todo INTO @DatabaseName, @SchemaName, @TableName, @RowCnt, @Reserved, @Data, @IndexSize, @Unused;
		IF @@FETCH_STATUS != 0
			BREAK;

		SET @currentDate = GETDATE();

		INSERT INTO [dbo].[DatabasesTablesStatistic]
		(
			[Period],
			[DatabaseName],
			[SchemaName],
			[TableName],
			[RowCnt],
			[Reserved],
			[Data],
			[IndexSize],
			[Unused]
		) VALUES
		(
			@currentDate,
			@DatabaseName, 
			@SchemaName, 
			@TableName, 
			@RowCnt, 
			@Reserved, 
			@Data,
			@IndexSize, 
			@Unused
		);
	END

	CLOSE todo;
	DEALLOCATE todo;

	IF OBJECT_ID('tempdb..#tableSizeResult') IS NOT NULL
		DROP TABLE #tableSizeResult;
END
GO

CREATE PROCEDURE [dbo].[sp_set_maintenance_action_log_finish_date]
	@MaintenanceActionLogId bigint,
	@FinishDate datetime2(0),
	@Comment nvarchar(255) = ''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @databaseName sysname;
	SELECT
		@databaseName = [DatabaseName]
	FROM [dbo].[MaintenanceActionsLog]
	WHERE [Id] = @MaintenanceActionLogId

	DECLARE @currentTransactionLogSizeMB int;
	-- Информация о размере лога транзакций
    DECLARE @tranLogInfo TABLE
    (
        servername varchar(250) not null default @@servername,
        dbname varchar(250),
        logsize real,
        logspace real,
        stat int
    ) 
	-- Проверка процента занятого места в логе транзакций
    INSERT INTO @tranLogInfo (dbname,logsize,logspace,stat) exec('dbcc sqlperf(logspace)')
    SELECT
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM @tranLogInfo WHERE dbname = @databaseName

	UPDATE [dbo].[MaintenanceActionsLog]
	SET FinishDate = @FinishDate, 
		Comment = @Comment,
		TransactionLogUsageAfterMB = @currentTransactionLogSizeMB
	WHERE Id = @MaintenanceActionLogId
	RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_StatisticMaintenance]
	@databaseName sysname,
	@timeFrom TIME = '00:00:00',
	@timeTo TIME = '23:59:59',
	@mode int = 0,
	@ConditionTableName nvarchar(max) = 'LIKE ''%'''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 			
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;

	IF(@mode = 0)
	BEGIN
		EXECUTE [dbo].[sp_StatisticMaintenance_Sampled] 
		   @databaseName
		  ,@timeFrom
		  ,@timeTo
		  ,@ConditionTableName
	END ELSE IF(@mode = 1)
	BEGIN
		EXECUTE [dbo].[sp_StatisticMaintenance_Detailed] 
		   @databaseName
		  ,@timeFrom
		  ,@timeTo
		  ,@ConditionTableName
	END

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_StatisticMaintenance_Detailed]
	@databaseName sysname,
	@timeFrom TIME = '00:00:00',
	@timeTo TIME = '23:59:59',	
	@ConditionTableName nvarchar(max) = 'LIKE ''%'''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@msg nvarchar(max),
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;;

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + @databaseName + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	DECLARE @cmd nvarchar(max);
	SET @cmd = 
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;
DECLARE
	-- Текущее время
	@timeNow TIME = CAST(GETDATE() AS TIME)
	-- Начало доступного интервала времени обслуживания
	-- @timeFrom TIME
	-- Окончание доступного интервала времени обслуживания
	-- @timeTo TIME
-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
	IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
		RETURN;
	END ELSE BEGIN
		IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
			OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))  
				RETURN;
END
-- Служебные переменные
DECLARE
	@DBID SMALLINT = DB_ID()
	,@DBNAME sysname = DB_NAME()
    ,@TableName SYSNAME
    ,@IndexName SYSNAME
    ,@Operation NVARCHAR(128) = ''UPDATE STATISTICS''
    ,@RunDate DATETIME = GETDATE()
    ,@StartDate DATETIME
    ,@FinishDate DATETIME
    ,@SQL NVARCHAR(500)	
	,@RowModCtr BIGINT
	,@MaintenanceActionLogId bigint;
DECLARE todo CURSOR FOR
SELECT
    ''
    UPDATE STATISTICS ['' + SCHEMA_NAME([o].[schema_id]) + ''].['' + [o].[name] + ''] ['' + [s].[name] + '']
        WITH FULLSCAN'' + CASE WHEN [s].[no_recompute] = 1 THEN '', NORECOMPUTE'' ELSE '''' END + '';''
    , [o].[name]
    , [s].[name] AS [stat_name],
	[rowmodctr]
FROM (
    SELECT
        [object_id]
        ,[name]
        ,[stats_id]
        ,[no_recompute]
        ,[last_update] = STATS_DATE([object_id], [stats_id])
        ,[auto_created]
    FROM sys.stats WITH(NOLOCK)
    WHERE [is_temporary] = 0) s
        LEFT JOIN sys.objects o WITH(NOLOCK) 
            ON [s].[object_id] = [o].[object_id]
        LEFT JOIN (
            SELECT
                [p].[object_id]
                ,[p].[index_id]
                ,[total_pages] = SUM([a].[total_pages])
            FROM sys.partitions p WITH(NOLOCK)
                JOIN sys.allocation_units a WITH(NOLOCK) ON [p].[partition_id] = [a].[container_id]
            GROUP BY 
                [p].[object_id]
                ,[p].[index_id]) p 
            ON [o].[object_id] = [p].[object_id] AND [p].[index_id] = [s].[stats_id]
        LEFT JOIN sys.sysindexes si
    ON [si].[id] = [s].[object_id] AND [si].[indid] = [s].[stats_id]
WHERE [o].[type] IN (''U'', ''V'')
    AND [o].[is_ms_shipped] = 0
    AND [rowmodctr] > 0
	AND [o].[name] ' AS nvarchar(max)) + CAST(@ConditionTableName AS nvarchar(max)) + CAST('
ORDER BY [rowmodctr] DESC;
OPEN todo;
WHILE 1=1
BEGIN
	FETCH NEXT FROM todo INTO @SQL, @TableName, @IndexName, @RowModCtr;
	IF @@FETCH_STATUS != 0
        BREAK;
	-- Проверка доступен ли запуск обслуживания в текущее время
    SET @timeNow = CAST(GETDATE() AS TIME);
    IF (@timeTo >= @timeFrom) BEGIN
        IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
            RETURN;
    END ELSE BEGIN
        IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
            OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))  
        RETURN;
    END
	SET @StartDate = GetDate();
	BEGIN TRY
		-- Сохраняем предварительную информацию об операции обслуживания без даты завершения
		IF(@useMonitoringDatabase = 1)
		BEGIN
			EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_log] 
			   @TableName
			  ,@IndexName
			  ,@Operation
			  ,@RunDate
			  ,@StartDate
			  ,null
			  ,@DBNAME
			  ,0
			  ,''''
			  ,0
			  ,@RowModCtr
			  ,@SQL
			  ,@MaintenanceActionLogId OUTPUT;
		END
		EXEC sp_executesql @SQL;
		SET @FinishDate = GetDate();
		-- Устанавливаем фактическую дату завершения операции
		IF(@useMonitoringDatabase = 1)
		BEGIN
			EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
				@MaintenanceActionLogId,
				@FinishDate;
		END
	END TRY
    BEGIN CATCH
		IF(@MaintenanceActionLogId <> 0)
		BEGIN
			DECLARE @msg nvarchar(500) = ''Error: '' + CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' + CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' + CAST(Error_Line() AS NVARCHAR(500))
			-- Устанавливаем текст ошибки при обслуживании объекта статистики
			-- Дата завершения при этом остается незаполненной
			EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
				@MaintenanceActionLogId,
				@FinishDate,
				@msg;			
		END
	END CATCH
END
CLOSE todo;
DEALLOCATE todo;
' AS nvarchar(max))

	EXECUTE sp_executesql 
		@cmd,
		N'@timeFrom TIME, @timeTo TIME,
		@useMonitoringDatabase bit, @monitoringDatabaseName sysname',
		@timeFrom, @timeTo,
		@useMonitoringDatabase, @monitoringDatabaseName;

    RETURN 0
END
GO

CREATE PROCEDURE [dbo].[sp_StatisticMaintenance_Sampled]
	@databaseName sysname,
	@timeFrom TIME = '00:00:00',
	@timeTo TIME = '23:59:59',
	@ConditionTableName nvarchar(max) = 'LIKE ''%'''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@msg nvarchar(max),
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;;

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + @databaseName + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	DECLARE @cmd nvarchar(max);
	SET @cmd = 
CAST('USE [' AS nvarchar(max)) + CAST(@databasename AS nvarchar(max)) + CAST(']
SET NOCOUNT ON;
DECLARE
	-- Текущее время
	@timeNow TIME = CAST(GETDATE() AS TIME)
	-- Начало доступного интервала времени обслуживания
	-- @timeFrom TIME
	-- Окончание доступного интервала времени обслуживания
	-- @timeTo TIME
-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
	IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
		RETURN;
	END ELSE BEGIN
		IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
			OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))  
				RETURN;
END
-- Служебные переменные
DECLARE
	@DBID SMALLINT = DB_ID()
	,@DBNAME sysname = DB_NAME()
    ,@TableName SYSNAME
    ,@IndexName SYSNAME
    ,@Operation NVARCHAR(128) = ''UPDATE STATISTICS''
    ,@RunDate DATETIME = GETDATE()
    ,@StartDate DATETIME
    ,@FinishDate DATETIME
    ,@SQL NVARCHAR(500)	
	,@RowModCtr BIGINT
	,@MaintenanceActionLogId bigint;
DECLARE @resample CHAR(8)=''NO'' -- Для включения установить значение RESAMPLE
DECLARE @dbsid VARBINARY(85)
SELECT @dbsid = owner_sid
FROM sys.databases
WHERE name = db_name()
DECLARE @exec_stmt NVARCHAR(4000)
-- "UPDATE STATISTICS [SYSNAME].[SYSNAME] [SYSNAME] WITH RESAMPLE NORECOMPUTE"
DECLARE @exec_stmt_head NVARCHAR(4000)
-- "UPDATE STATISTICS [SYSNAME].[SYSNAME] "
DECLARE @options NVARCHAR(100)
-- "RESAMPLE NORECOMPUTE"
DECLARE @index_names CURSOR
DECLARE @ind_name SYSNAME
DECLARE @ind_id INT
DECLARE @ind_rowmodctr INT
DECLARE @updated_count INT
DECLARE @skipped_count INT
DECLARE @sch_id INT
DECLARE @schema_name SYSNAME
DECLARE @table_name SYSNAME
DECLARE @table_id INT
DECLARE @table_type CHAR(2)
DECLARE @schema_table_name NVARCHAR(640)
DECLARE @compatlvl tinyINT
-- Получаем список объектов, для которых нужно обслуживание статистики
DECLARE ms_crs_tnames CURSOR LOCAL FAST_FORWARD READ_ONLY for
SELECT
    name, -- Имя объекта
    object_id, -- Идентификатор объекта
    schema_id, -- Идентификатор схемы
    type
-- Тип объекта
FROM sys.objects o
WHERE (o.type = ''U'' OR o.type = ''IT'')
	AND [name] ' AS nvarchar(max)) + CAST(@ConditionTableName AS nvarchar(max)) + CAST('
-- внутренняя таблица
OPEN ms_crs_tnames
FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
-- Определяем уровень совместимости для базы данных
SELECT @compatlvl = cmptlevel
FROM sys.sysdatabases
WHERE name = db_name()
WHILE (@@fetch_status <> -1)
BEGIN
    -- Формируем полное имя объекта (схема + имя)
    SELECT @schema_name = schema_name(@sch_id)
    SELECT @schema_table_name = quotename(@schema_name, ''['') +''.''+ quotename(rtrim(@table_name), ''['')
    -- Пропускаем таблицы, для которых отключен кластерный индекс
    IF (1 = isnull((SELECT is_disabled
        FROM sys.indexes
        WHERE object_id = @table_id AND index_id = 1), 0))
	BEGIN
        FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
        CONTINUE;
    END
	ELSE BEGIN
        -- Пропускаем локальные временные таблицы
        IF ((@@fetch_status <> -2) AND (substring(@table_name, 1, 1) <> ''#''))
		BEGIN
            SELECT @updated_count = 0
            SELECT @skipped_count = 0
            -- Подготавливаем начало команды: UPDATE STATISTICS [schema].[name]
            SELECT @exec_stmt_head = ''UPDATE STATISTICS '' + @schema_table_name + '' ''
            -- Обходим индексы и объекты статистики для текущего объекта
            -- Объекты статистики как пользовательские, так и созданные автоматически.				
            IF ((@table_type = ''U'') AND (1 = OBJECTPROPERTY(@table_id, ''TableIsMemoryOptimized'')))	-- In-Memory OLTP
			BEGIN
                -- Hekaton-индексы (функциональность In-Memory OLTP) не отображаются в системном представлении sys.sysindexes,
                -- Поэтому нужно использовать sys.stats для их обработки.
                -- Примечание: OBJECTPROPERTY возвращает NULL для типа объекта "IT" (внутренние таблицы), 
                -- поэтому можно использовать это только для типа ''U'' (пользовательские таблицы)
                -- Для Hekaton-индексов (функциональность In-Memory OLTP) 
                SET @index_names = CURSOR LOCAL FAST_FORWARD READ_ONLY for
						SELECT name, stat.stats_id, modification_counter AS rowmodctr
                FROM sys.stats AS stat
						CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id)
                WHERE stat.object_id = @table_id AND indexproperty(stat.object_id, name, ''ishypothetical'') = 0
                    AND indexproperty(stat.object_id, name, ''iscolumnstore'') = 0
                -- Для колоночных индексов статистика не обновляется
                ORDER BY stat.stats_id
            END ELSE 
            BEGIN
                -- Для обычных таблиц
                SET @index_names = CURSOR LOCAL FAST_FORWARD READ_ONLY for
						SELECT name, indid, rowmodctr
                FROM sys.sysindexes
                WHERE id = @table_id AND indid > 0 AND indexproperty(id, name, ''ishypothetical'') = 0
                    AND indexproperty(id, name, ''iscolumnstore'') = 0
                ORDER BY indid
            END
            OPEN @index_names
            FETCH @index_names INTO @ind_name, @ind_id, @ind_rowmodctr
            -- Если объектов статистик нет, то пропускаем
            IF @@fetch_status < 0
			BEGIN
                FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
                CONTINUE;
            END ELSE 
				BEGIN
                WHILE @@fetch_status >= 0
					BEGIN
                    -- Формируем имя индекса
                    DECLARE @ind_name_quoted NVARCHAR(258)
                    SELECT @ind_name_quoted = quotename(@ind_name, ''['')
                    SELECT @options = ''''
                    -- Если нет данных о накопленных изменениях или они больше 0 (количество измененных строк)
                    IF ((@ind_rowmodctr is null) OR (@ind_rowmodctr <> 0))
						BEGIN
                        SELECT @exec_stmt = @exec_stmt_head + @ind_name_quoted
                        -- Добавляем полное сканирование (FULLSCAN) для оптимизированных в памяти таблиц, если уровень совместимости < 130
                        IF ((@compatlvl < 130) AND (@table_type = ''U'') AND (1 = OBJECTPROPERTY(@table_id, ''TableIsMemoryOptimized''))) -- In-Memory OLTP
								SELECT @options = ''FULLSCAN''
							-- add resample IF needed
							ELSE IF (upper(@resample)=''RESAMPLE'')
								SELECT @options = ''RESAMPLE ''
                        -- Для уровнея совместимости больше 90 определяем доп. параметры
                        IF (@compatlvl >= 90)
                                -- Устанавливаем параметр NORECOMPUTE, если свойство AUTOSTATS для него было установлено в OFF
								IF ((SELECT no_recompute
                        FROM sys.stats
                        WHERE object_id = @table_id AND name = @ind_name) = 1)
								BEGIN
                            IF (len(@options) > 0) SELECT @options = @options + '', NORECOMPUTE''
									ELSE SELECT @options = ''NORECOMPUTE''
                        END
                        -- Добавляем сформированные параметры в команду обновления статистики
                        IF (len(@options) > 0)
								SELECT @exec_stmt = @exec_stmt + '' WITH '' + @options
                        
                        SET @StartDate = GetDate();
                        
                        -- Проверка доступен ли запуск обслуживания в текущее время
                        SET @timeNow = CAST(GETDATE() AS TIME);
                        IF (@timeTo >= @timeFrom) BEGIN
                            IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
                                RETURN;
                        END ELSE BEGIN
                            IF(NOT ((@timeFrom <= @timeNow AND ''23:59:59'' >= @timeNow)
                                OR (@timeTo >= @timeNow AND ''00:00:00'' <= @timeNow)))		
                            RETURN;
                        END
                        BEGIN TRY                            
							-- Сохраняем предварительную информацию об операции обслуживания без даты завершения
							IF(@useMonitoringDatabase = 1)
							BEGIN
								EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName  AS nvarchar(max)) + CAST('].[dbo].[sp_add_maintenance_action_log] 
								   @table_name
								  ,@ind_name
								  ,@Operation
								  ,@RunDate
								  ,@StartDate
								  ,null
								  ,@DBNAME
								  ,0
								  ,''''
								  ,0
								  ,@ind_rowmodctr
								  ,@exec_stmt
								  ,@MaintenanceActionLogId OUTPUT;
							END
                            EXEC sp_executesql @exec_stmt;
							SET @FinishDate = GetDate();
                            -- Устанавливаем фактическую дату завершения операции
							IF(@useMonitoringDatabase = 1)
							BEGIN
								EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
									@MaintenanceActionLogId,
									@FinishDate;
							END
                        END TRY
                        BEGIN CATCH
                            IF(@MaintenanceActionLogId <> 0)
							BEGIN
								DECLARE @msg nvarchar(500) = ''Error: '' + CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' + CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' + CAST(Error_Line() AS NVARCHAR(500))
								-- Устанавливаем текст ошибки при обслуживании объекта статистики
								-- Дата завершения при этом остается незаполненной
								EXECUTE [' AS nvarchar(max)) + CAST(@monitoringDatabaseName AS nvarchar(max)) + CAST('].[dbo].[sp_set_maintenance_action_log_finish_date]
									@MaintenanceActionLogId,
									@FinishDate,
									@msg;			
							END
                        END CATCH
                        
                        SELECT @updated_count = @updated_count + 1
                    END ELSE
					BEGIN
                        SELECT @skipped_count = @skipped_count + 1
                    END
                    FETCH @index_names INTO @ind_name, @ind_id, @ind_rowmodctr
                END
            END
            DEALLOCATE @index_names
        END
    END
    FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
END
DEALLOCATE ms_crs_tnames
' AS nvarchar(max))

	EXECUTE sp_executesql 
		@cmd,
		N'@timeFrom TIME, @timeTo TIME,
		@useMonitoringDatabase bit, @monitoringDatabaseName sysname',
		@timeFrom, @timeTo,
		@useMonitoringDatabase, @monitoringDatabaseName;

    RETURN 0
END
GO

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
GO

ALTER TABLE [dbo].[JobTemplates] ENABLE TRIGGER [tg_JobTemplate_AfterUpdate]
GO

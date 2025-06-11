/*
Скрипт для создания служебной базы данных для управления обслуживанием и мониторингом.
*/

USE [SQLServerMaintenance]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_ConvertBinary1CIdToUniqueidentifier]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_ConvertBinary1CIdToUniqueidentifier] 
(
	@uuidAsBinary binary(16)
)
RETURNS uniqueidentifier
AS
BEGIN
	DECLARE @uuid1C binary(16) = CAST(REVERSE(SUBSTRING(@uuidAsBinary, 9, 8)) AS binary(8)) + SUBSTRING(@uuidAsBinary, 1, 8);

	RETURN CAST(@uuid1C AS uniqueidentifier);
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_ResumableIndexMaintenanceAvailiable]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[MaintenanceActionsLog]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[v_CommonStatsByDay]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[AlwaysOnReplicaMissingStats]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AlwaysOnReplicaMissingStats](
	[DatabaseName] [nvarchar](255) NULL,
	[TableName] [nvarchar](255) NULL,
	[StatsName] [nvarchar](255) NULL,
	[CreatedDate] [datetime] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UK_AlwaysOnReplicaMissingStats_CreatedDate_DatabaseName_TableName]    Script Date: 11.06.2025 18:05:56 ******/
CREATE CLUSTERED INDEX [UK_AlwaysOnReplicaMissingStats_CreatedDate_DatabaseName_TableName] ON [dbo].[AlwaysOnReplicaMissingStats]
(
	[CreatedDate] ASC,
	[DatabaseName] ASC,
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[changelog]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConnectionsStatistic]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DatabaseObjectsState]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DatabasesTablesStatistic]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
SET ANSI_PADDING ON
GO
/****** Object:  Index [UK_DatabasesTablesStatistic_Period_DatabaseName_TableName]    Script Date: 11.06.2025 18:05:56 ******/
CREATE UNIQUE CLUSTERED INDEX [UK_DatabasesTablesStatistic_Period_DatabaseName_TableName] ON [dbo].[DatabasesTablesStatistic]
(
	[Period] ASC,
	[DatabaseName] ASC,
	[SchemaName] ASC,
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DatabaseTimezones]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DatabaseTimezones](
	[DatabaseName] [nvarchar](250) NOT NULL,
	[TimezoneOffset] [decimal](15, 2) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[JobTemplates]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
	[SchedulesAdditional] [nvarchar](max) NULL,
	[TemplateGroupName] [nvarchar](250) NULL,
 CONSTRAINT [PK_JobTemplates] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[JobTimeouts]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobTimeouts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](250) NULL,
	[TimeoutSec] [int] NOT NULL,
 CONSTRAINT [PK_JobTimeouts] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LogTransactionControlSettings]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogTransactionControlSettings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](250) NULL,
	[MinDiskFreeSpace] [int] NOT NULL,
	[MaxLogUsagePercentThreshold] [int] NOT NULL,
	[MinAllowDataFileFreeSpaceForResumableRebuildMb] [int] NOT NULL,
 CONSTRAINT [PK_LogTransactionControlSettings] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MaintenanceActionsToRun]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MaintenanceIndexPriority]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SessionControlSettings]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SessionControlSettings](
	[SPID] [int] NOT NULL,
	[Login] [nvarchar](250) NULL,
	[HostName] [nvarchar](250) NULL,
	[ProgramName] [nvarchar](250) NULL,
	[WorkFrom] [time](7) NULL,
	[WorkTo] [time](7) NULL,
	[MaxLogUsagePercent] [int] NULL,
	[MaxLogUsageMb] [int] NULL,
	[Created] [datetime] NOT NULL,
	[DatabaseName] [nvarchar](250) NULL,
	[WorkTimeoutSec] [int] NULL,
	[AbortIfLockOtherSessions] [bit] NOT NULL,
	[AbortIfLockOtherSessionsTimeoutSec] [int] NOT NULL,
 CONSTRAINT [PK_SessionControlSettings] PRIMARY KEY CLUSTERED 
(
	[SPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Settings]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Settings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[DatabaseName] [nvarchar](250) NULL,
	[ValueNumeric] [numeric](18, 3) NULL,
	[ValueVarbinary] [varbinary](max) NULL,
 CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[changelog] ON 
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (1, 2, N'0', N'Empty schema found: dbo.', N'dbo', N'', N'sa', CAST(N'2025-06-11T18:01:11.630' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (2, 0, N'1.0.0.0', N'Initializing (55 ms)', N'V1_0_0_0__Initializing.sql', N'E29CBD2E2588AD0496EAD6531C63CC7F', N'sa', CAST(N'2025-06-11T18:01:11.720' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (3, 0, N'1.0.0.1', N'FixView CommonStatsByDay (6 ms)', N'V1_0_0_1__FixView_CommonStatsByDay.sql', N'E148A3049C07BE2692277AAF1FF1EEAC', N'sa', CAST(N'2025-06-11T18:01:11.730' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (4, 0, N'1.0.0.2', N'MaintainanceActionLog AddTranLogSizeInfo (18 ms)', N'V1_0_0_2__MaintainanceActionLog_AddTranLogSizeInfo.sql', N'A8B95D18EE751AC15A2DFF3601538ADE', N'sa', CAST(N'2025-06-11T18:01:11.747' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (5, 0, N'1.0.0.3', N'IndexMaintenance FixQueryRetriveIndexListForMaintenance (10 ms)', N'V1_0_0_3__IndexMaintenance_FixQueryRetriveIndexListForMaintenance.sql', N'55E540697C7AFFEDB68D8FC815091F61', N'sa', CAST(N'2025-06-11T18:01:11.760' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (6, 0, N'1.0.0.4', N'TransactionLogControl AddTableWithSettingsAndProc (19 ms)', N'V1_0_0_4__TransactionLogControl_AddTableWithSettingsAndProc.sql', N'655D9D4645CBA6710081AB9846140A0F', N'sa', CAST(N'2025-06-11T18:01:11.780' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (7, 0, N'1.0.0.5', N'IndexMaintenance AddSupportIndexReorganizeWithoutPageLocks copy (23 ms)', N'V1_0_0_5__IndexMaintenance_AddSupportIndexReorganizeWithoutPageLocks copy.sql', N'E22174E62CA8468BF1AA629DBDEA3CB3', N'sa', CAST(N'2025-06-11T18:01:11.803' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (8, 0, N'1.0.0.6', N'IndexMaintenance ImproveReorganizeIndexes (10 ms)', N'V1_0_0_6__IndexMaintenance_ImproveReorganizeIndexes.sql', N'D0D4BA4F63B28FDFDFA3847ACD5D4C29', N'sa', CAST(N'2025-06-11T18:01:11.813' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (9, 0, N'1.0.0.7', N'IndexMaintenance ImproveReorganizeIndexes v2 (10 ms)', N'V1_0_0_7__IndexMaintenance_ImproveReorganizeIndexes_v2.sql', N'36937240442EEBAB330DA107755213C1', N'sa', CAST(N'2025-06-11T18:01:11.823' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (10, 0, N'1.0.0.8', N'Backup AddProcBackupDatabase (7 ms)', N'V1_0_0_8__Backup_AddProcBackupDatabase.sql', N'8D060910FFC1AE7D67B7A6758F8DEE94', N'sa', CAST(N'2025-06-11T18:01:11.833' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (11, 0, N'1.0.0.9', N'Backup AddProcClearFiles (5 ms)', N'V1_0_0_9__Backup_AddProcClearFiles.sql', N'A8A4CA79BA41288175A164A32D606AD0', N'sa', CAST(N'2025-06-11T18:01:11.840' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (12, 0, N'1.0.0.10', N'Jobs AddSettingsAndControlFunctions (22 ms)', N'V1_0_0_10__Jobs_AddSettingsAndControlFunctions.sql', N'882BB44E8B3B6D443958089B08BCA066', N'sa', CAST(N'2025-06-11T18:01:11.860' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (13, 0, N'1.0.0.11', N'Refactoring (17 ms)', N'V1_0_0_11__Refactoring.sql', N'F32BC5B3DCA7EFEB049F1C7A032C30F3', N'sa', CAST(N'2025-06-11T18:01:11.880' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (14, 0, N'1.0.0.12', N'Jobs FixCreateOrUPdateJobsBySettingsProc (7 ms)', N'V1_0_0_12__Jobs_FixCreateOrUPdateJobsBySettingsProc.sql', N'830D32CAB88A1ACC673F515AA8D5B96D', N'sa', CAST(N'2025-06-11T18:01:11.887' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (15, 0, N'1.0.0.13', N'Jobs FixCreateOrUPdateJobsBySettingsProcV2 (7 ms)', N'V1_0_0_13__Jobs_FixCreateOrUPdateJobsBySettingsProcV2.sql', N'20830460B9482F8F0E072F0258C2C246', N'sa', CAST(N'2025-06-11T18:01:11.897' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (16, 0, N'1.0.0.14', N'Jobs FixCreateOrUPdateJobsBySettingsProcV3 (7 ms)', N'V1_0_0_14__Jobs_FixCreateOrUPdateJobsBySettingsProcV3.sql', N'571DD04E9B906479334878ACC81AB34A', N'sa', CAST(N'2025-06-11T18:01:11.907' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (17, 0, N'1.0.0.15', N'IndexMaintenance FixResumableIndexRebuild (10 ms)', N'V1_0_0_15__IndexMaintenance_FixResumableIndexRebuild.sql', N'EF60D201A601434CAA1032690382553C', N'sa', CAST(N'2025-06-11T18:01:11.917' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (18, 0, N'1.0.0.16', N'Settings AddedDatabaseTimezones (5 ms)', N'V1_0_0_16__Settings_AddedDatabaseTimezones.sql', N'6EDA232CB4592E9145C70930F83C502A', N'sa', CAST(N'2025-06-11T18:01:11.923' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (19, 0, N'1.0.0.17', N'Settings ExtendJobSettingsForGroupsAndAdditionalSettings (5 ms)', N'V1_0_0_17__Settings_ExtendJobSettingsForGroupsAndAdditionalSettings.sql', N'0B4827FA1EACFDDF24EBEBA4C755E176', N'sa', CAST(N'2025-06-11T18:01:11.930' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (20, 0, N'1.0.0.18', N'Settings ExtendLogTransactionControlSettingForResumableOperations (5 ms)', N'V1_0_0_18__Settings_ExtendLogTransactionControlSettingForResumableOperations.sql', N'1159DDF11897AA731034D3A406ACD205', N'sa', CAST(N'2025-06-11T18:01:11.937' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (21, 0, N'1.0.0.19', N'Settings AddedSessionControlSettings Step1 (5 ms)', N'V1_0_0_19__Settings_AddedSessionControlSettings_Step1.sql', N'B30592544D5226AC51A861AF52DB97B4', N'sa', CAST(N'2025-06-11T18:01:11.943' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (22, 0, N'1.0.0.20', N'Settings AddedSessionControlSettings Step2 (5 ms)', N'V1_0_0_20__Settings_AddedSessionControlSettings_Step2.sql', N'6DECF8953D9DF14EEA9868D99EB702A3', N'sa', CAST(N'2025-06-11T18:01:11.950' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (23, 0, N'1.0.0.21', N'Settings AddedSessionControlSettings Step3 (5 ms)', N'V1_0_0_21__Settings_AddedSessionControlSettings_Step3.sql', N'F644C198AEA410F2213F625A2865B7D1', N'sa', CAST(N'2025-06-11T18:01:11.953' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (24, 0, N'1.0.0.22', N'Settings AddedSettingsTable Step1 (5 ms)', N'V1_0_0_22__Settings_AddedSettingsTable_Step1.sql', N'042EE64104E86E79C1D0C7E5792A9522', N'sa', CAST(N'2025-06-11T18:01:11.960' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (25, 0, N'1.0.0.23', N'Settings AddedSettingsTable Step2 (5 ms)', N'V1_0_0_23__Settings_AddedSettingsTable_Step2.sql', N'FCCE5639405A8B45C6320D0FAA74060A', N'sa', CAST(N'2025-06-11T18:01:11.967' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (26, 0, N'1.0.0.24', N'IndexMaintenance AddProcAbortReumableIndexRebuilds (7 ms)', N'V1_0_0_24__IndexMaintenance_AddProcAbortReumableIndexRebuilds.sql', N'04AF7C6BEA8B945C78FEBE0AF2E1E5DC', N'sa', CAST(N'2025-06-11T18:01:11.973' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (27, 0, N'1.0.0.25', N'Control AddProcSessionControlSettings (7 ms)', N'V1_0_0_25__Control_AddProcSessionControlSettings.sql', N'950F42DF429E15DF3FA9AE0E3F6B141D', N'sa', CAST(N'2025-06-11T18:01:11.980' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (28, 0, N'1.0.0.26', N'Backup FixProcBackupDatabase (7 ms)', N'V1_0_0_26__Backup_FixProcBackupDatabase.sql', N'1DA39459FCF53CD715315A076DFE5D6F', N'sa', CAST(N'2025-06-11T18:01:11.990' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (29, 0, N'1.0.0.27', N'Control AddProcClearOldSessionControlSettings (6 ms)', N'V1_0_0_27__Control_AddProcClearOldSessionControlSettings.sql', N'8DCC7D87D6C3C6CC2C0384DF0E000784', N'sa', CAST(N'2025-06-11T18:01:11.997' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (30, 0, N'1.0.0.28', N'Maintenance AddProcCompressDatabaseObjects (6 ms)', N'V1_0_0_28__Maintenance_AddProcCompressDatabaseObjects.sql', N'DEA9C6358AACBAE35414D93B29745354', N'sa', CAST(N'2025-06-11T18:01:12.003' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (31, 0, N'1.0.0.29', N'Maintenance AddProcShrinkDatabaseDataFile (5 ms)', N'V1_0_0_29__Maintenance_AddProcShrinkDatabaseDataFile.sql', N'D7B9A0A7E9E14AFC4E9F6713E7F21441', N'sa', CAST(N'2025-06-11T18:01:12.010' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (32, 0, N'1.0.0.30', N'Maintenance AddProcCompressAndShrinkDataFile (5 ms)', N'V1_0_0_30__Maintenance_AddProcCompressAndShrinkDataFile.sql', N'F399F75E5A2CB906D0119B372A7C50DA', N'sa', CAST(N'2025-06-11T18:01:12.013' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (33, 0, N'1.0.0.31', N'Control UpdateProcControlJobsExecutionTimeout (8 ms)', N'V1_0_0_31__Control_UpdateProcControlJobsExecutionTimeout.sql', N'475C41495828036AEC160A8FF13E0836', N'sa', CAST(N'2025-06-11T18:01:12.023' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (34, 0, N'1.0.0.32', N'Control AddProcControlSessionLocks (6 ms)', N'V1_0_0_32__Control_AddProcControlSessionLocks.sql', N'F4BC11213EFAF841489E4EC9DD7686EA', N'sa', CAST(N'2025-06-11T18:01:12.030' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (35, 0, N'1.0.0.33', N'Control UpdateProcControlTransactionLogUsage (12 ms)', N'V1_0_0_33__Control_UpdateProcControlTransactionLogUsage.sql', N'444017B690C4E79AE50B4674A637C248', N'sa', CAST(N'2025-06-11T18:01:12.043' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (36, 0, N'1.0.0.34', N'Monitoring AddCreateOrUpdateExtendedEventSessions (8 ms)', N'V1_0_0_34__Monitoring_AddCreateOrUpdateExtendedEventSessions.sql', N'723F804A7A3D421ADF70C7CDB35A238E', N'sa', CAST(N'2025-06-11T18:01:12.050' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (37, 0, N'1.0.0.35', N'Jobs FixCreateOrUPdateJobsBySettingsProcV4 (9 ms)', N'V1_0_0_35__Jobs_FixCreateOrUPdateJobsBySettingsProcV4.sql', N'6B2923C18E720E5E40981BC8027B42D0', N'sa', CAST(N'2025-06-11T18:01:12.060' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (38, 0, N'1.0.0.36', N'Jobs FixCreateSimpleJob (15 ms)', N'V1_0_0_36__Jobs_FixCreateSimpleJob.sql', N'504CF381C17588ED7F046FFBA2FDB0A5', N'sa', CAST(N'2025-06-11T18:01:12.077' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (39, 0, N'1.0.0.37', N'Monitoring FixFillConnectionsStatistic (5 ms)', N'V1_0_0_37__Monitoring_FixFillConnectionsStatistic.sql', N'7B30E7D2DD4A409550A833DA35FD174D', N'sa', CAST(N'2025-06-11T18:01:12.083' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (40, 0, N'1.0.0.38', N'Monitoring FillDatabaseObjectsState (5 ms)', N'V1_0_0_38__Monitoring_FillDatabaseObjectsState.sql', N'7CCDF9BF62300ABEF1D6D515A71BBD1F', N'sa', CAST(N'2025-06-11T18:01:12.090' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (41, 0, N'1.0.0.39', N'Maintenance UpdateProcFixMissingStatisticOnAlwaysOnReplica (7 ms)', N'V1_0_0_39__Maintenance_UpdateProcFixMissingStatisticOnAlwaysOnReplica.sql', N'44A0A69952CF894DA0E28CF332073209', N'sa', CAST(N'2025-06-11T18:01:12.097' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (42, 0, N'1.0.0.40', N'Maintenance UpdateProcIndexMaintenance (11 ms)', N'V1_0_0_40__Maintenance_UpdateProcIndexMaintenance.sql', N'8B9916FC86E6983D4A1C5DC433DAD833', N'sa', CAST(N'2025-06-11T18:01:12.110' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (43, 0, N'1.0.0.41', N'Control AddProcRemoveSessionControlSetting (5 ms)', N'V1_0_0_41__Control_AddProcRemoveSessionControlSetting.sql', N'32E43479274353D814C45CFEBA1A0612', N'sa', CAST(N'2025-06-11T18:01:12.113' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (44, 0, N'1.0.0.42', N'Monitoring AddProcRestartMonitoringXEventSessions (5 ms)', N'V1_0_0_42__Monitoring_AddProcRestartMonitoringXEventSessions.sql', N'38C8845E19B666AF876AFF7F3FF7B676', N'sa', CAST(N'2025-06-11T18:01:12.120' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (45, 0, N'1.0.0.43', N'Monitoring UpdateProcSaveDatabasesTablesStatistic (7 ms)', N'V1_0_0_43__Monitoring_UpdateProcSaveDatabasesTablesStatistic.sql', N'51BAE2DAACCECA0A5B743387F848232A', N'sa', CAST(N'2025-06-11T18:01:12.127' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (46, 0, N'1.0.0.44', N'Maintenance UpdateProcStatisticMaintenance Detailed (5 ms)', N'V1_0_0_44__Maintenance_UpdateProcStatisticMaintenance_Detailed.sql', N'D48C8F0AF138FB775298E716302363FE', N'sa', CAST(N'2025-06-11T18:01:12.133' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (47, 0, N'1.0.0.45', N'Maintenance UpdateProcStatisticMaintenance Sampled (6 ms)', N'V1_0_0_45__Maintenance_UpdateProcStatisticMaintenance_Sampled.sql', N'AF1C02FE80B65A4DD319CD3BF63C2C2F', N'sa', CAST(N'2025-06-11T18:01:12.140' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (48, 0, N'1.0.0.46', N'Maintenance UpdateProcStatisticMaintenance (6 ms)', N'V1_0_0_46__Maintenance_UpdateProcStatisticMaintenance.sql', N'D83E17411219B7D7AD0DE43581BFE281', N'sa', CAST(N'2025-06-11T18:01:12.147' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (49, 0, N'1.0.0.47', N'Platform1C AddedFuncConvertBinary1CIdToUniqueidentifier (5 ms)', N'V1_0_0_47__Platform1C_AddedFuncConvertBinary1CIdToUniqueidentifier.sql', N'4B9EC42293D26C71EA27DE40EF204475', N'sa', CAST(N'2025-06-11T18:01:12.150' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (50, 0, N'1.0.0.48', N'Settings FixTransactionControlSettingsStructure (100 ms)', N'V1_0_0_48__Settings_FixTransactionControlSettingsStructure.sql', N'18FB3BFEBA2F4B707D14B9671F0E9826', N'sa', CAST(N'2025-06-11T18:01:12.253' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (51, 0, N'1.0.0.49', N'Settings AddDefaultTransactionControlSettings (5 ms)', N'V1_0_0_49__Settings_AddDefaultTransactionControlSettings.sql', N'9F743C941905C5C1A4D6C4086F0E807D', N'sa', CAST(N'2025-06-11T18:01:12.260' AS DateTime), 1)
GO
INSERT [dbo].[changelog] ([id], [type], [version], [description], [name], [checksum], [installed_by], [installed_on], [success]) VALUES (52, 0, N'1.0.0.50', N'Jobs AddedDefaultJobsTemplates (16 ms)', N'V1_0_0_50__Jobs_AddedDefaultJobsTemplates.sql', N'9E6089F3FF8B180ACAB0A7DC7AD91CDF', N'sa', CAST(N'2025-06-11T18:01:12.277' AS DateTime), 1)
GO
SET IDENTITY_INSERT [dbo].[changelog] OFF
GO
SET IDENTITY_INSERT [dbo].[JobTemplates] ON 
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (3, 1, 1, NULL, N'Maintenance.ControlTransactionLogUsage', N'Контроль заполнения лога транзакций', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlTransactionLogUsage] ', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2024-05-22T11:44:12.793' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (4, 1, 1, NULL, N'XEventSessionRestart', N'Перезапуск сессий сбора данных логов расширенных событий', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_RestartMonitoringXEventSessions]', 1, 4, 1, 4, 10, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2024-05-22T11:44:26.777' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (5, 1, 1, NULL, N'Maintenance.GetDatabasesTableStatistics', N'Сбор общей информации о таблицах в базах данных.', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_SaveDatabasesTablesStatistic]', 1, 4, 1, 1, 0, 0, 0, 20000101, 99991231, 200000, 235959, CAST(N'2024-05-22T11:44:25.680' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (6, 1, 1, NULL, N'Maintenance.Clear_TRN', N'Очистка старых бэкапов логов транзакций.', N'DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END
	EXECUTE [SQLServerMaintenance].[dbo].[sp_ClearFiles] 
	   @folderPath = @BackupDirectory
	  ,@fileExtension = ''trn''
	  ,@cutoffDateDays = 2', 1, 4, 1, 1, 1, 0, 0, 20000101, 99991231, 230000, 235959, CAST(N'2024-05-22T11:44:25.083' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (7, 1, 1, NULL, N'Maintenance.Clear_FULL', N'Очистка старых полных бэкапов.', N'DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END	
	EXECUTE [SQLServerMaintenance].[dbo].[sp_ClearFiles] 
		@folderPath = @BackupDirectory
		,@fileExtension = ''bak''
		,@cutoffDateDays = 7', 1, 4, 1, 1, 0, 0, 0, 20000101, 99991231, 230000, 235959, CAST(N'2024-05-22T11:44:24.477' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (9, 1, 1, NULL, N'Maintenance.ApplyNontplatrofmObjects', N'Поддержка неплатформенных объектов 1С (индексы, сжатие и др.)', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_ApplyNontplatrofmObjects]', 1, 4, 1, 1, 0, 0, 0, 20000101, 99991231, 210000, 235959, CAST(N'2024-05-22T11:45:20.017' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (14, 1, 1, NULL, N'Maintenance.ControlJobsExecutionTimeout', N'Контроль таймаутов выполнения заданий.', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_ControlJobsExecutionTimeout] ', 1, 4, 1, 4, 1, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2024-05-22T11:45:25.097' AS DateTime), 0, NULL, N'ОБЩИЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (23, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE dbs.recovery_model = 1
	AND NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_TRN', N'Бэкап лога транзакций для базы данных {DatabaseName}', N'DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END
EXECUTE [SQLServerMaintenance].[dbo].[sp_BackupDatabase] 
	-- Имя базы
	 @databaseName = ''{DatabaseName}''
	-- Тип бэкапа (FULL, DIFF, TRN)
	,@backupType = ''TRN''
	-- Каталог сохранения бэкапов
	,@backupDirectory = @BackupDirectory
    -- Сжатие (не обязателен, по умолчанию AUTO)
	-- * AUTO - (по умолчанию) брать из параметров сервера
	-- * ENABLE - со сжатием
	-- * DISABLE - без сжатия
    ,@backupCompressionType = ''ENABLE''
', 1, 4, 1, 4, 30, 0, 0, 20000101, 99991231, 0, 235959, CAST(N'2024-05-22T12:13:43.407' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (24, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_FULL', N'Полный бэкап для базы данных ({DatabaseName})', N'DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END
EXECUTE [SQLServerMaintenance].[dbo].[sp_BackupDatabase] 
	-- Имя базы
	 @databaseName = ''{DatabaseName}''
	-- Тип бэкапа (FULL, DIFF, TRN)
	,@backupType = ''FULL''
	-- Каталог сохранения бэкапов
	,@backupDirectory = @BackupDirectory
    -- Сжатие (не обязателен, по умолчанию AUTO)
	-- * AUTO - (по умолчанию) брать из параметров сервера
	-- * ENABLE - со сжатием
	-- * DISABLE - без сжатия
    ,@backupCompressionType = ''ENABLE''', 1, 4, 1, 8, 12, 0, 0, 20000101, 99991231, 500, 235959, CAST(N'2024-05-22T12:14:01.343' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (25, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_Daily', N'Ежедневное обслуживание индексов и статистик для базы ({DatabaseName})', N'<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''19:00:00''
  ,@timeTo = ''22:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxIndexSizePages = 13107200
  ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeMB = 25600
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Index Maintenance Huge Objects</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''20:00:00''
  ,@timeTo = ''05:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxTransactionLogSizeMB = 51200
  ,@fillFactorForIndex = 80
  ,@minIndexSizePages = 13107200
  ,@useResumableIndexRebuildIfAvailable = 1
  ,@onlyResumeIfExistIndexRebuildOperation = 1
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Statistic Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
    @databaseName = ''{DatabaseName}''
   ,@timeFrom = ''19:00:00''
   ,@timeTo = ''23:59:59''
   ,@mode = 0
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>', 1, 8, 95, 4, 30, 0, 1, 20000101, 99991231, 200000, 235959, CAST(N'2024-05-22T12:13:58.603' AS DateTime), 0, N'<schedules>
    <schedule>
        <scheduleEnabled>1</scheduleEnabled>
        <scheduleName>Maintenance.{DatabaseName}_IndicesAndStatistics_Daily</scheduleName>
        <scheduleFreqType>8</scheduleFreqType>
        <scheduleFreqInterval>63</scheduleFreqInterval>
        <scheduleFreqSubdayType>8</scheduleFreqSubdayType>
        <scheduleFreqSubdayInterval>1</scheduleFreqSubdayInterval>
        <scheduleFreqRelativeInterval>0</scheduleFreqRelativeInterval>
        <scheduleFreqRecurrenceFactor>1</scheduleFreqRecurrenceFactor>
        <scheduleActiveStartDate>20000101</scheduleActiveStartDate>
        <scheduleActiveEndDate>99991231</scheduleActiveEndDate>
        <scheduleActiveStartTime>0</scheduleActiveStartTime>
        <scheduleActiveEndTime>50000</scheduleActiveEndTime>
    </schedule>
</schedules>', N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (26, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_StatisticsOnly_Daily', N'Ежедневное обслуживание статистик для базы ({DatabaseName})', N'<steps>
        <step>
            <name>Statistics Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''00:00:00''
  ,@timeTo = ''15:00:00''
  ,@mode = 0
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>', 1, 4, 1, 1, 0, 0, 0, 20000101, 99991231, 120000, 235959, CAST(N'2024-05-22T12:13:58.090' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (27, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_Weekly', N'Еженедельное обслуживание индексов и статистик для баз ({DatabaseName})', N'<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''20:00:00''
  ,@timeTo = ''23:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxTransactionLogSizeMB = 409600
  ,@fillFactorForIndex = 80
  ,@maxIndexSizePages = 13107200
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Index Maintenance Huge Objects</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''20:00:00''
  ,@timeTo = ''05:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxTransactionLogSizeMB = 409600
  ,@fillFactorForIndex = 80
  ,@minIndexSizePages = 13107200
  ,@useResumableIndexRebuildIfAvailable = 1
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Statistic Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''19:00:00''
  ,@timeTo = ''23:59:59''
  ,@mode = 0
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>', 1, 8, 32, 1, 0, 0, 1, 20000101, 99991231, 200000, 235959, CAST(N'2024-05-22T12:13:57.573' AS DateTime), 0, N'<schedules>
    <schedule>
        <scheduleEnabled>1</scheduleEnabled>
        <scheduleName>Maintenance.{DatabaseName}_IndicesAndStatistics_Weekly</scheduleName>
        <scheduleFreqType>8</scheduleFreqType>
        <scheduleFreqInterval>64</scheduleFreqInterval>
        <scheduleFreqSubdayType>4</scheduleFreqSubdayType>
        <scheduleFreqSubdayInterval>30</scheduleFreqSubdayInterval>
        <scheduleFreqRelativeInterval>0</scheduleFreqRelativeInterval>
        <scheduleFreqRecurrenceFactor>1</scheduleFreqRecurrenceFactor>
        <scheduleActiveStartDate>20000101</scheduleActiveStartDate>
        <scheduleActiveEndDate>99991231</scheduleActiveEndDate>
        <scheduleActiveStartTime>0</scheduleActiveStartTime>
        <scheduleActiveEndTime>50000</scheduleActiveEndTime>
    </schedule>
</schedules>', N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (28, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_SpecialLegacyObjects_Daily', N'Ежедневное обслуживание особых индексов для баз ({DatabaseName})', N'<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance]
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''23:00:00''
  ,@timeTo = ''23:30:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 2
  ,@maxIndexSizePages = 3932160
   ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeUsagePercent = 30
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>', 1, 8, 95, 1, 0, 0, 1, 20000101, 99991231, 230000, 235959, CAST(N'2024-05-22T12:13:57.087' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (29, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_SpecialLegacyObjects_Weekly', N'Еженедельное обслуживание особых индексов для баз ({DatabaseName})', N'<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''23:00:00''
  ,@timeTo = ''23:30:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 2
  ,@maxTransactionLogSizeUsagePercent = 50
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>', 1, 8, 32, 1, 0, 1, 1, 20000101, 99991231, 230000, 235959, CAST(N'2024-05-22T12:13:56.620' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (30, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_FillDatabaseObjectsState', N'Сбор информации о состоянии объектов для баз ({DatabaseName})', N'EXECUTE [SQLServerMaintenance].[dbo].[sp_FillDatabaseObjectsState] 
   @databaseName = ''{DatabaseName}''', 1, 4, 1, 8, 8, 0, 0, 20000101, 99991231, 80000, 235959, CAST(N'2024-05-22T12:13:56.070' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ВОЗОБНОВЛЯЕМОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (38, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_Daily', N'Ежедневное обслуживание индексов и статистик ({DatabaseName})', N'
    <steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''01:00:00''
  ,@timeTo = ''08:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxIndexSizePages = 6553600
  ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeMB = 1048576
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Index Maintenance Huge Objects</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''01:00:00''
  ,@timeTo = ''08:00:00'', @maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeMB = 1048576
  ,@fillFactorForIndex = 80
  ,@minIndexSizePages = 6553600
  ,@useResumableIndexRebuildIfAvailable = 1
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Statistic Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
    @databaseName = ''{DatabaseName}''
   ,@timeFrom = ''01:00:00''
   ,@timeTo = ''09:00:00''
   ,@mode = 0
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>
', 1, 8, 63, 1, 30, 0, 1, 20000101, 99991231, 10000, 235959, CAST(N'2024-05-22T13:20:26.603' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ПРОСТОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (39, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_Weekly', N'Еженедельное обслуживание индексов и статистик ({DatabaseName})', N'
    <steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''01:00:00''
  ,@timeTo = ''08:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@maxIndexSizePages = 6553600
  ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeMB = 1048576
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Index Maintenance Huge Objects</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance] 
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''01:00:00''
  ,@timeTo = ''08:00:00'', @maxDop = 8
  ,@useOnlineIndexRebuild = 1
  ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeMB = 1048576
  ,@fillFactorForIndex = 80
  ,@minIndexSizePages = 6553600
  ,@useResumableIndexRebuildIfAvailable = 1
            </script>
            <on_success_action>3</on_success_action>
            <on_fail_action>3</on_fail_action>
        </step>
        <step>
            <name>Statistic Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_StatisticMaintenance] 
    @databaseName = ''{DatabaseName}''
   ,@timeFrom = ''01:00:00''
   ,@timeTo = ''09:00:00''
   ,@mode = 0
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>
', 1, 8, 64, 1, 0, 0, 1, 20000101, 99991231, 10000, 235959, CAST(N'2024-05-22T13:20:27.507' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ПРОСТОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (40, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_SpecialLegacyObjects_Daily', N'Ежедневное обслуживание особых индексов ({DatabaseName})', N'
<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance]
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''04:00:00''
  ,@timeTo = ''08:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 2
  ,@maxIndexSizePages = 3932160
   ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeUsagePercent = 30
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>
', 1, 8, 63, 1, 0, 0, 1, 20000101, 99991231, 40000, 235959, CAST(N'2024-05-22T13:20:28.283' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ПРОСТОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (41, 0, 1, N'
SELECT
	[name] AS [DatabaseName]
FROM sys.databases dbs
WHERE NOT [name] IN (''master'',''msdb'',''model'', ''tempdb'')
', N'Maintenance.{DatabaseName}_IndicesAndStatistics_SpecialLegacyObjects_Weekly', N'Еженедельное обслуживание особых индексов ({DatabaseName})', N'
<steps>
        <step>
            <name>Index Maintenance</name>
            <script>
EXECUTE [SQLServerMaintenance].[dbo].[sp_IndexMaintenance]
   @databaseName = ''{DatabaseName}''
  ,@timeFrom = ''04:00:00''
  ,@timeTo = ''08:00:00''
  ,@maxDop = 8
  ,@useOnlineIndexRebuild = 2
  ,@maxIndexSizePages = 3932160
   ,@fragmentationPercentMinForMaintenance = 30
  ,@maxTransactionLogSizeUsagePercent = 30
  ,@fillFactorForIndex = 80
            </script>
            <on_success_action>1</on_success_action>
            <on_fail_action>1</on_fail_action>
        </step>
    </steps>
', 1, 8, 64, 1, 0, 1, 1, 20000101, 99991231, 40000, 235959, CAST(N'2024-05-22T13:20:29.220' AS DateTime), 0, NULL, N'ЛЮБАЯ_БАЗА_ПРОСТОЕ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (54, 0, 1, NULL, N'Maintenance.FillDatabaseObjectsState', N'Сбор информации о состоянии объектов всех баз данных на сервере.', N'
DECLARE @databaseName sysname;

IF OBJECT_ID(''tempdb..#dbToAnalyze'') IS NOT NULL DROP TABLE #dbToAnalyze
CREATE TABLE #dbToAnalyze ( DatabaseName nvarchar(250));
INSERT INTO #dbToAnalyze(DatabaseName)
SELECT
	[name]
FROM sys.databases
WHERE NOT [name] IN (''master'', ''model'', ''tempdb'', ''msdb'', ''SQLServerMaintenance'')
	AND state_desc = ''ONLINE''

DECLARE databases_cursor CURSOR  
FOR SELECT
	[DatabaseName]
FROM #dbToAnalyze;
OPEN databases_cursor;

FETCH NEXT FROM databases_cursor INTO @databaseName;

WHILE @@FETCH_STATUS = 0  
BEGIN
	PRINT @databaseName;
	EXECUTE [SQLServerMaintenance].[dbo].[sp_FillDatabaseObjectsState] 
		@databaseName = @databaseName

	FETCH NEXT FROM databases_cursor INTO @databaseName;
END
CLOSE databases_cursor;  
DEALLOCATE databases_cursor;
    ', 1, 4, 1, 1, 1, 0, 0, 20000101, 99991231, 230000, 235959, CAST(N'2024-06-27T09:15:23.290' AS DateTime), 0, NULL, N'ОБЩИЕ_ДОПОЛНИТЕЛЬНЫЕ_ЗАДАНИЯ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (55, 0, 1, NULL, N'Maintenance.FullBackupAllDatabases', N'Полный бэкап всех баз данных.', N'
DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END

DECLARE @databaseName sysname;

IF OBJECT_ID(''tempdb..#dbToBackup'') IS NOT NULL DROP TABLE #dbToBackup
CREATE TABLE #dbToBackup ( DatabaseName nvarchar(250));
INSERT INTO #dbToBackup(DatabaseName)
SELECT
	[name]
FROM sys.databases
WHERE state_desc = ''ONLINE''
	AND NOT [name] IN (''master'', ''model'', ''tempdb'', ''msdb'', ''SQLServerMaintenance'')

DECLARE databases_cursor CURSOR  
FOR SELECT
	[DatabaseName]
FROM #dbToBackup;
OPEN databases_cursor;

FETCH NEXT FROM databases_cursor INTO @databaseName;

WHILE @@FETCH_STATUS = 0  
BEGIN
	PRINT @databaseName;
	
	EXECUTE [SQLServerMaintenance].[dbo].[sp_BackupDatabase] 
		@databaseName = @databaseName
		,@backupType = ''FULL''
		,@backupDirectory = @BackupDirectory
		,@backupCompressionType = ''ENABLE''

	FETCH NEXT FROM databases_cursor INTO @databaseName;
END
CLOSE databases_cursor;  
DEALLOCATE databases_cursor;
    ', 1, 4, 1, 1, 1, 0, 0, 20000101, 99991231, 230000, 235959, CAST(N'2024-06-27T09:15:23.290' AS DateTime), 0, NULL, N'ОБЩИЕ_ДОПОЛНИТЕЛЬНЫЕ_ЗАДАНИЯ')
GO
INSERT [dbo].[JobTemplates] ([Id], [UseSetting], [Enable], [ApplyTemplateQuery], [Name], [Description], [JobAction], [ScheduleEnable], [ScheduleFreqType], [ScheduleFreqInterval], [ScheduleFreqSubdayType], [ScheduleFreqSubdayInterval], [ScheduleFreqRelativeInterval], [ScheduleFreqRecurrenceFactor], [ScheduleActiveStartDay], [ScheduleActiveEndDay], [ScheduleActiveStartTime], [ScheduleActiveEndTime], [VersionDate], [TimeoutSec], [SchedulesAdditional], [TemplateGroupName]) VALUES (56, 0, 1, NULL, N'Maintenance.TransactionLogBackupAllDatabases', N'Бэкап лога транзакций всех баз данных.', N'
DECLARE @BackupDirectory VARCHAR(512);
EXEC  master.dbo.xp_instance_regread 
	N''HKEY_LOCAL_MACHINE'', 
	N''Software\Microsoft\MSSQLServer\MSSQLServer'',
	N''BackupDirectory'', 
	@BackupDirectory = @BackupDirectory OUTPUT
IF(@BackupDirectory IS NULL)
BEGIN
	SET @BackupDirectory = ''G:\SQL_backup''
END

DECLARE @databaseName sysname;

IF OBJECT_ID(''tempdb..#dbToBackup'') IS NOT NULL DROP TABLE #dbToBackup
CREATE TABLE #dbToBackup ( DatabaseName nvarchar(250));
INSERT INTO #dbToBackup(DatabaseName)
SELECT
	[name]
FROM sys.databases
WHERE state_desc = ''ONLINE''
	AND recovery_model = 1
	AND NOT [name] IN (''master'', ''model'', ''tempdb'', ''msdb'', ''SQLServerMaintenance'')

DECLARE databases_cursor CURSOR  
FOR SELECT
	[DatabaseName]
FROM #dbToBackup;
OPEN databases_cursor;

FETCH NEXT FROM databases_cursor INTO @databaseName;

WHILE @@FETCH_STATUS = 0  
BEGIN
	PRINT @databaseName;	
	EXECUTE [SQLServerMaintenance].[dbo].[sp_BackupDatabase] 
		@databaseName = @databaseName
		,@backupType = ''TRN''
		,@backupDirectory = @BackupDirectory
		,@backupCompressionType = ''ENABLE''
	FETCH NEXT FROM databases_cursor INTO @databaseName;
END
CLOSE databases_cursor;  
DEALLOCATE databases_cursor;
    ', 1, 4, 1, 1, 1, 0, 0, 20000101, 99991231, 230000, 235959, CAST(N'2024-06-27T09:15:23.290' AS DateTime), 0, NULL, N'ОБЩИЕ_ДОПОЛНИТЕЛЬНЫЕ_ЗАДАНИЯ')
GO
SET IDENTITY_INSERT [dbo].[JobTemplates] OFF
GO
SET IDENTITY_INSERT [dbo].[LogTransactionControlSettings] ON 
GO
INSERT [dbo].[LogTransactionControlSettings] ([Id], [DatabaseName], [MinDiskFreeSpace], [MaxLogUsagePercentThreshold], [MinAllowDataFileFreeSpaceForResumableRebuildMb]) VALUES (1, NULL, 307200, 75, 307200)
GO
SET IDENTITY_INSERT [dbo].[LogTransactionControlSettings] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UK_Table_Object_Period]    Script Date: 11.06.2025 18:05:56 ******/
CREATE NONCLUSTERED INDEX [UK_Table_Object_Period] ON [dbo].[DatabaseObjectsState]
(
	[DatabaseName] ASC,
	[TableName] ASC,
	[Object] ASC,
	[Period] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_LogTransactionControlSettings_DatabaseName]    Script Date: 11.06.2025 18:05:56 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_LogTransactionControlSettings_DatabaseName] ON [dbo].[LogTransactionControlSettings]
(
	[DatabaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UK_RunDate_Table_Index_Period_Operation]    Script Date: 11.06.2025 18:05:56 ******/
CREATE NONCLUSTERED INDEX [UK_RunDate_Table_Index_Period_Operation] ON [dbo].[MaintenanceActionsLog]
(
	[RunDate] ASC,
	[DatabaseName] ASC,
	[TableName] ASC,
	[IndexName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Settings_Name_DatabaseName]    Script Date: 11.06.2025 18:05:56 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Settings_Name_DatabaseName] ON [dbo].[Settings]
(
	[Name] ASC,
	[DatabaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[changelog] ADD  DEFAULT (getdate()) FOR [installed_on]
GO
ALTER TABLE [dbo].[JobTemplates] ADD  CONSTRAINT [DF_JobTemplates_VersionDate]  DEFAULT (getdate()) FOR [VersionDate]
GO
ALTER TABLE [dbo].[LogTransactionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_MinLogUsagePercentThreshold]  DEFAULT ((90)) FOR [MaxLogUsagePercentThreshold]
GO
ALTER TABLE [dbo].[LogTransactionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_MinAllowDataFileFreeSpaceForResumableRebuildMb]  DEFAULT ((0)) FOR [MinAllowDataFileFreeSpaceForResumableRebuildMb]
GO
ALTER TABLE [dbo].[MaintenanceActionsLog] ADD  CONSTRAINT [DF_MaintenanceActionsLog_TransactionLogUsageBeforeMB]  DEFAULT ((0)) FOR [TransactionLogUsageBeforeMB]
GO
ALTER TABLE [dbo].[MaintenanceActionsToRun] ADD  CONSTRAINT [DF_MaintenanceActionsToRun_RunAttempts]  DEFAULT ((0)) FOR [RunAttempts]
GO
ALTER TABLE [dbo].[SessionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_AbortIfLockOtherSessions]  DEFAULT ((0)) FOR [AbortIfLockOtherSessions]
GO
ALTER TABLE [dbo].[SessionControlSettings] ADD  CONSTRAINT [DF_LogTransactionControlSettings_AbortIfLockOtherSessionsTimeoutSec]  DEFAULT ((0)) FOR [AbortIfLockOtherSessionsTimeoutSec]
GO
/****** Object:  StoredProcedure [dbo].[sp_AbortResumableIndexRebuilds]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AbortResumableIndexRebuilds] 
	@databaseNameFilter nvarchar(max) = null,
	@dataFileName nvarchar(max) = null
AS
BEGIN
	SET NOCOUNT ON;
		
	IF OBJECT_ID('tempdb..#controlDataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #controlDataFileInfoByDatabases;
	CREATE TABLE #controlDataFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		DataFileName varchar(255),
		DataFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[DataSizeMB] numeric(15,0),
		[DataMaxSizeMB] numeric(15,0),
		[DataFileCanGrow] bit,
		[DataFileFreeSpaceMB] numeric(15,0),
		[ResumableRebuildDataFileUsageMb] numeric(15,0),
		[SqlAbort] nvarchar(max)
	);

	DECLARE 
		@RunDate datetime = GetDate(),
		@startDate datetime = GetDate(),
		@finishDate datetime = GetDate(),
		@MaintenanceActionLogId bigint,
		@SqlStatement nvarchar(MAX),
		@CurrentDatabaseName sysname,
		@message nvarchar(max);
	DECLARE ControlDatabaseList CURSOR LOCAL FAST_FORWARD FOR
		SELECT [name] FROM sys.databases 
		WHERE state_desc = 'ONLINE'
			AND NOT [name] IN ('master', 'tempdb', 'model', 'msdb');;
	OPEN ControlDatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM ControlDatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;

		-- Заполняем информации о файлах данных
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'
IF(EXISTS(SELECT * FROM sys.index_resumable_operations))
BEGIN
	INSERT INTO #controlDataFileInfoByDatabases
	SELECT
		DB_NAME(f.database_id) AS [Database],
		f.[name] AS [DataFileName],
		f.physical_name AS [DataFilePath],
		volume_mount_point AS [Disk],
		available_bytes/1048576 as [DiskFreeSpaceMB],
		CAST(f.size AS bigint) * 8 / 1024 AS [DataSizeMB],
		CAST(f.size AS bigint) * 8 / 1024 + CAST(available_bytes/1048576 AS bigint) AS [DataMaxSizeMB],
		CASE 
			WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
			THEN 0
			ELSE 1
		END AS [DataFileCanGrow],
		size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [DataFileFreeSpaceMB],
		ISNULL(rir.DataFileUsageMb, 0) AS [ResumableRebuildDataFileUsageMb],
		''USE ['' + DB_NAME(f.database_id) + '']; ALTER INDEX ['' + rir.[name] + ''] ON ['' + [SchemaName] + ''].['' + [ObjectName] + ''] ABORT'' AS [SqlAbort]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	  INNER JOIN (
			SELECT 
				disks.FileName,
				disks.PhysicalName,
				iro.object_id,
				OBJECT_NAME(iro.object_id) AS [ObjectName],
				OBJECT_SCHEMA_NAME(iro.object_id) AS [SchemaName],
				iro.index_id,
				iro.name,
				iro.page_count * 8 / 1024 AS [DataFileUsageMb]
			FROM sys.index_resumable_operations iro
				INNER JOIN (
					select 
						p.object_id AS [ObjectId],
						p.[index_id] AS [IndexId],
						ISNULL(p.[partition_number], 1) AS [PartitionNumber],
						f.[name] AS [FileName],
						f.physical_name AS [PhysicalName]
					from sys.allocation_units u 
						join sys.database_files f on u.data_space_id = f.data_space_id 
						join sys.partitions p on u.container_id = p.hobt_id
				) disks
				ON iro.object_id = disks.ObjectId
					AND iro.index_id = disks.IndexId
					AND ISNULL(iro.partition_number, 1) = disks.PartitionNumber
	  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
	WHERE [type_desc] = ''ROWS''
		and f.database_id = DB_ID()
END';
				
		BEGIN TRY
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH
	END

	DECLARE
		@currentDataFileName nvarchar(max),
		@currentResumableRebuildDataFileUsageMb bigint,
		@currentSqlAbort nvarchar(max);
	DECLARE controlDataFileUsageByResumableRebuild CURSOR FOR
	SELECT 
		DatabaseName,
		DataFileName,
		ResumableRebuildDataFileUsageMb,
		[SqlAbort]
	FROM #controlDataFileInfoByDatabases
	WHERE (@databaseNameFilter IS NULL OR [DatabaseName] = @databaseNameFilter)
		AND (@dataFileName IS NULL OR DataFileName = @dataFileName);
	OPEN controlDataFileUsageByResumableRebuild;
	FETCH NEXT FROM controlDataFileUsageByResumableRebuild 
	INTO @currentDatabaseName, @currentDataFileName, @currentResumableRebuildDataFileUsageMb, @currentSqlAbort;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @message = 
			'Для базы данных ' + @currentDatabaseName + ' файла ' + @currentDataFileName + ' отменена возобновляемая операция перестроения. ' +
			'Команда: ' + @currentSqlAbort + '.';
		PRINT @message

		BEGIN TRY
			EXECUTE(@currentSqlAbort);
		END TRY
		BEGIN CATCH
			SET @message = 'Ошибка: ' + ERROR_MESSAGE() + '. ' + 'Не удалось завершить возобновляемую операцию.'
			PRINT @message
		END CATCH

		EXECUTE [dbo].[sp_add_maintenance_action_log]
			''
			,''
			,'RESUMABLE REBULD CONTROL'
			,@RunDate
		    ,@startDate
			,@finishDate
			,@currentDatabaseName
			,0
			,@message
			,0
			,0
			,@currentSqlAbort
			,@MaintenanceActionLogId OUTPUT;

		FETCH NEXT FROM controlDataFileUsageByResumableRebuild 
		INTO @currentDatabaseName, @currentDataFileName, @currentResumableRebuildDataFileUsageMb, @currentSqlAbort;
	END
	CLOSE controlDataFileUsageByResumableRebuild;  
	DEALLOCATE controlDataFileUsageByResumableRebuild;

	IF OBJECT_ID('tempdb..#controlDataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #controlDataFileInfoByDatabases;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_add_maintenance_action_log]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_add_maintenance_action_to_run]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_AddOrUpdateJobTimeout]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_AddSessionControlSetting]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddSessionControlSetting]
	@databaseName nvarchar(250) = null,
	@workFrom time(7) = null,
	@workTo time(7) = null,
	@timeTimeoutSec int = null,
	@maxLogUsagePercent int = null,
	@maxLogUsageMb int = null,
	@abortIfLockOtherSessions bit = 0,
	@abortIfLockOtherSessionsTimeoutSec int = 0
AS
BEGIN
	SET NOCOUNT ON;

	EXEC [dbo].[sp_RemoveSessionControlSetting];

	DECLARE @currentSpid smallint;
	SELECT @currentSpid = @@SPID

	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	);
	INSERT INTO @AllConnections EXEC sp_who2;	

	INSERT INTO [dbo].[SessionControlSettings]
	(
		[SPID],
		[Login],
		[HostName],
		[ProgramName],
		[WorkFrom],
		[WorkTo],
		[MaxLogUsagePercent],
		[MaxLogUsageMb],
		[Created],
		[DatabaseName],
		[WorkTimeoutSec],
		[AbortIfLockOtherSessions],
		[AbortIfLockOtherSessionsTimeoutSec]
	)
	SELECT TOP 1
		[SPID],
		[Login],
		[HostName],
		[ProgramName],
		@workFrom,
		@workTo,
		@maxLogUsagePercent,
		@MaxLogUsageMb,
		GetDate(),
		@databaseName,
		@timeTimeoutSec,
		@abortIfLockOtherSessions,
		@abortIfLockOtherSessionsTimeoutSec
	FROM @AllConnections
	WHERE SPID = @currentSpid;	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_AdvancedPrint]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_apply_maintenance_action_to_run]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_BackupDatabase]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

		IF(@backupSetId is null)
		BEGIN
			SET @sql = @sql + '

-- Не найден резервный набор данных. Верификация будет пропущена.'
		END ELSE
		BEGIN
			SET @sql = @sql + '

	RESTORE VERIFYONLY FROM  DISK = N''' + @backupFileFullName + ''' WITH  FILE = ' + CAST(@backupSetId AS nvarchar(max)) + ',  NOUNLOAD,  NOREWIND;'
		END
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
/****** Object:  StoredProcedure [dbo].[sp_ClearFiles]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_ClearOldSessionControlSettings]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ClearOldSessionControlSettings]
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
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	);
	INSERT INTO @AllConnections EXEC sp_who2;	

	DELETE FROM [dbo].[SessionControlSettings]
	WHERE [SPID] IN (
		SELECT 
			ISNULL([AC].[SPID],[SCS].[SPID]) AS [SPID]
		FROM @AllConnections AS [AC]
			FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
			ON [AC].[SPID] = [SCS].[SPID]
				AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
				AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
				AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		WHERE -- Есть подходящие настройки ограничений для соединения
			[SCS].[SPID] IS NOT NULL	
			AND (
				-- Исключаем статусы соединений
				UPPER([Status]) IN (
					'BACKGROUND' -- Фоновые процессы
					,'SLEEPING' -- Ожидающие команды, не активные
				)

				OR

				-- Настройка была добавлена 24 часа назад
				DATEDIFF(HOUR, [Created], GETDATE()) >= 24

				OR

				-- Соединения уже не существует
				[AC].[SPID] IS NULL
			)
	)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CompressAndShrinkDataFile]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CompressAndShrinkDataFile] 
	@databaseName sysname,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@useOnlineRebuild bit = 1,
	@userResumableRebuild bit = 1,
	@maxDop int = 4,
	@databaseFileNameForShrink nvarchar(512) = null,		
	@delayBetweenShrinkSteps nvarchar(8) = '00:00:10',
	@shrinkStepMb int = 10240,
	@stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3) = 1.0
AS
BEGIN
	SET NOCOUNT ON;

    EXECUTE [SQLServerMonitoring].[dbo].[sp_CompressDatabaseObjects] 
		@databaseName = @databaseName,
		@timeFrom = @timeFrom,
		@timeTo = @timeTo,
		@useOnlineRebuild = @useOnlineRebuild,
		@userResumableRebuild = @userResumableRebuild,
		@maxDop = @maxDop
	
	EXECUTE [SQLServerMonitoring].[dbo].[sp_ShrinkDatabaseDataFile]
		@databaseName = @databaseName,
		@databaseFileName = @databaseFileNameForShrink,
		@delayBetweenSteps = @delayBetweenShrinkSteps,
		@timeFrom = @timeFrom,
		@timeTo = @timeTo,
		@shrinkStepMb = @shrinkStepMb,
		@stopShrinkThresholdByDataFileFreeSpacePercent = @stopShrinkThresholdByDataFileFreeSpacePercent;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CompressDatabaseObjects]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CompressDatabaseObjects]
	@databaseName sysname,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@useOnlineRebuild bit = 1,
	@userResumableRebuild bit = 1,
	@maxDop int = 4
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE		
	   @sql nvarchar(max)
	   ,@msg nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + ISNULL(@databaseName, '') + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	-- Включаем контроль потребления ресурсов текущим соединением
	if(@timeFrom is not null and @timeTo is not null)
	BEGIN
		EXEC [SQLServerMonitoring].[dbo].[sp_AddSessionControlSetting]
			@databaseName = @databaseName,
			@workFrom = @timeFrom,
			@workTo = @timeTo,
			@timeTimeoutSec = 60,
			@abortIfLockOtherSessions = 1,
			@abortIfLockOtherSessionsTimeoutSec = 0;
	END

	IF OBJECT_ID('tempdb..#dataToCompress') IS NOT NULL
		DROP TABLE #dataToCompress;
	CREATE TABLE #dataToCompress
	(
		[SchemaName] varchar(255) not null,
		[Table] varchar(255),
		[Index] varchar(255),
		[Compression] varchar(25),
		[IndexType] numeric(15,0),
		[IndexsizeKB] numeric(15,0),
		[SqlCommandBase] nvarchar(max),
		[SqlCommandWithoutOnline] nvarchar(max)
	);

	SET @sql = CAST('
	USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST(']
	INSERT INTO #dataToCompress (
		[SchemaName],
		[Table],
		[Index],
		[Compression],
		[IndexType],
		[IndexsizeKB],
		[SqlCommandBase],
		[SqlCommandWithoutOnline]
	)
	SELECT
		dt.[SchemaName],
		dt.[Table],
		dt.[Index],
		dt.[Compression],
		dt.[IndexType],
		dtsz.[IndexsizeKB],
		''USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
		alter index '' + dt.[Index] 
			+ '' on ['' + dt.[SchemaName] + ''].['' + dt.[Table] + ''] rebuild with (data_compression = page, maxdop='' 
			+ CAST(@maxDop as nvarchar(max)) + '', online='' + 
			+ CASE WHEN @useOnlineRebuild = 1 THEN ''ON'' ELSE ''OFF'' END +
			+ '', RESUMABLE = '' +
			+ CASE WHEN @userResumableRebuild = 1 THEN ''ON'' ELSE ''OFF'' END +
			+ '')'' AS [SqlCommandBase],
		''USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
		alter index '' + dt.[Index] 
			+ '' on ['' + dt.[SchemaName] + ''].['' + dt.[Table] + ''] rebuild with (data_compression = page, maxdop='' 
			+ CAST(@maxDop as nvarchar(max)) + '', online=off)'' AS [SqlCommandWithoutOnline]
	FROM (
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			null AS [Index],  
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			-1 AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
		WHERE [p].[index_id] = 0
		UNION
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			[i].[name] AS [Index],   
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			[i].[type] AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
			INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
		WHERE [p].[index_id] = 1
		UNION
		SELECT 
			OBJECT_SCHEMA_NAME(p.OBJECT_ID) AS [SchemaName],
			[t].[name] AS [Table], 
			[i].[name] AS [Index],  
			[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			[i].[type] AS [IndexType]
		FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
			INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id] AND [i].[index_id] = [p].[index_id]
		WHERE [p].[index_id] > 0) dt
		LEFT JOIN (
			SELECT
				OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
				OBJECT_NAME(i.OBJECT_ID) AS TableName,
				i.name AS IndexName,
				i.index_id AS IndexID,
				8 * SUM(a.used_pages) AS ''IndexsizeKB''
			FROM sys.indexes AS i
				JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
				JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			GROUP BY i.OBJECT_ID,i.index_id,i.name
		) dtsz
		ON dt.SchemaName = dtsz.SchemaName
			AND dt.[Table] = dtsz.TableName
			AND dt.[Index] = dtsz.[IndexName]
	WHERE [Compression] = ''NONE''
		AND [Index] IS NOT NULL
		AND ISNULL(dtsz.[IndexsizeKB], -1) <> 0
	ORDER BY dt.[IndexType], [IndexsizeKB]' AS nvarchar(max));

	EXECUTE sp_executesql
			@sql,
			N'@maxDop INT, @useOnlineRebuild bit, @userResumableRebuild bit',
			@maxDop, @useOnlineRebuild, @userResumableRebuild;

	DECLARE 
		@sqlCompressObject nvarchar(max),
		@sqlCompressObjectWitoutOnline nvarchar(max);

	DECLARE objectsToCompress CURSOR FOR 
	SELECT
		dt.SqlCommandBase,
		dt.SqlCommandWithoutOnline
	FROM #dataToCompress dt
	ORDER BY dt.[IndexType], dt.IndexsizeKB;
	OPEN objectsToCompress;

	FETCH NEXT FROM objectsToCompress INTO @sqlCompressObject, @sqlCompressObjectWitoutOnline;

	WHILE @@FETCH_STATUS = 0  
	BEGIN	

		BEGIN TRY
			exec(@sqlCompressObject)
			PRINT 'Объект сжат командой:'
			PRINT @sqlCompressObject;
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось сжать объект командой:'
			PRINT @sqlCompressObject

			BEGIN TRY
				exec(@sqlCompressObjectWitoutOnline)
				PRINT 'Объект сжат командой:'
				PRINT @sqlCompressObject;
			END TRY
			BEGIN CATCH
				PRINT 'Не удалось сжать объект командой:'
				PRINT @sqlCompressObjectWitoutOnline
			END CATCH
		END CATCH

		FETCH NEXT FROM objectsToCompress INTO @sqlCompressObject, @sqlCompressObjectWitoutOnline;
	END
	CLOSE objectsToCompress;  
	DEALLOCATE objectsToCompress;

	IF OBJECT_ID('tempdb..#dataToCompress') IS NOT NULL
			DROP TABLE #dataToCompress;

	-- Удаляем контроль для текущей сессии
	EXEC [SQLServerMonitoring].[dbo].[sp_RemoveSessionControlSetting];
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ControlJobsExecutionTimeout]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ControlJobsExecutionTimeout]
AS
BEGIN
	SET NOCOUNT ON;

	-- Очистка устаревших настроек контроля соединений
	EXEC [dbo].[sp_ClearOldSessionControlSettings];

	DECLARE @msg nvarchar(max), @sql nvarchar(max);
	DECLARE @startDate datetime = GetDate(),
			@finishDate datetime = GetDate(),
			@timeNow time = CAST(GetDate() AS TIME),
			@runDate datetime = GetDate(),
			@MaintenanceActionLogId bigint;

	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
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
		@programName nvarchar(max),
		@DBName VARCHAR(MAX),
		@WorkFrom time,
		@WorkTo time,
		@WorkTimeoutSec int,
		@CurrentWorkTimeoutSec int;

	-- Проверка таймаута работы заданий
	DECLARE timeout_jobs_cursor CURSOR FOR 
	SELECT 
		DATEDIFF(SECOND, sja.[start_execution_date], GETDATE()) AS 'ExecutionDurationSec',
		jtime.TimeoutSec,
		SPID,
		ProgramName,
		DBName
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
	FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName, @DBName;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @msg = 'Задание ''' + @programName + ''' завершено по таймауту. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Время работы: ' + CAST(@executionTimeSec  AS nvarchar(max))+ '. Таймаут: ' + CAST(@timeoutSec AS nvarchar(max)) + '.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			PRINT @msg
		END CATCH

		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'JOB EXECUTION TIME CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@DBName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		FETCH NEXT FROM timeout_jobs_cursor INTO @executionTimeSec, @timeoutSec, @SPID, @programName, @DBName;
	END
	CLOSE timeout_jobs_cursor;  
	DEALLOCATE timeout_jobs_cursor;



	-- Проверка времени работы соединений
	DECLARE timeout_session_cursor CURSOR FOR
	SELECT [AC].[SPID], [WorkFrom], [WorkTo], [SCS].[DatabaseName],
		ISNULL([SCS].[WorkTimeoutSec],0) AS [WorkTimeoutSec],
		queryExecution.[QueryActiveTimeSec] AS [CurrentWorkTimeoutSec]
	FROM @AllConnections AS [AC]
		FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
		ON [AC].[SPID] = [SCS].[SPID]
			AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
			AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
			AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		LEFT JOIN (
			SELECT 
				req.session_id AS [SessionId],
				req.total_elapsed_time / 1000 AS [QueryActiveTimeSec]
			FROM sys.dm_exec_requests req
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
		) queryExecution
		ON [AC].[SPID] = queryExecution.SessionId
	WHERE -- Есть подходящие настройки ограничений для соединения
		[SCS].[SPID] IS NOT NULL	
		-- Исключаем статусы соединений
		AND NOT UPPER([Status]) IN (
			'BACKGROUND' -- Фоновые процессы
			,'SLEEPING' -- Ожидающие команды, не активные
		)
		-- Проверка превышения таймаута времени выполнения в разрешенном диапазоне времени
		AND CASE
				WHEN ISNULL([SCS].[WorkTimeoutSec],0) <= 0
				THEN 1
				WHEN ISNULL([SCS].[WorkTimeoutSec],0) <= queryExecution.[QueryActiveTimeSec]
				THEN 1
				ELSE 0
			END > 0
		AND (
			-- Проверка времени запуска
			CASE
				-- Ограничения не заданы
				WHEN [WorkFrom] IS NULL OR [WorkTo] IS NULL
				THEN 0
				-- Время окончания больше времени начала. Текущее время выходит за рамки диапазона.
				WHEN [WorkTo] >= [WorkFrom]
				THEN 
					CASE
						WHEN NOT ([WorkFrom] <= @timeNow AND [WorkTo] >= @timeNow)
						THEN 1
						ELSE 0
					END
				-- Время окончания меньше времени начала. 
				-- Текущее время выходит за рамки диапазона.
				WHEN [WorkTo] >= [WorkFrom]
				THEN 
					CASE
						WHEN NOT (([WorkFrom] <= @timeNow AND '23:59:59' >= @timeNow)
								OR ([WorkTo] >= @timeNow AND '00:00:00' <= @timeNow))
						THEN 1
						ELSE 0
					END
				ELSE 0
			END >= 1
		)
	OPEN timeout_session_cursor;
	FETCH NEXT FROM timeout_session_cursor INTO @SPID, @WorkFrom, @WorkTo, @DBName, @WorkTimeoutSec, @CurrentWorkTimeoutSec;
	WHILE @@FETCH_STATUS = 0  
	BEGIN		
		SET @msg = 'Завершено, т.к. время выполнения выходит за допущенный диапазон времени. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Текущее время: ' + CAST(@timeNow  AS nvarchar(max))+ '. Разрешенный диапазон времени: ' + CAST(@WorkFrom AS nvarchar(max)) + ' - ' + CAST(@WorkTo AS nvarchar(max)) + '. Таймаут выполнения текущий ' + CAST(@CurrentWorkTimeoutSec AS nvarchar(max)) + ' сек., максимальный ' + CAST(@WorkTimeoutSec AS nvarchar(max)) + ' сек.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			SET @msg = 'Не удалось завершить соединение. ' +  @msg
			PRINT @msg
		END CATCH
		
		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'JOB EXECUTION TIME CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@DBName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		EXEC [dbo].[sp_RemoveSessionControlSetting]
			@spid = @SPID;

		FETCH NEXT FROM timeout_session_cursor INTO @SPID, @WorkFrom, @WorkTo, @DBName, @WorkTimeoutSec, @CurrentWorkTimeoutSec;
	END
	CLOSE timeout_session_cursor;  
	DEALLOCATE timeout_session_cursor;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ControlSessionLocks]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ControlSessionLocks]
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#connectionsInfo') IS NOT NULL
		DROP TABLE #connectionsInfo;
	CREATE TABLE #connectionsInfo
	(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	);

	IF OBJECT_ID('tempdb..#connectionsInfoExtended') IS NOT NULL
		DROP TABLE #connectionsInfoExtended;
	CREATE TABLE #connectionsInfoExtended
	(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT,
		WaitType nvarchar(max),
		BlockingSessionId INT,
		WaitDurationMs BIGINT
	);

	-- Проверку выполняем пока есть настройки с контролем блокировки
	WHILE(EXISTS(SELECT * FROM [dbo].[SessionControlSettings]
			WHERE [AbortIfLockOtherSessions] = 1))
	BEGIN
		TRUNCATE TABLE #connectionsInfo;
		INSERT INTO #connectionsInfo EXEC sp_who2;

		TRUNCATE TABLE #connectionsInfoExtended;
		INSERT INTO #connectionsInfoExtended
		SELECT SPID, Status, LOGIN,	HostName, BlkBy, DBName, Command, CPUTime, DiskIO, LastBatch, ProgramName, SPID_1, REQUESTID,
			wait_type AS [WaitType], blocking_session_id AS [BlockingSessionId], wait_duration_ms AS [WaitDurationMs]
		FROM #connectionsInfo c
			LEFT JOIN sys.dm_os_waiting_tasks w
				ON c.SPID = [w].[session_id];
		TRUNCATE TABLE #connectionsInfo;

		DECLARE badSessions CURSOR FOR
		SELECT
			REASONE.SPID,
			REASONE.DatabaseName
		FROM (
			SELECT [AC].[SPID],
				[SCS].[DatabaseName],
				[SCS].[AbortIfLockOtherSessions],
				[SCS].[AbortIfLockOtherSessionsTimeoutSec]
			FROM #connectionsInfoExtended AS [AC]
				FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
				ON [AC].[SPID] = [SCS].[SPID]
					AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
					AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
					AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
			WHERE -- Есть подходящие настройки ограничений для соединения
				[SCS].[SPID] IS NOT NULL	
				-- Исключаем статусы соединений
				AND NOT UPPER([Status]) IN (
					'BACKGROUND' -- Фоновые процессы
				)
				-- Только с контролем блокировку соединений
				AND [SCS].[AbortIfLockOtherSessions] = 1) REASONE
			LEFT JOIN (
				SELECT
					SPID AS [BlockedSessionId],
					BlockingSessionId,
					WaitType,
					WaitDurationMs
				FROM #connectionsInfoExtended blk
				WHERE WaitType IS NOT NULL
			) BLOCKED
			ON REASONE.SPID = BLOCKED.BlockingSessionId
			-- Учитываем только ожидания на блокировках
			WHERE WaitType LIKE 'LCK_%'
				-- И ожидания выше указанного таймаута
				AND ((WaitDurationMs/1000) >= REASONE.AbortIfLockOtherSessionsTimeoutSec)
				-- Блокируемый сеанс и блокирующий сеанс не должны совпадать.
				-- Такое возможно, когда соединения в разных потоках выполняет работу и эти потоки ждут друг друга.
				AND REASONE.SPID <> BLOCKED.[BlockedSessionId];
		OPEN badSessions;
	
		DECLARE @killCommand VARCHAR(15);
		DECLARE 
			@badSessionId int,
			@sessionDatabaseName nvarchar(max),
			@comment nvarchar(max),
			@RunDate datetime = GetDate(),
			@startDate datetime = GetDate(),
			@finishDate datetime = GetDate(),
			@MaintenanceActionLogId bigint;
		FETCH NEXT FROM badSessions INTO @badSessionId, @sessionDatabaseName;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @killCommand = 'KILL ' + CAST(@badSessionId AS VARCHAR(5));
			SET @comment = 'Соединение ' + CAST(@badSessionId AS VARCHAR(5)) +' блокирует работы других запросов и будет завершено.'

			EXECUTE [dbo].[sp_add_maintenance_action_log]
				''
				,''
				,'BLOCKING SESSION CONTROL'
				,@RunDate
				,@startDate
				,@finishDate
				,@sessionDatabaseName
				,0
				,@comment
				,0
				,0
				,@killCommand
				,@MaintenanceActionLogId OUTPUT;
						
			EXEC(@killCommand)

			EXEC [dbo].[sp_RemoveSessionControlSetting]
				@spid = @badSessionId;

			FETCH NEXT FROM badSessions INTO @badSessionId, @sessionDatabaseName;
		END

		CLOSE badSessions;  
		DEALLOCATE badSessions;

        WAITFOR DELAY '00:00:03'
	END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ControlTransactionLogUsage]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ControlTransactionLogUsage]
	@databaseNameFilter nvarchar(255) = null,
	@showDiagnosticMessages bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- Время работы задания ограничено 2 минутами, чтобы защитить
	-- зависания задания, если оно будет ожидать завершения других соединений
	DECLARE @currentDatabase nvarchar(250) = DB_NAME();
	EXECUTE [dbo].[sp_AddSessionControlSetting] 
	   @databaseName = @currentDatabase
	  ,@workFrom = '00:00:00'
	  ,@workTo = '00:00:00'
	  ,@timeTimeoutSec = 120;

	-- Очистка устаревших настроек контроля соединений
	EXEC [dbo].[sp_ClearOldSessionControlSettings];

	DECLARE @startDate datetime = GetDate(),
		@finishDate datetime = GetDate(),
		@MaintenanceActionLogId bigint;

	IF OBJECT_ID('tempdb..#dataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #dataFileInfoByDatabases;
	CREATE TABLE #dataFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		DataFileName varchar(255),
		DataFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[DataSizeMB] numeric(15,0),
		[DataMaxSizeMB] numeric(15,0),
		[DataFileCanGrow] bit,
		[DataFileFreeSpaceMB] numeric(15,0),
		[ResumableRebuildDataFileUsageMb] numeric(15,0)
	);

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
		SELECT name FROM sys.databases 
		WHERE state_desc = 'ONLINE' 
		AND NOT [name] IN ('master', 'tempdb', 'model', 'msdb');
	OPEN DatabaseList;
	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM DatabaseList INTO @CurrentDatabaseName;
		IF @@FETCH_STATUS = -1 BREAK;

		PRINT @CurrentDatabaseName

		-- Заполняем информации о файлах логов транзакций
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
		BEGIN TRY
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH
	
		-- Заполняем информации о файлах данных
		SET @SqlStatement = N'USE '
			+ QUOTENAME(@CurrentDatabaseName)
			+ CHAR(13)+ CHAR(10)
			+ N'
IF(EXISTS(SELECT * FROM sys.index_resumable_operations))
BEGIN
	INSERT INTO #dataFileInfoByDatabases
	SELECT
		DB_NAME(f.database_id) AS [Database],
		f.[name] AS [DataFileName],
		f.physical_name AS [DataFilePath],
		volume_mount_point AS [Disk],
		available_bytes/1048576 as [DiskFreeSpaceMB],
		CAST(f.size AS bigint) * 8 / 1024 AS [DataSizeMB],
		CAST(f.size AS bigint) * 8 / 1024 + CAST(available_bytes/1048576 AS bigint) AS [DataMaxSizeMB],
		CASE 
			WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
			THEN 0
			ELSE 1
		END AS [DataFileCanGrow],
		size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [DataFileFreeSpaceMB],
		ISNULL(rir.DataFileUsageMb, 0) AS [ResumableRebuildDataFileUsageMb]
	FROM sys.master_files AS f CROSS APPLY 
	  sys.dm_os_volume_stats(f.database_id, f.file_id)
	  LEFT JOIN (
			SELECT 
				disks.FileName,
				disks.PhysicalName,
				SUM(iro.page_count * 8 / 1024) AS [DataFileUsageMb]
			FROM sys.index_resumable_operations iro
				INNER JOIN (
					select 
						p.object_id AS [ObjectId],
						p.[index_id] AS [IndexId],
						ISNULL(p.[partition_number], 1) AS [PartitionNumber],
						f.[name] AS [FileName],
						f.physical_name AS [PhysicalName]
					from sys.allocation_units u 
						join sys.database_files f on u.data_space_id = f.data_space_id 
						join sys.partitions p on u.container_id = p.hobt_id
				) disks
				ON iro.object_id = disks.ObjectId
					AND iro.index_id = disks.IndexId
					AND ISNULL(iro.partition_number, 1) = disks.PartitionNumber
			GROUP BY disks.FileName, disks.PhysicalName
	  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
	WHERE [type_desc] = ''ROWS''
		and f.database_id = DB_ID()
END';

		BEGIN TRY			
			EXECUTE(@SqlStatement);
		END TRY
		BEGIN CATCH
			PRINT 'Не удалось получить информацию о файлах.'
		END CATCH

	END
	CLOSE DatabaseList;
	DEALLOCATE DatabaseList;
	
	DECLARE @databaseName sysname,
			@MinDiskFreeSpaceMB int,
			@MaxLogUsagePercentThreshold int,
			@MinAllowDataFileFreeSpaceForResumableRebuildMb int,
			@currentTransactionLogSizeFreePercent int,
			@currentTransactionLogSizeFreeMB int,
			@logUsageBadStatus bit = 0,
			@RunDate datetime = GETDATE(),
			@comment nvarchar(255),
			@message nvarchar(max);

	-- Проверка общих правил контроля использования лога транзакций
	DECLARE databasesUnderControl CURSOR FOR
    -- Правила для конкретных баз
	SELECT
		[DatabaseName],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold],[MinAllowDataFileFreeSpaceForResumableRebuildMb]
	FROM [dbo].[LogTransactionControlSettings]
	WHERE [DatabaseName] IS NOT NULL
		AND ([DatabaseName] = @databaseNameFilter or @databaseNameFilter IS NULL)
	UNION
    -- Правало общее для всех баз по умолчанию. 
    -- Кроме тех баз, для которых правила заданы явно.
	SELECT
		dbs.[name],[MinDiskFreeSpace],[MaxLogUsagePercentThreshold],[MinAllowDataFileFreeSpaceForResumableRebuildMb]
	FROM [sys].[databases] dbs
		LEFT JOIN [dbo].[LogTransactionControlSettings] ltcs
			ON ltcs.[DatabaseName] IS NULL
	WHERE [DatabaseName] IS NULL
		AND dbs.[name] NOT IN ('master','model','tempdb','msdb')
		AND NOT dbs.[name] IN (
			SELECT
				[DatabaseName]
			FROM [dbo].[LogTransactionControlSettings]
			WHERE [DatabaseName] IS NOT NULL
		)
		AND (dbs.[name] = @databaseNameFilter or @databaseNameFilter IS NULL);
	OPEN databasesUnderControl;

	FETCH NEXT FROM databasesUnderControl 
	INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold, @MinAllowDataFileFreeSpaceForResumableRebuildMb;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		BEGIN -- Проверка использования файлов данных
			-- Если поддерживается возобновляемое обслуживание, тогда
			-- проверка имеет смысл
			IF([dbo].fn_ResumableIndexMaintenanceAvailiable() = 1)
			BEGIN				
				-- Получаем использование файлов данных возобновляемыми операциями.
				-- Проверяем сколько свободного места в файле данных осталось
				-- с учетом возможности его роста.
				-- Если остается менее 300 ГБ (см. в настройке), то прерываем перестроение.
				-- Также отменяем возобновляемую операцию
				DECLARE
					@dataFileName nvarchar(max),
					@resumableRebuildDataFileUsageMb bigint,
					@totalAvailiableDataSpaceForRebuild bigint;
				DECLARE dataFileUsageByResumableRebuild CURSOR FOR
				SELECT
					DataFileName
					,ResumableRebuildDataFileUsageMb
					,DataMaxSizeMB - DataSizeMB + DataFileFreeSpaceMB AS [TotalAvailiableDataSpaceForRebuild]
				FROM #dataFileInfoByDatabases d
				WHERE d.DatabaseName = @databaseName
					AND ResumableRebuildDataFileUsageMb > 0
					AND (DataMaxSizeMB - DataSizeMB + DataFileFreeSpaceMB) <= @MinAllowDataFileFreeSpaceForResumableRebuildMb;
				OPEN dataFileUsageByResumableRebuild;
				FETCH NEXT FROM dataFileUsageByResumableRebuild 
				INTO @dataFileName, @resumableRebuildDataFileUsageMb, @totalAvailiableDataSpaceForRebuild;
				WHILE @@FETCH_STATUS = 0  
				BEGIN
					SET @message = 
							'Для базы данных ' + @databaseName + ' файла ' + @dataFileName + ' будут отменены все возобновляемые перестроения. ' +
							'Свободного места осталось ' + CAST(@totalAvailiableDataSpaceForRebuild AS nvarchar(max)) + 
							' МБ, при этом минимально допустимое значение ' + CAST(@MinAllowDataFileFreeSpaceForResumableRebuildMb AS nvarchar(max)) + ' МБ.';
					PRINT @message

					EXEC [dbo].[sp_AbortResumableIndexRebuilds]
						@databaseNameFilter = @databaseName,
						@dataFileName = @dataFileName;

					FETCH NEXT FROM dataFileUsageByResumableRebuild 
					INTO @dataFileName, @resumableRebuildDataFileUsageMb, @totalAvailiableDataSpaceForRebuild;
				END
				CLOSE dataFileUsageByResumableRebuild;  
				DEALLOCATE dataFileUsageByResumableRebuild;
			END
		END
		
		BEGIN -- Проверка использования файлов логов транзакций
			IF(@showDiagnosticMessages = 1)
			BEGIN
				SET @message = 'Запуск проверки лога транзакций для базы ' 
					+ @databaseName 
					+ '. Мин. свободное место на диске должно быть ' 
					+ CAST(@MinDiskFreeSpaceMB AS nvarchar(max))
					+ ' МБ. Мин. занятый % лога транзакций при этом '
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
				CASE WHEN [LogSizeMB] = 0 THEN 0 ELSE 100 - ([LogFileFreeSpaceMB] / ([LogSizeMB] / 100)) END AS [LogFileUsedPercent],
				CASE WHEN [TotalLogMaxSizeMB] = 0 THEN 0 ELSE 100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100) END AS [TotalLogFileUsedPercent]
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
					CASE WHEN [LogSizeMB] = 0 THEN 0 ELSE (100 - ([LogFileFreeSpaceMB] / ([LogSizeMB] / 100))) END >= @MaxLogUsagePercentThreshold AND [DiskFreeSpaceMB] <= @MinDiskFreeSpaceMB				
					OR
					-- Лог транзакций заполнен более чем на 95% от максимального размер лога (с учетом автоприроста)
					CASE WHEN [TotalLogMaxSizeMB] = 0 THEN 0 ELSE (100 - [TotalLogFileFreeMB] / ([TotalLogMaxSizeMB] / 100)) END >= @MaxLogUsagePercentThreshold
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
		END

		FETCH NEXT FROM databasesUnderControl 
		INTO @databaseName, @MinDiskFreeSpaceMB, @MaxLogUsagePercentThreshold, @MinAllowDataFileFreeSpaceForResumableRebuildMb;
	END
	CLOSE databasesUnderControl;  
	DEALLOCATE databasesUnderControl;
	
	-- Проверка правил использования лога транзакций по соединениям
	DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	)
	INSERT INTO @AllConnections EXEC sp_who2;

	DECLARE 
		@SPID int,
		@MaxLogUsagePercent int,
		@MaxLogUsageMb int,
		@curDatabaseName nvarchar(250),
		@TotalLogSizeMB int,
		@TotalUseLogSizeMB int,
		@curTotalLogFileUsedPercent int,
		@sql nvarchar(max),
		@msg nvarchar(max);
	DECLARE log_usage_session_cursor CURSOR FOR
	SELECT [AC].[SPID],
		[MaxLogUsagePercent], 
		[MaxLogUsageMb], 
		[SCS].[DatabaseName],
		-- Размер лога транзакций
		[TotalLogSizeMB],
		-- Использование лога транзакций в мегабайтах
		[TotalUseLogSizeMB],
		-- Процент использования файла лога транзакций
		[TotalUseLogSizeMB] / ([TotalLogSizeMB] / 100) AS [TotalLogFileUsedPercent]
	FROM @AllConnections AS [AC]
		FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
		ON [AC].[SPID] = [SCS].[SPID]
			AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
			AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
			AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		LEFT JOIN (
			SELECT
				DatabaseName,
				SUM(LogMaxSizeMB) AS [TotalLogMaxSizeMB],
				SUM(LogSizeMB) AS [TotalLogSizeMB],
				SUM(LogSizeMB - LogFileFreeSpaceMB) AS [TotalUseLogSizeMB],
				SUM(LogMaxSizeMB - (LogSizeMB - LogFileFreeSpaceMB)) AS [TotalLogFileFreeMB]
			FROM #logFileInfoByDatabases
			GROUP BY DatabaseName
		) lf
		ON [SCS].DatabaseName = lf.DatabaseName
	WHERE -- Есть подходящие настройки ограничений для соединения
		[SCS].[SPID] IS NOT NULL	
		-- Исключаем статусы соединений
		AND NOT UPPER([Status]) IN (
			'BACKGROUND' -- Фоновые процессы
			,'SLEEPING' -- Ожидающие команды, не активные
		)		
		AND (
			-- Проверка % использования лога транзакций
			CASE
				WHEN ISNULL([MaxLogUsagePercent], 0) > 0
				THEN CASE
						WHEN [MaxLogUsagePercent] <= [TotalUseLogSizeMB] / ([TotalLogSizeMB] / 100)
						THEN 1
						ELSE 0
					END				
				ELSE 0
			END > 0

			OR

			-- Проверка использования лога транзакций в МБ
			CASE			
				WHEN ISNULL([MaxLogUsageMb], 0) > 0
				THEN CASE
						WHEN [MaxLogUsageMb] <= [TotalUseLogSizeMB]
						THEN 1
						ELSE 0
					END
				ELSE 0
			END > 0
		)
	OPEN log_usage_session_cursor;
	FETCH NEXT FROM log_usage_session_cursor INTO 		
		@SPID,
		@MaxLogUsagePercent,
		@MaxLogUsageMb,
		@curDatabaseName,
		@TotalLogSizeMB,
		@TotalUseLogSizeMB,
		@curTotalLogFileUsedPercent;
	WHILE @@FETCH_STATUS = 0  
	BEGIN		
		SET @msg = 'Соединение ''' + CAST(@SPID AS nvarchar(max)) + ''' завершено, т.к. превышено допустимое использование лога транзакций. Соединение: ' + CAST(@SPID AS nvarchar(max)) + '. Текущее использование лога: ' + CAST(@TotalUseLogSizeMB  AS nvarchar(max))+ ', макс. доступно ' + CAST(@MaxLogUsageMb AS nvarchar(max)) + '. Текущий % использования: ' + CAST(@curTotalLogFileUsedPercent AS nvarchar(max)) + ' из макс. доступного ' + CAST(@MaxLogUsagePercent AS nvarchar(max)) + '.';
		PRINT @msg;

		SET @sql = 'KILL ' + CAST(@SPID as nvarchar(max));
		BEGIN TRY
			EXEC sp_executesql @sql;
		END TRY
		BEGIN CATCH
			SET @msg = 'Не удалось завершить соединение. ' +  @msg
			PRINT @msg
		END CATCH
		
		EXECUTE [dbo].[sp_add_maintenance_action_log]
			 ''
			,''
			,'TRANSACTION LOG CONTROL'
			,@runDate
			,@startDate
			,@finishDate
			,@curDatabaseName
			,0
			,@msg
			,0
			,0
			,@sql
			,@MaintenanceActionLogId OUTPUT;

		EXEC [dbo].[sp_RemoveSessionControlSetting]
			@spid = @SPID;

		FETCH NEXT FROM log_usage_session_cursor INTO 		
			@SPID,
			@MaxLogUsagePercent,
			@MaxLogUsageMb,
			@curDatabaseName,
			@TotalLogSizeMB,
			@TotalUseLogSizeMB,
			@curTotalLogFileUsedPercent;
	END
	CLOSE log_usage_session_cursor;  
	DEALLOCATE log_usage_session_cursor;

	IF OBJECT_ID('tempdb..#dataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #dataFileInfoByDatabases;
	IF OBJECT_ID('tempdb..#logFileInfoByDatabases') IS NOT NULL
		DROP TABLE #logFileInfoByDatabases;

	-- Удаляем контроль для текущей сессии
	EXEC [dbo].[sp_RemoveSessionControlSetting];
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CreateOrUpdateExtendedEventSessions]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CreateOrUpdateExtendedEventSessions]
	@startSessions bit = 1,
	@logPath nvarchar(max) = 'G:\Logs_SQL'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql nvarchar(max);

	-- Создаем каталог для логов, если его еще нет
	SET @sql = 'EXEC master.sys.xp_create_subdir N''' + @logPath + ''''
	EXECUTE sp_executesql @sql
	
	-- Сессия сбора по ошибкам
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'Errors'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [Errors] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [Errors] ON SERVER
ADD EVENT sqlserver.error_reported(     ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.username)
	WHERE ([severity]>(10)))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\Errors.xel'',max_file_size=(100),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON);
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [Errors] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END

	-- Сессия сбора тяжелых запросов по ЦП
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'HeavyQueryByCPU'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [HeavyQueryByCPU] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [HeavyQueryByCPU] ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(100000))))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\HeavyQueryByCPU.xel'',max_file_size=(500),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [HeavyQueryByCPU] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END


	-- Сессия сбора тяжелых запросов по чтениям
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'HeavyQueryByReads'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [HeavyQueryByReads] ON SERVER'
		EXEC sp_executesql @sql
	END
	SET @sql = N'
CREATE EVENT SESSION [HeavyQueryByReads] ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([logical_reads]>(12500))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([logical_reads]>(12500)))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\HeavyQueryByReads.xel'',max_file_size=(500),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [HeavyQueryByReads] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END

	-- Сессия сбора информации об ожиданиях на блокировках
	IF(EXISTS(SELECT * FROM sys.dm_xe_sessions RS
					RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
				WHERE es.name = 'BlocksAndDeadlocksAnalyse'))
	BEGIN
		SET @sql = 'DROP EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER'
		EXEC sp_executesql @sql
	END

	SET @sql = N'
EXEC sp_configure ''show advanced options'', 1;
RECONFIGURE;
EXEC sp_configure ''blocked process threshold'', ''5'';
RECONFIGURE;
'
	EXEC sp_executesql @sql

	SET @sql = N'
CREATE EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_instance_name)),
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_instance_name))
ADD TARGET package0.event_file(SET filename=N''' + @logPath + '\LockAndDeadlockAnalyzeReports.xel'',max_file_size=(100),max_rollover_files=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
'
	EXEC sp_executesql @sql
	IF(@startSessions = 1)
	BEGIN
		SET @sql = 'ALTER EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER  STATE = START'
		EXECUTE sp_executesql  @sql
	END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CreateOrUpdateJobsBySettings]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CreateOrUpdateJobsBySettings]
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
GO
/****** Object:  StoredProcedure [dbo].[sp_CreateSimpleJob]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
GO
/****** Object:  StoredProcedure [dbo].[sp_FillConnectionsStatistic]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_FillConnectionsStatistic]
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @cmd nvarchar(max),
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

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
/****** Object:  StoredProcedure [dbo].[sp_FillDatabaseObjectsState]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_FillDatabaseObjectsState]
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max),
			@monitoringDatabaseName sysname = DB_NAME(),
			@useMonitoringDatabase bit = 1;

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
  ISNULL(ind.name, '''') AS [Object],
  MAX(CAST([page_count] AS BIGINT)) AS [page_count], 
  MAX(CAST([si].[rowmodctr] AS BIGINT)) AS [rowmodctr],
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
	ON dt.object_id = p.object_id AND p.partition_number = dt.partition_number
	AND dt.index_id = p.index_id
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
	LEFT JOIN sys.sysindexes si ON dt.object_id = si.id 
		AND si.name = ind.name
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
/****** Object:  StoredProcedure [dbo].[sp_FixMissingStatisticOnAlwaysOnReplica]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_FixMissingStatisticOnAlwaysOnReplica]
	@databaseName sysname = null
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max),
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
		WHERE o.is_ms_shipped = 0
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
/****** Object:  StoredProcedure [dbo].[sp_GetCurrentResumableIndexRebuilds]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_IndexMaintenance]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_IndexMaintenance]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
	@timeTimeoutSec int = 600,
    @fragmentationPercentMinForMaintenance FLOAT = 10.0,
    @fragmentationPercentForRebuild FLOAT = 30.0,
    @maxDop int = 8,
    @minIndexSizePages int = 0,
    @maxIndexSizePages int = 0,
    @useOnlineIndexRebuild int = 0,
	@useResumableIndexRebuildIfAvailable int = 0,
	@onlyResumeIfExistIndexRebuildOperation bit = 0,
    @maxIndexSizeForReorganizingPages int = 6553600,
    @usePreparedInformationAboutObjectsStateIfExists bit = 0,
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
    @ConditionIndexName nvarchar(max) = 'LIKE ''%''',
    @onlineRebuildAbortAfterWaitMode int = 1,
    @onlineRebuildWaitMinutes int = 5,
    @maxTransactionLogSizeUsagePercent int = 999,  
    @maxTransactionLogSizeMB bigint = 0,
	@fillFactorForIndex int = 0
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @msg nvarchar(max),
            @abortAfterWaitOnlineRebuil nvarchar(25),
            @currentTransactionLogSizeUsagePercent int,
            @currentTransactionLogSizeMB int,
			@useResumableIndexRebuild bit,
			@timeNow TIME = CAST(GETDATE() AS TIME),
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

	-- Включаем контроль потребления ресурсов текущим соединением
	EXEC [dbo].[sp_AddSessionControlSetting]
		@databaseName = @databaseName,
		@workFrom = @timeFrom,
		@workTo = @timeTo,
		@timeTimeoutSec = @timeTimeoutSec,
		@maxLogUsagePercent = @maxTransactionLogSizeUsagePercent,
		@maxLogUsageMb = @maxTransactionLogSizeMB;

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

	if(@onlyResumeIfExistIndexRebuildOperation = 1)
	BEGIN
		-- Удаляем контроль для текущей сессии
		EXEC [dbo].[sp_RemoveSessionControlSetting];
		-- Останавливаем дальнейшее обслуживание, т.к. передан флаг выполнения только возобновляемых операций,
		-- которые были на паузе.
		RETURN 0;
	END

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
    INSERT INTO #tranLogInfo (dbname,logsize,logspace,stat) exec(''dbcc sqlperf(logspace)'')
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

	-- Удаляем контроль для текущей сессии
	EXEC [dbo].[sp_RemoveSessionControlSetting];

    RETURN 0
END
GO
/****** Object:  StoredProcedure [dbo].[sp_remove_maintenance_action_to_run]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_RemoveSessionControlSetting]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_RemoveSessionControlSetting]
	@spid int = null
AS
BEGIN
	SET NOCOUNT ON;

	if(@spid is null)
	BEGIN
		SELECT @spid = @@SPID
	END

    DELETE FROM [dbo].[SessionControlSettings]
	WHERE [SPID] = @spid;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_RestartMonitoringXEventSessions]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_RestartMonitoringXEventSessions]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @xevents_name nvarchar(250),
			@cmd nvarchar(max);
	DECLARE xevents_cursor CURSOR FOR
	SELECT
	   ES.name AS [xevents_session_name]
	FROM sys.dm_xe_sessions RS
		RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
	WHERE iif(RS.name IS NULL, 0, 1) = 1
		AND es.name IN (
			'HeavyQueryByReads',
			'HeavyQueryByCPU',
			'Errors',
			'BlocksAndDeadlocksAnalyse'
		)
	OPEN xevents_cursor  
	FETCH NEXT FROM xevents_cursor INTO @xevents_name
	WHILE @@FETCH_STATUS = 0
	BEGIN    
  
		SET @cmd = 'ALTER EVENT SESSION ' + @xevents_name + ' ON SERVER  STATE = STOP'
		EXECUTE sp_executesql  @cmd
  
		SET @cmd = 'ALTER EVENT SESSION ' + @xevents_name + ' ON SERVER  STATE = START'
		EXECUTE sp_executesql  @cmd
  
		FETCH NEXT FROM xevents_cursor INTO @xevents_name
	END 
  
	CLOSE xevents_cursor;
	DEALLOCATE xevents_cursor;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_SaveDatabasesTablesStatistic]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_set_maintenance_action_log_finish_date]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[sp_ShrinkDatabaseDataFile]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ShrinkDatabaseDataFile] 
	@databaseName sysname,
	@databaseFileName nvarchar(512) = null,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@delayBetweenSteps nvarchar(8) = '00:00:10',
	@shrinkStepMb int = 10240,
	@stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3) = 1.0
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE		
	   @sql nvarchar(max)
	   ,@msg nvarchar(max);

	IF DB_ID(@databaseName) IS NULL
	BEGIN
		SET @msg = 'Database ' + @databaseName + ' is not exists.';
		THROW 51000, @msg, 1;
		RETURN -1;
	END

	IF OBJECT_ID('tempdb..#dataFileInfoByDatabases') IS NOT NULL
		DROP TABLE #dataFileInfoByDatabases;
	CREATE TABLE #dataFileInfoByDatabases
	(
		DatabaseName varchar(255) not null,
		DataFileName varchar(255),
		DataFilePath varchar(max),
		[Disk] varchar(25),
		[DiskFreeSpaceMB] numeric(15,0),
		[DataSizeMB] numeric(15,0),
		[DataMaxSizeMB] numeric(15,0),
		[DataFileCanGrow] bit,
		[DataFileFreeSpaceMB] numeric(15,0),
		[ResumableRebuildDataFileUsageMb] numeric(15,0)
	);

	-- Заполняем информации о файлах данных
	SET @sql = N'USE '
		+ QUOTENAME(@databaseName)
		+ CHAR(13)+ CHAR(10)
		+ N'
		INSERT INTO #dataFileInfoByDatabases
		SELECT
			DB_NAME(f.database_id) AS [Database],
			f.[name] AS [DataFileName],
			f.physical_name AS [DataFilePath],
			volume_mount_point AS [Disk],
			available_bytes/1048576 as [DiskFreeSpaceMB],
			CAST(f.size AS bigint) * 8 / 1024 AS [DataSizeMB],
			CAST(f.size AS bigint) * 8 / 1024 + CAST(available_bytes/1048576 AS bigint) AS [DataMaxSizeMB],
			CASE 
				WHEN (CAST(f.size AS bigint) * 8 / 1024) = (CAST(CASE WHEN f.max_size = 0 THEN 268435456 ELSE f.max_size END AS bigint) * 8 / 1024)
				THEN 0
				ELSE 1
			END AS [DataFileCanGrow],
			size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS [DataFileFreeSpaceMB],
			ISNULL(rir.DataFileUsageMb, 0) AS [ResumableRebuildDataFileUsageMb]
		FROM sys.master_files AS f CROSS APPLY 
		  sys.dm_os_volume_stats(f.database_id, f.file_id)
		  LEFT JOIN (
				SELECT 
					disks.FileName,
					disks.PhysicalName,
					SUM(iro.page_count * 8 / 1024) AS [DataFileUsageMb]
				FROM sys.index_resumable_operations iro
					INNER JOIN (
						select 
							p.object_id AS [ObjectId],
							p.[index_id] AS [IndexId],
							ISNULL(p.[partition_number], 1) AS [PartitionNumber],
							f.[name] AS [FileName],
							f.physical_name AS [PhysicalName]
						from sys.allocation_units u 
							join sys.database_files f on u.data_space_id = f.data_space_id 
							join sys.partitions p on u.container_id = p.hobt_id
					) disks
					ON iro.object_id = disks.ObjectId
						AND iro.index_id = disks.IndexId
						AND ISNULL(iro.partition_number, 1) = disks.PartitionNumber
				GROUP BY disks.FileName, disks.PhysicalName
		  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
		WHERE [type_desc] = ''ROWS''
			and f.database_id = DB_ID()';

	BEGIN TRY			
		EXECUTE(@sql);
	END TRY
	BEGIN CATCH
		PRINT 'Не удалось получить информацию о файлах.'
	END CATCH

	IF(@databaseFileName IS NULL)
	BEGIN
		IF(EXISTS(SELECT COUNT(*) FROM #dataFileInfoByDatabases HAVING(COUNT(*) > 1)))
		BEGIN
			SET @msg = 'Required to setup parameter @databaseFileName. Database has multiple data files.';
			THROW 51000, @msg, 1;
			RETURN -1;
		END

		SELECT @databaseFileName = DataFileName FROM #dataFileInfoByDatabases
	END
	ELSE BEGIN
		PRINT 1
		IF(NOT EXISTS(SELECT * FROM #dataFileInfoByDatabases WHERE DataFileName = @databaseFileName))
		BEGIN
			SET @msg = 'Data file with name ' + @databaseFileName + 'not exists.';
			THROW 51000, @msg, 1;
			--RETURN -1;
		END
	END

	SET @sql = CAST('
	USE [' as nvarchar(max)) + CAST(@databaseName as nvarchar(max)) + CAST('];
	DECLARE @currentFreeSpaceDataFilePercent numeric(15,3) = 0;
	IF(NOT EXISTS(SELECT * FROM sys.index_resumable_operations))
	BEGIN
		DECLARE @totalDatabaseSize BIGINT;
		WHILE 1 = 1
		BEGIN
			-- Включаем контроль потребления ресурсов текущим соединением
			if(@timeFrom is not null and @timeTo is not null)
			BEGIN
				EXEC [SQLServerMonitoring].[dbo].[sp_AddSessionControlSetting]
					@databaseName = @databaseName,
					@workFrom = @timeFrom,
					@workTo = @timeTo,
					@timeTimeoutSec = 60,
					@abortIfLockOtherSessions = 1,
					@abortIfLockOtherSessionsTimeoutSec = 0;
			END

		  SELECT
			@totalDatabaseSize = [Size] / 128.0
		  FROM sys.database_files (NOLOCK) 
		  WHERE [name] = @databaseFileName
		  OPTION (RECOMPILE)
		  set @totalDatabaseSize = @totalDatabaseSize - @shrinkStepMb
  
		  PRINT @totalDatabaseSize

		  DBCC SHRINKFILE (@databaseFileName , @totalDatabaseSize)  

		  -- Удаляем контроль для текущей сессии
		  EXEC [SQLServerMonitoring].[dbo].[sp_RemoveSessionControlSetting];

		  -- Проверяем границу свободного пространства в файле данных
		SELECT
			@currentFreeSpaceDataFilePercent = CAST(size/128.0 - CAST(FILEPROPERTY(f.[name],''SpaceUsed'') AS INT)/128.0 AS numeric(15,0)) / CAST(CAST(f.size AS bigint) * 8 / 1024 AS numeric(15,0)) * 100
		FROM sys.master_files AS f CROSS APPLY 
			sys.dm_os_volume_stats(f.database_id, f.file_id)
				LEFT JOIN (
						SELECT 
							disks.FileName,
							disks.PhysicalName,
							SUM(iro.page_count * 8 / 1024) AS [DataFileUsageMb]
						FROM sys.index_resumable_operations iro
							INNER JOIN (
								select 
									p.object_id AS [ObjectId],
									p.[index_id] AS [IndexId],
									ISNULL(p.[partition_number], 1) AS [PartitionNumber],
									f.[name] AS [FileName],
									f.physical_name AS [PhysicalName]
								from sys.allocation_units u 
									join sys.database_files f on u.data_space_id = f.data_space_id 
									join sys.partitions p on u.container_id = p.hobt_id
							) disks
							ON iro.object_id = disks.ObjectId
								AND iro.index_id = disks.IndexId
								AND ISNULL(iro.partition_number, 1) = disks.PartitionNumber
						GROUP BY disks.FileName, disks.PhysicalName
				  ) rir ON f.[name] = rir.FileName and f.physical_name = rir.PhysicalName
		WHERE [type_desc] = ''ROWS'' and f.database_id = DB_ID()
			AND f.[name] = @databaseFileName;

		  if(@stopShrinkThresholdByDataFileFreeSpacePercent >= @currentFreeSpaceDataFilePercent)
		  BEGIN
			PRINT ''Достигнута граница свободного пространства. Сжатие (shrink) файла данных остановлено.''
			return
		  END

		  WAITFOR DELAY @delayBetweenSteps
		END
	END
	' AS nvarchar(max));

	EXECUTE sp_executesql
			@sql,
			N'@databaseName sysname, @databaseFileName nvarchar(512), @timeFrom TIME, @timeTo TIME, @delayBetweenSteps nvarchar(8), @shrinkStepMb int, @stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3)',
			@databaseName, @databaseFileName, @timeFrom, @timeTo, @delayBetweenSteps, @shrinkStepMb, @stopShrinkThresholdByDataFileFreeSpacePercent;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_StatisticMaintenance]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_StatisticMaintenance]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
	@timeTimeoutSec int = 600,
    @mode int = 0,
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
	@ConditionIndexName nvarchar(max) = 'LIKE ''%''',
	@ConditionStatisticName nvarchar(max) = 'LIKE ''%''',
	@MinRowsChangedToMaintenance bigint = 1,
	@abortIfLockOtherSessions bit = 0,
	@abortIfLockOtherSessionsTimeoutSec int = 0
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE 			
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;

	-- Проверка доступен ли запуск обслуживания в текущее время
	DECLARE @timeNow TIME = CAST(GETDATE() AS TIME);
	IF (@timeTo >= @timeFrom) BEGIN
		IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
			RETURN;
		END ELSE BEGIN
			IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
				OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow))) 
					RETURN;
	END
 
 	-- Включаем контроль потребления ресурсов текущим соединением
	EXEC [dbo].[sp_AddSessionControlSetting]
		@databaseName = @databaseName,
		@workFrom = @timeFrom,
		@workTo = @timeTo,
		@timeTimeoutSec = @timeTimeoutSec,
		@abortIfLockOtherSessions = @abortIfLockOtherSessions,
		@abortIfLockOtherSessionsTimeoutSec = @abortIfLockOtherSessionsTimeoutSec;

    IF(@mode = 0)
    BEGIN
        EXECUTE [dbo].[sp_StatisticMaintenance_Sampled]
           @databaseName
          ,@timeFrom
          ,@timeTo
          ,@ConditionTableName
		  ,@ConditionIndexName
		  ,@ConditionStatisticName
		  ,@MinRowsChangedToMaintenance
          ,@useMonitoringDatabase
          ,@monitoringDatabaseName
    END ELSE IF(@mode = 1)
    BEGIN
        EXECUTE [dbo].[sp_StatisticMaintenance_Detailed]
           @databaseName
          ,@timeFrom
          ,@timeTo
          ,@ConditionTableName
		  ,@ConditionIndexName
		  ,@ConditionStatisticName
		  ,@MinRowsChangedToMaintenance
          ,@useMonitoringDatabase
          ,@monitoringDatabaseName
    END

	-- Удаляем контроль для текущей сессии
	EXEC [dbo].[sp_RemoveSessionControlSetting];
 
    RETURN 0
END
GO
/****** Object:  StoredProcedure [dbo].[sp_StatisticMaintenance_Detailed]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_StatisticMaintenance_Detailed]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59', 
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
	@ConditionIndexName nvarchar(max) = 'LIKE ''%''',
	@ConditionStatisticName nvarchar(max) = 'LIKE ''%''',
	@MinRowsChangedToMaintenance bigint = 1,
    @useMonitoringDatabase bit = 1,
    @monitoringDatabaseName sysname = 'SQLServerMonitoring'
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
    AND [rowmodctr] >= @MinRowsChangedToMaintenance
    AND [o].[name] ' AS nvarchar(max)) + CAST(@ConditionTableName AS nvarchar(max)) + CAST('
	AND CASE WHEN [si].[root] IS NULL THEN '''' ELSE [si].[name] END ' AS nvarchar(max)) + CAST(@ConditionIndexName AS nvarchar(max)) + CAST('
	AND [s].[name] ' AS nvarchar(max)) + CAST(@ConditionStatisticName AS nvarchar(max)) + CAST('
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
        @useMonitoringDatabase bit, @monitoringDatabaseName sysname, @MinRowsChangedToMaintenance bigint',
        @timeFrom, @timeTo,
        @useMonitoringDatabase, @monitoringDatabaseName, @MinRowsChangedToMaintenance;
 
    RETURN 0
END
GO
/****** Object:  StoredProcedure [dbo].[sp_StatisticMaintenance_Sampled]    Script Date: 11.06.2025 18:05:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_StatisticMaintenance_Sampled]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
	@ConditionIndexName nvarchar(max) = 'LIKE ''%''',
	@ConditionStatisticName nvarchar(max) = 'LIKE ''%''',
	@MinRowsChangedToMaintenance bigint = 1,
    @useMonitoringDatabase bit = 1,
    @monitoringDatabaseName sysname = 'SQLServerMonitoring'
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
            IF ((@table_type = ''U'') AND (1 = OBJECTPROPERTY(@table_id, ''TableIsMemoryOptimized'')))  -- In-Memory OLTP
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
                    AND CASE WHEN [auto_created] = 1 THEN '''' ELSE [name] END ' AS nvarchar(max)) + CAST(@ConditionIndexName AS nvarchar(max)) + CAST('
                    AND [name] ' AS nvarchar(max)) + CAST(@ConditionStatisticName AS nvarchar(max)) + CAST('
					AND modification_counter >= @MinRowsChangedToMaintenance
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
                    AND CASE WHEN [root] IS NULL THEN '''' ELSE [name] END ' AS nvarchar(max)) + CAST(@ConditionIndexName AS nvarchar(max)) + CAST('
                    AND [name] ' AS nvarchar(max)) + CAST(@ConditionStatisticName AS nvarchar(max)) + CAST('
				AND rowmodctr >= @MinRowsChangedToMaintenance
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
        @useMonitoringDatabase bit, @monitoringDatabaseName sysname, @MinRowsChangedToMaintenance bigint',
        @timeFrom, @timeTo,
        @useMonitoringDatabase, @monitoringDatabaseName, @MinRowsChangedToMaintenance;
 
    RETURN 0
END
GO
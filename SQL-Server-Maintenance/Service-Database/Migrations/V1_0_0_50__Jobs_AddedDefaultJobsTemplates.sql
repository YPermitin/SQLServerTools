TRUNCATE TABLE [dbo].[JobTemplates];
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
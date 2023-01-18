IF(OBJECT_ID('dbo.MaintenanceActionsLog') IS NOT NULL)
BEGIN
	IF NOT EXISTS(SELECT 1
	FROM sys.columns
	WHERE Name = N'TransactionLogUsageBeforeMB'
		AND Object_ID = Object_ID(N'dbo.MaintenanceActionsLog'))
	BEGIN
		DECLARE @sql nvarchar(max)
		
		SET @sql = '
BEGIN TRANSACTION

ALTER TABLE dbo.MaintenanceActionsLog ADD
	TransactionLogUsageBeforeMB bigint NOT NULL CONSTRAINT DF_MaintenanceActionsLog_TransactionLogUsageBeforeMB DEFAULT 0,
	TransactionLogUsageAfterMB bigint NULL

ALTER TABLE dbo.MaintenanceActionsLog SET (LOCK_ESCALATION = TABLE)

COMMIT'
		EXECUTE sp_executesql @sql
		

		SET @sql = '
ALTER PROCEDURE [dbo].[sp_add_maintenance_action_log]
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
    INSERT INTO @tranLogInfo (dbname,logsize,logspace,stat) exec(''dbcc sqlperf(logspace)'')
    SELECT
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM @tranLogInfo WHERE dbname = @databaseName

	SET @TableName = REPLACE(@TableName, ''['', '''')
	SET @TableName = REPLACE(@TableName, '']'', '''')
	SET @IndexName = REPLACE(@IndexName, ''['', '''')
	SET @IndexName = REPLACE(@IndexName, '']'', '''')
	SET @DatabaseName = REPLACE(@DatabaseName, ''['', '''')
	SET @DatabaseName = REPLACE(@DatabaseName, '']'', '''')

	SET @RowModCtr = ISNULL(@RowModCtr,0);
	
	SET @SQLCommand = LTRIM(RTRIM((REPLACE(REPLACE(@SQLCommand, CHAR(13), ''''), CHAR(10), ''''))));

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
END'
		EXECUTE sp_executesql @sql

		SET @sql = '
ALTER PROCEDURE [dbo].[sp_set_maintenance_action_log_finish_date]
	@MaintenanceActionLogId bigint,
	@FinishDate datetime2(0),
	@Comment nvarchar(255) = ''''
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
    INSERT INTO @tranLogInfo (dbname,logsize,logspace,stat) exec(''dbcc sqlperf(logspace)'')
    SELECT
        @currentTransactionLogSizeMB = logsize * (logspace / 100)
    FROM @tranLogInfo WHERE dbname = @databaseName

	UPDATE [dbo].[MaintenanceActionsLog]
	SET FinishDate = @FinishDate, 
		Comment = @Comment,
		TransactionLogUsageAfterMB = @currentTransactionLogSizeMB
	WHERE Id = @MaintenanceActionLogId
	RETURN 0
END'
		EXECUTE sp_executesql @sql
	END
END